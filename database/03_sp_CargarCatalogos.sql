CREATE OR ALTER PROCEDURE dbo.sp_CargarCatalogosXML
    @inXml XML,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;


    DECLARE @true BIT = 1,
            @false BIT = 0;


    DECLARE @RawTipoMovimiento TABLE (
        Id INT PRIMARY KEY
        , Nombre VARCHAR(128)
        , Accion VARCHAR(32)
        , flag_genera_comprobante BIT
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        /* 1. TipoMoneda */
        INSERT INTO dbo.TipoMoneda (
            Id
            , Nombre
            , Simbolo
        )
        SELECT 
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
            , T.c.value('@Simbolo', 'NVARCHAR(2)')
        FROM @inXml.nodes('/Catalogos/Tipo_Moneda/TipoMoneda') AS T(c)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.TipoMoneda x 
            WHERE x.Id = T.c.value('@Id', 'INT')
        );

        /* 2. TipoDocuIdentidad */
        INSERT INTO dbo.TipoDocuIdentidad (
            Id
            , Nombre
        )
        SELECT 
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
        FROM @inXml.nodes('/Catalogos/Tipo_Doc/TipoDocuIdentidad') AS T(c)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.TipoDocuIdentidad x 
            WHERE x.Id = T.c.value('@Id', 'INT')
        );

        /* 3. Parentezco */
        INSERT INTO dbo.Parentezco (
            Id
            , Nombre
        )
        SELECT 
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(32)')
        FROM @inXml.nodes('/Catalogos/Parentezcos/Parentezco') AS T(c)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.Parentezco x 
            WHERE x.Id = T.c.value('@Id', 'INT')
        );

        /* 4. TipoOperacion */
        INSERT INTO dbo.TipoOperacion (
            Id
            , Nombre
        )
        SELECT 
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
        FROM @inXml.nodes('/Catalogos/TipoOperacionesBitacora/TipoOperacion') AS T(c)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.TipoOperacion x 
            WHERE x.Id = T.c.value('@Id', 'INT')
        );

        /* 5. TipoCuentaAhorro */
        INSERT INTO dbo.TipoCuentaAhorro (
            Id
            , Nombre
            , IdTipoMoneda
            , SaldoMinimo
            , MultaSaldoMin
            , CargoMensual
            , NumRetirosHumano
            , NumRetirosAutomatico
            , ComisionHumano
            , ComisionAutomatico
            , TasaInteresAnual
            , MontoMaxSinpeDiario
            , ComisionSinpe
        )
        SELECT
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
            , T.c.value('@IdTipoMoneda', 'INT')
            , T.c.value('@SaldoMinimo', 'DECIMAL(18,2)')
            , T.c.value('@MultaSaldoMin', 'DECIMAL(18,2)')
            , T.c.value('@CargoMensual', 'DECIMAL(18,2)')
            , T.c.value('@NumRetirosHumano', 'INT')
            , T.c.value('@NumRetirosAutomatico', 'INT')
            , T.c.value('@ComisionHumano', 'DECIMAL(18,2)')
            , T.c.value('@ComisionAutomatico', 'DECIMAL(18,2)')
            , T.c.value('@TasaInteresAnual', 'DECIMAL(5,2)')
            , T.c.value('@MontoMaxSinpeDiario', 'DECIMAL(18,2)')
            , T.c.value('@ComisionSinpe', 'DECIMAL(18,2)')
        FROM @inXml.nodes('/Catalogos/Tipo_Cuenta_Ahorros/TipoCuentaAhorro') AS T(c)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.TipoCuentaAhorro x 
            WHERE x.Id = T.c.value('@Id', 'INT')
        );

        /* 6. TipoMovimiento */
        INSERT INTO @RawTipoMovimiento (
            Id
            , Nombre
            , Accion
            , flag_genera_comprobante
        )
        SELECT 
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
            , T.c.value('@Accion', 'VARCHAR(32)')
            , T.c.value('@flagGeneraComprobante', 'BIT')
        FROM @inXml.nodes('/Catalogos/Tipos_Movimiento/TipoMovimiento') AS T(c);

        INSERT INTO dbo.TipoMovimiento (
            Id
            , Nombre
            , Efecto
            , Canal
            , flag_requiere_comprobante
        )
        SELECT 
            r.Id
            , r.Nombre
            , CASE r.Accion 
                WHEN 'Credito' THEN 1 
                WHEN 'Debito' THEN -1 
              END
            , CASE 
                WHEN r.Nombre LIKE '%ATM%'     THEN 'ATM'
                WHEN r.Nombre LIKE '%Ventana%' THEN 'Ventana'
                WHEN r.Nombre LIKE '%Sinpe%'   THEN 'Sinpe'
                ELSE NULL 
              END
            , r.flag_genera_comprobante
        FROM @RawTipoMovimiento r
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.TipoMovimiento x 
            WHERE x.Id = r.Id
        );

        COMMIT TRANSACTION;

        SET @outResult = 0; 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;

        SET @outResult = 50000;
        THROW;
    END CATCH;
END;
GO