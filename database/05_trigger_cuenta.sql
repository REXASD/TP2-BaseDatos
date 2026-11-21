CREATE OR ALTER TRIGGER dbo.trg_Cuenta_CrearPrimerEstadoCuenta
ON dbo.Cuenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @false BIT = 0;

    BEGIN TRY
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
            , @false
        FROM inserted AS i;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
