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
        pa.Id,
        pa.Nombre
    FROM dbo.Parentezco AS pa;
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

    SELECT @IdUsuario = u.IdUsuario
    FROM dbo.Usuario AS u
    WHERE u.[User] = @Usuario
      AND u.Pass = @Password;

    IF @IdUsuario IS NOT NULL
    BEGIN

        EXEC dbo.sp_RegistrarBitacora
            @IdUsuario = @IdUsuario,
            @IdTipoOperacion = 1,
            @IP = @IP;

        SELECT
            u.IdUsuario,
            u.[User],
            u.EsAdministrador
        FROM dbo.Usuario AS u
        WHERE u.IdUsuario = @IdUsuario;

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
        c.IdCuenta,
        c.NumeroCuenta,
        c.FechaCreacion,
        c.Saldo
    FROM dbo.UsuarioCuenta AS uc
    INNER JOIN dbo.Cuenta AS c
        ON uc.IdCuenta = c.IdCuenta
    WHERE uc.IdUsuario = @IdUsuario;
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
        b.IdBeneficiario,
        b.IdCuenta,
        b.IdPersona,
        p.IdTipoDocuIdentidad,
        p.ValorDocumentoIdentidad,
        p.Nombre,
        p.FechaNacimiento,
        p.Email,
        p.Telefono1,
        p.Telefono2,
        b.IdParentezco,
        pa.Nombre AS Parentezco,
        b.Porcentaje
    FROM dbo.Beneficiario AS b
    INNER JOIN dbo.Persona AS p
        ON b.IdPersona = p.IdPersona
    INNER JOIN dbo.Parentezco AS pa
        ON b.IdParentezco = pa.Id
    WHERE b.IdCuenta = @IdCuenta
      AND b.Activo = 1;
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

    SELECT @TotalPorcentaje = ISNULL(SUM(b.Porcentaje), 0)
    FROM dbo.Beneficiario AS b
    WHERE b.IdCuenta = @IdCuenta
      AND b.Activo = 1;

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
        ec.IdEstadoCuenta,
        ec.FechaInicio,
        ec.FechaFin,
        ec.SaldoInicial,
        ec.SaldoMinimo,
        ec.SaldoFinal,
        ec.InteresesAcumulados,
        ec.CantidadRetiros,
        ec.CantidadDepositos,
        ec.CantidadSinpeEntrantes,
        ec.CantidadSinpeSalientes
    FROM dbo.EstadoDeCuenta AS ec
    WHERE ec.IdCuenta = @IdCuenta
    ORDER BY ec.FechaFin DESC, ec.IdEstadoCuenta DESC;
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
    FROM dbo.Beneficiario AS b
    WHERE b.IdCuenta = @IdCuenta
      AND b.Activo = 1;

    IF @CantidadBeneficiarios >= 3
    BEGIN
        RETURN 1;
    END

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @IdPersona INT;

        SELECT @IdPersona = p.IdPersona
        FROM dbo.Persona AS p
        WHERE p.ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

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
                b.IdBeneficiario,
                b.IdCuenta,
                b.IdPersona,
                b.IdParentezco,
                b.Porcentaje,
                b.Activo,
                b.FechaDesactivacion
            FROM dbo.Beneficiario AS b
            WHERE b.IdBeneficiario = @IdBeneficiario
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
        FROM dbo.Beneficiario AS b
        WHERE b.IdBeneficiario = @IdBeneficiario
          AND b.Activo = 1
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
                b.IdBeneficiario,
                b.IdCuenta,
                b.IdPersona,
                b.IdParentezco,
                b.Porcentaje,
                p.Nombre,
                p.ValorDocumentoIdentidad,
                p.FechaNacimiento,
                p.Email,
                p.Telefono1,
                p.Telefono2
            FROM dbo.Beneficiario AS b
            INNER JOIN dbo.Persona AS p
                ON b.IdPersona = p.IdPersona
            WHERE b.IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE b
        SET b.IdParentezco = @IdParentezco,
            b.Porcentaje = @Porcentaje
        FROM dbo.Beneficiario AS b
        WHERE b.IdBeneficiario = @IdBeneficiario;

        UPDATE p
        SET p.Nombre = @Nombre,
            p.ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
            p.FechaNacimiento = @FechaNacimiento,
            p.Email = @Email,
            p.Telefono1 = @Telefono1,
            p.Telefono2 = @Telefono2
        FROM dbo.Persona AS p
        INNER JOIN dbo.Beneficiario AS b
            ON p.IdPersona = b.IdPersona
        WHERE b.IdBeneficiario = @IdBeneficiario;

        SELECT @JsonDespues =
        (
            SELECT
                b.IdBeneficiario,
                b.IdCuenta,
                b.IdPersona,
                b.IdParentezco,
                b.Porcentaje,
                p.Nombre,
                p.ValorDocumentoIdentidad,
                p.FechaNacimiento,
                p.Email,
                p.Telefono1,
                p.Telefono2
            FROM dbo.Beneficiario AS b
            INNER JOIN dbo.Persona AS p
                ON b.IdPersona = p.IdPersona
            WHERE b.IdBeneficiario = @IdBeneficiario
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
        FROM dbo.Beneficiario AS b
        WHERE b.IdBeneficiario = @IdBeneficiario
          AND b.Activo = 1
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
                b.IdBeneficiario,
                b.IdCuenta,
                b.IdPersona,
                b.Porcentaje
            FROM dbo.Beneficiario AS b
            WHERE b.IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE b
        SET b.Porcentaje = @Porcentaje
        FROM dbo.Beneficiario AS b
        WHERE b.IdBeneficiario = @IdBeneficiario;

        SELECT @JsonDespues =
        (
            SELECT
                b.IdBeneficiario,
                b.IdCuenta,
                b.IdPersona,
                b.Porcentaje
            FROM dbo.Beneficiario AS b
            WHERE b.IdBeneficiario = @IdBeneficiario
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
        FROM dbo.Beneficiario AS b
        WHERE b.IdBeneficiario = @IdBeneficiario
          AND b.Activo = 1
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
                b.IdBeneficiario,
                b.IdCuenta,
                b.IdPersona,
                b.IdParentezco,
                b.Porcentaje,
                b.Activo,
                b.FechaDesactivacion
            FROM dbo.Beneficiario AS b
            WHERE b.IdBeneficiario = @IdBeneficiario
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE b
        SET b.Activo = 0,
            b.FechaDesactivacion = CAST(GETDATE() AS DATE)
        FROM dbo.Beneficiario AS b
        WHERE b.IdBeneficiario = @IdBeneficiario;

        SELECT @JsonDespues =
        (
            SELECT
                b.IdBeneficiario,
                b.IdCuenta,
                b.IdPersona,
                b.IdParentezco,
                b.Porcentaje,
                b.Activo,
                b.FechaDesactivacion
            FROM dbo.Beneficiario AS b
            WHERE b.IdBeneficiario = @IdBeneficiario
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

CREATE OR ALTER PROCEDURE dbo.sp_ObtenerTiposDocumento
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        td.Id,
        td.Nombre
    FROM dbo.TipoDocuIdentidad AS td;
END;
GO


-- ============================================================
-- 14. Obtener beneficiario por id
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_ObtenerBeneficiarioPorId
    @IdBeneficiario INT,
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.IdBeneficiario,
        b.IdCuenta,
        b.IdPersona,
        p.IdTipoDocuIdentidad,
        p.ValorDocumentoIdentidad,
        p.Nombre,
        p.FechaNacimiento,
        p.Email,
        p.Telefono1,
        p.Telefono2,
        b.IdParentezco,
        b.Porcentaje
    FROM dbo.Beneficiario AS b
    INNER JOIN dbo.Persona AS p
        ON b.IdPersona = p.IdPersona
    WHERE b.IdBeneficiario = @IdBeneficiario
      AND b.IdCuenta = @IdCuenta
      AND b.Activo = 1;
END;
GO