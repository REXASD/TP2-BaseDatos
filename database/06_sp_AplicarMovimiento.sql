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
        DECLARE @TransaccionInicial INT = @@TRANCOUNT;
        DECLARE @flag_puntoGuardado BIT = 0;

        DECLARE @IdCuenta INT;
        DECLARE @FechaCreacion DATE;
        DECLARE @SaldoBase DECIMAL(18,2);
        DECLARE @IdTipoCuenta INT;
        DECLARE @IdPersonaDueno INT;

        DECLARE @IdEstadoCuenta INT;
        DECLARE @CantidadEstados INT;
        DECLARE @FechaInicio DATE;
        DECLARE @FechaFin DATE;
        DECLARE @SaldoMinimoActual DECIMAL(18,2);
        DECLARE @SaldoMinimoFinal DECIMAL(18,2);
        DECLARE @SaldoPrincipal DECIMAL(18,2);
        DECLARE @SaldoFinal DECIMAL(18,2);

        DECLARE @CantidadRetiros INT;
        DECLARE @CantidadDepositos INT;
        DECLARE @CantidadSinpeEntrantes INT;
        DECLARE @CantidadSinpeSalientes INT;
        DECLARE @CantidadRetirosATM INT;
        DECLARE @CantidadRetirosHumano INT;
        DECLARE @CantidadDepositosATM INT;
        DECLARE @CantidadDepositosHumano INT;

        DECLARE @Dia DATE;
        DECLARE @Efecto INT;
        DECLARE @NombreTipo VARCHAR(128);
        DECLARE @flag_primerMovimiento BIT;

        DECLARE @LimiteSinpe DECIMAL(18,2);
        DECLARE @ComisionSinpe DECIMAL(18,2);
        DECLARE @EnviadoHoy DECIMAL(38,2);
        DECLARE @Comision DECIMAL(18,2) = 0;
        DECLARE @IdTipoComision INT;
        DECLARE @CantidadTiposComision INT;

        DECLARE @Email VARCHAR(128);
        DECLARE @NombreDueno VARCHAR(64);

        DECLARE @DatosXML XML;
        DECLARE @FechaXML DATE;
        DECLARE @NodoXML VARCHAR(128);
        DECLARE @flag_procesada BIT;

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
            Detalle VARCHAR(MAX) NOT NULL,
            flag_comprobante BIT NULL
        );

        SET @outResult = 50000;
        SET @outIdMovimiento = NULL;
        SET @Dia = CONVERT(DATE, @inFecha);

        ----------------------------------------------------------------
        -- 1. Validaciones de entrada
        ----------------------------------------------------------------

        IF @inNumeroCuenta IS NULL
           OR LTRIM(RTRIM(@inNumeroCuenta)) = ''
           OR @inIdTipoMovimiento IS NULL
           OR @inFecha IS NULL
           OR @inMonto IS NULL
           OR @inMonto <= 0
           OR @inDescripcion IS NULL
           OR LTRIM(RTRIM(@inDescripcion)) = ''
        BEGIN
            THROW 50001,
                'Revise la cuenta, tipo de movimiento, fecha, monto y descripcion.',
                1;
        END;

        ----------------------------------------------------------------
        -- 2. Preparar la transacción
        ----------------------------------------------------------------

        IF @TransaccionInicial > 0
        BEGIN
            SAVE TRANSACTION AplicarMovimiento;
            SET @flag_puntoGuardado = 1;
        END;
        ELSE
        BEGIN
            BEGIN TRANSACTION;
        END;

        ----------------------------------------------------------------
        -- 3. Consultar y bloquear la operación XML, si corresponde
        ----------------------------------------------------------------

        IF @inIdOperacionXML IS NOT NULL
        BEGIN
            SELECT
                @DatosXML = o.Datos,
                @FechaXML = o.Fecha,
                @NodoXML = o.NombreNodo,
                @flag_procesada = o.flag_procesada
            FROM dbo.OperacionXML AS o WITH (UPDLOCK, HOLDLOCK)
            WHERE o.IdOperacionXML = @inIdOperacionXML;

            IF @DatosXML IS NULL
               OR @NodoXML <> 'Movimientos'
               OR @FechaXML <> @Dia
            BEGIN
                THROW 50006,
                    'La operacion XML no existe o no corresponde a este movimiento.',
                    1;
            END;
        END;

        ----------------------------------------------------------------
        -- 4. Consultar el tipo de movimiento
        ----------------------------------------------------------------

        SELECT
            @Efecto = t.Efecto,
            @NombreTipo = t.Nombre
        FROM dbo.TipoMovimiento AS t
        WHERE t.Id = @inIdTipoMovimiento;

        IF @Efecto IS NULL OR @Efecto NOT IN (-1, 1)
        BEGIN
            THROW 50002,
                'El tipo de movimiento no existe o su efecto es invalido.',
                1;
        END;

        ----------------------------------------------------------------
        -- 5. Validar que los datos coincidan con el XML
        ----------------------------------------------------------------

        IF @inIdOperacionXML IS NOT NULL
        BEGIN
            IF @DatosXML.exist(
                '/Movimientos[@CodigoCuenta and @Tipo and @Monto and @Descripcion]'
            ) = 0
            BEGIN
                THROW 50006,
                    'El nodo XML no contiene todos los atributos requeridos.',
                    1;
            END;

            IF LTRIM(RTRIM(
                    @DatosXML.value(
                        '(/Movimientos/@CodigoCuenta)[1]',
                        'VARCHAR(32)'
                    )
                )) <> @inNumeroCuenta
               OR LTRIM(RTRIM(
                    @DatosXML.value(
                        '(/Movimientos/@Tipo)[1]',
                        'VARCHAR(128)'
                    )
                )) <> @NombreTipo
               OR @DatosXML.value(
                    '(/Movimientos/@Monto)[1]',
                    'DECIMAL(18,2)'
                ) <> @inMonto
               OR @DatosXML.value(
                    '(/Movimientos/@Descripcion)[1]',
                    'VARCHAR(256)'
                ) <> @inDescripcion
            BEGIN
                THROW 50006,
                    'Los parametros no coinciden con el nodo de movimiento XML.',
                    1;
            END;
        END;

        ----------------------------------------------------------------
        -- 6. Consultar y bloquear la cuenta
        ----------------------------------------------------------------

        SELECT
            @IdCuenta = c.IdCuenta,
            @FechaCreacion = c.FechaCreacion,
            @SaldoBase = c.Saldo,
            @IdTipoCuenta = c.IdTipoCuenta,
            @IdPersonaDueno = c.IdPersonaDueno
        FROM dbo.Cuenta AS c WITH (UPDLOCK, HOLDLOCK)
        WHERE c.NumeroCuenta = @inNumeroCuenta;

        IF @IdCuenta IS NULL
        BEGIN
            THROW 50003, 'La cuenta indicada no existe.', 1;
        END;

        ----------------------------------------------------------------
        -- 7. Validar si el movimiento XML ya fue aplicado
        ----------------------------------------------------------------

        IF @inIdOperacionXML IS NOT NULL
        BEGIN
            SELECT
                @outIdMovimiento = m.IdMovimiento
            FROM dbo.Movimiento AS m WITH (UPDLOCK, HOLDLOCK)
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
                BEGIN
                    THROW 50007,
                        'La operacion XML ya esta asociada a otro movimiento.',
                        1;
                END;

                IF @TransaccionInicial = 0
                    COMMIT TRANSACTION;

                SET @outResult = 0;
                RETURN 0;
            END;

            IF @flag_procesada = 1
            BEGIN
                THROW 50007,
                    'La operacion figura procesada pero no tiene movimiento asociado.',
                    1;
            END;
        END;

        ----------------------------------------------------------------
        -- 8. Consultar los datos del tipo de cuenta y del dueño
        ----------------------------------------------------------------

        SELECT
            @LimiteSinpe = t.MontoMaxSinpeDiario,
            @ComisionSinpe = t.ComisionSinpe,
            @Email = CONVERT(VARCHAR(128), p.Email),
            @NombreDueno = p.Nombre
        FROM dbo.TipoCuentaAhorro AS t
        INNER JOIN dbo.Persona AS p
            ON p.IdPersona = @IdPersonaDueno
        WHERE t.Id = @IdTipoCuenta;

        IF @NombreTipo = 'Retiro Sinpe'
           AND (@LimiteSinpe IS NULL OR @ComisionSinpe IS NULL)
        BEGIN
            THROW 50008,
                'La cuenta no tiene configurado el limite o la comision SINPE.',
                1;
        END;

        ----------------------------------------------------------------
        -- 9. Consultar el estado de cuenta abierto
        ----------------------------------------------------------------

        SELECT
            @CantidadEstados = COUNT(1),
            @IdEstadoCuenta = MIN(e.IdEstadoCuenta)
        FROM dbo.EstadoDeCuenta AS e WITH (UPDLOCK, HOLDLOCK)
        WHERE e.IdCuenta = @IdCuenta
          AND e.Cerrado = 0;

        IF @CantidadEstados <> 1
        BEGIN
            THROW 50004,
                'La cuenta debe tener exactamente un estado de cuenta abierto.',
                1;
        END;

        SELECT
            @FechaInicio = e.FechaInicio,
            @FechaFin = e.FechaFin,
            @SaldoMinimoActual = e.SaldoMinimo,
            @CantidadRetiros = e.CantidadRetiros,
            @CantidadDepositos = e.CantidadDepositos,
            @CantidadSinpeEntrantes = e.CantidadSinpeEntrantes,
            @CantidadSinpeSalientes = e.CantidadSinpeSalientes,
            @CantidadRetirosATM = e.CantidadRetirosATM,
            @CantidadRetirosHumano = e.CantidadRetirosHumano,
            @CantidadDepositosATM = e.CantidadDepositosATM,
            @CantidadDepositosHumano = e.CantidadDepositosHumano
        FROM dbo.EstadoDeCuenta AS e WITH (UPDLOCK, HOLDLOCK)
        WHERE e.IdEstadoCuenta = @IdEstadoCuenta;

        IF @Dia < @FechaInicio OR @Dia > @FechaFin
        BEGIN
            THROW 50005,
                'La fecha no pertenece al periodo abierto de la cuenta.',
                1;
        END;

        ----------------------------------------------------------------
        -- 10. Validar el orden cronológico
        ----------------------------------------------------------------

        IF EXISTS (
            SELECT 1
            FROM dbo.Movimiento AS m
            INNER JOIN dbo.EstadoDeCuenta AS e
                ON e.IdEstadoCuenta = m.IdEstadoCuenta
            WHERE e.IdCuenta = @IdCuenta
              AND m.Fecha > @inFecha
        )
        BEGIN
            THROW 50005,
                'Los movimientos de la cuenta deben aplicarse en orden cronologico.',
                1;
        END;

        ----------------------------------------------------------------
        -- 11. Calcular comisión por retiro SINPE
        ----------------------------------------------------------------

        IF @NombreTipo = 'Retiro Sinpe'
        BEGIN
            IF @LimiteSinpe < 0 OR @ComisionSinpe < 0
            BEGIN
                THROW 50008,
                    'El limite diario y la comision SINPE no pueden ser negativos.',
                    1;
            END;

            SELECT
                @EnviadoHoy = ISNULL(SUM(m.Monto), 0)
            FROM dbo.Movimiento AS m
            INNER JOIN dbo.EstadoDeCuenta AS e
                ON e.IdEstadoCuenta = m.IdEstadoCuenta
            INNER JOIN dbo.TipoMovimiento AS t
                ON t.Id = m.IdTipoMovimiento
            WHERE e.IdCuenta = @IdCuenta
              AND t.Nombre = 'Retiro Sinpe'
              AND m.Fecha >= @Dia
              AND m.Fecha < DATEADD(
                    DAY,
                    1,
                    CONVERT(DATETIME, @Dia)
                );

            IF @EnviadoHoy + @inMonto > @LimiteSinpe
                SET @Comision = @ComisionSinpe;

            IF @Comision > 0
            BEGIN
                SELECT
                    @CantidadTiposComision = COUNT(1),
                    @IdTipoComision = MIN(t.Id)
                FROM dbo.TipoMovimiento AS t
                WHERE t.Nombre = 'Comision Sinpe'
                  AND t.Efecto = -1;

                IF @CantidadTiposComision <> 1
                BEGIN
                    THROW 50008,
                        'Debe existir un unico tipo Comision Sinpe con efecto -1.',
                        1;
                END;
            END;
        END;

        ----------------------------------------------------------------
        -- 12. Determinar si es el primer movimiento del estado
        ----------------------------------------------------------------

        SET @flag_primerMovimiento = 0;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Movimiento AS m
            WHERE m.IdEstadoCuenta = @IdEstadoCuenta
        )
           AND @FechaInicio = @FechaCreacion
        BEGIN
            SET @flag_primerMovimiento = 1;
        END;

        ----------------------------------------------------------------
        -- 13. Calcular los nuevos saldos
        ----------------------------------------------------------------

        SET @SaldoPrincipal = @SaldoBase + (@inMonto * @Efecto);
        SET @SaldoFinal = @SaldoPrincipal;

        IF @Comision > 0
            SET @SaldoFinal = @SaldoPrincipal - @Comision;

        SET @SaldoMinimoFinal = CASE
            WHEN @flag_primerMovimiento = 1
                THEN @SaldoFinal
            WHEN @SaldoFinal < @SaldoMinimoActual
                THEN @SaldoFinal
            ELSE @SaldoMinimoActual
        END;

        ----------------------------------------------------------------
        -- 14. Preparar el movimiento principal
        ----------------------------------------------------------------

        INSERT INTO @Plan (
            Orden,
            IdTipoMovimiento,
            Monto,
            NuevoSaldo,
            Descripcion,
            Detalle,
            flag_comprobante
        )
        SELECT
            1,
            t.Id,
            @inMonto,
            @SaldoPrincipal,
            @inDescripcion,
            (
                SELECT
                    @inNumeroCuenta AS NumeroCuenta,
                    @NombreDueno AS Dueno,
                    @Email AS Email,
                    @inFecha AS Fecha,
                    t.Nombre AS TipoMovimiento,
                    @inMonto AS Monto,
                    @SaldoPrincipal AS NuevoSaldo,
                    @inDescripcion AS Descripcion
                FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
            ),
            t.flag_requiere_comprobante
        FROM dbo.TipoMovimiento AS t
        WHERE t.Id = @inIdTipoMovimiento;

        ----------------------------------------------------------------
        -- 15. Preparar el movimiento de comisión, si corresponde
        ----------------------------------------------------------------

        IF @Comision > 0
        BEGIN
            INSERT INTO @Plan (
                Orden,
                IdTipoMovimiento,
                Monto,
                NuevoSaldo,
                Descripcion,
                Detalle,
                flag_comprobante
            )
            SELECT
                2,
                t.Id,
                @Comision,
                @SaldoFinal,
                'Comision por exceder el limite diario SINPE',
                (
                    SELECT
                        @inNumeroCuenta AS NumeroCuenta,
                        @NombreDueno AS Dueno,
                        @Email AS Email,
                        @inFecha AS Fecha,
                        t.Nombre AS TipoMovimiento,
                        @Comision AS Monto,
                        @SaldoFinal AS NuevoSaldo,
                        'Comision por exceder el limite diario SINPE' AS Descripcion
                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
                ),
                t.flag_requiere_comprobante
            FROM dbo.TipoMovimiento AS t
            WHERE t.Id = @IdTipoComision;
        END;

        ----------------------------------------------------------------
        -- 16. Validar el correo si se requiere comprobante
        ----------------------------------------------------------------

        IF EXISTS (
            SELECT 1
            FROM @Plan AS p
            WHERE p.flag_comprobante = 1
        )
           AND (@Email IS NULL OR LTRIM(RTRIM(@Email)) = '')
        BEGIN
            THROW 50009,
                'El dueño de la cuenta no tiene un correo configurado para el comprobante.',
                1;
        END;

        ----------------------------------------------------------------
        -- 17. Insertar el movimiento principal
        ----------------------------------------------------------------

        INSERT INTO dbo.Movimiento (
            IdEstadoCuenta,
            IdTipoMovimiento,
            Fecha,
            Monto,
            NuevoSaldo,
            Descripcion,
            IdOperacionXML,
            IdMovimientoOrigen
        )
        OUTPUT
            inserted.IdMovimiento,
            1
        INTO @Generados (
            IdMovimiento,
            Orden
        )
        SELECT
            @IdEstadoCuenta,
            p.IdTipoMovimiento,
            @inFecha,
            p.Monto,
            p.NuevoSaldo,
            p.Descripcion,
            @inIdOperacionXML,
            NULL
        FROM @Plan AS p
        WHERE p.Orden = 1;

        SELECT
            @outIdMovimiento = g.IdMovimiento
        FROM @Generados AS g
        WHERE g.Orden = 1;

        ----------------------------------------------------------------
        -- 18. Insertar el movimiento de comisión SINPE
        ----------------------------------------------------------------

        IF @Comision > 0
        BEGIN
            INSERT INTO dbo.Movimiento (
                IdEstadoCuenta,
                IdTipoMovimiento,
                Fecha,
                Monto,
                NuevoSaldo,
                Descripcion,
                IdOperacionXML,
                IdMovimientoOrigen
            )
            OUTPUT
                inserted.IdMovimiento,
                2
            INTO @Generados (
                IdMovimiento,
                Orden
            )
            SELECT
                @IdEstadoCuenta,
                p.IdTipoMovimiento,
                @inFecha,
                p.Monto,
                p.NuevoSaldo,
                p.Descripcion,
                @inIdOperacionXML,
                @outIdMovimiento
            FROM @Plan AS p
            WHERE p.Orden = 2;
        END;

        ----------------------------------------------------------------
        -- 19. Generar los comprobantes correspondientes
        ----------------------------------------------------------------

        INSERT INTO dbo.Comprobante (
            IdMovimiento,
            FechaEmision,
            Detalle
        )
        SELECT
            g.IdMovimiento,
            @inFecha,
            p.Detalle
        FROM @Generados AS g
        INNER JOIN @Plan AS p
            ON p.Orden = g.Orden
        WHERE p.flag_comprobante = 1;

        ----------------------------------------------------------------
        -- 20. Marcar la operación XML como procesada
        ----------------------------------------------------------------

        IF @inIdOperacionXML IS NOT NULL
        BEGIN
            UPDATE dbo.OperacionXML
            SET flag_procesada = 1
            WHERE IdOperacionXML = @inIdOperacionXML;

            IF @@ROWCOUNT <> 1
            BEGIN
                THROW 50006,
                    'No fue posible marcar la operacion XML como procesada.',
                    1;
            END;
        END;

        ----------------------------------------------------------------
        -- 21. Actualizar los datos del estado de cuenta
        ----------------------------------------------------------------

        UPDATE dbo.EstadoDeCuenta
        SET
            SaldoFinal = @SaldoFinal,
            SaldoMinimo = @SaldoMinimoFinal,

            CantidadRetiros = ISNULL(@CantidadRetiros, 0)
                + CASE
                    WHEN @NombreTipo IN ('Retiro ATM', 'Retiro Ventana')
                    THEN 1 ELSE 0
                  END,

            CantidadDepositos = ISNULL(@CantidadDepositos, 0)
                + CASE
                    WHEN @NombreTipo IN ('Deposito ATM', 'Deposito Ventana')
                    THEN 1 ELSE 0
                  END,

            CantidadRetirosATM = ISNULL(@CantidadRetirosATM, 0)
                + CASE
                    WHEN @NombreTipo = 'Retiro ATM'
                    THEN 1 ELSE 0
                  END,

            CantidadRetirosHumano = ISNULL(@CantidadRetirosHumano, 0)
                + CASE
                    WHEN @NombreTipo = 'Retiro Ventana'
                    THEN 1 ELSE 0
                  END,

            CantidadDepositosATM = ISNULL(@CantidadDepositosATM, 0)
                + CASE
                    WHEN @NombreTipo = 'Deposito ATM'
                    THEN 1 ELSE 0
                  END,

            CantidadDepositosHumano = ISNULL(@CantidadDepositosHumano, 0)
                + CASE
                    WHEN @NombreTipo = 'Deposito Ventana'
                    THEN 1 ELSE 0
                  END,

            CantidadSinpeEntrantes = ISNULL(@CantidadSinpeEntrantes, 0)
                + CASE
                    WHEN @NombreTipo = 'Deposito Sinpe'
                    THEN 1 ELSE 0
                  END,

            CantidadSinpeSalientes = ISNULL(@CantidadSinpeSalientes, 0)
                + CASE
                    WHEN @NombreTipo = 'Retiro Sinpe'
                    THEN 1 ELSE 0
                  END

        WHERE IdEstadoCuenta = @IdEstadoCuenta;

        ----------------------------------------------------------------
        -- 22. Actualizar el saldo de la cuenta
        ----------------------------------------------------------------

        UPDATE dbo.Cuenta
        SET Saldo = @SaldoFinal
        WHERE IdCuenta = @IdCuenta;

        ----------------------------------------------------------------
        -- 23. Finalizar la transacción
        ----------------------------------------------------------------

        IF @TransaccionInicial = 0
            COMMIT TRANSACTION;

        SET @outResult = 0;

        RETURN 0;
    END TRY

    BEGIN CATCH

        ----------------------------------------------------------------
        -- 24. Revertir los cambios cuando corresponda
        ----------------------------------------------------------------

        IF @@TRANCOUNT > 0
        BEGIN
            IF @TransaccionInicial = 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;
            ELSE IF @flag_puntoGuardado = 1 AND XACT_STATE() = 1
            BEGIN
                ROLLBACK TRANSACTION AplicarMovimiento;
            END;
        END;

        SET @outResult = ERROR_NUMBER();
        SET @outIdMovimiento = NULL;

        THROW;
    END CATCH;
END;
GO