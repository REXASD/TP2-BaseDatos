CREATE OR ALTER PROCEDURE dbo.sp_ProcesarFechaOperacion
    @inFecha DATE,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        ----------------------------------------------------------------
        -- a) Constantes
        ----------------------------------------------------------------
        DECLARE @true BIT = 1,
                @false BIT = 0;

        ----------------------------------------------------------------
        -- b) Variables
        ----------------------------------------------------------------
        DECLARE @Procesada BIT;
        DECLARE @IdOp INT;
        DECLARE @Nodo VARCHAR(128);
        DECLARE @Datos XML;

        DECLARE @ResultadoSP INT;
        DECLARE @IdEstado INT;
        DECLARE @IdEstadoNuevo INT;

        DECLARE @IdTipo INT;
        DECLARE @IdPersona INT;
        DECLARE @IdCuenta INT;
        DECLARE @IdUsuario INT;

        DECLARE @Doc VARCHAR(64);
        DECLARE @NumeroCuenta VARCHAR(32);
        DECLARE @User VARCHAR(64);

        DECLARE @Tipo VARCHAR(128);
        DECLARE @Monto DECIMAL(18,2);
        DECLARE @Descripcion VARCHAR(256);

        DECLARE @FechaMov DATETIME;
        DECLARE @Saldo DECIMAL(18,2);

        DECLARE @TipoDocumento INT;
        DECLARE @Nombre VARCHAR(64);
        DECLARE @FechaNacimiento DATE;
        DECLARE @Email VARCHAR(128);
        DECLARE @Telefono1 VARCHAR(32);
        DECLARE @Telefono2 VARCHAR(32);

        DECLARE @TipoCuenta INT;
        DECLARE @FechaCreacion DATE;

        DECLARE @IdParentezco INT;
        DECLARE @Porcentaje INT;

        DECLARE @EsAdministrador BIT;
        DECLARE @Password VARCHAR(256);

        DECLARE @Mensaje VARCHAR(MAX);
        DECLARE @Candado INT;
        DECLARE @TieneCandado BIT = 0;

        SET @outResult = 50000;

        ----------------------------------------------------------------
        -- c) Validaciones iniciales
        ----------------------------------------------------------------
        IF @inFecha IS NULL
        BEGIN
            THROW 50400, 'Debe indicar una fecha valida.', 1;
        END;

        IF @@TRANCOUNT <> 0
        BEGIN
            THROW 50400,
                'Ejecute la simulacion sin una transaccion externa.',
                1;
        END;

        ----------------------------------------------------------------
        -- d) Obtener candado exclusivo de sesion
        ----------------------------------------------------------------
        EXEC @Candado = sys.sp_getapplock
            @Resource = 'sp_ProcesarSimulacion',
            @LockMode = 'Exclusive',
            @LockOwner = 'Session',
            @LockTimeout = 0;

        IF @Candado < 0
        BEGIN
            THROW 50420,
                'Ya hay un proceso de simulacion en ejecucion.',
                1;
        END;

        SET @TieneCandado = 1;

        ----------------------------------------------------------------
        -- e) Validar existencia y estado de la fecha
        ----------------------------------------------------------------
        SELECT
            @Procesada = cf.flag_procesada
        FROM dbo.ControlFechaOperacion AS cf
        WHERE cf.Fecha = @inFecha;

        IF @Procesada IS NULL
        BEGIN
            THROW 50401,
                'La fecha no existe en ControlFechaOperacion.',
                1;
        END;

        IF @Procesada = @true
        BEGIN
            EXEC sys.sp_releaseapplock
                @Resource = 'sp_ProcesarSimulacion',
                @LockOwner = 'Session';

            SET @TieneCandado = 0;
            SET @outResult = 0;

            RETURN 0;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.ControlFechaOperacion AS cf
            WHERE cf.Fecha < @inFecha
              AND cf.flag_procesada = @false
        )
        BEGIN
            THROW 50402,
                'Hay fechas anteriores sin procesar; deben procesarse primero.',
                1;
        END;

        ----------------------------------------------------------------
        -- f) Registrar intento de procesamiento
        ----------------------------------------------------------------
        UPDATE dbo.ControlFechaOperacion
        SET
            Intentos = Intentos + 1,
            FechaUltimoIntento = GETDATE()
        WHERE Fecha = @inFecha
          AND flag_procesada = @false;

        SET @FechaMov = CONVERT(DATETIME, @inFecha);

        ----------------------------------------------------------------
        -- g) Procesar operaciones XML pendientes
        ----------------------------------------------------------------
        WHILE 1 = 1
        BEGIN
            SET @IdOp = NULL;
            SET @Nodo = NULL;
            SET @Datos = NULL;

            SELECT TOP (1)
                @IdOp = ox.IdOperacionXML,
                @Nodo = ox.NombreNodo,
                @Datos = ox.Datos
            FROM dbo.OperacionXML AS ox
            WHERE ox.Fecha = @inFecha
              AND ox.flag_procesada = @false
            ORDER BY
                ox.OrdenEnArchivo,
                ox.IdOperacionXML;

            IF @IdOp IS NULL
                BREAK;

            BEGIN TRANSACTION;

            ------------------------------------------------------------
            -- g.1) Movimientos
            ------------------------------------------------------------
            IF @Nodo = 'Movimientos'
            BEGIN
                IF @Datos.exist(
                    '(/*/@CodigoCuenta)[1]'
                ) = 0
                OR @Datos.exist(
                    '(/*/@Tipo)[1]'
                ) = 0
                OR @Datos.exist(
                    '(/*/@Monto)[1]'
                ) = 0
                BEGIN
                    THROW 50413,
                        'El movimiento XML no contiene cuenta, tipo o monto.',
                        1;
                END;

                SET @NumeroCuenta = @Datos.value(
                    '(/*/@CodigoCuenta)[1]',
                    'VARCHAR(32)'
                );

                SET @Tipo = @Datos.value(
                    '(/*/@Tipo)[1]',
                    'VARCHAR(128)'
                );

                SET @Monto = @Datos.value(
                    '(/*/@Monto)[1]',
                    'DECIMAL(18,2)'
                );

                SET @Descripcion = '';

                IF @Datos.exist('(/*/@Descripcion)[1]') = 1
                BEGIN
                    SET @Descripcion = @Datos.value(
                        '(/*/@Descripcion)[1]',
                        'VARCHAR(256)'
                    );
                END;

                IF @NumeroCuenta IS NULL
                   OR LTRIM(RTRIM(@NumeroCuenta)) = ''
                   OR @Tipo IS NULL
                   OR LTRIM(RTRIM(@Tipo)) = ''
                   OR @Monto <= 0
                BEGIN
                    THROW 50413,
                        'Los datos del movimiento XML no son validos.',
                        1;
                END;

                SET @IdTipo = NULL;

                SELECT
                    @IdTipo = tm.Id
                FROM dbo.TipoMovimiento AS tm
                WHERE tm.Nombre = LTRIM(RTRIM(@Tipo));

                IF @IdTipo IS NULL
                BEGIN
                    THROW 50403,
                        'El tipo de movimiento del XML no existe en el catalogo.',
                        1;
                END;

                SET @ResultadoSP = 50000;

                EXEC dbo.sp_AplicarMovimiento
                    @inNumeroCuenta = @NumeroCuenta,
                    @inIdTipoMovimiento = @IdTipo,
                    @inFecha = @FechaMov,
                    @inMonto = @Monto,
                    @inDescripcion = @Descripcion,
                    @outResult = @ResultadoSP OUTPUT,
                    @inIdOperacionXML = @IdOp;

                IF @ResultadoSP <> 0
                BEGIN
                    THROW 50404,
                        'No fue posible aplicar un movimiento del XML.',
                        1;
                END;
            END;

            ------------------------------------------------------------
            -- g.2) Personas
            ------------------------------------------------------------
            ELSE IF @Nodo = 'Persona'
            BEGIN
                SET @Doc = NULL;

                IF @Datos.exist(
                    '(/*/@ValorDocumentoIdentidad)[1]'
                ) = 1
                BEGIN
                    SET @Doc = @Datos.value(
                        '(/*/@ValorDocumentoIdentidad)[1]',
                        'VARCHAR(64)'
                    );
                END;
                ELSE IF @Datos.exist(
                    '(/*/@ValorDocumentoIdentidadDelCliente)[1]'
                ) = 1
                BEGIN
                    SET @Doc = @Datos.value(
                        '(/*/@ValorDocumentoIdentidadDelCliente)[1]',
                        'VARCHAR(64)'
                    );
                END;

                IF @Doc IS NULL
                   OR @Datos.exist('(/*/@TipoDocuIdentidad)[1]') = 0
                   OR @Datos.exist('(/*/@Nombre)[1]') = 0
                   OR @Datos.exist('(/*/@FechaNacimiento)[1]') = 0
                BEGIN
                    THROW 50413,
                        'El nodo Persona no contiene todos los datos obligatorios.',
                        1;
                END;

                SET @TipoDocumento = @Datos.value(
                    '(/*/@TipoDocuIdentidad)[1]',
                    'INT'
                );

                SET @Nombre = @Datos.value(
                    '(/*/@Nombre)[1]',
                    'VARCHAR(64)'
                );

                SET @FechaNacimiento = @Datos.value(
                    '(/*/@FechaNacimiento)[1]',
                    'DATE'
                );

                SET @Email = '';
                SET @Telefono1 = '';
                SET @Telefono2 = '';

                IF @Datos.exist('(/*/@Email)[1]') = 1
                BEGIN
                    SET @Email = @Datos.value(
                        '(/*/@Email)[1]',
                        'VARCHAR(128)'
                    );
                END;

                IF @Datos.exist('(/*/@telefono1)[1]') = 1
                BEGIN
                    SET @Telefono1 = @Datos.value(
                        '(/*/@telefono1)[1]',
                        'VARCHAR(32)'
                    );
                END;

                IF @Datos.exist('(/*/@telefono2)[1]') = 1
                BEGIN
                    SET @Telefono2 = @Datos.value(
                        '(/*/@telefono2)[1]',
                        'VARCHAR(32)'
                    );
                END;

                IF EXISTS (
                    SELECT 1
                    FROM dbo.Persona AS p WITH (UPDLOCK, HOLDLOCK)
                    WHERE p.ValorDocumentoIdentidad = @Doc
                )
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.Persona AS p
                        WHERE p.ValorDocumentoIdentidad = @Doc
                          AND p.IdTipoDocuIdentidad = @TipoDocumento
                          AND p.Nombre = @Nombre
                          AND p.FechaNacimiento = @FechaNacimiento
                          AND ISNULL(p.Email, '') = @Email
                          AND ISNULL(p.Telefono1, '') = @Telefono1
                          AND ISNULL(p.Telefono2, '') = @Telefono2
                    )
                    BEGIN
                        THROW 50415,
                            'La persona ya existe, pero sus datos no coinciden con el XML.',
                            1;
                    END;
                END;
                ELSE
                BEGIN
                    INSERT INTO dbo.Persona (
                        IdTipoDocuIdentidad,
                        ValorDocumentoIdentidad,
                        Nombre,
                        FechaNacimiento,
                        Email,
                        Telefono1,
                        Telefono2
                    )
                    VALUES (
                        @TipoDocumento,
                        @Doc,
                        @Nombre,
                        @FechaNacimiento,
                        @Email,
                        @Telefono1,
                        @Telefono2
                    );
                END;
            END;

            ------------------------------------------------------------
            -- g.3) Cuentas
            ------------------------------------------------------------
            ELSE IF @Nodo = 'Cuenta'
            BEGIN
                SET @Doc = NULL;

                IF @Datos.exist(
                    '(/*/@ValorDocumentoIdentidadDelCliente)[1]'
                ) = 1
                BEGIN
                    SET @Doc = @Datos.value(
                        '(/*/@ValorDocumentoIdentidadDelCliente)[1]',
                        'VARCHAR(64)'
                    );
                END;
                ELSE IF @Datos.exist(
                    '(/*/@ValorDocumentoIdentidad)[1]'
                ) = 1
                BEGIN
                    SET @Doc = @Datos.value(
                        '(/*/@ValorDocumentoIdentidad)[1]',
                        'VARCHAR(64)'
                    );
                END;

                IF @Doc IS NULL
                   OR @Datos.exist('(/*/@NumeroCuenta)[1]') = 0
                   OR @Datos.exist('(/*/@TipoCuentaId)[1]') = 0
                   OR @Datos.exist('(/*/@FechaCreacion)[1]') = 0
                BEGIN
                    THROW 50413,
                        'El nodo Cuenta no contiene todos los datos obligatorios.',
                        1;
                END;

                SET @NumeroCuenta = @Datos.value(
                    '(/*/@NumeroCuenta)[1]',
                    'VARCHAR(32)'
                );

                SET @TipoCuenta = @Datos.value(
                    '(/*/@TipoCuentaId)[1]',
                    'INT'
                );

                SET @FechaCreacion = @Datos.value(
                    '(/*/@FechaCreacion)[1]',
                    'DATE'
                );

                SET @Saldo = 0;

                IF @Datos.exist('(/*/@Saldo)[1]') = 1
                BEGIN
                    SET @Saldo = @Datos.value(
                        '(/*/@Saldo)[1]',
                        'DECIMAL(18,2)'
                    );
                END;

                SET @IdPersona = NULL;

                SELECT
                    @IdPersona = p.IdPersona
                FROM dbo.Persona AS p WITH (UPDLOCK, HOLDLOCK)
                WHERE p.ValorDocumentoIdentidad = @Doc;

                IF @IdPersona IS NULL
                BEGIN
                    THROW 50405,
                        'El cliente de la cuenta no existe.',
                        1;
                END;

                IF @Saldo <> 0
                BEGIN
                    THROW 50406,
                        'Las cuentas deben crearse con saldo cero.',
                        1;
                END;

                IF EXISTS (
                    SELECT 1
                    FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
                    WHERE c.NumeroCuenta = @NumeroCuenta
                )
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.Cuenta AS c
                        WHERE c.NumeroCuenta = @NumeroCuenta
                          AND c.IdPersonaDueno = @IdPersona
                          AND c.IdTipoCuenta = @TipoCuenta
                          AND c.FechaCreacion = @FechaCreacion
                          AND c.Saldo = 0
                    )
                    BEGIN
                        THROW 50415,
                            'La cuenta ya existe, pero sus datos no coinciden con el XML.',
                            1;
                    END;
                END;
                ELSE
                BEGIN
                    INSERT INTO dbo.Cuenta (
                        NumeroCuenta,
                        IdPersonaDueno,
                        IdTipoCuenta,
                        FechaCreacion,
                        Saldo
                    )
                    VALUES (
                        @NumeroCuenta,
                        @IdPersona,
                        @TipoCuenta,
                        @FechaCreacion,
                        0
                    );
                END;
            END;

            ------------------------------------------------------------
            -- g.4) Beneficiarios
            ------------------------------------------------------------
            ELSE IF @Nodo = 'Beneficiario'
            BEGIN
                SET @NumeroCuenta = NULL;
                SET @Doc = NULL;

                IF @Datos.exist('(/*/@NumeroCuenta)[1]') = 0
                   OR @Datos.exist('(/*/@IdParentezco)[1]') = 0
                   OR @Datos.exist('(/*/@Porcentaje)[1]') = 0
                BEGIN
                    THROW 50413,
                        'El nodo Beneficiario no contiene todos los datos obligatorios.',
                        1;
                END;

                SET @NumeroCuenta = @Datos.value(
                    '(/*/@NumeroCuenta)[1]',
                    'VARCHAR(32)'
                );

                IF @Datos.exist(
                    '(/*/@ValorDocumentoIdentidadBeneficiario)[1]'
                ) = 1
                BEGIN
                    SET @Doc = @Datos.value(
                        '(/*/@ValorDocumentoIdentidadBeneficiario)[1]',
                        'VARCHAR(64)'
                    );
                END;
                ELSE IF @Datos.exist(
                    '(/*/@ValorDocumentoIdentidad)[1]'
                ) = 1
                BEGIN
                    SET @Doc = @Datos.value(
                        '(/*/@ValorDocumentoIdentidad)[1]',
                        'VARCHAR(64)'
                    );
                END;

                IF @Doc IS NULL
                BEGIN
                    THROW 50413,
                        'El nodo Beneficiario no contiene el documento de identidad.',
                        1;
                END;

                SET @IdParentezco = @Datos.value(
                    '(/*/@IdParentezco)[1]',
                    'INT'
                );

                SET @Porcentaje = @Datos.value(
                    '(/*/@Porcentaje)[1]',
                    'INT'
                );

                SET @IdCuenta = NULL;
                SET @IdPersona = NULL;

                SELECT
                    @IdCuenta = c.IdCuenta
                FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
                WHERE c.NumeroCuenta = @NumeroCuenta;

                SELECT
                    @IdPersona = p.IdPersona
                FROM dbo.Persona AS p WITH (UPDLOCK, HOLDLOCK)
                WHERE p.ValorDocumentoIdentidad = @Doc;

                IF @IdCuenta IS NULL OR @IdPersona IS NULL
                BEGIN
                    THROW 50407,
                        'La cuenta o la persona del beneficiario no existe.',
                        1;
                END;

                IF EXISTS (
                    SELECT 1
                    FROM dbo.Beneficiario AS b WITH (UPDLOCK, HOLDLOCK)
                    WHERE b.IdCuenta = @IdCuenta
                      AND b.IdPersona = @IdPersona
                      AND b.Activo = @true
                )
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.Beneficiario AS b
                        WHERE b.IdCuenta = @IdCuenta
                          AND b.IdPersona = @IdPersona
                          AND b.Activo = @true
                          AND b.IdParentezco = @IdParentezco
                          AND b.Porcentaje = @Porcentaje
                    )
                    BEGIN
                        THROW 50415,
                            'El beneficiario ya existe, pero sus datos no coinciden con el XML.',
                            1;
                    END;
                END;
                ELSE
                BEGIN
                    INSERT INTO dbo.Beneficiario (
                        IdCuenta,
                        IdPersona,
                        IdParentezco,
                        Porcentaje,
                        Activo,
                        FechaDesactivacion
                    )
                    VALUES (
                        @IdCuenta,
                        @IdPersona,
                        @IdParentezco,
                        @Porcentaje,
                        @true,
                        NULL
                    );
                END;
            END;

            ------------------------------------------------------------
            -- g.5) Usuarios
            ------------------------------------------------------------
            ELSE IF @Nodo = 'Usuario'
            BEGIN
                SET @User = NULL;

                IF @Datos.exist('(/*/@User)[1]') = 1
                BEGIN
                    SET @User = @Datos.value(
                        '(/*/@User)[1]',
                        'VARCHAR(64)'
                    );
                END;
                ELSE IF @Datos.exist('(/*/@NombreUsuario)[1]') = 1
                BEGIN
                    SET @User = @Datos.value(
                        '(/*/@NombreUsuario)[1]',
                        'VARCHAR(64)'
                    );
                END;

                IF @User IS NULL
                   OR @Datos.exist('(/*/@ValorDocId)[1]') = 0
                   OR @Datos.exist('(/*/@Pass)[1]') = 0
                   OR @Datos.exist('(/*/@EsAdministrador)[1]') = 0
                BEGIN
                    THROW 50413,
                        'El nodo Usuario no contiene todos los datos obligatorios.',
                        1;
                END;

                SET @Doc = @Datos.value(
                    '(/*/@ValorDocId)[1]',
                    'VARCHAR(64)'
                );

                SET @Password = @Datos.value(
                    '(/*/@Pass)[1]',
                    'VARCHAR(256)'
                );

                SET @EsAdministrador = @Datos.value(
                    '(/*/@EsAdministrador)[1]',
                    'BIT'
                );

                SET @IdPersona = NULL;

                SELECT
                    @IdPersona = p.IdPersona
                FROM dbo.Persona AS p WITH (UPDLOCK, HOLDLOCK)
                WHERE p.ValorDocumentoIdentidad = @Doc;

                IF @IdPersona IS NULL
                BEGIN
                    THROW 50408,
                        'La persona del usuario no existe.',
                        1;
                END;

                IF EXISTS (
                    SELECT 1
                    FROM dbo.Usuario AS u WITH (UPDLOCK, HOLDLOCK)
                    WHERE u.[User] = @User
                )
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.Usuario AS u
                        WHERE u.[User] = @User
                          AND u.IdPersona = @IdPersona
                          AND u.EsAdministrador = @EsAdministrador
                    )
                    BEGIN
                        THROW 50415,
                            'El usuario ya existe, pero sus datos no coinciden con el XML.',
                            1;
                    END;
                END;
                ELSE
                BEGIN
                    INSERT INTO dbo.Usuario (
                        [User],
                        Pass,
                        EsAdministrador,
                        IdPersona
                    )
                    VALUES (
                        @User,
                        @Password,
                        @EsAdministrador,
                        @IdPersona
                    );
                END;
            END;

            ------------------------------------------------------------
            -- g.6) UsuarioPuedeVer
            ------------------------------------------------------------
            ELSE IF @Nodo = 'UsuarioPuedeVer'
            BEGIN
                SET @User = NULL;

                IF @Datos.exist('(/*/@User)[1]') = 1
                BEGIN
                    SET @User = @Datos.value(
                        '(/*/@User)[1]',
                        'VARCHAR(64)'
                    );
                END;
                ELSE IF @Datos.exist('(/*/@NombreUsuario)[1]') = 1
                BEGIN
                    SET @User = @Datos.value(
                        '(/*/@NombreUsuario)[1]',
                        'VARCHAR(64)'
                    );
                END;

                IF @User IS NULL
                   OR @Datos.exist('(/*/@NumeroCuenta)[1]') = 0
                BEGIN
                    THROW 50413,
                        'El nodo UsuarioPuedeVer no contiene usuario o cuenta.',
                        1;
                END;

                SET @NumeroCuenta = @Datos.value(
                    '(/*/@NumeroCuenta)[1]',
                    'VARCHAR(32)'
                );

                SET @IdUsuario = NULL;
                SET @IdCuenta = NULL;

                SELECT
                    @IdUsuario = u.IdUsuario
                FROM dbo.Usuario AS u WITH (UPDLOCK, HOLDLOCK)
                WHERE u.[User] = @User;

                SELECT
                    @IdCuenta = c.IdCuenta
                FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
                WHERE c.NumeroCuenta = @NumeroCuenta;

                IF @IdUsuario IS NULL OR @IdCuenta IS NULL
                BEGIN
                    THROW 50409,
                        'El usuario o la cuenta de UsuarioPuedeVer no existe.',
                        1;
                END;

                IF NOT EXISTS (
                    SELECT 1
                    FROM dbo.UsuarioCuenta AS uc WITH (UPDLOCK, HOLDLOCK)
                    WHERE uc.IdUsuario = @IdUsuario
                      AND uc.IdCuenta = @IdCuenta
                )
                BEGIN
                    INSERT INTO dbo.UsuarioCuenta (
                        IdUsuario,
                        IdCuenta
                    )
                    VALUES (
                        @IdUsuario,
                        @IdCuenta
                    );
                END;
            END;
            ELSE
            BEGIN
                THROW 50410,
                    'Nodo desconocido en OperacionXML.',
                    1;
            END;

            ------------------------------------------------------------
            -- g.7) Marcar operación como procesada
            ------------------------------------------------------------
            UPDATE dbo.OperacionXML
            SET flag_procesada = @true
            WHERE IdOperacionXML = @IdOp
              AND flag_procesada = @false;

            IF @@ROWCOUNT <> 1
            BEGIN
                THROW 50416,
                    'No fue posible marcar la operacion XML como procesada.',
                    1;
            END;

            COMMIT TRANSACTION;
        END;

        ----------------------------------------------------------------
        -- h) Cerrar estados de cuenta correspondientes a la fecha
        ----------------------------------------------------------------
        WHILE 1 = 1
        BEGIN
            SET @IdEstado = NULL;
            SET @IdEstadoNuevo = NULL;
            SET @ResultadoSP = 50000;

            SELECT TOP (1)
                @IdEstado = e.IdEstadoCuenta
            FROM dbo.EstadoDeCuenta AS e
            WHERE e.Cerrado = @false
              AND e.FechaFin = @inFecha
            ORDER BY
                e.IdCuenta,
                e.IdEstadoCuenta;

            IF @IdEstado IS NULL
                BREAK;

            EXEC dbo.sp_CerrarEstadoCuenta
                @inIdEstadoCuenta = @IdEstado,
                @inFechaCierre = @inFecha,
                @outResult = @ResultadoSP OUTPUT,
                @outIdNuevoEstadoCuenta = @IdEstadoNuevo OUTPUT;

            IF @ResultadoSP <> 0
            BEGIN
                THROW 50411,
                    'No fue posible cerrar un estado de cuenta.',
                    1;
            END;

            IF EXISTS (
                SELECT 1
                FROM dbo.EstadoDeCuenta AS e
                WHERE e.IdEstadoCuenta = @IdEstado
                  AND e.Cerrado = @false
            )
            BEGIN
                THROW 50414,
                    'El procedimiento de cierre no cerro el estado de cuenta.',
                    1;
            END;
        END;

        ----------------------------------------------------------------
        -- i) Validar que no queden estados vencidos abiertos
        ----------------------------------------------------------------
        IF EXISTS (
            SELECT 1
            FROM dbo.EstadoDeCuenta AS e
            WHERE e.Cerrado = @false
              AND e.FechaFin < @inFecha
        )
        BEGIN
            THROW 50412,
                'Quedaron estados de cuenta abiertos con fecha final vencida.',
                1;
        END;

        ----------------------------------------------------------------
        -- j) Confirmar fecha procesada
        ----------------------------------------------------------------
        UPDATE dbo.ControlFechaOperacion
        SET
            flag_procesada = @true,
            FechaProcesamiento = GETDATE(),
            UltimoError = NULL
        WHERE Fecha = @inFecha
          AND flag_procesada = @false;

        IF @@ROWCOUNT <> 1
        BEGIN
            THROW 50417,
                'No fue posible marcar la fecha como procesada.',
                1;
        END;

        ----------------------------------------------------------------
        -- k) Liberar candado y finalizar
        ----------------------------------------------------------------
        EXEC sys.sp_releaseapplock
            @Resource = 'sp_ProcesarSimulacion',
            @LockOwner = 'Session';

        SET @TieneCandado = 0;
        SET @outResult = 0;

        RETURN 0;
    END TRY

    BEGIN CATCH
        ----------------------------------------------------------------
        -- l) Revertir la transacción activa
        ----------------------------------------------------------------
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        ----------------------------------------------------------------
        -- m) Registrar error
        ----------------------------------------------------------------
        SET @Mensaje = CONCAT(
            '[',
            ERROR_NUMBER(),
            '] ',
            ERROR_MESSAGE(),
            ' (linea ',
            ERROR_LINE(),
            ', ',
            ISNULL(ERROR_PROCEDURE(), 'lote'),
            ')'
        );

        SET @outResult = ERROR_NUMBER();

        UPDATE dbo.ControlFechaOperacion
        SET UltimoError = @Mensaje
        WHERE Fecha = @inFecha
          AND flag_procesada = @false;

        ----------------------------------------------------------------
        -- n) Liberar candado
        ----------------------------------------------------------------
        IF @TieneCandado = 1
        BEGIN
            EXEC sys.sp_releaseapplock
                @Resource = 'sp_ProcesarSimulacion',
                @LockOwner = 'Session';

            SET @TieneCandado = 0;
        END;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ProcesarSimulacion
    @inFechaHasta DATE = NULL,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        ----------------------------------------------------------------
        -- a) Constantes
        ----------------------------------------------------------------
        DECLARE @true BIT = 1,
                @false BIT = 0;

        ----------------------------------------------------------------
        -- b) Variables
        ----------------------------------------------------------------
        DECLARE @Fecha DATE;
        DECLARE @ResultadoSP INT;
        DECLARE @Candado INT;
        DECLARE @TieneCandado BIT = 0;

        SET @outResult = 50000;

        ----------------------------------------------------------------
        -- c) Validar transacción externa
        ----------------------------------------------------------------
        IF @@TRANCOUNT <> 0
        BEGIN
            THROW 50400,
                'Ejecute la simulacion sin una transaccion externa.',
                1;
        END;

        ----------------------------------------------------------------
        -- d) Obtener candado exclusivo de sesion
        ----------------------------------------------------------------
        EXEC @Candado = sys.sp_getapplock
            @Resource = 'sp_ProcesarSimulacion',
            @LockMode = 'Exclusive',
            @LockOwner = 'Session',
            @LockTimeout = 0;

        IF @Candado < 0
        BEGIN
            THROW 50420,
                'Ya hay un proceso de simulacion en ejecucion.',
                1;
        END;

        SET @TieneCandado = 1;

        ----------------------------------------------------------------
        -- e) Procesar fechas pendientes en orden cronologico
        ----------------------------------------------------------------
        WHILE 1 = 1
        BEGIN
            SET @Fecha = NULL;

            SELECT TOP (1)
                @Fecha = cf.Fecha
            FROM dbo.ControlFechaOperacion AS cf
            WHERE cf.flag_procesada = @false
              AND (
                    @inFechaHasta IS NULL
                    OR cf.Fecha <= @inFechaHasta
                  )
            ORDER BY cf.Fecha;

            IF @Fecha IS NULL
                BREAK;

            SET @ResultadoSP = 50000;

            EXEC dbo.sp_ProcesarFechaOperacion
                @inFecha = @Fecha,
                @outResult = @ResultadoSP OUTPUT;

            IF @ResultadoSP <> 0
            BEGIN
                THROW 50421,
                    'Ocurrio un error procesando una fecha de operacion.',
                    1;
            END;

            ------------------------------------------------------------
            -- Verificar que la fecha realmente quedo procesada
            ------------------------------------------------------------
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.ControlFechaOperacion AS cf
                WHERE cf.Fecha = @Fecha
                  AND cf.flag_procesada = @true
            )
            BEGIN
                THROW 50422,
                    'El procedimiento de fecha finalizo sin marcarla como procesada.',
                    1;
            END;
        END;

        ----------------------------------------------------------------
        -- f) Liberar candado y finalizar
        ----------------------------------------------------------------
        EXEC sys.sp_releaseapplock
            @Resource = 'sp_ProcesarSimulacion',
            @LockOwner = 'Session';

        SET @TieneCandado = 0;
        SET @outResult = 0;

        RETURN 0;
    END TRY

    BEGIN CATCH
        ----------------------------------------------------------------
        -- g) Registrar error
        ----------------------------------------------------------------
        SET @outResult = ERROR_NUMBER();

        ----------------------------------------------------------------
        -- h) Liberar candado
        ----------------------------------------------------------------
        IF @TieneCandado = 1
        BEGIN
            EXEC sys.sp_releaseapplock
                @Resource = 'sp_ProcesarSimulacion',
                @LockOwner = 'Session';

            SET @TieneCandado = 0;
        END;

        THROW;
    END CATCH;
END;
GO