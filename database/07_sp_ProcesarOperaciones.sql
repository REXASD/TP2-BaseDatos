SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
DECLARE @outResult INT;
EXEC dbo.sp_ProcesarPersonaXML
    @inIdOperacionXML = 1,
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
-- Resultado: 0 = correcto, 50430 = la operacion XML no existe
===================================================================
*/
CREATE OR ALTER PROCEDURE dbo.sp_ProcesarPersonaXML
    @inIdOperacionXML INT,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @true BIT = 1;

    DECLARE @Datos XML;
    DECLARE @Doc VARCHAR(64);
    DECLARE @IdTipoDocu INT;
    DECLARE @Nombre VARCHAR(64);
    DECLARE @FechaNacimiento DATE;
    DECLARE @Email VARCHAR(128);
    DECLARE @Telefono1 VARCHAR(32);
    DECLARE @Telefono2 VARCHAR(32);

    BEGIN TRY
        SELECT @Datos = o.Datos
        FROM dbo.OperacionXML AS o
        WHERE o.IdOperacionXML = @inIdOperacionXML;

        IF @Datos IS NULL
        BEGIN
            SET @outResult = 50430;
            RETURN 50430;
        END;

        SET @Doc = ISNULL(
            @Datos.value('(/*/@ValorDocumentoIdentidad)[1]', 'VARCHAR(64)')
            , @Datos.value('(/*/@ValorDocumentoIdentidadDelCliente)[1]', 'VARCHAR(64)')
        );
        SET @IdTipoDocu = @Datos.value('(/*/@TipoDocuIdentidad)[1]', 'INT');
        SET @Nombre = @Datos.value('(/*/@Nombre)[1]', 'VARCHAR(64)');
        SET @FechaNacimiento = @Datos.value('(/*/@FechaNacimiento)[1]', 'DATE');
        SET @Email = ISNULL(@Datos.value('(/*/@Email)[1]', 'VARCHAR(128)'), '');
        SET @Telefono1 = ISNULL(@Datos.value('(/*/@telefono1)[1]', 'VARCHAR(32)'), '');
        SET @Telefono2 = ISNULL(@Datos.value('(/*/@telefono2)[1]', 'VARCHAR(32)'), '');

        BEGIN TRANSACTION;

            INSERT INTO dbo.Persona (
                IdTipoDocuIdentidad
                , ValorDocumentoIdentidad
                , Nombre
                , FechaNacimiento
                , Email
                , Telefono1
                , Telefono2
            )
            SELECT
                @IdTipoDocu
                , @Doc
                , @Nombre
                , @FechaNacimiento
                , @Email
                , @Telefono1
                , @Telefono2
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.Persona AS p
                WHERE p.ValorDocumentoIdentidad = @Doc
            );

            UPDATE dbo.OperacionXML
            SET flag_procesada = @true
            WHERE IdOperacionXML = @inIdOperacionXML;

        COMMIT TRANSACTION;

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();
        THROW;
    END CATCH;
END;
GO


