CREATE OR ALTER PROCEDURE dbo.sp_AplicarMovimiento
    @inNumeroCuenta VARCHAR(32),
    @inIdTipoMovimiento INT,
    @inFecha DATETIME,
    @inMonto DECIMAL(18,2),
    @inDescripcion VARCHAR(255),
    @outResult INT OUTPUT,
    @inIdOperacionXML INT = NULL,
    @outIdMovimiento BIGINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TransaccionInicial INT = @@TRANCOUNT;
    DECLARE @PuntoGuardado BIT = 0;
    DECLARE @Dia DATE = CONVERT(DATE, @inFecha);
    DECLARE @IdCuenta INT, @IdEstadoCuenta INT, @CantidadEstados INT;
    DECLARE @Saldo DECIMAL(18,2), @NuevoSaldo DECIMAL(18,2);
    DECLARE @LimiteSinpe DECIMAL(18,2), @ComisionSinpe DECIMAL(18,2);
    DECLARE @EnviadoHoy DECIMAL(38,2), @Comision DECIMAL(18,2) = 0;
    DECLARE @Efecto INT, @NombreTipo VARCHAR(128);
    DECLARE @IdTipoComision INT, @CantidadTiposComision INT;
    DECLARE @Email VARCHAR(100), @NombreDueno VARCHAR(64);
    DECLARE @DatosXML XML, @FechaXML DATE, @NodoXML VARCHAR(128);
    DECLARE @Procesada BIT;

    SET @outResult = 50000;
    SET @outIdMovimiento = NULL;

    BEGIN TRY
        IF @inNumeroCuenta IS NULL OR LTRIM(RTRIM(@inNumeroCuenta)) = ''
           OR @inFecha IS NULL OR @inMonto IS NULL OR @inMonto <= 0
           OR @inDescripcion IS NULL OR LTRIM(RTRIM(@inDescripcion)) = ''
            THROW 50001, 'Revise cuenta, fecha, monto positivo y descripcion.', 1;

        IF @TransaccionInicial = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION AplicarMovimiento;
            SET @PuntoGuardado = 1;
        END;

        -- Bloquear el nodo evita aplicar dos veces una operacion XML.
        IF @inIdOperacionXML IS NOT NULL
        BEGIN
            SELECT @DatosXML = Datos, @FechaXML = Fecha,
                   @NodoXML = NombreNodo, @Procesada = flag_procesada
            FROM dbo.OperacionXML WITH (UPDLOCK, HOLDLOCK)
            WHERE IdOperacionXML = @inIdOperacionXML;

            IF @DatosXML IS NULL OR @NodoXML <> 'Movimientos' OR @FechaXML <> @Dia
                THROW 50006, 'La operacion XML no existe o no corresponde a este movimiento.', 1;
        END;

        SELECT @Efecto = Efecto, @NombreTipo = Nombre
        FROM dbo.TipoMovimiento
        WHERE Id = @inIdTipoMovimiento;

        IF @Efecto IS NULL OR @Efecto NOT IN (-1, 1)
            THROW 50002, 'El tipo de movimiento no existe o su efecto es invalido.', 1;

        IF @inIdOperacionXML IS NOT NULL
        BEGIN
            IF @DatosXML.value('(/Movimientos/@CodigoCuenta)[1]', 'VARCHAR(32)') <> @inNumeroCuenta
               OR @DatosXML.value('(/Movimientos/@Tipo)[1]', 'VARCHAR(128)') <> @NombreTipo
               OR @DatosXML.value('(/Movimientos/@Monto)[1]', 'DECIMAL(18,2)') <> @inMonto
               OR @DatosXML.value('(/Movimientos/@Descripcion)[1]', 'VARCHAR(255)') <> @inDescripcion
               OR @DatosXML.exist('/Movimientos[@CodigoCuenta and @Tipo and @Monto and @Descripcion]') = 0
                THROW 50006, 'Los parametros no coinciden con el nodo de movimiento XML.', 1;
        END;

        -- Serializar los movimientos de una misma cuenta protege el saldo
        -- y el acumulado diario SINPE ante llamadas simultaneas.
        SELECT @IdCuenta = c.IdCuenta, @Saldo = c.Saldo,
               @LimiteSinpe = t.MontoMaxSinpeDiario,
               @ComisionSinpe = t.ComisionSinpe,
               @Email = p.Email, @NombreDueno = p.Nombre
        FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.TipoCuentaAhorro AS t ON t.Id = c.IdTipoCuenta
        INNER JOIN dbo.Persona AS p ON p.IdPersona = c.IdPersonaDueno
        WHERE c.NumeroCuenta = @inNumeroCuenta;

        IF @IdCuenta IS NULL
            THROW 50003, 'La cuenta indicada no existe.', 1;

        IF @inIdOperacionXML IS NOT NULL
        BEGIN
            SELECT @outIdMovimiento = IdMovimiento
            FROM dbo.Movimiento
            WHERE IdOperacionXML = @inIdOperacionXML
              AND IdMovimientoOrigen IS NULL;

            IF @outIdMovimiento IS NOT NULL
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM dbo.Movimiento AS m
                    INNER JOIN dbo.EstadoDeCuenta AS e ON e.IdEstadoCuenta = m.IdEstadoCuenta
                    WHERE m.IdMovimiento = @outIdMovimiento
                      AND e.IdCuenta = @IdCuenta
                      AND m.IdTipoMovimiento = @inIdTipoMovimiento
                      AND m.Fecha = @inFecha AND m.Monto = @inMonto
                      AND m.Descripcion = @inDescripcion
                )
                    THROW 50007, 'La operacion XML ya esta asociada a otro movimiento.', 1;

                IF @TransaccionInicial = 0
                    COMMIT TRANSACTION;
                SET @outResult = 0;
                RETURN 0;
            END;

            IF @Procesada = 1
                THROW 50007, 'La operacion figura procesada pero no tiene movimiento asociado.', 1;
        END;

        SELECT @CantidadEstados = COUNT(*), @IdEstadoCuenta = MIN(IdEstadoCuenta)
        FROM dbo.EstadoDeCuenta WITH (UPDLOCK, HOLDLOCK)
        WHERE IdCuenta = @IdCuenta AND Cerrado = 0;

        IF @CantidadEstados <> 1
            THROW 50004, 'La cuenta debe tener exactamente un estado de cuenta abierto.', 1;

        IF NOT EXISTS (
            SELECT 1 FROM dbo.EstadoDeCuenta
            WHERE IdEstadoCuenta = @IdEstadoCuenta
              AND @Dia >= FechaInicio AND @Dia <= FechaFin
        )
            THROW 50005, 'La fecha no pertenece al periodo abierto de la cuenta.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.Movimiento AS m
            INNER JOIN dbo.EstadoDeCuenta AS e ON e.IdEstadoCuenta = m.IdEstadoCuenta
            WHERE e.IdCuenta = @IdCuenta AND m.Fecha > @inFecha
        )
            THROW 50005, 'Los movimientos de la cuenta deben aplicarse en orden cronologico.', 1;

        IF @NombreTipo = 'Retiro Sinpe'
        BEGIN
            IF @LimiteSinpe < 0 OR @ComisionSinpe < 0
                THROW 50008, 'El limite diario y la comision SINPE no pueden ser negativos.', 1;

            -- Incluir todos los estados: el limite es diario, no por periodo.
            -- Se excluyen comisiones y entradas SINPE.
            SELECT @EnviadoHoy = ISNULL(SUM(m.Monto), 0)
            FROM dbo.Movimiento AS m
            INNER JOIN dbo.EstadoDeCuenta AS e ON e.IdEstadoCuenta = m.IdEstadoCuenta
            INNER JOIN dbo.TipoMovimiento AS t ON t.Id = m.IdTipoMovimiento
            WHERE e.IdCuenta = @IdCuenta AND t.Nombre = 'Retiro Sinpe'
              AND m.Fecha >= @Dia
              AND m.Fecha < DATEADD(DAY, 1, CONVERT(DATETIME, @Dia));

            IF @EnviadoHoy + @inMonto > @LimiteSinpe
                SET @Comision = @ComisionSinpe;

            IF @Comision > 0
            BEGIN
                SELECT @CantidadTiposComision = COUNT(*), @IdTipoComision = MIN(Id)
                FROM dbo.TipoMovimiento
                WHERE Nombre = 'Comision Sinpe' AND Efecto = -1;

                IF @CantidadTiposComision <> 1
                    THROW 50008, 'Debe existir un unico tipo Comision Sinpe con efecto -1.', 1;
            END;
        END;

        -- Primero se guarda el saldo posterior al movimiento principal.
        SET @NuevoSaldo = @Saldo + (@inMonto * @Efecto);

        INSERT INTO dbo.Movimiento (
            IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto, NuevoSaldo,
            Descripcion, IdOperacionXML, IdMovimientoOrigen
        )
        VALUES (
            @IdEstadoCuenta, @inIdTipoMovimiento, @inFecha, @inMonto,
            @NuevoSaldo, @inDescripcion, @inIdOperacionXML, NULL
        );

        SET @outIdMovimiento = CONVERT(BIGINT, SCOPE_IDENTITY());

        IF @Comision > 0
        BEGIN
            SET @NuevoSaldo = @NuevoSaldo - @Comision;

            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto, NuevoSaldo,
                Descripcion, IdOperacionXML, IdMovimientoOrigen
            )
            VALUES (
                @IdEstadoCuenta, @IdTipoComision, @inFecha, @Comision,
                @NuevoSaldo, 'Comision por exceder el limite diario SINPE',
                @inIdOperacionXML, @outIdMovimiento
            );
        END;

        UPDATE dbo.Cuenta
        SET Saldo = @NuevoSaldo
        WHERE IdCuenta = @IdCuenta;

        UPDATE dbo.EstadoDeCuenta
        SET SaldoFinal = @NuevoSaldo,
            SaldoMinimo = CASE WHEN @NuevoSaldo < SaldoMinimo THEN @NuevoSaldo ELSE SaldoMinimo END,
            CantidadRetiros = CantidadRetiros + CASE WHEN @NombreTipo IN ('Retiro ATM', 'Retiro Ventana') THEN 1 ELSE 0 END,
            CantidadDepositos = CantidadDepositos + CASE WHEN @NombreTipo IN ('Deposito ATM', 'Deposito Ventana') THEN 1 ELSE 0 END,
            CantidadRetirosATM = CantidadRetirosATM + CASE WHEN @NombreTipo = 'Retiro ATM' THEN 1 ELSE 0 END,
            CantidadRetirosHumano = CantidadRetirosHumano + CASE WHEN @NombreTipo = 'Retiro Ventana' THEN 1 ELSE 0 END,
            CantidadDepositosATM = CantidadDepositosATM + CASE WHEN @NombreTipo = 'Deposito ATM' THEN 1 ELSE 0 END,
            CantidadDepositosHumano = CantidadDepositosHumano + CASE WHEN @NombreTipo = 'Deposito Ventana' THEN 1 ELSE 0 END,
            CantidadSinpeEntrantes = CantidadSinpeEntrantes + CASE WHEN @NombreTipo = 'Deposito Sinpe' THEN 1 ELSE 0 END,
            CantidadSinpeSalientes = CantidadSinpeSalientes + CASE WHEN @NombreTipo = 'Retiro Sinpe' THEN 1 ELSE 0 END
        WHERE IdEstadoCuenta = @IdEstadoCuenta;

        -- Cada comprobante conserva el saldo de su propio movimiento.
        INSERT INTO dbo.Comprobante (IdMovimiento, FechaEmision, Detalle)
        SELECT m.IdMovimiento, @inFecha,
               (SELECT @inNumeroCuenta AS NumeroCuenta, @NombreDueno AS Dueno,
                       @Email AS Email, m.Fecha, t.Nombre AS TipoMovimiento,
                       m.Monto, m.NuevoSaldo, m.Descripcion
                FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
        FROM dbo.Movimiento AS m
        INNER JOIN dbo.TipoMovimiento AS t ON t.Id = m.IdTipoMovimiento
        WHERE (m.IdMovimiento = @outIdMovimiento OR m.IdMovimientoOrigen = @outIdMovimiento)
          AND t.flag_requiere_comprobante = 1;

        IF @inIdOperacionXML IS NOT NULL
            UPDATE dbo.OperacionXML
            SET flag_procesada = 1
            WHERE IdOperacionXML = @inIdOperacionXML;

        IF @TransaccionInicial = 0
            COMMIT TRANSACTION;

        SET @outResult = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @outResult = ERROR_NUMBER();
        SET @outIdMovimiento = NULL;

        IF @TransaccionInicial = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @PuntoGuardado = 1 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION AplicarMovimiento;

        THROW;
    END CATCH;
END;
GO
