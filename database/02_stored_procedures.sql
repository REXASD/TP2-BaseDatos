-- ============================================================
-- TP2 - Base de Datos
-- Stored Procedures
-- ============================================================


-- ============================================================
-- 1. Registrar Bitacora
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_RegistrarBitacora
    @IdUsuario INT,
    @IdTipoOperacion INT,
    @IP VARCHAR(64) = NULL,
    @JsonAntes NVARCHAR(MAX) = NULL,
    @JsonDespues NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Bitacora
    (
        IdUsuario,
        IdTipoOperacion,
        IP,
        JsonAntes,
        JsonDespues,
        FechaHora
    )
    VALUES
    (
        @IdUsuario,
        @IdTipoOperacion,
        @IP,
        @JsonAntes,
        @JsonDespues,
        GETDATE()
    );

    RETURN 0;
END;
GO


-- ============================================================
-- 2. Obtener Parentescos
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ObtenerParentescos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Nombre
    FROM dbo.Parentezco;
END;
GO


-- ============================================================
-- 3. Validar Login
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ValidarLogin
    @Usuario VARCHAR(64),
    @Password VARCHAR(255),
    @IP VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUsuario INT;

    SELECT @IdUsuario = IdUsuario
    FROM dbo.Usuario
    WHERE [User] = @Usuario
      AND Pass = @Password;

    IF @IdUsuario IS NOT NULL
    BEGIN

        EXEC dbo.sp_RegistrarBitacora
            @IdUsuario = @IdUsuario,
            @IdTipoOperacion = 1,
            @IP = @IP;

        SELECT
            IdUsuario,
            [User],
            EsAdministrador
        FROM dbo.Usuario
        WHERE IdUsuario = @IdUsuario;

        RETURN 0;
    END
    ELSE
    BEGIN
        RETURN 1;
    END
END;
GO


-- ============================================================
-- 4. Logout
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_LogoutUsuario
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.sp_RegistrarBitacora
        @IdUsuario = @IdUsuario,
        @IdTipoOperacion = 2;

    RETURN 0;
END;
GO


-- ============================================================
-- 5. Obtener Cuentas de Usuario
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ObtenerCuentasUsuario
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Cuenta.IdCuenta,
        Cuenta.NumeroCuenta,
        Cuenta.FechaCreacion,
        Cuenta.Saldo
    FROM dbo.UsuarioCuenta
    INNER JOIN dbo.Cuenta
        ON UsuarioCuenta.IdCuenta = Cuenta.IdCuenta
    WHERE UsuarioCuenta.IdUsuario = @IdUsuario;
END;
GO


-- ============================================================
-- 6. Obtener Beneficiarios
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ObtenerBeneficiarios
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Beneficiario.IdBeneficiario,
        Beneficiario.IdCuenta,
        Beneficiario.IdPersona,
        Persona.IdTipoDocuIdentidad,
        Persona.ValorDocumentoIdentidad,
        Persona.Nombre,
        Persona.FechaNacimiento,
        Persona.Email,
        Persona.Telefono1,
        Persona.Telefono2,
        Beneficiario.IdParentezco,
        Parentezco.Nombre AS Parentezco,
        Beneficiario.Porcentaje
    FROM dbo.Beneficiario
    INNER JOIN dbo.Persona
        ON Beneficiario.IdPersona = Persona.IdPersona
    INNER JOIN dbo.Parentezco
        ON Beneficiario.IdParentezco = Parentezco.Id
    WHERE Beneficiario.IdCuenta = @IdCuenta
      AND Beneficiario.Activo = 1;
END;
GO


-- ============================================================
-- 7. Verificar Porcentaje de Beneficiarios
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_VerificarPorcentajeBeneficiarios
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalPorcentaje INT;

    SELECT @TotalPorcentaje = ISNULL(SUM(Porcentaje), 0)
    FROM dbo.Beneficiario
    WHERE IdCuenta = @IdCuenta
      AND Activo = 1;

    SELECT
        @TotalPorcentaje AS TotalPorcentaje,
        CASE
            WHEN @TotalPorcentaje = 100 THEN 1
            ELSE 0
        END AS PorcentajeCorrecto;
