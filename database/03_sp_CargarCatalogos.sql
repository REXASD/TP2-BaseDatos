
/*
==================================================================
Estándar E31: Ejemplo ejecutable para pruebas del SP
==================================================================

DECLARE @outResult INT;

EXEC dbo.sp_CargarCatalogosXML
    @inXml = N'<Catalogos />'
    , @outResult = @outResult OUTPUT;

SELECT @outResult AS CodigoResultado;

==================================================================
*/

CREATE OR ALTER PROCEDURE dbo.sp_CargarCatalogosXML
    @inXml XML
    , @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        -- a) Declaración de variables generales

        SET @outResult = 0;

        IF @inXml IS NULL
        BEGIN
            SET @outResult = 50001;
            RETURN 50001;
        END;

        -- b) Tablas variables para preprocesamiento en RAM

        DECLARE @TablaTipoMoneda TABLE (
            Id INT PRIMARY KEY
            , Nombre VARCHAR(128)
            , Simbolo NVARCHAR(2)
        );

        DECLARE @TablaTipoDocuIdentidad TABLE (
            Id INT PRIMARY KEY
            , Nombre VARCHAR(128)
        );

        DECLARE @TablaParentezco TABLE (
            Id INT PRIMARY KEY
            , Nombre VARCHAR(32)
        );

        DECLARE @TablaTipoOperacion TABLE (
            Id INT PRIMARY KEY
            , Nombre VARCHAR(128)
        );

        DECLARE @TablaTipoCuentaAhorro TABLE (
            Id INT PRIMARY KEY
            , Nombre VARCHAR(128)
            , IdTipoMoneda INT
            , SaldoMinimo DECIMAL(18,2)
            , MultaSaldoMin DECIMAL(18,2)
            , CargoMensual DECIMAL(18,2)
            , NumRetirosHumano INT
            , NumRetirosAutomatico INT
            , ComisionHumano DECIMAL(18,2)
            , ComisionAutomatico DECIMAL(18,2)
            , TasaInteresAnual DECIMAL(5,2)
            , MontoMaxSinpeDiario DECIMAL(18,2)
            , ComisionSinpe DECIMAL(18,2)
        );

        DECLARE @TablaTipoMovimiento TABLE (
            Id INT PRIMARY KEY
            , Nombre VARCHAR(128)
            , Accion VARCHAR(32)
            , flag_genera_comprobante BIT
        );

        -- c) Preprocesamiento de TipoMoneda

        INSERT INTO @TablaTipoMoneda (
            Id
            , Nombre
            , Simbolo
        )
        SELECT
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
            , T.c.value('@Simbolo', 'NVARCHAR(2)')
        FROM @inXml.nodes(
            '/Catalogos/Tipo_Moneda/TipoMoneda'
        ) AS T(c);

        -- d) Preprocesamiento de TipoDocuIdentidad

        INSERT INTO @TablaTipoDocuIdentidad (
            Id
            , Nombre
        )
        SELECT
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
        FROM @inXml.nodes(
            '/Catalogos/Tipo_Doc/TipoDocuIdentidad'
        ) AS T(c);

        -- e) Preprocesamiento de Parentezco

        INSERT INTO @TablaParentezco (
            Id
            , Nombre
        )
        SELECT
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(32)')
        FROM @inXml.nodes(
            '/Catalogos/Parentezcos/Parentezco'
        ) AS T(c);

        -- f) Preprocesamiento de TipoOperacion

        INSERT INTO @TablaTipoOperacion (
            Id
            , Nombre
        )
        SELECT
            T.c.value('@Id', 'INT')
            , T.c.value('@Nombre', 'VARCHAR(128)')
        FROM @inXml.nodes(
            '/Catalogos/TipoOperacionesBitacora/TipoOperacion'
        ) AS T(c);

        -- g) Preprocesamiento de TipoCuentaAhorro

        INSERT INTO @TablaTipoCuentaAhorro (
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
        FROM @inXml.nodes(
            '/Catalogos/Tipo_Cuenta_Ahorros/TipoCuentaAhorro'
        ) AS T(c);

        -- h) Preprocesamiento de TipoMovimiento

        INSERT INTO @TablaTipoMovimiento (
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
        FROM @inXml.nodes(
            '/Catalogos/Tipos_Movimiento/TipoMovimiento'
        ) AS T(c);

        -- i) Transacción de base de datos
        -- Todas las modificaciones físicas se realizan al final.

        BEGIN TRANSACTION;

            -- 1. TipoMoneda

            INSERT INTO dbo.TipoMoneda (
                Id
                , Nombre
                , Simbolo
            )
            SELECT
                t.Id
                , t.Nombre
                , t.Simbolo
            FROM @TablaTipoMoneda t
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.TipoMoneda x
                WHERE x.Id = t.Id
            );

            -- 2. TipoDocuIdentidad

            INSERT INTO dbo.TipoDocuIdentidad (
                Id
                , Nombre
            )
            SELECT
                t.Id
                , t.Nombre
            FROM @TablaTipoDocuIdentidad t
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.TipoDocuIdentidad x
                WHERE x.Id = t.Id
            );

            -- 3. Parentezco

            INSERT INTO dbo.Parentezco (
                Id
                , Nombre
            )
            SELECT
                t.Id
                , t.Nombre
            FROM @TablaParentezco t
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.Parentezco x
                WHERE x.Id = t.Id
            );

            -- 4. TipoOperacion

            INSERT INTO dbo.TipoOperacion (
                Id
                , Nombre
            )
            SELECT
                t.Id
                , t.Nombre
            FROM @TablaTipoOperacion t
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.TipoOperacion x
                WHERE x.Id = t.Id
            );

            -- 5. TipoCuentaAhorro

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
                t.Id
                , t.Nombre
                , t.IdTipoMoneda
                , t.SaldoMinimo
                , t.MultaSaldoMin
                , t.CargoMensual
                , t.NumRetirosHumano
                , t.NumRetirosAutomatico
                , t.ComisionHumano
                , t.ComisionAutomatico
                , t.TasaInteresAnual
                , t.MontoMaxSinpeDiario
                , t.ComisionSinpe
            FROM @TablaTipoCuentaAhorro t
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.TipoCuentaAhorro x
                WHERE x.Id = t.Id
            );

            -- 6. TipoMovimiento

            INSERT INTO dbo.TipoMovimiento (
                Id
                , Nombre
                , Efecto
                , Canal
                , flag_requiere_comprobante
            )
            SELECT
                t.Id
                , t.Nombre
                , CASE t.Accion
                    WHEN 'Credito' THEN 1
                    WHEN 'Debito' THEN -1
                  END
                , CASE
                    WHEN t.Nombre LIKE '%ATM%' THEN 'ATM'
                    WHEN t.Nombre LIKE '%Ventana%' THEN 'Ventana'
                    WHEN t.Nombre LIKE '%Sinpe%' THEN 'Sinpe'
                    ELSE NULL
                  END
                , t.flag_genera_comprobante
            FROM @TablaTipoMovimiento t
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.TipoMovimiento x
                WHERE x.Id = t.Id
            );

        COMMIT TRANSACTION;

        SET @outResult = 0;

        RETURN 0;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = 50000;

        THROW;

    END CATCH;
END;
GO