/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
DECLARE @outResult INT;
EXEC dbo.sp_ProcesarCuentaXML
    @inIdOperacionXML = 2,
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
-- Resultado: 0 = correcto
--            50430 = la operacion XML no existe
--            50405 = el cliente de la cuenta no existe
--            50406 = la cuenta no viene con saldo cero
===================================================================
*/
CREATE OR ALTER PROCEDURE dbo.sp_ProcesarCuentaXML
    @inIdOperacionXML INT,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @true BIT = 1;

    DECLARE @Datos XML;
    DECLARE @Doc VARCHAR(64);
    DECLARE @NumeroCuenta VARCHAR(32);
    DECLARE @Saldo DECIMAL(18,2);
    DECLARE @IdPersona INT;
    DECLARE @IdTipoCuenta INT;
    DECLARE @FechaCreacion DATE;

    BEGIN TRY
        SELECT @Datos = o.Datos
        FROM dbo.OperacionXML AS o
        WHERE o.IdOperacionXML = @inIdOperacionXML;

        IF @Datos IS NULL
        BEGIN
            SET @outResult = 50430;
            RETURN 50430;
        END;

        SET @Doc = ISNULL(
            @Datos.value('(/*/@ValorDocumentoIdentidadDelCliente)[1]', 'VARCHAR(64)')
            , @Datos.value('(/*/@ValorDocumentoIdentidad)[1]', 'VARCHAR(64)')
        );
        SET @NumeroCuenta = @Datos.value('(/*/@NumeroCuenta)[1]', 'VARCHAR(32)');
        SET @Saldo = ISNULL(@Datos.value('(/*/@Saldo)[1]', 'DECIMAL(18,2)'), 0);
        SET @IdTipoCuenta = @Datos.value('(/*/@TipoCuentaId)[1]', 'INT');
        SET @FechaCreacion = @Datos.value('(/*/@FechaCreacion)[1]', 'DATE');

        SELECT @IdPersona = p.IdPersona
        FROM dbo.Persona AS p
        WHERE p.ValorDocumentoIdentidad = @Doc;

        IF @IdPersona IS NULL
        BEGIN
            SET @outResult = 50405;
            RETURN 50405;
        END;

        IF @Saldo <> 0
        BEGIN
            SET @outResult = 50406;
            RETURN 50406;
        END;

        BEGIN TRANSACTION;

            INSERT INTO dbo.Cuenta (
                NumeroCuenta
                , IdPersonaDueno
                , IdTipoCuenta
                , FechaCreacion
                , Saldo
            )
            SELECT
                @NumeroCuenta
                , @IdPersona
                , @IdTipoCuenta
                , @FechaCreacion
                , 0
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.Cuenta AS c
                WHERE c.NumeroCuenta = @NumeroCuenta
            );

            UPDATE dbo.OperacionXML
            SET flag_procesada = @true
            WHERE IdOperacionXML = @inIdOperacionXML;

        COMMIT TRANSACTION;

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();
        THROW;
    END CATCH;
END;
GO


/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
DECLARE @outResult INT;
EXEC dbo.sp_ProcesarBeneficiarioXML
    @inIdOperacionXML = 3,
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
-- Resultado: 0 = correcto
--            50430 = la operacion XML no existe
--            50407 = la cuenta o la persona del beneficiario no existe
===================================================================
*/
CREATE OR ALTER PROCEDURE dbo.sp_ProcesarBeneficiarioXML
    @inIdOperacionXML INT,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @true BIT = 1;

    DECLARE @Datos XML;
    DECLARE @Doc VARCHAR(64);
    DECLARE @NumeroCuenta VARCHAR(32);
    DECLARE @IdCuenta INT;
    DECLARE @IdPersona INT;
    DECLARE @IdParentezco INT;
    DECLARE @Porcentaje INT;

    BEGIN TRY
        SELECT @Datos = o.Datos
        FROM dbo.OperacionXML AS o
        WHERE o.IdOperacionXML = @inIdOperacionXML;

        IF @Datos IS NULL
        BEGIN
            SET @outResult = 50430;
            RETURN 50430;
        END;

        SET @NumeroCuenta = @Datos.value('(/*/@NumeroCuenta)[1]', 'VARCHAR(32)');
        SET @Doc = ISNULL(
            @Datos.value('(/*/@ValorDocumentoIdentidadBeneficiario)[1]', 'VARCHAR(64)')
            , @Datos.value('(/*/@ValorDocumentoIdentidad)[1]', 'VARCHAR(64)')
        );
        SET @IdParentezco = @Datos.value('(/*/@IdParentezco)[1]', 'INT');
        SET @Porcentaje = @Datos.value('(/*/@Porcentaje)[1]', 'INT');

        SELECT @IdCuenta = c.IdCuenta
        FROM dbo.Cuenta AS c
        WHERE c.NumeroCuenta = @NumeroCuenta;

        SELECT @IdPersona = p.IdPersona
        FROM dbo.Persona AS p
        WHERE p.ValorDocumentoIdentidad = @Doc;

        IF @IdCuenta IS NULL OR @IdPersona IS NULL
        BEGIN
            SET @outResult = 50407;
            RETURN 50407;
        END;

        BEGIN TRANSACTION;

            INSERT INTO dbo.Beneficiario (
                IdCuenta
                , IdPersona
                , IdParentezco
                , Porcentaje
                , Activo
                , FechaDesactivacion
            )
            SELECT
                @IdCuenta
                , @IdPersona
                , @IdParentezco
                , @Porcentaje
                , @true
                , NULL
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.Beneficiario AS b
                WHERE b.IdCuenta = @IdCuenta
                  AND b.IdPersona = @IdPersona
                  AND b.Activo = @true
            );

            UPDATE dbo.OperacionXML
            SET flag_procesada = @true
            WHERE IdOperacionXML = @inIdOperacionXML;

        COMMIT TRANSACTION;

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();
        THROW;
    END CATCH;
END;
GO


/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
DECLARE @outResult INT;
EXEC dbo.sp_ProcesarUsuarioXML
    @inIdOperacionXML = 4,
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
-- Resultado: 0 = correcto
--            50430 = la operacion XML no existe
--            50408 = la persona del usuario no existe
===================================================================
*/
CREATE OR ALTER PROCEDURE dbo.sp_ProcesarUsuarioXML
    @inIdOperacionXML INT,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @true BIT = 1;

    DECLARE @Datos XML;
    DECLARE @User VARCHAR(64);
    DECLARE @Doc VARCHAR(64);
    DECLARE @Pass VARCHAR(256);
    DECLARE @flag_administrador BIT;
    DECLARE @IdPersona INT;

    BEGIN TRY
        SELECT @Datos = o.Datos
        FROM dbo.OperacionXML AS o
        WHERE o.IdOperacionXML = @inIdOperacionXML;

        IF @Datos IS NULL
        BEGIN
            SET @outResult = 50430;
            RETURN 50430;
        END;

        SET @User = ISNULL(
            @Datos.value('(/*/@User)[1]', 'VARCHAR(64)')
            , @Datos.value('(/*/@NombreUsuario)[1]', 'VARCHAR(64)')
        );
        SET @Doc = @Datos.value('(/*/@ValorDocId)[1]', 'VARCHAR(64)');
        SET @Pass = @Datos.value('(/*/@Pass)[1]', 'VARCHAR(256)');
        SET @flag_administrador = @Datos.value('(/*/@EsAdministrador)[1]', 'BIT');

        SELECT @IdPersona = p.IdPersona
        FROM dbo.Persona AS p
        WHERE p.ValorDocumentoIdentidad = @Doc;

        IF @IdPersona IS NULL
        BEGIN
            SET @outResult = 50408;
            RETURN 50408;
        END;

        BEGIN TRANSACTION;

            INSERT INTO dbo.Usuario (
                [User]
                , Pass
                , EsAdministrador
                , IdPersona
            )
            SELECT
                @User
                , @Pass
                , @flag_administrador
                , @IdPersona
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.Usuario AS u
                WHERE u.[User] = @User
            );

            UPDATE dbo.OperacionXML
            SET flag_procesada = @true
            WHERE IdOperacionXML = @inIdOperacionXML;

        COMMIT TRANSACTION;

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();
        THROW;
    END CATCH;
END;
GO


/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
DECLARE @outResult INT;
EXEC dbo.sp_ProcesarUsuarioPuedeVerXML
    @inIdOperacionXML = 5,
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
-- Resultado: 0 = correcto
--            50430 = la operacion XML no existe
--            50409 = el usuario o la cuenta no existe
===================================================================
*/
CREATE OR ALTER PROCEDURE dbo.sp_ProcesarUsuarioPuedeVerXML
    @inIdOperacionXML INT,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @true BIT = 1;

    DECLARE @Datos XML;
    DECLARE @User VARCHAR(64);
    DECLARE @NumeroCuenta VARCHAR(32);
    DECLARE @IdUsuario INT;
    DECLARE @IdCuenta INT;

    BEGIN TRY
        SELECT @Datos = o.Datos
        FROM dbo.OperacionXML AS o
        WHERE o.IdOperacionXML = @inIdOperacionXML;

        IF @Datos IS NULL
        BEGIN
            SET @outResult = 50430;
            RETURN 50430;
        END;

        SET @User = ISNULL(
            @Datos.value('(/*/@User)[1]', 'VARCHAR(64)')
            , @Datos.value('(/*/@NombreUsuario)[1]', 'VARCHAR(64)')
        );
        SET @NumeroCuenta = @Datos.value('(/*/@NumeroCuenta)[1]', 'VARCHAR(32)');

        SELECT @IdUsuario = u.IdUsuario
        FROM dbo.Usuario AS u
        WHERE u.[User] = @User;

        SELECT @IdCuenta = c.IdCuenta
        FROM dbo.Cuenta AS c
        WHERE c.NumeroCuenta = @NumeroCuenta;

        IF @IdUsuario IS NULL OR @IdCuenta IS NULL
        BEGIN
            SET @outResult = 50409;
            RETURN 50409;
        END;

        BEGIN TRANSACTION;

            INSERT INTO dbo.UsuarioCuenta (
                IdUsuario
                , IdCuenta
            )
            SELECT
                @IdUsuario
                , @IdCuenta
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.UsuarioCuenta AS uc
                WHERE uc.IdUsuario = @IdUsuario
                  AND uc.IdCuenta = @IdCuenta
            );

            UPDATE dbo.OperacionXML
            SET flag_procesada = @true
            WHERE IdOperacionXML = @inIdOperacionXML;

        COMMIT TRANSACTION;

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();
        THROW;
    END CATCH;
