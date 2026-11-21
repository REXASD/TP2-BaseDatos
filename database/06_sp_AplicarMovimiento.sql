/*
E31. Ejecutar el ejemplo en una copia de pruebas con la cuenta indicada.
DECLARE @outResult INT;
DECLARE @IdMovimiento BIGINT;
EXEC dbo.sp_AplicarMovimiento
    @inNumeroCuenta = '11000001',
    @inIdTipoMovimiento = 3,
    @inFecha = '20260630T12:00:00',
    @inMonto = 100.00,
    @inDescripcion = 'Prueba de compra',
    @outResult = @outResult OUTPUT,
    @outIdMovimiento = @IdMovimiento OUTPUT;
SELECT @IdMovimiento AS IdMovimiento;
SELECT @outResult AS Resultado;
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.sp_AplicarMovimiento
    @inNumeroCuenta VARCHAR(32),
    @inIdTipoMovimiento INT,
    @inFecha DATETIME,
    @inMonto DECIMAL(18,2),
    @inDescripcion VARCHAR(256),
    @outResult INT OUTPUT,
    @inIdOperacionXML INT = NULL,
    @outIdMovimiento BIGINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @IdCuenta INT, @NumeroCuenta VARCHAR(32);
        DECLARE @FechaCreacion DATE, @SaldoBase DECIMAL(18,2);
        DECLARE @IdTipoCuenta INT, @IdPersonaDueno INT;
        DECLARE @CantidadMovimientos BIGINT, @UltimoMovimiento BIGINT;
        DECLARE @Dia DATE;
        DECLARE @IdEstadoCuenta INT, @CantidadEstados INT;
        DECLARE @SaldoPrincipal DECIMAL(18,2), @SaldoFinal DECIMAL(18,2);
        DECLARE @MinimoFinal DECIMAL(18,2), @flag_primerMovimiento BIT;
        DECLARE @LimiteSinpe DECIMAL(18,2), @ComisionSinpe DECIMAL(18,2);
        DECLARE @EnviadoHoy DECIMAL(38,2), @Comision DECIMAL(18,2);
        DECLARE @Efecto INT, @NombreTipo VARCHAR(128);
        DECLARE @IdTipoComision INT, @CantidadTiposComision INT;
        DECLARE @Email VARCHAR(128), @NombreDueno VARCHAR(64);
        DECLARE @DatosXML XML, @FechaXML DATE, @NodoXML VARCHAR(128);
        DECLARE @flag_procesada BIT, @flag_xmlConsistente BIT;
        DECLARE @flag_consistente BIT;
        DECLARE @Generados TABLE (
            IdMovimiento BIGINT NOT NULL,
            Orden INT NOT NULL
        );
        DECLARE @Plan TABLE (
            Orden INT PRIMARY KEY,
            IdTipoMovimiento INT NOT NULL,
            Monto DECIMAL(18,2) NOT NULL,
            NuevoSaldo DECIMAL(18,2) NOT NULL,
            Descripcion VARCHAR(256) NOT NULL,
            Detalle VARCHAR(1024) NOT NULL,
            flag_comprobante BIT NULL
        );
        DECLARE @Foto TABLE (
            IdCuenta INT NULL,
            NumeroCuenta VARCHAR(32) NULL,
            FechaCreacion DATE NULL,
            SaldoCuenta DECIMAL(18,2) NULL,
            IdTipoCuenta INT NULL,
            IdPersonaDueno INT NULL,
            CantidadMovimientos BIGINT NULL,
            UltimoMovimiento BIGINT NULL,
            IdEstadoCuenta INT NULL,
            FechaInicio DATE NULL,
            FechaFin DATE NULL,
            SaldoInicial DECIMAL(18,2) NULL,
            SaldoMinimo DECIMAL(18,2) NULL,
            SaldoFinal DECIMAL(18,2) NULL,
            InteresesAcumulados DECIMAL(18,2) NULL,
            CantidadRetiros INT NULL,
            CantidadDepositos INT NULL,
            CantidadSinpeEntrantes INT NULL,
            CantidadSinpeSalientes INT NULL,
            CantidadRetirosATM INT NULL,
            CantidadRetirosHumano INT NULL,
            CantidadDepositosATM INT NULL,
            CantidadDepositosHumano INT NULL,
            Cerrado BIT NULL
        );

        SET @outResult = 50000;
        SET @outIdMovimiento = NULL;
        SET @Dia = CONVERT(DATE, @inFecha);

        IF @inNumeroCuenta IS NULL OR LTRIM(RTRIM(@inNumeroCuenta)) = ''
           OR @inFecha IS NULL OR @inMonto IS NULL OR @inMonto <= 0
           OR @inDescripcion IS NULL OR LTRIM(RTRIM(@inDescripcion)) = ''
            THROW 50001, 'Revise cuenta, fecha, monto positivo y descripcion.', 1;

        WHILE 1 = 1
        BEGIN
            SET @IdCuenta = NULL;
            SET @Efecto = NULL;
            SET @DatosXML = NULL;
            SET @Comision = 0;
            SET @flag_primerMovimiento = 0;
            SET @flag_consistente = 0;
            SET @flag_xmlConsistente = CASE
                WHEN @inIdOperacionXML IS NULL THEN 1 ELSE 0 END;
            SET @outIdMovimiento = NULL;
            DELETE FROM @Plan;
            DELETE FROM @Generados;

            IF @inIdOperacionXML IS NOT NULL
            BEGIN
                SELECT
                    @DatosXML = o.Datos,
                    @FechaXML = o.Fecha,
                    @NodoXML = o.NombreNodo,
                    @flag_procesada = o.flag_procesada
                FROM dbo.OperacionXML AS o WITH (UPDLOCK, HOLDLOCK)
                WHERE o.IdOperacionXML = @inIdOperacionXML;

                IF @DatosXML IS NULL OR @NodoXML <> 'Movimientos' OR @FechaXML <> @Dia
                    THROW 50006,
                        'La operacion XML no existe o no corresponde a este movimiento.',
                        1;
            END;

            SELECT @Efecto = t.Efecto, @NombreTipo = t.Nombre
            FROM dbo.TipoMovimiento AS t
            WHERE t.Id = @inIdTipoMovimiento;

            IF @Efecto IS NULL OR @Efecto NOT IN (-1, 1)
                THROW 50002, 'El tipo de movimiento no existe o su efecto es invalido.', 1;

            IF @inIdOperacionXML IS NOT NULL
            BEGIN
                IF @DatosXML.value('(/Movimientos/@CodigoCuenta)[1]', 'VARCHAR(32)')
                        <> @inNumeroCuenta
                   OR @DatosXML.value('(/Movimientos/@Tipo)[1]', 'VARCHAR(128)')
                        <> @NombreTipo
                   OR @DatosXML.value('(/Movimientos/@Monto)[1]', 'DECIMAL(18,2)')
                        <> @inMonto
                   OR @DatosXML.value('(/Movimientos/@Descripcion)[1]', 'VARCHAR(256)')
                        <> @inDescripcion
                   OR @DatosXML.exist(
                        '/Movimientos[@CodigoCuenta and @Tipo and @Monto and @Descripcion]'
                      ) = 0
                    THROW 50006, 'Los parametros no coinciden con el nodo de movimiento XML.', 1;
            END;
            DELETE FROM @Foto;
            INSERT INTO @Foto (
                IdCuenta,
                NumeroCuenta,
                FechaCreacion,
                SaldoCuenta,
                IdTipoCuenta,
                IdPersonaDueno,
                CantidadMovimientos,
                UltimoMovimiento,
                IdEstadoCuenta,
                FechaInicio,
                FechaFin,
                SaldoInicial,
                SaldoMinimo,
                SaldoFinal,
                InteresesAcumulados,
                CantidadRetiros,
                CantidadDepositos,
                CantidadSinpeEntrantes,
                CantidadSinpeSalientes,
                CantidadRetirosATM,
                CantidadRetirosHumano,
                CantidadDepositosATM,
                CantidadDepositosHumano,
                Cerrado
            )
            SELECT
                c.IdCuenta,
                c.NumeroCuenta,
                c.FechaCreacion,
                c.Saldo,
                c.IdTipoCuenta,
                c.IdPersonaDueno,
                a.CantidadMovimientos,
                a.UltimoMovimiento,
                e.IdEstadoCuenta,
                e.FechaInicio,
                e.FechaFin,
                e.SaldoInicial,
                e.SaldoMinimo,
                e.SaldoFinal,
                e.InteresesAcumulados,
                e.CantidadRetiros,
                e.CantidadDepositos,
                e.CantidadSinpeEntrantes,
                e.CantidadSinpeSalientes,
                e.CantidadRetirosATM,
                e.CantidadRetirosHumano,
                e.CantidadDepositosATM,
                e.CantidadDepositosHumano,
                e.Cerrado
            FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
            LEFT JOIN dbo.EstadoDeCuenta AS e WITH (UPDLOCK, HOLDLOCK)
                ON e.IdCuenta = c.IdCuenta
            CROSS APPLY (
                SELECT
                    COUNT_BIG(1) AS CantidadMovimientos,
                    MAX(m.IdMovimiento) AS UltimoMovimiento
                FROM dbo.Movimiento AS m
                INNER JOIN dbo.EstadoDeCuenta AS em
                    ON em.IdEstadoCuenta = m.IdEstadoCuenta
                WHERE em.IdCuenta = c.IdCuenta
            ) AS a
            WHERE c.NumeroCuenta = @inNumeroCuenta;

            SELECT TOP (1)
                @IdCuenta = f.IdCuenta,
                @NumeroCuenta = f.NumeroCuenta,
                @FechaCreacion = f.FechaCreacion,
                @SaldoBase = f.SaldoCuenta,
                @IdTipoCuenta = f.IdTipoCuenta,
                @IdPersonaDueno = f.IdPersonaDueno,
                @CantidadMovimientos = f.CantidadMovimientos,
                @UltimoMovimiento = f.UltimoMovimiento
            FROM @Foto AS f;

            IF @IdCuenta IS NULL
                THROW 50003, 'La cuenta indicada no existe.', 1;

            SELECT
                @LimiteSinpe = t.MontoMaxSinpeDiario,
                @ComisionSinpe = t.ComisionSinpe,
                @Email = p.Email,
                @NombreDueno = p.Nombre
            FROM dbo.TipoCuentaAhorro AS t
            INNER JOIN dbo.Persona AS p ON p.IdPersona = @IdPersonaDueno
            WHERE t.Id = @IdTipoCuenta;

            IF @inIdOperacionXML IS NOT NULL
            BEGIN
                SELECT @outIdMovimiento = m.IdMovimiento
                FROM dbo.Movimiento AS m
                WHERE m.IdOperacionXML = @inIdOperacionXML
                  AND m.IdMovimientoOrigen IS NULL;

                IF @outIdMovimiento IS NOT NULL
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM dbo.Movimiento AS m
                        INNER JOIN dbo.EstadoDeCuenta AS e
                            ON e.IdEstadoCuenta = m.IdEstadoCuenta
                        WHERE m.IdMovimiento = @outIdMovimiento
                          AND e.IdCuenta = @IdCuenta
                          AND m.IdTipoMovimiento = @inIdTipoMovimiento
                          AND m.Fecha = @inFecha
                          AND m.Monto = @inMonto
                          AND m.Descripcion = @inDescripcion
                    )
                        THROW 50007, 'La operacion XML ya esta asociada a otro movimiento.', 1;
                    SET @outResult = 0;
                    RETURN 0;
                END;
                IF @flag_procesada = 1
                    THROW 50007,
                        'La operacion figura procesada pero no tiene movimiento asociado.',
                        1;
            END;

            SELECT
                @CantidadEstados = COUNT(1),
                @IdEstadoCuenta = MIN(f.IdEstadoCuenta)
            FROM @Foto AS f
            WHERE f.Cerrado = 0;

            IF @CantidadEstados <> 1
                THROW 50004, 'La cuenta debe tener exactamente un estado de cuenta abierto.', 1;
            IF NOT EXISTS (
                SELECT 1 FROM @Foto AS f
                WHERE f.IdEstadoCuenta = @IdEstadoCuenta
                  AND @Dia >= f.FechaInicio AND @Dia <= f.FechaFin
            )
                THROW 50005, 'La fecha no pertenece al periodo abierto de la cuenta.', 1;
            IF EXISTS (
                SELECT 1
                FROM dbo.Movimiento AS m
                INNER JOIN dbo.EstadoDeCuenta AS e
                    ON e.IdEstadoCuenta = m.IdEstadoCuenta
                WHERE e.IdCuenta = @IdCuenta AND m.Fecha > @inFecha
            )
                THROW 50005,
                    'Los movimientos de la cuenta deben aplicarse en orden cronologico.',
                    1;

            IF @NombreTipo = 'Retiro Sinpe'
            BEGIN
                IF @LimiteSinpe < 0 OR @ComisionSinpe < 0
                    THROW 50008, 'El limite diario y la comision SINPE no pueden ser negativos.', 1;
                SELECT @EnviadoHoy = ISNULL(SUM(m.Monto), 0)
                FROM dbo.Movimiento AS m
                INNER JOIN dbo.EstadoDeCuenta AS e
                    ON e.IdEstadoCuenta = m.IdEstadoCuenta
                INNER JOIN dbo.TipoMovimiento AS t ON t.Id = m.IdTipoMovimiento
                WHERE e.IdCuenta = @IdCuenta AND t.Nombre = 'Retiro Sinpe'
                  AND m.Fecha >= @Dia
                  AND m.Fecha < DATEADD(DAY, 1, CONVERT(DATETIME, @Dia));

                IF @EnviadoHoy + @inMonto > @LimiteSinpe
                    SET @Comision = @ComisionSinpe;
                IF @Comision > 0
                BEGIN
                    SELECT
                        @CantidadTiposComision = COUNT(1),
                        @IdTipoComision = MIN(t.Id)
                    FROM dbo.TipoMovimiento AS t
                    WHERE t.Nombre = 'Comision Sinpe' AND t.Efecto = -1;
                    IF @CantidadTiposComision <> 1
                        THROW 50008, 'Debe existir un unico tipo Comision Sinpe con efecto -1.', 1;
                END;
            END;

            IF NOT EXISTS (
                SELECT 1 FROM dbo.Movimiento AS m
                WHERE m.IdEstadoCuenta = @IdEstadoCuenta
            ) AND EXISTS (
                SELECT 1 FROM @Foto AS f
                WHERE f.IdEstadoCuenta = @IdEstadoCuenta
                  AND f.FechaInicio = @FechaCreacion
            )
                SET @flag_primerMovimiento = 1;

            SET @SaldoPrincipal = @SaldoBase + (@inMonto * @Efecto);
            SET @SaldoFinal = @SaldoPrincipal;
            IF @Comision > 0
                SET @SaldoFinal = @SaldoPrincipal - @Comision;

            SELECT @MinimoFinal = CASE
                WHEN @flag_primerMovimiento = 1 OR @SaldoFinal < f.SaldoMinimo
                    THEN @SaldoFinal
                ELSE f.SaldoMinimo
            END
            FROM @Foto AS f WHERE f.IdEstadoCuenta = @IdEstadoCuenta;

            INSERT INTO @Plan (
                Orden, IdTipoMovimiento, Monto, NuevoSaldo,
                Descripcion, Detalle, flag_comprobante
            )
            SELECT
                1, t.Id, @inMonto, @SaldoPrincipal, @inDescripcion,
                (SELECT
                    @inNumeroCuenta AS NumeroCuenta,
                    @NombreDueno AS Dueno,
                    @Email AS Email,
                    @inFecha AS Fecha,
                    t.Nombre AS TipoMovimiento,
                    @inMonto AS Monto,
                    @SaldoPrincipal AS NuevoSaldo,
                    @inDescripcion AS Descripcion
                 FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER),
                t.flag_requiere_comprobante
            FROM dbo.TipoMovimiento AS t
            WHERE t.Id = @inIdTipoMovimiento;

            INSERT INTO @Plan (
                Orden, IdTipoMovimiento, Monto, NuevoSaldo,
                Descripcion, Detalle, flag_comprobante
            )
            SELECT
                2, t.Id, @Comision, @SaldoFinal,
                'Comision por exceder el limite diario SINPE',
                (SELECT
                    @inNumeroCuenta AS NumeroCuenta,
                    @NombreDueno AS Dueno,
                    @Email AS Email,
                    @inFecha AS Fecha,
                    t.Nombre AS TipoMovimiento,
                    @Comision AS Monto,
                    @SaldoFinal AS NuevoSaldo,
                    'Comision por exceder el limite diario SINPE' AS Descripcion
                 FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER),
                t.flag_requiere_comprobante
            FROM dbo.TipoMovimiento AS t
            WHERE t.Id = @IdTipoComision AND @Comision > 0;

            BEGIN TRANSACTION;

            SELECT @flag_xmlConsistente = CASE
                WHEN NOT EXISTS (
                    SELECT o.Fecha, o.NombreNodo, o.flag_procesada,
                        CONVERT(NVARCHAR(MAX), o.Datos)
                    EXCEPT
                    SELECT @FechaXML, @NodoXML, @flag_procesada,
                        CONVERT(NVARCHAR(MAX), @DatosXML)
                ) THEN 1 ELSE 0 END
            FROM dbo.OperacionXML AS o WITH (UPDLOCK, HOLDLOCK)
            WHERE o.IdOperacionXML = @inIdOperacionXML;

            SELECT @flag_consistente = CASE
                WHEN c.Saldo = @SaldoBase
                AND c.NumeroCuenta = @NumeroCuenta
                AND c.FechaCreacion = @FechaCreacion
                AND c.IdTipoCuenta = @IdTipoCuenta
                AND c.IdPersonaDueno = @IdPersonaDueno
                AND NOT EXISTS (
                    SELECT
                        e.IdEstadoCuenta,
                        e.FechaInicio,
                        e.FechaFin,
                        e.SaldoInicial,
                        e.SaldoMinimo,
                        e.SaldoFinal,
                        e.InteresesAcumulados,
                        e.CantidadRetiros,
                        e.CantidadDepositos,
                        e.CantidadSinpeEntrantes,
                        e.CantidadSinpeSalientes,
                        e.CantidadRetirosATM,
                        e.CantidadRetirosHumano,
                        e.CantidadDepositosATM,
                        e.CantidadDepositosHumano,
                        e.Cerrado
                    FROM dbo.EstadoDeCuenta AS e WITH (UPDLOCK, HOLDLOCK)
                    WHERE e.IdCuenta = @IdCuenta
                    EXCEPT
                    SELECT
                        f.IdEstadoCuenta,
                        f.FechaInicio,
                        f.FechaFin,
                        f.SaldoInicial,
                        f.SaldoMinimo,
                        f.SaldoFinal,
                        f.InteresesAcumulados,
                        f.CantidadRetiros,
                        f.CantidadDepositos,
                        f.CantidadSinpeEntrantes,
                        f.CantidadSinpeSalientes,
                        f.CantidadRetirosATM,
                        f.CantidadRetirosHumano,
                        f.CantidadDepositosATM,
                        f.CantidadDepositosHumano,
                        f.Cerrado
                    FROM @Foto AS f
                    WHERE f.IdEstadoCuenta IS NOT NULL
                )
                AND NOT EXISTS (
                    SELECT
                        f.IdEstadoCuenta,
                        f.FechaInicio,
                        f.FechaFin,
                        f.SaldoInicial,
                        f.SaldoMinimo,
                        f.SaldoFinal,
                        f.InteresesAcumulados,
                        f.CantidadRetiros,
                        f.CantidadDepositos,
                        f.CantidadSinpeEntrantes,
                        f.CantidadSinpeSalientes,
                        f.CantidadRetirosATM,
                        f.CantidadRetirosHumano,
                        f.CantidadDepositosATM,
                        f.CantidadDepositosHumano,
                        f.Cerrado
                    FROM @Foto AS f
                    WHERE f.IdEstadoCuenta IS NOT NULL
                    EXCEPT
                    SELECT
                        e.IdEstadoCuenta,
                        e.FechaInicio,
                        e.FechaFin,
                        e.SaldoInicial,
                        e.SaldoMinimo,
                        e.SaldoFinal,
                        e.InteresesAcumulados,
                        e.CantidadRetiros,
                        e.CantidadDepositos,
                        e.CantidadSinpeEntrantes,
                        e.CantidadSinpeSalientes,
                        e.CantidadRetirosATM,
                        e.CantidadRetirosHumano,
                        e.CantidadDepositosATM,
                        e.CantidadDepositosHumano,
                        e.Cerrado
                    FROM dbo.EstadoDeCuenta AS e WITH (UPDLOCK, HOLDLOCK)
                    WHERE e.IdCuenta = @IdCuenta
                )
                AND @CantidadMovimientos = (
                    SELECT COUNT_BIG(1)
                    FROM dbo.Movimiento AS m WITH (UPDLOCK, HOLDLOCK)
                    INNER JOIN dbo.EstadoDeCuenta AS em
                        ON em.IdEstadoCuenta = m.IdEstadoCuenta
                    WHERE em.IdCuenta = @IdCuenta
                )
                AND ISNULL(@UltimoMovimiento, 0) = ISNULL((
                    SELECT MAX(m.IdMovimiento)
                    FROM dbo.Movimiento AS m WITH (UPDLOCK, HOLDLOCK)
                    INNER JOIN dbo.EstadoDeCuenta AS em
                        ON em.IdEstadoCuenta = m.IdEstadoCuenta
                    WHERE em.IdCuenta = @IdCuenta
                ), 0)
                AND @flag_xmlConsistente = 1
                    THEN 1
                ELSE 0
            END
            FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
            WHERE c.IdCuenta = @IdCuenta;

            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto,
                NuevoSaldo, Descripcion, IdOperacionXML, IdMovimientoOrigen
            )
            OUTPUT inserted.IdMovimiento, 1
                INTO @Generados (IdMovimiento, Orden)
            SELECT
                @IdEstadoCuenta, p.IdTipoMovimiento, @inFecha, p.Monto,
                p.NuevoSaldo, p.Descripcion, @inIdOperacionXML, NULL
            FROM @Plan AS p
            WHERE p.Orden = 1 AND @flag_consistente = 1;

            SELECT @outIdMovimiento = g.IdMovimiento
            FROM @Generados AS g WHERE g.Orden = 1;

            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto,
                NuevoSaldo, Descripcion, IdOperacionXML, IdMovimientoOrigen
            )
            OUTPUT inserted.IdMovimiento, 2
                INTO @Generados (IdMovimiento, Orden)
            SELECT
                @IdEstadoCuenta, p.IdTipoMovimiento, @inFecha, p.Monto,
                p.NuevoSaldo, p.Descripcion, @inIdOperacionXML, @outIdMovimiento
            FROM @Plan AS p
            WHERE p.Orden = 2 AND @flag_consistente = 1;

            INSERT INTO dbo.Comprobante (IdMovimiento, FechaEmision, Detalle)
            SELECT g.IdMovimiento, @inFecha, p.Detalle
            FROM @Generados AS g
            INNER JOIN @Plan AS p ON p.Orden = g.Orden
            WHERE p.flag_comprobante = 1 AND @flag_consistente = 1
            ORDER BY g.Orden;

            UPDATE dbo.OperacionXML
            SET flag_procesada = 1
            WHERE IdOperacionXML = @inIdOperacionXML AND @flag_consistente = 1;

            UPDATE e
            SET
                SaldoFinal = @SaldoFinal,
                SaldoMinimo = @MinimoFinal,
                CantidadRetiros = f.CantidadRetiros
                    + CASE WHEN @NombreTipo IN ('Retiro ATM', 'Retiro Ventana') THEN 1 ELSE 0 END,
                CantidadDepositos = f.CantidadDepositos
                    + CASE
                        WHEN @NombreTipo IN ('Deposito ATM', 'Deposito Ventana') THEN 1
                        ELSE 0
                      END,
                CantidadRetirosATM = f.CantidadRetirosATM
                    + CASE WHEN @NombreTipo = 'Retiro ATM' THEN 1 ELSE 0 END,
                CantidadRetirosHumano = f.CantidadRetirosHumano
                    + CASE WHEN @NombreTipo = 'Retiro Ventana' THEN 1 ELSE 0 END,
                CantidadDepositosATM = f.CantidadDepositosATM
                    + CASE WHEN @NombreTipo = 'Deposito ATM' THEN 1 ELSE 0 END,
                CantidadDepositosHumano = f.CantidadDepositosHumano
                    + CASE WHEN @NombreTipo = 'Deposito Ventana' THEN 1 ELSE 0 END,
                CantidadSinpeEntrantes = f.CantidadSinpeEntrantes
                    + CASE WHEN @NombreTipo = 'Deposito Sinpe' THEN 1 ELSE 0 END,
                CantidadSinpeSalientes = f.CantidadSinpeSalientes
                    + CASE WHEN @NombreTipo = 'Retiro Sinpe' THEN 1 ELSE 0 END
            FROM dbo.EstadoDeCuenta AS e
            INNER JOIN @Foto AS f ON f.IdEstadoCuenta = e.IdEstadoCuenta
            WHERE e.IdEstadoCuenta = @IdEstadoCuenta AND @flag_consistente = 1;

            UPDATE dbo.Cuenta
            SET Saldo = @SaldoFinal
            WHERE IdCuenta = @IdCuenta AND @flag_consistente = 1;

            COMMIT TRANSACTION;

            IF @flag_consistente = 1
            BEGIN
                SET @outResult = 0;
                RETURN 0;
            END;
        END;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResult = ERROR_NUMBER();
        SET @outIdMovimiento = NULL;
        THROW;
    END CATCH;
END;
GO
