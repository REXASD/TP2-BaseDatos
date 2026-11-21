
CREATE OR ALTER TRIGGER dbo.trg_Cuenta_CrearPrimerEstadoCuenta
ON dbo.Cuenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.EstadoDeCuenta (
        IdCuenta
        , FechaInicio
        , FechaFin
        , SaldoInicial
        , SaldoMinimo
        , SaldoFinal
        , InteresesAcumulados
        , CantidadRetiros
        , CantidadDepositos
        , CantidadSinpeEntrantes
        , CantidadSinpeSalientes
        , CantidadRetirosATM
        , CantidadRetirosHumano
        , CantidadDepositosATM
        , CantidadDepositosHumano
        , Cerrado
    )
    SELECT
        i.IdCuenta
        , i.FechaCreacion
        , DATEADD(MONTH, 1, i.FechaCreacion)
        , i.Saldo
        , i.Saldo
        , i.Saldo
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
    FROM inserted i;
END;
GO
