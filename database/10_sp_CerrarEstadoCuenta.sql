/*
E31. Ejecutar el ejemplo en una copia de pruebas con la cuenta indicada.
DECLARE @outResult INT;
DECLARE @IdActual INT, @IdSiguiente INT;
SELECT @IdActual = e.IdEstadoCuenta
FROM dbo.EstadoDeCuenta AS e
INNER JOIN dbo.Cuenta AS c ON c.IdCuenta = e.IdCuenta
WHERE c.NumeroCuenta = '11000001' AND e.FechaFin = '20260501';
EXEC dbo.sp_CerrarEstadoCuenta
    @inIdEstadoCuenta = @IdActual,
    @inFechaCierre = '20260501',
    @outResult = @outResult OUTPUT,
    @outIdNuevoEstadoCuenta = @IdSiguiente OUTPUT;
SELECT @IdSiguiente AS IdNuevoEstadoCuenta;
SELECT @outResult AS Resultado;
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.sp_CerrarEstadoCuenta
    @inIdEstadoCuenta INT,
    @inFechaCierre DATE,
    @outResult INT OUTPUT,
    @outIdNuevoEstadoCuenta INT = NULL OUTPUT
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
        DECLARE @FechaInicio DATE, @FechaFin DATE, @InicioSiguiente DATE;
        DECLARE @flag_cerrado BIT, @flag_consistente BIT;
        DECLARE @MinimoPeriodo DECIMAL(18,2), @MinimoPermitido DECIMAL(18,2);
        DECLARE @SaldoEstado DECIMAL(18,2), @TasaAnual DECIMAL(5,2);
        DECLARE @Intereses DECIMAL(18,2), @Multa DECIMAL(18,2);
        DECLARE @CargoMensual DECIMAL(18,2), @MultaConfigurada DECIMAL(18,2);
        DECLARE @MaxATM INT, @MaxHumano INT;
        DECLARE @OperacionesATM INT, @OperacionesHumano INT;
        DECLARE @TarifaATM DECIMAL(18,2), @TarifaHumano DECIMAL(18,2);
        DECLARE @ComisionATM DECIMAL(18,2), @ComisionHumano DECIMAL(18,2);
        DECLARE @Cantidad INT, @Orden INT, @Tipo INT, @Efecto INT;
        DECLARE @NombreTipo VARCHAR(128), @Descripcion VARCHAR(256);
        DECLARE @Monto DECIMAL(18,2), @FechaAsiento DATETIME;
        DECLARE @SaldoCalculado DECIMAL(18,2), @MinimoCalculado DECIMAL(18,2);
        DECLARE @flag_primerMovimiento BIT;
        DECLARE @flag_hayAsientos BIT, @flag_insertarPeriodo BIT;
        DECLARE @Email VARCHAR(128), @NombreDueno VARCHAR(64);
        DECLARE @DiaCorte INT, @Mes DATE, @FinSiguiente DATE;
        DECLARE @FinAnterior DATE, @CerradoAnterior BIT;
        DECLARE @SaldoAnterior DECIMAL(18,2);
        DECLARE @Asientos TABLE (
            Orden INT PRIMARY KEY,
            NombreTipo VARCHAR(128) NOT NULL,
            Monto DECIMAL(18,2) NULL,
            Descripcion VARCHAR(256) NOT NULL,
            IdTipoMovimiento INT NULL,
            NuevoSaldo DECIMAL(18,2) NULL,
            Detalle VARCHAR(MAX) NULL,
            flag_comprobante BIT NULL
        );
        DECLARE @Generados TABLE (IdMovimiento BIGINT NOT NULL, Orden INT NOT NULL);
        DECLARE @NuevoPeriodo TABLE (IdEstadoCuenta INT NOT NULL);
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
        SET @outIdNuevoEstadoCuenta = NULL;

        IF @inIdEstadoCuenta IS NULL OR @inFechaCierre IS NULL
            THROW 50301, 'Indique el estado y su fecha de cierre.', 1;

        IF @TransaccionInicial > 0
        BEGIN
            SAVE TRANSACTION CerrarEstadoCuenta;
            SET @flag_puntoGuardado = 1;
        END;

        WHILE 1 = 1
        BEGIN
            SET @IdCuenta = NULL;
            SET @flag_consistente = 0;
            SET @flag_primerMovimiento = 0;
            SET @flag_hayAsientos = 0;
            SET @flag_insertarPeriodo = 0;
            SET @Intereses = 0;
            SET @Multa = 0;
            SET @ComisionATM = 0;
            SET @ComisionHumano = 0;
            SET @Orden = 1;
            SET @outIdNuevoEstadoCuenta = NULL;
            DELETE FROM @Asientos;
            DELETE FROM @Generados;
            DELETE FROM @NuevoPeriodo;

            SELECT @IdCuenta = e.IdCuenta
            FROM dbo.EstadoDeCuenta AS e
            WHERE e.IdEstadoCuenta = @inIdEstadoCuenta;
            IF @IdCuenta IS NULL
                THROW 50302, 'El estado de cuenta indicado no existe.', 1;
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
            WHERE c.IdCuenta = @IdCuenta;

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

            SELECT
                @MinimoPermitido = t.SaldoMinimo,
                @TasaAnual = t.TasaInteresAnual,
                @MaxATM = t.NumRetirosAutomatico,
                @MaxHumano = t.NumRetirosHumano,
                @TarifaATM = t.ComisionAutomatico,
                @TarifaHumano = t.ComisionHumano,
                @MultaConfigurada = t.MultaSaldoMin,
                @CargoMensual = t.CargoMensual
            FROM dbo.TipoCuentaAhorro AS t WHERE t.Id = @IdTipoCuenta;

            SELECT
                @FechaInicio = f.FechaInicio,
                @FechaFin = f.FechaFin,
                @flag_cerrado = f.Cerrado,
                @MinimoPeriodo = f.SaldoMinimo,
                @SaldoEstado = f.SaldoFinal,
                @OperacionesATM = f.CantidadRetirosATM + f.CantidadDepositosATM,
                @OperacionesHumano = f.CantidadRetirosHumano + f.CantidadDepositosHumano
            FROM @Foto AS f WHERE f.IdEstadoCuenta = @inIdEstadoCuenta;

            IF @inFechaCierre <> @FechaFin
                THROW 50303, 'El cierre debe realizarse en la fecha final del periodo.', 1;
            SET @InicioSiguiente = DATEADD(DAY, 1, @FechaFin);

            IF @flag_cerrado = 1
            BEGIN
                SELECT
                    @Cantidad = COUNT(1),
                    @outIdNuevoEstadoCuenta = MIN(f.IdEstadoCuenta)
                FROM @Foto AS f WHERE f.FechaInicio = @InicioSiguiente;
                IF @Cantidad <> 1
                    THROW 50304, 'El estado cerrado no tiene un unico periodo sucesor.', 1;
                SET @outResult = 0;
                RETURN 0;
            END;

            IF (SELECT COUNT(1) FROM @Foto AS f WHERE f.Cerrado = 0) <> 1
                THROW 50304, 'La cuenta debe tener exactamente un periodo abierto.', 1;
            IF @SaldoEstado <> @SaldoBase
                THROW 50305, 'El saldo de la cuenta no coincide con el del estado abierto.', 1;
            IF @TasaAnual < 0 OR @MaxATM < 0 OR @MaxHumano < 0
               OR @TarifaATM < 0 OR @TarifaHumano < 0
               OR @MultaConfigurada < 0 OR @CargoMensual < 0
               OR @MinimoPermitido < 0
                THROW 50306, 'El tipo de cuenta contiene una tasa, limite o cargo negativo.', 1;

            IF EXISTS (
                SELECT 1 FROM dbo.OperacionXML AS o
                WHERE o.NombreNodo = 'Movimientos' AND o.flag_procesada = 0
                  AND o.Fecha BETWEEN @FechaInicio AND @FechaFin
                  AND o.Datos.value('(/Movimientos/@CodigoCuenta)[1]', 'VARCHAR(32)') = @NumeroCuenta
            )
                THROW 50307, 'Quedan movimientos XML pendientes de esta cuenta dentro del periodo.', 1;

            IF @MinimoPeriodo > 0
                SET @Intereses = ROUND(@MinimoPeriodo * @TasaAnual / 1200.0, 2);
            IF @OperacionesATM > @MaxATM
                SET @ComisionATM = (@OperacionesATM - @MaxATM) * @TarifaATM;
            IF @OperacionesHumano > @MaxHumano
                SET @ComisionHumano = (@OperacionesHumano - @MaxHumano) * @TarifaHumano;
            IF @MinimoPeriodo < @MinimoPermitido
                SET @Multa = @MultaConfigurada;

            INSERT INTO @Asientos (Orden, NombreTipo, Monto, Descripcion)
            VALUES
                (1, 'Intereses Mensuales', @Intereses,
                    'Abono de intereses mensuales sobre el saldo minimo'),
                (2, 'Comision Exceso ATM', @ComisionATM,
                    'Comision mensual por exceso de operaciones ATM'),
                (3, 'Comision Exceso Ventana', @ComisionHumano,
                    'Comision mensual por exceso de operaciones en ventanilla'),
                (4, 'Multa Saldo Minimo', @Multa,
                    'Multa mensual por saldo inferior al minimo permitido'),
                (5, 'Cargo Servicio Mensual', @CargoMensual,
                    'Cargo mensual por servicio de la cuenta');

            SET @FechaAsiento = DATEADD(MILLISECOND, -3,
                DATEADD(DAY, 1, CONVERT(DATETIME, @FechaFin)));
            SET @SaldoCalculado = @SaldoBase;
            SET @MinimoCalculado = @MinimoPeriodo;

            IF NOT EXISTS (
                SELECT 1 FROM dbo.Movimiento AS m
                WHERE m.IdEstadoCuenta = @inIdEstadoCuenta
            ) AND @FechaInicio = @FechaCreacion
                SET @flag_primerMovimiento = 1;

            WHILE @Orden <= 5
            BEGIN
                SELECT
                    @NombreTipo = a.NombreTipo,
                    @Monto = a.Monto,
                    @Descripcion = a.Descripcion
                FROM @Asientos AS a WHERE a.Orden = @Orden;

                IF @Monto > 0
                BEGIN
                    SELECT
                        @Cantidad = COUNT(1),
                        @Tipo = MIN(t.Id),
                        @Efecto = MIN(t.Efecto)
                    FROM dbo.TipoMovimiento AS t WHERE t.Nombre = @NombreTipo;
                    IF @Cantidad <> 1
                       OR @Efecto <> CASE WHEN @Orden = 1 THEN 1 ELSE -1 END
                        THROW 50308, 'Falta un tipo de movimiento de cierre o tiene un efecto incorrecto.', 1;

                    IF @Efecto IS NULL OR @Efecto NOT IN (-1, 1)
                        THROW 50002, 'El tipo de movimiento no existe o su efecto es invalido.', 1;

                    IF @flag_hayAsientos = 0
                    BEGIN
                        IF NOT EXISTS (
                            SELECT 1 FROM @Foto AS f
                            WHERE f.IdEstadoCuenta = @inIdEstadoCuenta
                              AND f.Cerrado = 0
                              AND CONVERT(DATE, @FechaAsiento) >= f.FechaInicio
                              AND CONVERT(DATE, @FechaAsiento) <= f.FechaFin
                        )
                            THROW 50005, 'La fecha no pertenece al periodo abierto de la cuenta.', 1;
                        IF EXISTS (
                            SELECT 1
                            FROM dbo.Movimiento AS m
                            INNER JOIN dbo.EstadoDeCuenta AS e
                                ON e.IdEstadoCuenta = m.IdEstadoCuenta
                            WHERE e.IdCuenta = @IdCuenta AND m.Fecha > @FechaAsiento
                        )
                            THROW 50005, 'Los movimientos de la cuenta deben aplicarse en orden cronologico.', 1;
                    END;

                    SELECT
                        @Email = CONVERT(VARCHAR(100), p.Email),
                        @NombreDueno = p.Nombre
                    FROM dbo.Persona AS p WHERE p.IdPersona = @IdPersonaDueno;

                    SET @SaldoCalculado = @SaldoCalculado + (@Monto * @Efecto);
                    SET @MinimoCalculado = CASE
                        WHEN @flag_primerMovimiento = 1
                             OR @SaldoCalculado < @MinimoCalculado
                            THEN @SaldoCalculado ELSE @MinimoCalculado END;
                    SET @flag_primerMovimiento = 0;
                    SET @flag_hayAsientos = 1;

                    UPDATE a
                    SET
                        IdTipoMovimiento = @Tipo,
                        NuevoSaldo = @SaldoCalculado,
                        flag_comprobante = t.flag_requiere_comprobante,
                        Detalle = (
                            SELECT
                                @NumeroCuenta AS NumeroCuenta,
                                @NombreDueno AS Dueno,
                                @Email AS Email,
                                @FechaAsiento AS Fecha,
                                t.Nombre AS TipoMovimiento,
                                @Monto AS Monto,
                                @SaldoCalculado AS NuevoSaldo,
                                @Descripcion AS Descripcion
                            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
                        )
                    FROM @Asientos AS a
                    INNER JOIN dbo.TipoMovimiento AS t ON t.Id = @Tipo
                    WHERE a.Orden = @Orden;
                END;
                SET @Orden = @Orden + 1;
            END;

            SET @DiaCorte = DAY(@FechaCreacion);
            SET @Mes = DATEFROMPARTS(YEAR(@InicioSiguiente), MONTH(@InicioSiguiente), 1);
            SET @FinSiguiente = DATEADD(DAY,
                CASE WHEN @DiaCorte > DAY(EOMONTH(@Mes))
                    THEN DAY(EOMONTH(@Mes)) ELSE @DiaCorte END - 1,
                @Mes);
            IF @InicioSiguiente = @FechaCreacion OR @FinSiguiente < @InicioSiguiente
            BEGIN
                SET @Mes = DATEADD(MONTH, 1, @Mes);
                SET @FinSiguiente = DATEADD(DAY,
                    CASE WHEN @DiaCorte > DAY(EOMONTH(@Mes))
                        THEN DAY(EOMONTH(@Mes)) ELSE @DiaCorte END - 1,
                    @Mes);
            END;

            SELECT
                @Cantidad = COUNT(1),
                @outIdNuevoEstadoCuenta = MIN(f.IdEstadoCuenta)
            FROM @Foto AS f WHERE f.FechaInicio = @InicioSiguiente;
            IF @Cantidad > 1
                THROW 50204, 'Hay periodos duplicados para la fecha inicial indicada.', 1;

            IF @Cantidad = 1
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM @Foto AS f
                    WHERE f.IdEstadoCuenta = @outIdNuevoEstadoCuenta
                      AND f.FechaFin = @FinSiguiente
                )
                    THROW 50204, 'El periodo existente tiene una fecha final inconsistente.', 1;
            END;
            ELSE
            BEGIN
                IF @InicioSiguiente < @FechaCreacion
                    THROW 50203, 'Un estado no puede iniciar antes de crear la cuenta.', 1;
                SELECT TOP (1)
                    @FinAnterior = f.FechaFin,
                    @CerradoAnterior = CASE
                        WHEN f.IdEstadoCuenta = @inIdEstadoCuenta THEN 1 ELSE f.Cerrado END,
                    @SaldoAnterior = CASE
                        WHEN f.IdEstadoCuenta = @inIdEstadoCuenta
                            THEN @SaldoCalculado ELSE f.SaldoFinal END
                FROM @Foto AS f
                WHERE f.IdEstadoCuenta IS NOT NULL
                ORDER BY f.FechaFin DESC, f.IdEstadoCuenta DESC;

                IF @CerradoAnterior <> 1
                   OR @InicioSiguiente <> DATEADD(DAY, 1, @FinAnterior)
                    THROW 50206, 'El nuevo periodo debe seguir al ultimo estado cerrado, sin saltar fechas.', 1;
                IF @SaldoAnterior <> @SaldoCalculado
                    THROW 50207, 'El saldo de la cuenta no coincide con el cierre anterior.', 1;
                SET @flag_insertarPeriodo = 1;
            END;

            IF @TransaccionInicial = 0
                BEGIN TRANSACTION;

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
                @inIdEstadoCuenta, a.IdTipoMovimiento, @FechaAsiento, a.Monto,
                a.NuevoSaldo, a.Descripcion, NULL, NULL
            FROM @Asientos AS a
            WHERE a.Orden = 1 AND a.Monto > 0 AND @flag_consistente = 1;

            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto,
                NuevoSaldo, Descripcion, IdOperacionXML, IdMovimientoOrigen
            )
            OUTPUT inserted.IdMovimiento, 2
                INTO @Generados (IdMovimiento, Orden)
            SELECT
                @inIdEstadoCuenta, a.IdTipoMovimiento, @FechaAsiento, a.Monto,
                a.NuevoSaldo, a.Descripcion, NULL, NULL
            FROM @Asientos AS a
            WHERE a.Orden = 2 AND a.Monto > 0 AND @flag_consistente = 1;

            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto,
                NuevoSaldo, Descripcion, IdOperacionXML, IdMovimientoOrigen
            )
            OUTPUT inserted.IdMovimiento, 3
                INTO @Generados (IdMovimiento, Orden)
            SELECT
                @inIdEstadoCuenta, a.IdTipoMovimiento, @FechaAsiento, a.Monto,
                a.NuevoSaldo, a.Descripcion, NULL, NULL
            FROM @Asientos AS a
            WHERE a.Orden = 3 AND a.Monto > 0 AND @flag_consistente = 1;

            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto,
                NuevoSaldo, Descripcion, IdOperacionXML, IdMovimientoOrigen
            )
            OUTPUT inserted.IdMovimiento, 4
                INTO @Generados (IdMovimiento, Orden)
            SELECT
                @inIdEstadoCuenta, a.IdTipoMovimiento, @FechaAsiento, a.Monto,
                a.NuevoSaldo, a.Descripcion, NULL, NULL
            FROM @Asientos AS a
            WHERE a.Orden = 4 AND a.Monto > 0 AND @flag_consistente = 1;

            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto,
                NuevoSaldo, Descripcion, IdOperacionXML, IdMovimientoOrigen
            )
            OUTPUT inserted.IdMovimiento, 5
                INTO @Generados (IdMovimiento, Orden)
            SELECT
                @inIdEstadoCuenta, a.IdTipoMovimiento, @FechaAsiento, a.Monto,
                a.NuevoSaldo, a.Descripcion, NULL, NULL
            FROM @Asientos AS a
            WHERE a.Orden = 5 AND a.Monto > 0 AND @flag_consistente = 1;

            INSERT INTO dbo.Comprobante (IdMovimiento, FechaEmision, Detalle)
            SELECT g.IdMovimiento, @FechaAsiento, a.Detalle
            FROM @Generados AS g
            INNER JOIN @Asientos AS a ON a.Orden = g.Orden
            WHERE a.flag_comprobante = 1 AND @flag_consistente = 1
            ORDER BY g.Orden;

            UPDATE dbo.EstadoDeCuenta
            SET
                Cerrado = 1,
                SaldoFinal = @SaldoCalculado,
                SaldoMinimo = @MinimoCalculado,
                InteresesAcumulados = @Intereses
            WHERE IdEstadoCuenta = @inIdEstadoCuenta AND @flag_consistente = 1;

            INSERT INTO dbo.EstadoDeCuenta (
                IdCuenta, FechaInicio, FechaFin,
                SaldoInicial, SaldoMinimo, SaldoFinal,
                InteresesAcumulados, CantidadRetiros, CantidadDepositos,
                CantidadSinpeEntrantes, CantidadSinpeSalientes,
                CantidadRetirosATM, CantidadRetirosHumano,
                CantidadDepositosATM, CantidadDepositosHumano, Cerrado
            )
            OUTPUT inserted.IdEstadoCuenta INTO @NuevoPeriodo (IdEstadoCuenta)
            SELECT
                @IdCuenta, @InicioSiguiente, @FinSiguiente,
                @SaldoCalculado, @SaldoCalculado, @SaldoCalculado,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            WHERE @flag_insertarPeriodo = 1 AND @flag_consistente = 1;

            SELECT @outIdNuevoEstadoCuenta = n.IdEstadoCuenta FROM @NuevoPeriodo AS n;

            UPDATE dbo.Cuenta
            SET Saldo = @SaldoCalculado
            WHERE IdCuenta = @IdCuenta AND @flag_consistente = 1;

            IF @TransaccionInicial = 0
                COMMIT TRANSACTION;

            IF @flag_consistente = 1
            BEGIN
                SET @outResult = 0;
                RETURN 0;
            END;
        END;
    END TRY
    BEGIN CATCH
        SET @outResult = ERROR_NUMBER();
        SET @outIdNuevoEstadoCuenta = NULL;
        IF @@TRANCOUNT > 0
        BEGIN
            IF @TransaccionInicial = 0
                ROLLBACK TRANSACTION;
            ELSE IF @flag_puntoGuardado = 1 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION CerrarEstadoCuenta;
        END;
        THROW;
    END CATCH;
END;
GO
