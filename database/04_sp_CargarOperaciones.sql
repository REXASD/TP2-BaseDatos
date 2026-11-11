

CREATE OR ALTER PROCEDURE dbo.sp_CargarOperacionesXML
    @inXml XML,
    @outResult INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

 
    DECLARE @true BIT = 1,
            @false BIT = 0;


    DECLARE @Hash VARCHAR(256);
    DECLARE @IdCarga INT;
    DECLARE @Min DATE;
    DECLARE @Max DATE;
    DECLARE @FechaActual DATE;

    
    DECLARE @FechasGeneradas TABLE (
        Fecha DATE PRIMARY KEY
    );

    BEGIN TRY
        -- Preprocesamiento fuera de la transacción
        SET @Hash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONVERT(VARBINARY(MAX), @inXml)), 2);

        
        SELECT @IdCarga = c.IdCarga 
        FROM dbo.CargaOperacionesXML c 
        WHERE c.HashArchivo = @Hash;

        IF @IdCarga IS NOT NULL
        BEGIN
            SET @outResult = 0; 
            RETURN 0;
        END;

       
        SELECT 
            @Min = MIN(F.c.value('@Fecha', 'DATE'))
            , @Max = MAX(F.c.value('@Fecha', 'DATE'))
        FROM @inXml.nodes('/Operaciones/FechaOperacion') AS F(c);

        IF @Min IS NULL
        BEGIN
            SET @outResult = 50001; -- Código >= 50000: Error de validación de datos
            RETURN 50001;
        END;

        
        SET @FechaActual = @Min;
        WHILE @FechaActual <= @Max
        BEGIN
            INSERT INTO @FechasGeneradas (Fecha) VALUES (@FechaActual);
            SET @FechaActual = DATEADD(DAY, 1, @FechaActual);
        END;

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
                , N.c.value('count(./preceding-sibling::*) + 1', 'INT')
                , N.c.value('local-name(.)', 'VARCHAR(128)')
                , N.c.query('.')
                , @false
            FROM @inXml.nodes('/Operaciones/FechaOperacion') AS F(c)
            CROSS APPLY F.c.nodes('*') AS N(c);

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