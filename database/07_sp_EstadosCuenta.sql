CREATE OR ALTER PROCEDURE dbo.sp_AbrirEstadoCuenta
    @inNumeroCuenta VARCHAR(32),
    @inFechaInicio DATE,
    @outResult INT OUTPUT,
    @outIdEstadoCuenta INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TransaccionInicial INT = @@TRANCOUNT, @PuntoGuardado BIT = 0;
    DECLARE @IdCuenta INT, @FechaCreacion DATE, @Saldo DECIMAL(18,2);
    DECLARE @DiaCorte INT, @Mes DATE, @FechaFin DATE;
    DECLARE @Cantidad INT, @FinAnterior DATE, @CerradoAnterior BIT;
    DECLARE @SaldoAnterior DECIMAL(18,2);
    SET @outResult = 50000;
    SET @outIdEstadoCuenta = NULL;

    BEGIN TRY
        IF @inFechaInicio IS NULL
            THROW 50201, 'La apertura requiere una fecha inicial.', 1;

        IF @TransaccionInicial = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION AbrirEstadoCuenta;
            SET @PuntoGuardado = 1;
        END;

        SELECT @IdCuenta = IdCuenta, @FechaCreacion = FechaCreacion, @Saldo = Saldo
        FROM dbo.Cuenta WITH (UPDLOCK, HOLDLOCK)
        WHERE NumeroCuenta = @inNumeroCuenta;

        IF @IdCuenta IS NULL
            THROW 50202, 'La cuenta indicada no existe.', 1;
        IF @inFechaInicio < @FechaCreacion
            THROW 50203, 'Un estado no puede iniciar antes de crear la cuenta.', 1;

        SET @DiaCorte = DAY(@FechaCreacion);
        SET @Mes = DATEFROMPARTS(YEAR(@inFechaInicio), MONTH(@inFechaInicio), 1);
        SET @FechaFin = DATEADD(DAY,
            CASE WHEN @DiaCorte > DAY(EOMONTH(@Mes)) THEN DAY(EOMONTH(@Mes)) ELSE @DiaCorte END - 1, @Mes);

        -- El primer estado dura hasta el primer corte del mes siguiente.
        IF @inFechaInicio = @FechaCreacion OR @FechaFin < @inFechaInicio
        BEGIN
            SET @Mes = DATEADD(MONTH, 1, @Mes);
            SET @FechaFin = DATEADD(DAY,
                CASE WHEN @DiaCorte > DAY(EOMONTH(@Mes)) THEN DAY(EOMONTH(@Mes)) ELSE @DiaCorte END - 1, @Mes);
        END;

        SELECT @Cantidad = COUNT(*), @outIdEstadoCuenta = MIN(IdEstadoCuenta)
        FROM dbo.EstadoDeCuenta WITH (UPDLOCK, HOLDLOCK)
        WHERE IdCuenta = @IdCuenta AND FechaInicio = @inFechaInicio;

        IF @Cantidad > 1
            THROW 50204, 'Hay periodos duplicados para la fecha inicial indicada.', 1;
        IF @Cantidad = 1
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.EstadoDeCuenta
                           WHERE IdEstadoCuenta = @outIdEstadoCuenta AND FechaFin = @FechaFin)
                THROW 50204, 'El periodo existente tiene una fecha final inconsistente.', 1;
            IF @TransaccionInicial = 0 COMMIT TRANSACTION;
            SET @outResult = 0;
            RETURN 0;
        END;

        IF EXISTS (SELECT 1 FROM dbo.EstadoDeCuenta WHERE IdCuenta = @IdCuenta AND Cerrado = 0)
            THROW 50205, 'Cierre el estado abierto antes de abrir otro periodo.', 1;

        SELECT TOP (1) @FinAnterior = FechaFin, @CerradoAnterior = Cerrado,
                       @SaldoAnterior = SaldoFinal
        FROM dbo.EstadoDeCuenta
        WHERE IdCuenta = @IdCuenta
        ORDER BY FechaFin DESC, IdEstadoCuenta DESC;

        IF @FinAnterior IS NULL AND @inFechaInicio <> @FechaCreacion
            THROW 50206, 'El primer estado debe iniciar en la fecha de creacion de la cuenta.', 1;
        IF @FinAnterior IS NOT NULL
        BEGIN
            IF @CerradoAnterior <> 1 OR @inFechaInicio <> DATEADD(DAY, 1, @FinAnterior)
                THROW 50206, 'El nuevo periodo debe seguir al ultimo estado cerrado, sin saltar fechas.', 1;
            IF @SaldoAnterior <> @Saldo
                THROW 50207, 'El saldo de la cuenta no coincide con el cierre anterior.', 1;
        END;

        INSERT INTO dbo.EstadoDeCuenta (
            IdCuenta, FechaInicio, FechaFin, SaldoInicial, SaldoMinimo,
            SaldoFinal, InteresesAcumulados, CantidadRetiros, CantidadDepositos,
            CantidadSinpeEntrantes, CantidadSinpeSalientes, CantidadRetirosATM,
            CantidadRetirosHumano, CantidadDepositosATM, CantidadDepositosHumano, Cerrado
        )
        VALUES (@IdCuenta, @inFechaInicio, @FechaFin, @Saldo, @Saldo,
                @Saldo, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        SET @outIdEstadoCuenta = CONVERT(INT, SCOPE_IDENTITY());

        IF @TransaccionInicial = 0 COMMIT TRANSACTION;
        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @outResult = ERROR_NUMBER();
        SET @outIdEstadoCuenta = NULL;
        IF @TransaccionInicial = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @PuntoGuardado = 1 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION AbrirEstadoCuenta;
        THROW;
    END CATCH;
END;
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

    DECLARE @TransaccionInicial INT = @@TRANCOUNT, @PuntoGuardado BIT = 0;
    DECLARE @IdCuenta INT, @NumeroCuenta VARCHAR(32), @Saldo DECIMAL(18,2);
    DECLARE @FechaInicio DATE, @FechaFin DATE, @InicioSiguiente DATE, @Cerrado BIT;
    DECLARE @MinimoPeriodo DECIMAL(18,2), @MinimoPermitido DECIMAL(18,2);
    DECLARE @SaldoEstado DECIMAL(18,2), @TasaAnual DECIMAL(5,2);
    DECLARE @Intereses DECIMAL(18,2) = 0, @Multa DECIMAL(18,2) = 0;
    DECLARE @CargoMensual DECIMAL(18,2), @MultaConfigurada DECIMAL(18,2);
    DECLARE @MaxATM INT, @MaxHumano INT, @OperacionesATM INT, @OperacionesHumano INT;
    DECLARE @TarifaATM DECIMAL(18,2), @TarifaHumano DECIMAL(18,2);
    DECLARE @ComisionATM DECIMAL(18,2) = 0, @ComisionHumano DECIMAL(18,2) = 0;
    DECLARE @Cantidad INT, @Orden INT = 1, @Tipo INT, @Efecto INT;
    DECLARE @NombreTipo VARCHAR(128), @Descripcion VARCHAR(255), @Monto DECIMAL(18,2);
    DECLARE @FechaAsiento DATETIME, @ResultadoMovimiento INT;
    DECLARE @Asientos TABLE (
        Orden INT PRIMARY KEY, NombreTipo VARCHAR(128),
        Monto DECIMAL(18,2), Descripcion VARCHAR(255)
    );
    SET @outResult = 50000;
    SET @outIdNuevoEstadoCuenta = NULL;

    BEGIN TRY
        IF @inIdEstadoCuenta IS NULL OR @inFechaCierre IS NULL
            THROW 50301, 'Indique el estado y su fecha de cierre.', 1;

        IF @TransaccionInicial = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION CerrarEstadoCuenta;
            SET @PuntoGuardado = 1;
        END;

        SELECT @IdCuenta = IdCuenta FROM dbo.EstadoDeCuenta WHERE IdEstadoCuenta = @inIdEstadoCuenta;
        IF @IdCuenta IS NULL
            THROW 50302, 'El estado de cuenta indicado no existe.', 1;

        -- Mismo orden de bloqueo que sp_AplicarMovimiento: cuenta y estado.
        SELECT @NumeroCuenta = c.NumeroCuenta, @Saldo = c.Saldo,
               @MinimoPermitido = t.SaldoMinimo, @TasaAnual = t.TasaInteresAnual,
               @MaxATM = t.NumRetirosAutomatico, @MaxHumano = t.NumRetirosHumano,
               @TarifaATM = t.ComisionAutomatico, @TarifaHumano = t.ComisionHumano,
               @MultaConfigurada = t.MultaSaldoMin, @CargoMensual = t.CargoMensual
        FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.TipoCuentaAhorro AS t ON t.Id = c.IdTipoCuenta
        WHERE c.IdCuenta = @IdCuenta;

        SELECT @FechaInicio = FechaInicio, @FechaFin = FechaFin, @Cerrado = Cerrado,
               @MinimoPeriodo = SaldoMinimo, @SaldoEstado = SaldoFinal,
               @OperacionesATM = CantidadRetirosATM + CantidadDepositosATM,
               @OperacionesHumano = CantidadRetirosHumano + CantidadDepositosHumano
        FROM dbo.EstadoDeCuenta WITH (UPDLOCK, HOLDLOCK)
        WHERE IdEstadoCuenta = @inIdEstadoCuenta;

        IF @inFechaCierre <> @FechaFin
            THROW 50303, 'El cierre debe realizarse en la fecha final del periodo.', 1;
        SET @InicioSiguiente = DATEADD(DAY, 1, @FechaFin);

        IF @Cerrado = 1
        BEGIN
            SELECT @Cantidad = COUNT(*), @outIdNuevoEstadoCuenta = MIN(IdEstadoCuenta)
            FROM dbo.EstadoDeCuenta
            WHERE IdCuenta = @IdCuenta AND FechaInicio = @InicioSiguiente;
            IF @Cantidad <> 1
                THROW 50304, 'El estado cerrado no tiene un unico periodo sucesor.', 1;
            IF @TransaccionInicial = 0 COMMIT TRANSACTION;
            SET @outResult = 0;
            RETURN 0;
        END;

        IF (SELECT COUNT(*) FROM dbo.EstadoDeCuenta WHERE IdCuenta = @IdCuenta AND Cerrado = 0) <> 1
            THROW 50304, 'La cuenta debe tener exactamente un periodo abierto.', 1;
        IF @SaldoEstado <> @Saldo
            THROW 50305, 'El saldo de la cuenta no coincide con el del estado abierto.', 1;
        IF @TasaAnual < 0 OR @MaxATM < 0 OR @MaxHumano < 0 OR @TarifaATM < 0
           OR @TarifaHumano < 0 OR @MultaConfigurada < 0 OR @CargoMensual < 0 OR @MinimoPermitido < 0
            THROW 50306, 'El tipo de cuenta contiene una tasa, limite o cargo negativo.', 1;

        IF EXISTS (
            SELECT 1 FROM dbo.OperacionXML
            WHERE NombreNodo = 'Movimientos' AND flag_procesada = 0
              AND Fecha BETWEEN @FechaInicio AND @FechaFin
              AND Datos.value('(/Movimientos/@CodigoCuenta)[1]', 'VARCHAR(32)') = @NumeroCuenta
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
        VALUES (1, 'Intereses Mensuales', @Intereses, 'Abono de intereses mensuales sobre el saldo minimo'),
               (2, 'Comision Exceso ATM', @ComisionATM, 'Comision mensual por exceso de operaciones ATM'),
               (3, 'Comision Exceso Ventana', @ComisionHumano, 'Comision mensual por exceso de operaciones en ventanilla'),
               (4, 'Multa Saldo Minimo', @Multa, 'Multa mensual por saldo inferior al minimo permitido'),
               (5, 'Cargo Servicio Mensual', @CargoMensual, 'Cargo mensual por servicio de la cuenta');

        -- Ultimo instante representable por DATETIME en el dia del corte.
        SET @FechaAsiento = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, CONVERT(DATETIME, @FechaFin)));
        WHILE @Orden <= 5
        BEGIN
            SELECT @NombreTipo = NombreTipo, @Monto = Monto, @Descripcion = Descripcion
            FROM @Asientos WHERE Orden = @Orden;
            IF @Monto > 0
            BEGIN
                SELECT @Cantidad = COUNT(*), @Tipo = MIN(Id), @Efecto = MIN(Efecto)
                FROM dbo.TipoMovimiento WHERE Nombre = @NombreTipo;
                IF @Cantidad <> 1 OR @Efecto <> CASE WHEN @Orden = 1 THEN 1 ELSE -1 END
                    THROW 50308, 'Falta un tipo de movimiento de cierre o tiene un efecto incorrecto.', 1;

                EXEC dbo.sp_AplicarMovimiento
                    @inNumeroCuenta = @NumeroCuenta, @inIdTipoMovimiento = @Tipo,
                    @inFecha = @FechaAsiento, @inMonto = @Monto,
                    @inDescripcion = @Descripcion, @outResult = @ResultadoMovimiento OUTPUT;
                IF @ResultadoMovimiento <> 0
                    THROW 50309, 'No fue posible aplicar un asiento de cierre.', 1;
            END;
            SET @Orden = @Orden + 1;
        END;

        SELECT @Saldo = Saldo FROM dbo.Cuenta WHERE IdCuenta = @IdCuenta;
        UPDATE dbo.EstadoDeCuenta
        SET Cerrado = 1, SaldoFinal = @Saldo,
            InteresesAcumulados = @Intereses
        WHERE IdEstadoCuenta = @inIdEstadoCuenta;

        EXEC dbo.sp_AbrirEstadoCuenta
            @inNumeroCuenta = @NumeroCuenta, @inFechaInicio = @InicioSiguiente,
            @outResult = @outResult OUTPUT, @outIdEstadoCuenta = @outIdNuevoEstadoCuenta OUTPUT;
        IF @outResult <> 0
            THROW 50310, 'No fue posible abrir el siguiente estado de cuenta.', 1;

        IF @TransaccionInicial = 0 COMMIT TRANSACTION;
        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @outResult = ERROR_NUMBER();
        SET @outIdNuevoEstadoCuenta = NULL;
        IF @TransaccionInicial = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @PuntoGuardado = 1 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION CerrarEstadoCuenta;
        THROW;
    END CATCH;
END;
GO