END;
GO


/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
-- Ejecutar sin BEGIN TRAN externo. Procesa una fecha de operacion:
-- primero cada operacion XML pendiente (en orden de archivo) y
-- luego los cierres de estado de cuenta que vencen ese dia.
DECLARE @outResult INT;
EXEC dbo.sp_ProcesarFechaOperacion
    @inFecha = '20260301',
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
-- Cada operacion confirma sus cambios y flag_procesada juntos. Si una
-- falla, se retoma desde la primera pendiente. La fecha solo se marca
-- procesada al terminar operaciones y cierres. Un candado de sesion
-- impide dos simulaciones a la vez.
===================================================================
*/
CREATE OR ALTER PROCEDURE dbo.sp_ProcesarFechaOperacion
    @inFecha DATE,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @true BIT = 1,
            @false BIT = 0;

    DECLARE @flag_procesada BIT;
    DECLARE @flag_candado BIT = 0;
    DECLARE @Candado INT;
    DECLARE @IdOp INT;
    DECLARE @Nodo VARCHAR(128);
    DECLARE @Datos XML;
    DECLARE @ResultadoSP INT;
    DECLARE @IdEstado INT;
    DECLARE @IdEstadoNuevo INT;
    DECLARE @IdTipo INT;
    DECLARE @NumeroCuenta VARCHAR(32);
    DECLARE @Tipo VARCHAR(128);
    DECLARE @Monto DECIMAL(18,2);
    DECLARE @Descripcion VARCHAR(256);
    DECLARE @FechaMov DATETIME;
    DECLARE @Mensaje NVARCHAR(1024);

    BEGIN TRY
        SET @outResult = 50000;

        IF @@TRANCOUNT <> 0
            THROW 50400, 'Ejecute la simulacion sin una transaccion externa.', 1;

        EXEC @Candado = sys.sp_getapplock
            @Resource = 'sp_ProcesarSimulacion'
            , @LockMode = 'Exclusive'
            , @LockOwner = 'Session'
            , @LockTimeout = 0;

        IF @Candado < 0
            THROW 50420, 'Ya hay un proceso de simulacion en ejecucion.', 1;

        SET @flag_candado = @true;

        SELECT @flag_procesada = c.flag_procesada
        FROM dbo.ControlFechaOperacion AS c
        WHERE c.Fecha = @inFecha;

        IF @flag_procesada IS NULL
            THROW 50401, 'La fecha no existe en ControlFechaOperacion.', 1;

        IF @flag_procesada = @true
        BEGIN
            EXEC sys.sp_releaseapplock
                @Resource = 'sp_ProcesarSimulacion'
                , @LockOwner = 'Session';

            SET @flag_candado = @false;
            SET @outResult = 0;
            RETURN 0;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.ControlFechaOperacion AS c
            WHERE c.Fecha < @inFecha
              AND c.flag_procesada = @false
        )
            THROW 50402,
                'Hay fechas anteriores sin procesar; deben procesarse primero.',
                1;

        UPDATE dbo.ControlFechaOperacion
        SET Intentos = Intentos + 1
            , FechaUltimoIntento = GETDATE()
        WHERE Fecha = @inFecha;

        SET @FechaMov = CONVERT(DATETIME, @inFecha);

        WHILE 1 = 1
        BEGIN
            SET @IdOp = NULL;

            SELECT TOP (1)
                @IdOp = o.IdOperacionXML
                , @Nodo = o.NombreNodo
                , @Datos = o.Datos
            FROM dbo.OperacionXML AS o
            WHERE o.Fecha = @inFecha
              AND o.flag_procesada = @false
            ORDER BY o.OrdenEnArchivo, o.IdOperacionXML;

            IF @IdOp IS NULL
                BREAK;

            IF @Nodo = 'Movimientos'
            BEGIN
                SET @NumeroCuenta = @Datos.value('(/*/@CodigoCuenta)[1]', 'VARCHAR(32)');
                SET @Tipo = @Datos.value('(/*/@Tipo)[1]', 'VARCHAR(128)');
                SET @Monto = @Datos.value('(/*/@Monto)[1]', 'DECIMAL(18,2)');
                SET @Descripcion = ISNULL(
                    @Datos.value('(/*/@Descripcion)[1]', 'VARCHAR(256)')
                    , ''
                );

                SET @IdTipo = NULL;
                SELECT @IdTipo = t.Id
                FROM dbo.TipoMovimiento AS t
                WHERE t.Nombre = LTRIM(RTRIM(@Tipo));

                SET @ResultadoSP = 50403;
                IF @IdTipo IS NOT NULL
                    EXEC dbo.sp_AplicarMovimiento
                        @inNumeroCuenta = @NumeroCuenta
                        , @inIdTipoMovimiento = @IdTipo
                        , @inFecha = @FechaMov
                        , @inMonto = @Monto
                        , @inDescripcion = @Descripcion
                        , @outResult = @ResultadoSP OUTPUT
                        , @inIdOperacionXML = @IdOp;
            END
            ELSE IF @Nodo = 'Persona'
                EXEC dbo.sp_ProcesarPersonaXML
                    @inIdOperacionXML = @IdOp
                    , @outResult = @ResultadoSP OUTPUT;
            ELSE IF @Nodo = 'Cuenta'
                EXEC dbo.sp_ProcesarCuentaXML
                    @inIdOperacionXML = @IdOp
                    , @outResult = @ResultadoSP OUTPUT;
            ELSE IF @Nodo = 'Beneficiario'
                EXEC dbo.sp_ProcesarBeneficiarioXML
                    @inIdOperacionXML = @IdOp
                    , @outResult = @ResultadoSP OUTPUT;
            ELSE IF @Nodo = 'Usuario'
                EXEC dbo.sp_ProcesarUsuarioXML
                    @inIdOperacionXML = @IdOp
                    , @outResult = @ResultadoSP OUTPUT;
            ELSE IF @Nodo = 'UsuarioPuedeVer'
                EXEC dbo.sp_ProcesarUsuarioPuedeVerXML
                    @inIdOperacionXML = @IdOp
                    , @outResult = @ResultadoSP OUTPUT;
            ELSE
                SET @ResultadoSP = 50410;

            IF @ResultadoSP <> 0
            BEGIN
                SET @Mensaje = CONCAT(
                    'Fallo la operacion XML ', @IdOp
                    , ' (nodo ', @Nodo, ', codigo ', @ResultadoSP, ').'
                );
                THROW 50404, @Mensaje, 1;
            END;

            UPDATE dbo.OperacionXML
            SET flag_procesada = @true
            WHERE IdOperacionXML = @IdOp
              AND flag_procesada = @false;
        END;

        WHILE 1 = 1
        BEGIN
            SET @IdEstado = NULL;

            SELECT TOP (1) @IdEstado = e.IdEstadoCuenta
            FROM dbo.EstadoDeCuenta AS e
            WHERE e.Cerrado = @false
              AND e.FechaFin = @inFecha
            ORDER BY e.IdCuenta, e.IdEstadoCuenta;

            IF @IdEstado IS NULL
                BREAK;

            EXEC dbo.sp_CerrarEstadoCuenta
                @inIdEstadoCuenta = @IdEstado
                , @inFechaCierre = @inFecha
                , @outResult = @ResultadoSP OUTPUT
                , @outIdNuevoEstadoCuenta = @IdEstadoNuevo OUTPUT;

            IF @ResultadoSP <> 0
            BEGIN
                SET @Mensaje = CONCAT(
                    'Fallo el cierre del estado de cuenta ', @IdEstado
                    , ' (codigo ', @ResultadoSP, ').'
                );
                THROW 50411, @Mensaje, 1;
            END;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.EstadoDeCuenta AS e
            WHERE e.Cerrado = @false
              AND e.FechaFin < @inFecha
        )
            THROW 50412,
                'Quedaron estados de cuenta abiertos con fecha final vencida.',
                1;

        UPDATE dbo.ControlFechaOperacion
        SET flag_procesada = @true
            , FechaProcesamiento = GETDATE()
            , UltimoError = NULL
        WHERE Fecha = @inFecha;

        EXEC sys.sp_releaseapplock
            @Resource = 'sp_ProcesarSimulacion'
            , @LockOwner = 'Session';

        SET @flag_candado = @false;
        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();
        SET @Mensaje = CONCAT(
            '[', ERROR_NUMBER(), '] ', ERROR_MESSAGE()
            , ' (linea ', ERROR_LINE(), ', '
            , ISNULL(ERROR_PROCEDURE(), 'lote'), ')'
        );

        IF @flag_candado = @true
        BEGIN
            EXEC sys.sp_releaseapplock
                @Resource = 'sp_ProcesarSimulacion'
                , @LockOwner = 'Session';

            UPDATE dbo.ControlFechaOperacion
            SET UltimoError = LEFT(@Mensaje, 1024)
            WHERE Fecha = @inFecha
              AND flag_procesada = @false;
        END;

        THROW;
    END CATCH;
