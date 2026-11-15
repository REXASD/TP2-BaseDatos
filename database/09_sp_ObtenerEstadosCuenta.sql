-- Punto 11: lista completa, ordenada del mas reciente al mas antiguo.
-- Ejecutar este archivo para actualizar solo este SP en Azure.
CREATE OR ALTER PROCEDURE dbo.sp_ObtenerEstadosCuenta
    @IdUsuario INT,
    @IdCuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.sp_RegistrarBitacora
        @IdUsuario = @IdUsuario,
        @IdTipoOperacion = 7;

    SELECT
        ec.IdEstadoCuenta,
        ec.FechaInicio,
        ec.FechaFin,
        ec.SaldoInicial,
        ec.SaldoMinimo,
        ec.SaldoFinal,
        ec.InteresesAcumulados,
        ec.CantidadRetiros,
        ec.CantidadDepositos,
        ec.CantidadSinpeEntrantes,
        ec.CantidadSinpeSalientes
    FROM dbo.EstadoDeCuenta AS ec
    WHERE ec.IdCuenta = @IdCuenta
    ORDER BY ec.FechaFin DESC, ec.IdEstadoCuenta DESC;
END;
GO
