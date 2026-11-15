CREATE OR ALTER PROCEDURE dbo.sp_ProcesarFechaOperacion
    @inFecha DATE,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- a) Declaración de constantes
    DECLARE @true BIT = 1,
            @false BIT = 0;

    -- b) Declaración de variables generales
    DECLARE @Procesada BIT;
    DECLARE @IdOp INT, 
            @Nodo VARCHAR(128), 
            @Datos XML;
    DECLARE @ResultadoSP INT, 
            @IdEstado INT, 
            @IdEstadoNuevo INT;
    DECLARE @IdTipo INT, 
            @IdPersona INT, 
            @IdCuenta INT, 
            @IdUsuario INT;
    DECLARE @Doc VARCHAR(64), 
            @NumeroCuenta VARCHAR(32), 
            @User VARCHAR(64);
    DECLARE @Tipo VARCHAR(128), 
            @Monto DECIMAL(18,2), 
            @Descripcion VARCHAR(256);
    DECLARE @FechaMov DATETIME, 
            @Saldo DECIMAL(18,2);
    DECLARE @Mensaje VARCHAR(256);

    SET @outResult = 50000;

    BEGIN TRY
        -- Validar existencia y estado de la fecha
        SELECT @Procesada = flag_procesada
        FROM dbo.ControlFechaOperacion
        WHERE Fecha = @inFecha;

        IF @Procesada IS NULL
            THROW 50401, 'La fecha no existe en ControlFechaOperacion.', 1;

        IF @Procesada = @true
        BEGIN
            SET @outResult = 0;
            RETURN 0;
        END;

        IF EXISTS (
            SELECT 1 
            FROM dbo.ControlFechaOperacion
            WHERE Fecha < @inFecha 
              AND flag_procesada = @false
        )
            THROW 50402, 'Hay fechas anteriores sin procesar; deben procesarse primero.', 1;

        UPDATE dbo.ControlFechaOperacion
        SET Intentos = Intentos + 1, 
            FechaUltimoIntento = GETDATE()
        WHERE Fecha = @inFecha;

        SET @FechaMov = CONVERT(DATETIME, @inFecha);


        BEGIN TRANSACTION;

        WHILE 1 = 1
        BEGIN
            SET @IdOp = NULL;

            SELECT TOP (1) 
                @IdOp = IdOperacionXML, 
                @Nodo = NombreNodo, 
                @Datos = Datos
            FROM dbo.OperacionXML
            WHERE Fecha = @inFecha 
              AND flag_procesada = @false
            ORDER BY OrdenEnArchivo, IdOperacionXML;

            IF @IdOp IS NULL BREAK;

            IF @Nodo = 'Movimiento' OR @Nodo = 'Movimientos'
            BEGIN
                SET @NumeroCuenta = ISNULL(@Datos.value('(@NumeroCuenta)[1]', 'VARCHAR(32)'), @Datos.value('(@CodigoCuenta)[1]', 'VARCHAR(32)'));
                SET @Tipo         = ISNULL(@Datos.value('(@TipoMov)[1]', 'VARCHAR(128)'), @Datos.value('(@TipoMovimiento)[1]', 'VARCHAR(128)'));
                SET @Monto        = @Datos.value('(@Monto)[1]', 'DECIMAL(18,2)');
                SET @Descripcion  = ISNULL(@Datos.value('(@Descripcion)[1]', 'VARCHAR(256)'), '');

                SET @IdTipo = NULL;
                SELECT @IdTipo = Id 
                FROM dbo.TipoMovimiento 
                WHERE Nombre = LTRIM(RTRIM(@Tipo));

                IF @IdTipo IS NULL
                    THROW 50403, 'El tipo de movimiento del XML no existe en el catalogo.', 1;

                EXEC dbo.sp_AplicarMovimiento
                    @inNumeroCuenta     = @NumeroCuenta,
                    @inIdTipoMovimiento = @IdTipo,
                    @inFecha            = @FechaMov,
                    @inMonto            = @Monto,
                    @inDescripcion      = @Descripcion,
                    @outResult          = @ResultadoSP OUTPUT,
                    @inIdOperacionXML   = @IdOp;

                IF @ResultadoSP <> 0
                    THROW 50404, 'No fue posible aplicar un movimiento del XML.', 1;
            END
            ELSE IF @Nodo = 'Persona'
            BEGIN
                SET @Doc = ISNULL(@Datos.value('(@ValorDocumentoIdentidad)[1]', 'VARCHAR(64)'),
                                  @Datos.value('(@ValorDocumentoIdentidadDelCliente)[1]', 'VARCHAR(64)'));

                IF NOT EXISTS (SELECT 1 FROM dbo.Persona WHERE ValorDocumentoIdentidad = @Doc)
                    INSERT INTO dbo.Persona (
                        IdTipoDocuIdentidad
                        , ValorDocumentoIdentidad
                        , Nombre
                        , FechaNacimiento
                        , Email
                        , Telefono1
                        , Telefono2
                    )
                    VALUES (
                        @Datos.value('(@TipoDocuIdentidad)[1]', 'INT')
                        , @Doc
                        , @Datos.value('(@Nombre)[1]', 'VARCHAR(128)')
                        , @Datos.value('(@FechaNacimiento)[1]', 'DATE')
                        , ISNULL(@Datos.value('(@Email)[1]', 'VARCHAR(128)'), '')
                        , ISNULL(@Datos.value('(@Telefono1)[1]', 'VARCHAR(32)'), '')
                        , ISNULL(@Datos.value('(@Telefono2)[1]', 'VARCHAR(32)'), '')
                    );
            END
            ELSE IF @Nodo = 'Cuenta'
            BEGIN
                SET @Doc          = ISNULL(@Datos.value('(@ValorDocumentoIdentidadDelCliente)[1]', 'VARCHAR(64)'),
                                            @Datos.value('(@ValorDocumentoIdentidad)[1]', 'VARCHAR(64)'));
                SET @NumeroCuenta = @Datos.value('(@NumeroCuenta)[1]', 'VARCHAR(32)');
                SET @Saldo        = ISNULL(@Datos.value('(@Saldo)[1]', 'DECIMAL(18,2)'), 0);

                SET @IdPersona = NULL;
                SELECT @IdPersona = IdPersona 
                FROM dbo.Persona 
                WHERE ValorDocumentoIdentidad = @Doc;

                IF @IdPersona IS NULL
                    THROW 50405, 'El cliente de la cuenta no existe.', 1;

                IF @Saldo <> 0
                    THROW 50406, 'Las cuentas deben crearse con saldo cero.', 1;

                IF NOT EXISTS (SELECT 1 FROM dbo.Cuenta WHERE NumeroCuenta = @NumeroCuenta)
                    INSERT INTO dbo.Cuenta (
                        NumeroCuenta
                        , IdPersonaDueno
                        , IdTipoCuenta
                        , FechaCreacion
                        , Saldo
                    )
                    VALUES (
                        @NumeroCuenta
                        , @IdPersona
                        , @Datos.value('(@IdTipoCuenta)[1]', 'INT')
                        , @Datos.value('(@FechaCreacion)[1]', 'DATE')
                        , 0
                    );
            END
            ELSE IF @Nodo = 'Beneficiario'
            BEGIN
                SET @NumeroCuenta = @Datos.value('(@NumeroCuenta)[1]', 'VARCHAR(32)');
                SET @Doc          = ISNULL(@Datos.value('(@ValorDocumentoIdentidadBeneficiario)[1]', 'VARCHAR(64)'),
                                            @Datos.value('(@ValorDocumentoIdentidad)[1]', 'VARCHAR(64)'));

                SET @IdCuenta  = NULL; 
                SET @IdPersona = NULL;

                SELECT @IdCuenta  = IdCuenta  FROM dbo.Cuenta  WHERE NumeroCuenta = @NumeroCuenta;
                SELECT @IdPersona = IdPersona FROM dbo.Persona WHERE ValorDocumentoIdentidad = @Doc;

                IF @IdCuenta IS NULL OR @IdPersona IS NULL
                    THROW 50407, 'La cuenta o la persona del beneficiario no existe.', 1;

                IF NOT EXISTS (
                    SELECT 1 
                    FROM dbo.Beneficiario
                    WHERE IdCuenta = @IdCuenta 
                      AND IdPersona = @IdPersona 
                      AND Activo = @true
                )
                    INSERT INTO dbo.Beneficiario (
                        IdCuenta
                        , IdPersona
                        , IdParentezco
                        , Porcentaje
                        , Activo
                        , FechaDesactivacion
                    )
                    VALUES (
                        @IdCuenta
                        , @IdPersona
                        , @Datos.value('(@IdParentezco)[1]', 'INT')
                        , @Datos.value('(@Porcentaje)[1]', 'INT')
                        , @true
                        , NULL
                    );
            END
            ELSE IF @Nodo = 'Usuario'
            BEGIN
                SET @User = ISNULL(@Datos.value('(@User)[1]', 'VARCHAR(64)'), @Datos.value('(@NombreUsuario)[1]', 'VARCHAR(64)'));
                SET @Doc  = @Datos.value('(@ValorDocId)[1]', 'VARCHAR(64)');

                SET @IdPersona = NULL;
                SELECT @IdPersona = IdPersona 
                FROM dbo.Persona 
                WHERE ValorDocumentoIdentidad = @Doc;

                IF @IdPersona IS NULL
                    THROW 50408, 'La persona del usuario no existe.', 1;

                IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE [User] = @User)
                    INSERT INTO dbo.Usuario (
                        [User]
                        , Pass
                        , EsAdministrador
                        , IdPersona
                    )
                    VALUES (
                        @User
                        , @Datos.value('(@Pass)[1]', 'VARCHAR(128)')
                        , @Datos.value('(@EsAdministrador)[1]', 'BIT')
                        , @IdPersona
                    );
            END
            ELSE IF @Nodo = 'UsuarioPuedeVer'
            BEGIN
                SET @User         = ISNULL(@Datos.value('(@User)[1]', 'VARCHAR(64)'), @Datos.value('(@NombreUsuario)[1]', 'VARCHAR(64)'));
                SET @NumeroCuenta = @Datos.value('(@NumeroCuenta)[1]', 'VARCHAR(32)');

                SET @IdUsuario = NULL; 
                SET @IdCuenta  = NULL;

                SELECT @IdUsuario = IdUsuario FROM dbo.Usuario WHERE [User] = @User;
                SELECT @IdCuenta  = IdCuenta  FROM dbo.Cuenta  WHERE NumeroCuenta = @NumeroCuenta;

                IF @IdUsuario IS NULL OR @IdCuenta IS NULL
                    THROW 50409, 'El usuario o la cuenta de UsuarioPuedeVer no existe.', 1;

                IF NOT EXISTS (
                    SELECT 1 
                    FROM dbo.UsuarioCuenta
                    WHERE IdUsuario = @IdUsuario 
                      AND IdCuenta = @IdCuenta
                )
                    INSERT INTO dbo.UsuarioCuenta (
                        IdUsuario
                        , IdCuenta
                    ) 
                    VALUES (
                        @IdUsuario
                        , @IdCuenta
                    );
            END
            ELSE
                THROW 50410, 'Nodo desconocido en OperacionXML.', 1;

            UPDATE dbo.OperacionXML 
            SET flag_procesada = @true 
            WHERE IdOperacionXML = @IdOp;
        END;

        -- Proceso de cierre de estados de cuenta
        WHILE 1 = 1
        BEGIN
            SET @IdEstado = NULL;

            SELECT TOP (1) @IdEstado = IdEstadoCuenta
            FROM dbo.EstadoDeCuenta
            WHERE Cerrado = @false 
              AND FechaFin = @inFecha
            ORDER BY IdCuenta, IdEstadoCuenta;

            IF @IdEstado IS NULL BREAK;

            EXEC dbo.sp_CerrarEstadoCuenta
                @inIdEstadoCuenta       = @IdEstado,
                @inFechaCierre          = @inFecha,
                @outResult              = @ResultadoSP OUTPUT,
                @outIdNuevoEstadoCuenta = @IdEstadoNuevo OUTPUT;

            IF @ResultadoSP <> 0
                THROW 50411, 'No fue posible cerrar un estado de cuenta.', 1;
        END;

        IF EXISTS (
            SELECT 1 
            FROM dbo.EstadoDeCuenta 
            WHERE Cerrado = @false 
              AND FechaFin < @inFecha
        )
            THROW 50412, 'Quedaron estados de cuenta abiertos con fecha final vencida.', 1;

        UPDATE dbo.ControlFechaOperacion
        SET flag_procesada = @true, 
            FechaProcesamiento = GETDATE(), 
            UltimoError = NULL
        WHERE Fecha = @inFecha;

        COMMIT TRANSACTION;

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @outResult = ERROR_NUMBER();
        SET @Mensaje = CONCAT('[', ERROR_NUMBER(), '] ', ERROR_MESSAGE(),
                              ' (linea ', ERROR_LINE(), ', ', ISNULL(ERROR_PROCEDURE(), 'lote'), ')');

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        UPDATE dbo.ControlFechaOperacion
        SET UltimoError = @Mensaje
        WHERE Fecha = @inFecha 
          AND flag_procesada = @false;

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

    -- a) Declaración de constantes
    DECLARE @true BIT = 1,
            @false BIT = 0;

    -- b) Declaración de variables generales
    DECLARE @Fecha DATE, 
            @ResultadoSP INT, 
            @Candado INT, 
            @Procesadas INT = 0;

    SET @outResult = 50000;

    EXEC @Candado = sp_getapplock
        @Resource   = 'sp_ProcesarSimulacion', 
        @LockMode   = 'Exclusive',
        @LockOwner  = 'Session', 
        @LockTimeout = 0;

    IF @Candado < 0
        THROW 50420, 'Ya hay un proceso de simulacion en ejecucion.', 1;

    BEGIN TRY
        WHILE 1 = 1
        BEGIN
            SET @Fecha = NULL;

            SELECT TOP (1) @Fecha = Fecha
            FROM dbo.ControlFechaOperacion
            WHERE flag_procesada = @false
              AND (@inFechaHasta IS NULL OR Fecha <= @inFechaHasta)
            ORDER BY Fecha;

            IF @Fecha IS NULL BREAK;

            EXEC dbo.sp_ProcesarFechaOperacion 
                @inFecha   = @Fecha, 
                @outResult = @ResultadoSP OUTPUT;

            IF @ResultadoSP <> 0
                THROW 50421, 'Ocurrio un error procesando una fecha de operacion.', 1;

            SET @Procesadas = @Procesadas + 1;
        END;

        EXEC sp_releaseapplock 
            @Resource  = 'sp_ProcesarSimulacion', 
            @LockOwner = 'Session';

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @outResult = ERROR_NUMBER();
        
        EXEC sp_releaseapplock 
            @Resource  = 'sp_ProcesarSimulacion', 
            @LockOwner = 'Session';
            
        THROW;
    END CATCH;
END;
GO