END;
GO


-- ============================================================
-- 8. Obtener Estados de Cuenta
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ObtenerEstadosCuenta
    @IdUsuario INT,
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.sp_RegistrarBitacora
        @IdUsuario = @IdUsuario,
        @IdTipoOperacion = 7;

    SELECT TOP 8
        IdEstadoCuenta,
        FechaInicio,
        FechaFin,
        SaldoInicial,
        SaldoFinal,
        InteresesAcumulados,
        CantidadRetiros,
        CantidadDepositos
    FROM dbo.EstadoDeCuenta
    WHERE IdCuenta = @IdCuenta
    ORDER BY FechaFin DESC;
END;
GO


-- ============================================================
-- 9. Insertar Beneficiario
--
-- Return:
-- 0 = Correcto
-- 1 = Ya existen 3 beneficiarios activos
-- 2 = Porcentaje invalido
-- 3 = Error
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_InsertarBeneficiario
    @IdUsuario INT,
    @IdCuenta INT,
    @IdTipoDocuIdentidad INT,
    @ValorDocumentoIdentidad VARCHAR(64),
    @Nombre VARCHAR(64),
    @FechaNacimiento DATE,
    @Email VARCHAR(100),
    @Telefono1 VARCHAR(20),
    @Telefono2 VARCHAR(20),
    @IdParentezco INT,
    @Porcentaje INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Porcentaje < 0 OR @Porcentaje > 100
    BEGIN
        RETURN 2;
    END

    DECLARE @CantidadBeneficiarios INT;

    SELECT @CantidadBeneficiarios = COUNT(*)
    FROM dbo.Beneficiario
    WHERE IdCuenta = @IdCuenta
      AND Activo = 1;

    IF @CantidadBeneficiarios >= 3
    BEGIN
        RETURN 1;
    END

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @IdPersona INT;

        SELECT @IdPersona = IdPersona
        FROM dbo.Persona
        WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

        IF @IdPersona IS NULL
        BEGIN

            INSERT INTO dbo.Persona
            (
                IdTipoDocuIdentidad,
                ValorDocumentoIdentidad,
                Nombre,
                FechaNacimiento,
                Email,
                Telefono1,
                Telefono2
            )
            VALUES
            (
                @IdTipoDocuIdentidad,
                @ValorDocumentoIdentidad,
                @Nombre,
                @FechaNacimiento,
                @Email,
                @Telefono1,
                @Telefono2
            );

            SET @IdPersona = SCOPE_IDENTITY();

        END

        INSERT INTO dbo.Beneficiario
        (
            IdCuenta,
            IdParentezco,
            IdPersona,
            Porcentaje,
            Activo,
            FechaDesactivacion
        )
        VALUES
        (
            @IdCuenta,
            @IdParentezco,
            @IdPersona,
            @Porcentaje,
            1,
            NULL
        );

        DECLARE @IdBeneficiario INT;

        SET @IdBeneficiario = SCOPE_IDENTITY();

        DECLARE @JsonDespues NVARCHAR(MAX);

        SELECT @JsonDespues =
        (
            SELECT
                IdBeneficiario,
                IdCuenta,
                IdPersona,
                IdParentezco,
                Porcentaje,
                Activo,
                FechaDesactivacion
            FROM dbo.Beneficiario
            WHERE IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.sp_RegistrarBitacora
            @IdUsuario = @IdUsuario,
            @IdTipoOperacion = 3,
            @JsonAntes = NULL,
            @JsonDespues = @JsonDespues;

        COMMIT TRANSACTION;

        RETURN 0;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        RETURN 3;

    END CATCH
END;
GO


-- ============================================================
-- 10. Actualizar Beneficiario
--
-- Return:
-- 0 = Correcto
-- 1 = No existe o esta inactivo
-- 2 = Porcentaje invalido
-- 3 = Error
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ActualizarBeneficiario
    @IdUsuario INT,
    @IdBeneficiario INT,
    @Nombre VARCHAR(64),
    @ValorDocumentoIdentidad VARCHAR(64),
    @FechaNacimiento DATE,
    @Email VARCHAR(100),
    @Telefono1 VARCHAR(20),
    @Telefono2 VARCHAR(20),
    @IdParentezco INT,
    @Porcentaje INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Porcentaje < 0 OR @Porcentaje > 100
    BEGIN
        RETURN 2;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Beneficiario
        WHERE IdBeneficiario = @IdBeneficiario
          AND Activo = 1
    )
    BEGIN
        RETURN 1;
    END

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @JsonAntes NVARCHAR(MAX);
        DECLARE @JsonDespues NVARCHAR(MAX);

        SELECT @JsonAntes =
        (
            SELECT
                Beneficiario.IdBeneficiario,
                Beneficiario.IdCuenta,
                Beneficiario.IdPersona,
                Beneficiario.IdParentezco,
                Beneficiario.Porcentaje,
                Persona.Nombre,
                Persona.ValorDocumentoIdentidad,
                Persona.FechaNacimiento,
                Persona.Email,
                Persona.Telefono1,
                Persona.Telefono2
            FROM dbo.Beneficiario
            INNER JOIN dbo.Persona
                ON Beneficiario.IdPersona = Persona.IdPersona
            WHERE Beneficiario.IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Beneficiario
        SET IdParentezco = @IdParentezco,
            Porcentaje = @Porcentaje
        WHERE IdBeneficiario = @IdBeneficiario;

        UPDATE dbo.Persona
        SET Nombre = @Nombre,
            ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
            FechaNacimiento = @FechaNacimiento,
            Email = @Email,
            Telefono1 = @Telefono1,
            Telefono2 = @Telefono2
        FROM dbo.Persona
        INNER JOIN dbo.Beneficiario
            ON Persona.IdPersona = Beneficiario.IdPersona
        WHERE Beneficiario.IdBeneficiario = @IdBeneficiario;

        SELECT @JsonDespues =
        (
            SELECT
                Beneficiario.IdBeneficiario,
                Beneficiario.IdCuenta,
                Beneficiario.IdPersona,
                Beneficiario.IdParentezco,
                Beneficiario.Porcentaje,
                Persona.Nombre,
                Persona.ValorDocumentoIdentidad,
                Persona.FechaNacimiento,
                Persona.Email,
                Persona.Telefono1,
                Persona.Telefono2
            FROM dbo.Beneficiario
            INNER JOIN dbo.Persona
                ON Beneficiario.IdPersona = Persona.IdPersona
            WHERE Beneficiario.IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.sp_RegistrarBitacora
            @IdUsuario = @IdUsuario,
            @IdTipoOperacion = 4,
            @JsonAntes = @JsonAntes,
            @JsonDespues = @JsonDespues;

        COMMIT TRANSACTION;

        RETURN 0;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        RETURN 3;

    END CATCH
END;
GO


-- ============================================================
-- 11. Actualizar Porcentaje de Beneficiario
--
-- Return:
-- 0 = Correcto
-- 1 = No existe o esta inactivo
-- 2 = Porcentaje invalido
-- 3 = Error
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ActualizarPorcentajeBeneficiario
    @IdUsuario INT,
    @IdBeneficiario INT,
    @Porcentaje INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Porcentaje < 0 OR @Porcentaje > 100
    BEGIN
        RETURN 2;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Beneficiario
        WHERE IdBeneficiario = @IdBeneficiario
          AND Activo = 1
    )
    BEGIN
        RETURN 1;
    END

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @JsonAntes NVARCHAR(MAX);
        DECLARE @JsonDespues NVARCHAR(MAX);

        SELECT @JsonAntes =
        (
            SELECT
                IdBeneficiario,
                IdCuenta,
                IdPersona,
                Porcentaje
            FROM dbo.Beneficiario
            WHERE IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Beneficiario
        SET Porcentaje = @Porcentaje
        WHERE IdBeneficiario = @IdBeneficiario;

        SELECT @JsonDespues =
        (
            SELECT
                IdBeneficiario,
                IdCuenta,
                IdPersona,
                Porcentaje
            FROM dbo.Beneficiario
            WHERE IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.sp_RegistrarBitacora
            @IdUsuario = @IdUsuario,
            @IdTipoOperacion = 6,
            @JsonAntes = @JsonAntes,
            @JsonDespues = @JsonDespues;

        COMMIT TRANSACTION;

        RETURN 0;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        RETURN 3;

    END CATCH
END;
GO


-- ============================================================
-- 12. Eliminar Beneficiario
--
-- Eliminacion logica
--
-- Return:
-- 0 = Correcto
-- 1 = No existe o esta inactivo
-- 2 = Error
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_EliminarBeneficiario
    @IdUsuario INT,
    @IdBeneficiario INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Beneficiario
        WHERE IdBeneficiario = @IdBeneficiario
          AND Activo = 1
    )
    BEGIN
        RETURN 1;
    END

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @JsonAntes NVARCHAR(MAX);
        DECLARE @JsonDespues NVARCHAR(MAX);

        SELECT @JsonAntes =
        (
            SELECT
                IdBeneficiario,
                IdCuenta,
                IdPersona,
                IdParentezco,
                Porcentaje,
                Activo,
                FechaDesactivacion
            FROM dbo.Beneficiario
            WHERE IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Beneficiario
        SET Activo = 0,
            FechaDesactivacion = CAST(GETDATE() AS DATE)
        WHERE IdBeneficiario = @IdBeneficiario;

        SELECT @JsonDespues =
        (
            SELECT
                IdBeneficiario,
                IdCuenta,
                IdPersona,
                IdParentezco,
                Porcentaje,
                Activo,
                FechaDesactivacion
            FROM dbo.Beneficiario
            WHERE IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.sp_RegistrarBitacora
            @IdUsuario = @IdUsuario,
            @IdTipoOperacion = 5,
            @JsonAntes = @JsonAntes,
            @JsonDespues = @JsonDespues;

        COMMIT TRANSACTION;

        RETURN 0;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        RETURN 2;

    END CATCH
END;
GO

-- ============================================================
-- 13. Obtener tipo de documentos de identidad
-- ============================================================


CREATE OR ALTER   PROCEDURE dbo.sp_ObtenerTiposDocumento
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Nombre
    FROM dbo.TipoDocuIdentidad;
END;
GO

-- ============================================================
-- 14. Obtener beneficiario por id
-- ============================================================

CREATE OR ALTER  PROCEDURE [dbo].[sp_ObtenerBeneficiarioPorId]
    @IdBeneficiario INT,
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Beneficiario.IdBeneficiario,
        Beneficiario.IdCuenta,
        Beneficiario.IdPersona,
        Persona.IdTipoDocuIdentidad,
        Persona.ValorDocumentoIdentidad,
        Persona.Nombre,
        Persona.FechaNacimiento,
        Persona.Email,
        Persona.Telefono1,
        Persona.Telefono2,
        Beneficiario.IdParentezco,
        Beneficiario.Porcentaje
    FROM dbo.Beneficiario
    INNER JOIN dbo.Persona
        ON Beneficiario.IdPersona = Persona.IdPersona
    WHERE Beneficiario.IdBeneficiario = @IdBeneficiario
      AND Beneficiario.IdCuenta = @IdCuenta
      AND Beneficiario.Activo = 1;
END;
GO
