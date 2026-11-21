/*
===================================================================
Estandar E31: ejemplo ejecutable
===================================================================
DECLARE @outResult INT;
DECLARE @Xml XML = N'
<Operaciones>
  <FechaOperacion Fecha="2026-03-01">
    <Persona ValorDocumentoIdentidad="123" Nombre="Prueba"/>
  </FechaOperacion>
</Operaciones>';
EXEC dbo.sp_CargarOperacionesXML
    @inXml = @Xml,
    @outResult = @outResult OUTPUT;
SELECT @outResult AS Resultado;
===================================================================
*/
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

    
    DECLARE @FechasGeneradas TABLE (
        Fecha DATE PRIMARY KEY
    );


    DECLARE @Numeros TABLE (
        Num INT PRIMARY KEY
    );
    DECLARE @MaxHijos INT;
    DECLARE @Contador INT;

    BEGIN TRY
        
        SET @Hash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONVERT(VARBINARY(MAX), @inXml)), 2);

        
        SELECT @IdCarga = c.IdCarga 
        FROM dbo.CargaOperacionesXML c 
        WHERE c.HashArchivo = @Hash;

        IF @IdCarga IS NOT NULL
        BEGIN
            SET @outResult = 0; -- Código 0: Ya procesado
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

        
        SELECT 
            @MaxHijos = MAX(F.c.value('count(*)', 'INT'))
        FROM @inXml.nodes('/Operaciones/FechaOperacion') AS F(c);

        SET @Contador = 1;
        WHILE @Contador <= ISNULL(@MaxHijos, 0)
        BEGIN
            INSERT INTO @Numeros (Num) VALUES (@Contador);
            SET @Contador = @Contador + 1;
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
        THROW; 
    END CATCH;
END;
GO
