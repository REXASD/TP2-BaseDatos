/*
E31. Ejecutar el ejemplo en una copia de pruebas con la cuenta indicada.
DECLARE @outResult INT;
DECLARE @IdEstado INT;
EXEC dbo.sp_AbrirEstadoCuenta
    @inNumeroCuenta = '11000001',
    @inFechaInicio = '20260301',
    @outResult = @outResult OUTPUT,
    @outIdEstadoCuenta = @IdEstado OUTPUT;
SELECT @IdEstado AS IdEstadoCuenta;
SELECT @outResult AS Resultado;
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.sp_AbrirEstadoCuenta
    @inNumeroCuenta VARCHAR(32),
    @inFechaInicio DATE,
    @outResult INT OUTPUT,
    @outIdEstadoCuenta INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TransaccionInicial INT = @@TRANCOUNT;
        DECLARE @flag_puntoGuardado BIT = 0;
        DECLARE @IdCuenta INT, @NumeroCuenta VARCHAR(32);
        DECLARE @FechaCreacion DATE, @SaldoBase DECIMAL(18,2);
        DECLARE @IdTipoCuenta INT, @IdPersonaDueno INT;
        DECLARE @CantidadMovimientos BIGINT, @UltimoMovimiento BIGINT;
        DECLARE @DiaCorte INT, @Mes DATE, @FechaFin DATE;
        DECLARE @Cantidad INT, @FinAnterior DATE, @CerradoAnterior BIT;
        DECLARE @SaldoAnterior DECIMAL(18,2);
        DECLARE @Insertado TABLE (IdEstadoCuenta INT NOT NULL);
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
        SET @outIdEstadoCuenta = NULL;

        IF @inFechaInicio IS NULL
            THROW 50201, 'La apertura requiere una fecha inicial.', 1;

        IF @TransaccionInicial > 0
        BEGIN
            SAVE TRANSACTION AbrirEstadoCuenta;
            SET @flag_puntoGuardado = 1;
        END;

        WHILE 1 = 1
        BEGIN
            SET @IdCuenta = NULL;
            SET @FinAnterior = NULL;
            SET @outIdEstadoCuenta = NULL;
            DELETE FROM @Insertado;
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
                THROW 50202, 'La cuenta indicada no existe.', 1;
            IF @inFechaInicio < @FechaCreacion
                THROW 50203, 'Un estado no puede iniciar antes de crear la cuenta.', 1;

            SET @DiaCorte = DAY(@FechaCreacion);
            SET @Mes = DATEFROMPARTS(YEAR(@inFechaInicio), MONTH(@inFechaInicio), 1);
            SET @FechaFin = DATEADD(DAY,
                CASE WHEN @DiaCorte > DAY(EOMONTH(@Mes))
                    THEN DAY(EOMONTH(@Mes)) ELSE @DiaCorte END - 1,
                @Mes);

            IF @inFechaInicio = @FechaCreacion OR @FechaFin < @inFechaInicio
            BEGIN
                SET @Mes = DATEADD(MONTH, 1, @Mes);
                SET @FechaFin = DATEADD(DAY,
                    CASE WHEN @DiaCorte > DAY(EOMONTH(@Mes))
                        THEN DAY(EOMONTH(@Mes)) ELSE @DiaCorte END - 1,
                    @Mes);
            END;

            SELECT
                @Cantidad = COUNT(1),
                @outIdEstadoCuenta = MIN(f.IdEstadoCuenta)
            FROM @Foto AS f
            WHERE f.FechaInicio = @inFechaInicio;

            IF @Cantidad > 1
                THROW 50204, 'Hay periodos duplicados para la fecha inicial indicada.', 1;
            IF @Cantidad = 1
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM @Foto AS f
                    WHERE f.IdEstadoCuenta = @outIdEstadoCuenta
                      AND f.FechaFin = @FechaFin
                )
                    THROW 50204, 'El periodo existente tiene una fecha final inconsistente.', 1;
                SET @outResult = 0;
                RETURN 0;
            END;

            IF EXISTS (SELECT 1 FROM @Foto AS f WHERE f.Cerrado = 0)
                THROW 50205, 'Cierre el estado abierto antes de abrir otro periodo.', 1;

            SELECT TOP (1)
                @FinAnterior = f.FechaFin,
                @CerradoAnterior = f.Cerrado,
                @SaldoAnterior = f.SaldoFinal
            FROM @Foto AS f
            WHERE f.IdEstadoCuenta IS NOT NULL
            ORDER BY f.FechaFin DESC, f.IdEstadoCuenta DESC;

            IF @FinAnterior IS NULL AND @inFechaInicio <> @FechaCreacion
                THROW 50206, 'El primer estado debe iniciar en la fecha de creacion de la cuenta.', 1;
            IF @FinAnterior IS NOT NULL
            BEGIN
                IF @CerradoAnterior <> 1
                   OR @inFechaInicio <> DATEADD(DAY, 1, @FinAnterior)
                    THROW 50206, 'El nuevo periodo debe seguir al ultimo estado cerrado, sin saltar fechas.', 1;
                IF @SaldoAnterior <> @SaldoBase
                    THROW 50207, 'El saldo de la cuenta no coincide con el cierre anterior.', 1;
            END;

            INSERT INTO dbo.EstadoDeCuenta (
                IdCuenta, FechaInicio, FechaFin,
                SaldoInicial, SaldoMinimo, SaldoFinal,
                InteresesAcumulados, CantidadRetiros, CantidadDepositos,
                CantidadSinpeEntrantes, CantidadSinpeSalientes,
                CantidadRetirosATM, CantidadRetirosHumano,
                CantidadDepositosATM, CantidadDepositosHumano, Cerrado
            )
            OUTPUT inserted.IdEstadoCuenta INTO @Insertado (IdEstadoCuenta)
            SELECT
                @IdCuenta, @inFechaInicio, @FechaFin,
                @SaldoBase, @SaldoBase, @SaldoBase,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
            WHERE c.IdCuenta = @IdCuenta
              AND c.Saldo = @SaldoBase
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
                ), 0);

            SELECT @outIdEstadoCuenta = i.IdEstadoCuenta FROM @Insertado AS i;
            IF @outIdEstadoCuenta IS NOT NULL
            BEGIN
                SET @outResult = 0;
                RETURN 0;
            END;
        END;
    END TRY
    BEGIN CATCH
        SET @outResult = ERROR_NUMBER();
        SET @outIdEstadoCuenta = NULL;
        IF @@TRANCOUNT > 0
           AND @flag_puntoGuardado = 1
           AND XACT_STATE() = 1
            ROLLBACK TRANSACTION AbrirEstadoCuenta;
        THROW;
    END CATCH;
END;
GO
