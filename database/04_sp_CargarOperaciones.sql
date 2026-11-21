
/*
==================================================================
Estándar E31: Ejemplo ejecutable para pruebas del SP
==================================================================

DECLARE @outResult INT;

DECLARE @inXml XML = '
<Operaciones>
    <FechaOperacion Fecha="2026-11-19">
        <Deposito Monto="15000.00" />
        <Retiro Monto="5000.00" />
    </FechaOperacion>
    <FechaOperacion Fecha="2026-11-20">
        <Sinpe Monto="2500.00" />
    </FechaOperacion>
</Operaciones>';

EXEC dbo.sp_CargarOperacionesXML
    @inXml = @inXml
    , @outResult = @outResult OUTPUT;

SELECT @outResult AS CodigoResultado;

==================================================================
*/

CREATE OR ALTER PROCEDURE dbo.sp_CargarOperacionesXML
    @inXml XML
    , @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        -- a) Declaración de variables generales

        SET @outResult = 0;

        DECLARE @Hash VARCHAR(64);
        DECLARE @IdCarga INT;
        DECLARE @Min DATE;
        DECLARE @Max DATE;
        DECLARE @FechaActual DATE;
        DECLARE @MaxHijos INT;
        DECLARE @Contador INT;

        -- b) Tablas variables para preprocesamiento en RAM

        DECLARE @FechasGeneradas TABLE (
            Fecha DATE PRIMARY KEY
        );

        DECLARE @Numeros TABLE (
            Num INT PRIMARY KEY
        );

        -- c) Validaciones fuera de la transacción

        IF @inXml IS NULL
        BEGIN
            SET @outResult = 50001;
            RETURN 50001;
        END;

        -- d) Generación del hash del XML

        SET @Hash = CONVERT(
            VARCHAR(64)
            , HASHBYTES(
                'SHA2_256'
                , CONVERT(
                    VARBINARY(MAX)
                    , CONVERT(NVARCHAR(MAX), @inXml)
                )
            )
            , 2
        );

        -- e) Validar si el archivo ya fue cargado

        SELECT
            @IdCarga = c.IdCarga
        FROM dbo.CargaOperacionesXML c
        WHERE c.HashArchivo = @Hash;

        IF @IdCarga IS NOT NULL
        BEGIN
            SET @outResult = 0;
            RETURN 0;
        END;

        -- f) Extraer el rango de fechas del XML

        SELECT
            @Min = MIN(F.c.value('@Fecha', 'DATE'))
            , @Max = MAX(F.c.value('@Fecha', 'DATE'))
        FROM @inXml.nodes(
            '/Operaciones/FechaOperacion'
        ) AS F(c);

        IF @Min IS NULL OR @Max IS NULL
        BEGIN
            SET @outResult = 50002;
            RETURN 50002;
        END;

        -- g) Generar las fechas en RAM

        SET @FechaActual = @Min;

        WHILE @FechaActual <= @Max
        BEGIN
            INSERT INTO @FechasGeneradas (
                Fecha
            )
            VALUES (
                @FechaActual
            );

            SET @FechaActual = DATEADD(
                DAY
                , 1
                , @FechaActual
            );
        END;

        -- h) Obtener la cantidad máxima de operaciones
        -- que contiene una FechaOperacion

        SELECT
            @MaxHijos = MAX(
                F.c.value('count(*)', 'INT')
            )
        FROM @inXml.nodes(
            '/Operaciones/FechaOperacion'
        ) AS F(c);

        -- i) Generar los números de posición en RAM

        SET @Contador = 1;

        WHILE @Contador <= ISNULL(@MaxHijos, 0)
        BEGIN
            INSERT INTO @Numeros (
                Num
            )
            VALUES (
                @Contador
            );

            SET @Contador = @Contador + 1;
        END;

        -- j) Transacción de base de datos
        -- Todas las modificaciones físicas se realizan al final.

        BEGIN TRANSACTION;

            -- 1. Registrar la carga del archivo

            INSERT INTO dbo.CargaOperacionesXML (
                NombreArchivo
                , HashArchivo
                , FechaCarga
                , Contenido
            )
            VALUES (
                'Operaciones (pegado manual)'
                , @Hash
                , GETDATE()
                , @inXml
            );

            SET @IdCarga = CONVERT(INT, SCOPE_IDENTITY());

            -- 2. Registrar las operaciones del XML

            INSERT INTO dbo.OperacionXML (
                IdCarga
                , Fecha
                , OrdenEnArchivo
                , NombreNodo
                , Datos
                , flag_procesada
            )
            SELECT
                @IdCarga
                , F.c.value('@Fecha', 'DATE')
                , Nm.Num
                , N.c.value(
                    'local-name(.)'
                    , 'VARCHAR(128)'
                )
                , N.c.query('.')
                , 0
            FROM @inXml.nodes(
                '/Operaciones/FechaOperacion'
            ) AS F(c)
            CROSS JOIN @Numeros AS Nm
            CROSS APPLY F.c.nodes(
                '*[position() = sql:column("Nm.Num")]'
            ) AS N(c);

            -- 3. Registrar las fechas pendientes de procesamiento

            INSERT INTO dbo.ControlFechaOperacion (
                Fecha
                , flag_procesada
                , Intentos
            )
            SELECT
                f.Fecha
                , 0
                , 0
            FROM @FechasGeneradas f
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.ControlFechaOperacion c
                WHERE c.Fecha = f.Fecha
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
