IF OBJECT_ID('dbo.sp_CargarDatosPrueba', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CargarDatosPrueba;
GO

CREATE PROCEDURE dbo.sp_CargarDatosPrueba
    @xmlData XML
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        /* ---------- 1. TipoMoneda ---------- */
        INSERT INTO dbo.TipoMoneda (Id, Nombre, Simbolo)
        SELECT
            T.c.value('@Id', 'INT'),
            T.c.value('@Nombre', 'VARCHAR(128)'),
            T.c.value('@Simbolo', 'NVARCHAR(10)')
        FROM @xmlData.nodes('/DatosPrueba/Tipo_Moneda/TipoMoneda') AS T(c);

        /* ---------- 2. TipoDocuIdentidad ---------- */
        INSERT INTO dbo.TipoDocuIdentidad (Id, Nombre)
        SELECT
            T.c.value('@Id', 'INT'),
            T.c.value('@Nombre', 'VARCHAR(128)')
        FROM @xmlData.nodes('/DatosPrueba/Tipo_Doc/TipoDocuIdentidad') AS T(c);

        /* ---------- 3. Parentezco ---------- */
        INSERT INTO dbo.Parentezco (Id, Nombre)
        SELECT
            T.c.value('@Id', 'INT'),
            T.c.value('@Nombre', 'VARCHAR(20)')
        FROM @xmlData.nodes('/DatosPrueba/Parentezcos/Parentezco') AS T(c);

        /* ---------- 4. TipoCuentaAhorro ---------- */
        INSERT INTO dbo.TipoCuentaAhorro (
            Id, Nombre, IdTipoMoneda, SaldoMinimo, MultaSaldoMin, CargoAnual,
            NumRetirosHumano, NumRetirosAutomatico, ComisionHumano, ComisionAutomatico, Interes
        )
        SELECT
            T.c.value('@Id', 'INT'),
            T.c.value('@Nombre', 'VARCHAR(128)'),
            T.c.value('@IdTipoMoneda', 'INT'),
            T.c.value('@SaldoMinimo', 'DECIMAL(18,2)'),
            T.c.value('@MultaSaldoMin', 'DECIMAL(18,2)'),
            T.c.value('@CargoAnual', 'DECIMAL(18,2)'),
            T.c.value('@NumRetirosHumano', 'INT'),
            T.c.value('@NumRetirosAutomatico', 'INT'),
            T.c.value('@comisionHumano', 'DECIMAL(18,2)'),
            T.c.value('@comisionAutomatico', 'DECIMAL(18,2)'),
            T.c.value('@interes', 'DECIMAL(5,2)')
        FROM @xmlData.nodes('/DatosPrueba/Tipo_Cuenta_Ahorros/TipoCuentaAhorro') AS T(c);

        /* ---------- 5. TipoOperaciones ---------- */
        INSERT INTO dbo.TipoOperaciones (Id, Nombre)
        SELECT
            T.c.value('@id', 'INT'),
            T.c.value('@nombre', 'VARCHAR(128)')
        FROM @xmlData.nodes('/DatosPrueba/TipoOperaciones/TipoOperacion') AS T(c);

        /* ---------- 6. Persona ---------- */
        INSERT INTO dbo.Persona (
            IdTipoDocuIdentidad, ValorDocumentoIdentidad, Nombre,
            FechaNacimiento, Email, Telefono1, Telefono2
        )
        SELECT
            T.c.value('@TipoDocuIdentidad', 'INT'),
            T.c.value('@ValorDocumentoIdentidad', 'VARCHAR(64)'),
            T.c.value('@Nombre', 'VARCHAR(64)'),
            T.c.value('@FechaNacimiento', 'DATE'),
            T.c.value('@Email', 'VARCHAR(100)'),
            T.c.value('@telefono1', 'VARCHAR(20)'),
            T.c.value('@telefono2', 'VARCHAR(20)')
        FROM @xmlData.nodes('/DatosPrueba/Personas/Persona') AS T(c)
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Persona p
            WHERE p.ValorDocumentoIdentidad = T.c.value('@ValorDocumentoIdentidad', 'VARCHAR(64)')
        );

        /* ---------- 7. Cuenta ---------- */
        INSERT INTO dbo.Cuenta (NumeroCuenta, IdPersonaDueno, IdTipoCuenta, FechaCreacion, Saldo)
        SELECT
            T.c.value('@NumeroCuenta', 'VARCHAR(32)'),
            p.IdPersona,
            T.c.value('@TipoCuentaId', 'INT'),
            T.c.value('@FechaCreacion', 'DATE'),
            T.c.value('@Saldo', 'DECIMAL(18,2)')
        FROM @xmlData.nodes('/DatosPrueba/Cuentas/Cuenta') AS T(c)
        INNER JOIN dbo.Persona p
            ON p.ValorDocumentoIdentidad = T.c.value('@ValorDocumentoIdentidadDelCliente', 'VARCHAR(64)');

        /* ---------- 8. Beneficiario ---------- */
        INSERT INTO dbo.Beneficiario (IdCuenta, IdPersona, IdParentezco, Porcentaje)
        SELECT
            cu.IdCuenta,
            pe.IdPersona,
            T.c.value('@ParentezcoId', 'INT'),
            T.c.value('@Porcentaje', 'INT')
        FROM @xmlData.nodes('/DatosPrueba/Beneficiarios/Beneficiario') AS T(c)
        INNER JOIN dbo.Cuenta cu
            ON cu.NumeroCuenta = T.c.value('@NumeroCuenta', 'VARCHAR(32)')
        INNER JOIN dbo.Persona pe
            ON pe.ValorDocumentoIdentidad = T.c.value('@ValorDocumentoIdentidadBeneficiario', 'VARCHAR(64)');

        /* ---------- 9. EstadoDeCuenta ---------- */
        INSERT INTO dbo.EstadoDeCuenta (
            IdCuenta, FechaInicio, FechaFin, SaldoInicial, SaldoFinal,
            InteresesAcumulados, CantidadRetiros, CantidadDepositos
        )
        SELECT
            cu.IdCuenta,
            T.c.value('@fechaInicio', 'DATE'),
            T.c.value('@fechafin', 'DATE'),
            T.c.value('@saldoinicial', 'DECIMAL(18,2)'),
            T.c.value('@saldo_final', 'DECIMAL(18,2)'),
            T.c.value('@interesesAcumulados', 'DECIMAL(18,2)'),
            T.c.value('@cantidadRetiros', 'INT'),
            T.c.value('@cantidadDepositos', 'INT')
        FROM @xmlData.nodes('/DatosPrueba/Estados_de_Cuenta/Estado_de_Cuenta') AS T(c)
        INNER JOIN dbo.Cuenta cu
            ON cu.NumeroCuenta = T.c.value('@NumeroCuenta', 'VARCHAR(32)');

        /* ---------- 10. Usuario ---------- */
        INSERT INTO dbo.Usuario ([User], Pass, EsAdministrador)
        SELECT
            T.c.value('@User', 'VARCHAR(64)'),
            T.c.value('@Pass', 'VARCHAR(255)'),
            T.c.value('@EsAdministrador', 'BIT')
        FROM @xmlData.nodes('/DatosPrueba/Usuarios/Usuario') AS T(c);

        /* ---------- 11. UsuarioCuenta ---------- */
        INSERT INTO dbo.UsuarioCuenta (IdUsuario, IdCuenta)
        SELECT
            u.IdUsuario,
            cu.IdCuenta
        FROM @xmlData.nodes('/DatosPrueba/Usuarios_Ver/UsuarioPuedeVer') AS T(c)
        INNER JOIN dbo.Usuario u
            ON u.[User] = T.c.value('@User', 'VARCHAR(64)')
        INNER JOIN dbo.Cuenta cu
            ON cu.NumeroCuenta = T.c.value('@NumeroCuenta', 'VARCHAR(32)');

        COMMIT TRANSACTION;
        PRINT 'Carga completada correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO