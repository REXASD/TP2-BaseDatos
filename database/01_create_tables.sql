/* =========================================
   1. TABLAS CATÁLOGO
   ========================================= */

CREATE TABLE dbo.TipoMoneda(
    Id INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(128) NOT NULL,
    Simbolo NVARCHAR(2) NOT NULL
);
GO

CREATE TABLE dbo.TipoDocuIdentidad(
    Id INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(128) NOT NULL
);
GO

CREATE TABLE dbo.Parentezco(
    Id INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(32) NOT NULL
);
GO

CREATE TABLE dbo.TipoOperacion(
    Id INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(128) NOT NULL
);
GO

CREATE TABLE dbo.TipoMovimiento (
    Id INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(128) NOT NULL,
    Efecto INT NOT NULL, 
    Canal VARCHAR(50) NULL, 
    flag_requiere_comprobante BIT NOT NULL
);
GO

CREATE TABLE dbo.ControlFechaOperacion (
    Fecha DATE PRIMARY KEY NOT NULL,
    flag_procesada BIT NOT NULL,
    Intentos INT NOT NULL,
    FechaUltimoIntento DATETIME NULL,
    FechaProcesamiento DATETIME NULL,
    UltimoError VARCHAR(MAX) NULL
);
GO

CREATE TABLE dbo.CargaOperacionesXML (
    IdCarga INT IDENTITY(1,1) PRIMARY KEY,
    NombreArchivo VARCHAR(255) NOT NULL,
    HashArchivo VARCHAR(255) NULL,
    FechaCarga DATETIME NOT NULL,
    Contenido XML NOT NULL
);
GO

/* =========================================
   2. TABLAS DE PRIMER NIVEL DE DEPENDENCIA
   ========================================= */

CREATE TABLE dbo.TipoCuentaAhorro(
    Id INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(128) NOT NULL,
    IdTipoMoneda INT NOT NULL,
    SaldoMinimo DECIMAL(18,2) NOT NULL,
    MultaSaldoMin DECIMAL(18,2) NOT NULL,
    CargoMensual DECIMAL(18,2) NOT NULL,
    NumRetirosHumano INT NOT NULL,
    NumRetirosAutomatico INT NOT NULL,
    ComisionHumano DECIMAL(18,2) NOT NULL,
    ComisionAutomatico DECIMAL(18,2) NOT NULL,
    TasaInteresAnual DECIMAL(5,2) NOT NULL,
    MontoMaxSinpeDiario DECIMAL(18,2) NOT NULL,
    ComisionSinpe DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (IdTipoMoneda) REFERENCES dbo.TipoMoneda(Id)
);
GO

CREATE TABLE dbo.Persona (
    IdPersona INT IDENTITY(1,1) PRIMARY KEY,
    IdTipoDocuIdentidad INT NOT NULL,
    ValorDocumentoIdentidad VARCHAR(64) NOT NULL UNIQUE,
    Nombre VARCHAR(64) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Email VARCHAR(100) NULL,
    Telefono1 VARCHAR(20) NOT NULL,
    Telefono2 VARCHAR(20) NOT NULL,
    FOREIGN KEY (IdTipoDocuIdentidad) REFERENCES dbo.TipoDocuIdentidad(Id)
);
GO

CREATE TABLE dbo.OperacionXML (
    IdOperacionXML INT IDENTITY(1,1) PRIMARY KEY,
    IdCarga INT NOT NULL,
    Fecha DATE NOT NULL,
    OrdenEnArchivo INT NOT NULL,
    NombreNodo VARCHAR(128) NOT NULL,
    Datos XML NOT NULL,
    flag_procesada BIT NOT NULL,
    FOREIGN KEY (IdCarga) REFERENCES dbo.CargaOperacionesXML(IdCarga)
);
GO

/* =========================================
   3. TABLAS DE SEGUNDO NIVEL
   ========================================= */

CREATE TABLE dbo.Cuenta (
    IdCuenta INT IDENTITY(1,1) PRIMARY KEY,
    NumeroCuenta VARCHAR(32) NOT NULL UNIQUE,
    IdPersonaDueno INT NOT NULL,
    IdTipoCuenta INT NOT NULL,
    FechaCreacion DATE NOT NULL,
    Saldo DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (IdPersonaDueno) REFERENCES dbo.Persona(IdPersona),
    FOREIGN KEY (IdTipoCuenta) REFERENCES dbo.TipoCuentaAhorro(Id)
);
GO

CREATE TABLE dbo.Usuario (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    [User] VARCHAR(64) NOT NULL UNIQUE,
    Pass VARCHAR(255) NOT NULL,
    EsAdministrador BIT NOT NULL,
    IdPersona INT NOT NULL,
    FOREIGN KEY (IdPersona) REFERENCES dbo.Persona(IdPersona)
);
GO

/* =========================================
   4. TABLAS DE TERCER NIVEL
   ========================================= */

CREATE TABLE dbo.Beneficiario (
    IdBeneficiario INT IDENTITY(1,1) PRIMARY KEY,
    IdCuenta INT NOT NULL,
    IdPersona INT NOT NULL,
    IdParentezco INT NOT NULL,
    Porcentaje INT NOT NULL,
    Activo BIT NOT NULL,
    FechaDesactivacion DATE NULL,
    FOREIGN KEY (IdCuenta) REFERENCES dbo.Cuenta(IdCuenta),
    FOREIGN KEY (IdPersona) REFERENCES dbo.Persona(IdPersona),
    FOREIGN KEY (IdParentezco) REFERENCES dbo.Parentezco(Id)
);
GO

CREATE TABLE dbo.UsuarioCuenta (
    IdUsuarioCuenta INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    IdCuenta INT NOT NULL,
    FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuario(IdUsuario),
    FOREIGN KEY (IdCuenta) REFERENCES dbo.Cuenta(IdCuenta)
);
GO

CREATE TABLE dbo.Bitacora (
    IdBitacora BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    IdTipoOperacion INT NOT NULL,
    IP VARCHAR(64) NULL,
    JsonAntes NVARCHAR(MAX) NULL,
    JsonDespues NVARCHAR(MAX) NULL,
    FechaHora DATETIME NOT NULL,
    FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuario(IdUsuario),
    FOREIGN KEY (IdTipoOperacion) REFERENCES dbo.TipoOperacion(Id)
);
GO

CREATE TABLE dbo.EstadoDeCuenta (
    IdEstadoCuenta INT IDENTITY(1,1) PRIMARY KEY,
    IdCuenta INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    SaldoInicial DECIMAL(18,2) NOT NULL,
    SaldoMinimo DECIMAL(18,2) NOT NULL,
    SaldoFinal DECIMAL(18,2) NOT NULL,
    InteresesAcumulados DECIMAL(18,2) NOT NULL,
    CantidadRetiros INT NOT NULL,
    CantidadDepositos INT NOT NULL,
    CantidadSinpeEntrantes INT NOT NULL,
    CantidadSinpeSalientes INT NOT NULL,
    CantidadRetirosATM INT NOT NULL,
    CantidadRetirosHumano INT NOT NULL,
    CantidadDepositosATM INT NOT NULL,
    CantidadDepositosHumano INT NOT NULL,
    Cerrado BIT NOT NULL,
    FOREIGN KEY (IdCuenta) REFERENCES dbo.Cuenta(IdCuenta)
);
GO

/* =========================================
   5. TABLAS DE CUARTO Y QUINTO NIVEL
   ========================================= */

CREATE TABLE dbo.Movimiento (
    IdMovimiento BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdEstadoCuenta INT NOT NULL,
    IdTipoMovimiento INT NOT NULL,
    Fecha DATETIME NOT NULL,
    Monto DECIMAL(18,2) NOT NULL,
    NuevoSaldo DECIMAL(18,2) NOT NULL,
    Descripcion VARCHAR(255) NOT NULL,
    IdOperacionXML INT NULL,
    IdMovimientoOrigen BIGINT NULL,
    FOREIGN KEY (IdEstadoCuenta) REFERENCES dbo.EstadoDeCuenta(IdEstadoCuenta),
    FOREIGN KEY (IdTipoMovimiento) REFERENCES dbo.TipoMovimiento(Id),
    FOREIGN KEY (IdOperacionXML) REFERENCES dbo.OperacionXML(IdOperacionXML),
    FOREIGN KEY (IdMovimientoOrigen) REFERENCES dbo.Movimiento(IdMovimiento)
);
GO

CREATE TABLE dbo.Comprobante (
    IdComprobante BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdMovimiento BIGINT NOT NULL,
    FechaEmision DATETIME NOT NULL,
    Detalle VARCHAR(MAX) NOT NULL,
    FOREIGN KEY (IdMovimiento) REFERENCES dbo.Movimiento(IdMovimiento)
);
GO