END;
GO


/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
-- Ejecutar sin BEGIN TRAN externo. Procesa en orden ascendente todas
-- las fechas pendientes (hasta @inFechaHasta, o todas si es NULL).
DECLARE @outResult INT;
EXEC dbo.sp_ProcesarSimulacion
    @inFechaHasta = NULL,
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
===================================================================
*/
CREATE OR ALTER PROCEDURE dbo.sp_ProcesarSimulacion
    @inFechaHasta DATE = NULL,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @true BIT = 1,
            @false BIT = 0;

    DECLARE @flag_candado BIT = 0;
    DECLARE @Candado INT;
    DECLARE @Fecha DATE;
    DECLARE @ResultadoSP INT;

    BEGIN TRY
        SET @outResult = 50000;

        IF @@TRANCOUNT <> 0
            THROW 50400, 'Ejecute la simulacion sin una transaccion externa.', 1;

        EXEC @Candado = sys.sp_getapplock
            @Resource = 'sp_ProcesarSimulacion'
            , @LockMode = 'Exclusive'
            , @LockOwner = 'Session'
            , @LockTimeout = 0;

        IF @Candado < 0
            THROW 50420, 'Ya hay un proceso de simulacion en ejecucion.', 1;

        SET @flag_candado = @true;

        WHILE 1 = 1
        BEGIN
            SET @Fecha = NULL;

            SELECT TOP (1) @Fecha = c.Fecha
            FROM dbo.ControlFechaOperacion AS c
            WHERE c.flag_procesada = @false
              AND (@inFechaHasta IS NULL OR c.Fecha <= @inFechaHasta)
            ORDER BY c.Fecha;

            IF @Fecha IS NULL
                BREAK;

            EXEC dbo.sp_ProcesarFechaOperacion
                @inFecha = @Fecha
                , @outResult = @ResultadoSP OUTPUT;

            IF @ResultadoSP <> 0
                THROW 50421,
                    'Ocurrio un error procesando una fecha de operacion.',
                    1;
        END;

        EXEC sys.sp_releaseapplock
            @Resource = 'sp_ProcesarSimulacion'
            , @LockOwner = 'Session';

        SET @flag_candado = @false;
        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();

        IF @flag_candado = @true
            EXEC sys.sp_releaseapplock
                @Resource = 'sp_ProcesarSimulacion'
                , @LockOwner = 'Session';

        THROW;
    END CATCH;
END;
GO
