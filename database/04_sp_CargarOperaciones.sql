CREATE OR ALTER PROCEDURE dbo.sp_CargarOperacionesXML
    @inXml XML,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- a) Declaración de constantes
    DECLARE @true BIT = 1,
            @false BIT = 0;

    -- b) Declaración de variables generales
    DECLARE @Hash VARCHAR(256);
    DECLARE @IdCarga INT;
    DECLARE @Min DATE;
    DECLARE @Max DATE;
    DECLARE @FechaActual DATE;

    -- c) Tabla variable en RAM para fechas (Sustituye el estatuto WITH/CTE)
    DECLARE @FechasGeneradas TABLE (
        Fecha DATE PRIMARY KEY
    );

    -- Tabla variable con los numeros 1..N para recorrer los nodos hijos por posicion
    -- (SQL Server no soporta el eje preceding-sibling en XQuery)
    DECLARE @Numeros TABLE (
        Num INT PRIMARY KEY
    );
    DECLARE @MaxHijos INT;
    DECLARE @Contador INT;

    BEGIN TRY
        -- d) Preprocesamiento fuera de la transacción
        SET @Hash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONVERT(VARBINARY(MAX), @inXml)), 2);

        -- Validar si el archivo ya fue cargado previamente
        SELECT @IdCarga = c.IdCarga 
        FROM dbo.CargaOperacionesXML c 
        WHERE c.HashArchivo = @Hash;

        IF @IdCarga IS NOT NULL
        BEGIN
            SET @outResult = 0; -- Código 0: Ya procesado
            RETURN 0;
        END;

        -- Extraer rango de fechas del XML
        SELECT 
            @Min = MIN(F.c.value('@Fecha', 'DATE'))
            , @Max = MAX(F.c.value('@Fecha', 'DATE'))
        FROM @inXml.nodes('/Operaciones/FechaOperacion') AS F(c);

        IF @Min IS NULL
        BEGIN
            SET @outResult = 50001; -- Código >= 50000: Error de validación de datos
            RETURN 50001;
        END;

        -- Generar el rango de fechas iterativamente en memoria (sin usar CTE)
        SET @FechaActual = @Min;
        WHILE @FechaActual <= @Max
        BEGIN
            INSERT INTO @FechasGeneradas (Fecha) VALUES (@FechaActual);
            SET @FechaActual = DATEADD(DAY, 1, @FechaActual);
        END;

        -- Cantidad maxima de nodos hijos que tiene cualquier FechaOperacion
        SELECT 
            @MaxHijos = MAX(F.c.value('count(*)', 'INT'))
        FROM @inXml.nodes('/Operaciones/FechaOperacion') AS F(c);

        SET @Contador = 1;
        WHILE @Contador <= ISNULL(@MaxHijos, 0)
        BEGIN
            INSERT INTO @Numeros (Num) VALUES (@Contador);
            SET @Contador = @Contador + 1;
        END;

        -- e) Transacción de BD atómica al final
        BEGIN TRANSACTION;

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

            SET @IdCarga = SCOPE_IDENTITY();

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
                , N.c.value('local-name(.)', 'VARCHAR(128)')
                , N.c.query('.')
                , @false
            FROM @inXml.nodes('/Operaciones/FechaOperacion') AS F(c)
            CROSS JOIN @Numeros AS Nm
            CROSS APPLY F.c.nodes('*[position() = sql:column("Nm.Num")]') AS N(c);

            INSERT INTO dbo.ControlFechaOperacion (
                Fecha
                , flag_procesada
                , Intentos
            )
            SELECT 
                f.Fecha
                , @false
                , 0
            FROM @FechasGeneradas f
            WHERE NOT EXISTS (
                SELECT 1 
                FROM dbo.ControlFechaOperacion c 
                WHERE c.Fecha = f.Fecha
            );

        COMMIT TRANSACTION;

        SET @outResult = 0; -- Código 0: Ejecución exitosa
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;

        SET @outResult = 50000;
        THROW; -- Propaga el error original al cliente/backend sin depender de tablas físicas
    END CATCH;
END;
GO
