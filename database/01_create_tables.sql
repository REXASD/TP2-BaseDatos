/* =========================================
   1. TIPO DE MONEDA
   ========================================= */
CREATE TABLE dbo.TipoMoneda(
    Id      INT PRIMARY KEY NOT NULL,
    Nombre  VARCHAR(128) NOT NULL,
    Simbolo NVARCHAR(2) NOT NULL
);
GO

/* =========================================
   2. TIPO DE DOCUMENTO DE IDENTIDAD
   ========================================= */
CREATE TABLE dbo.TipoDocuIdentidad(
    Id     INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(128) NOT NULL
);
GO

/* =========================================
   3. PARENTEZCO
   ========================================= */
CREATE TABLE dbo.Parentezco(
    Id     INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(20) NOT NULL
);
GO

/* =========================================
   4. TIPO DE CUENTA DE AHORRO
   ========================================= */
CREATE TABLE dbo.TipoCuentaAhorro(
    Id                   INT PRIMARY KEY NOT NULL,
    Nombre               VARCHAR(128) NOT NULL,
    IdTipoMoneda         INT NOT NULL,
    SaldoMinimo          DECIMAL(18,2) NOT NULL,
    MultaSaldoMin        DECIMAL(18,2) NOT NULL,
    CargoAnual           DECIMAL(18,2) NOT NULL,
    NumRetirosHumano     INT NOT NULL,
    NumRetirosAutomatico INT NOT NULL,
    ComisionHumano       DECIMAL(18,2) NOT NULL,
    ComisionAutomatico   DECIMAL(18,2) NOT NULL,
    Interes              DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (IdTipoMoneda) REFERENCES dbo.TipoMoneda(Id)
);
GO

/* =========================================
   5. TIPO DE OPERACIONES
   ========================================= */
CREATE TABLE dbo.TipoOperaciones(
    Id     INT PRIMARY KEY NOT NULL,
    Nombre VARCHAR(128) NOT NULL
);
GO

/* =========================================
   6. PERSONA
   ========================================= */
CREATE TABLE dbo.Persona (
    IdPersona               INT IDENTITY(1,1) PRIMARY KEY,
    IdTipoDocuIdentidad     INT NOT NULL,
    ValorDocumentoIdentidad VARCHAR(64) NOT NULL UNIQUE,
    Nombre                  VARCHAR(64) NOT NULL,
    FechaNacimiento         DATE NOT NULL,
    Email                   VARCHAR(100) NULL,
    Telefono1               VARCHAR(20) NOT NULL,
    Telefono2               VARCHAR(20) NOT NULL,
    FOREIGN KEY (IdTipoDocuIdentidad) REFERENCES dbo.TipoDocuIdentidad(Id)
);
GO

/* =========================================
   7. CUENTA
   ========================================= */
CREATE TABLE dbo.Cuenta (
    IdCuenta       INT IDENTITY(1,1) PRIMARY KEY,
    NumeroCuenta   VARCHAR(32) NOT NULL UNIQUE,
    IdPersonaDueno INT NOT NULL,
    IdTipoCuenta   INT NOT NULL,
    FechaCreacion  DATE NOT NULL,
    Saldo          DECIMAL(18,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (IdPersonaDueno) REFERENCES dbo.Persona(IdPersona),
    FOREIGN KEY (IdTipoCuenta)   REFERENCES dbo.TipoCuentaAhorro(Id)
);
GO

/* =========================================
   8. BENEFICIARIO
   ========================================= */
CREATE TABLE dbo.Beneficiario (
    IdBeneficiario     INT IDENTITY(1,1) PRIMARY KEY,
    IdCuenta           INT NOT NULL,
    IdPersona          INT NOT NULL,
    IdParentezco       INT NOT NULL,
    Porcentaje         INT NOT NULL CHECK (Porcentaje BETWEEN 0 AND 100),
    Activo             BIT NOT NULL DEFAULT 1,
    FechaDesactivacion DATE NULL,
    FOREIGN KEY (IdCuenta)     REFERENCES dbo.Cuenta(IdCuenta),
    FOREIGN KEY (IdPersona)    REFERENCES dbo.Persona(IdPersona),
    FOREIGN KEY (IdParentezco) REFERENCES dbo.Parentezco(Id)
);
GO

/* =========================================
   9. ESTADO DE CUENTA
   ========================================= */
CREATE TABLE dbo.EstadoDeCuenta (
    IdEstadoCuenta         INT IDENTITY(1,1) PRIMARY KEY,
    IdCuenta               INT NOT NULL,
    FechaInicio            DATE NOT NULL,
    FechaFin               DATE NOT NULL,
    SaldoInicial           DECIMAL(18,2) NOT NULL,
    SaldoMinimo            DECIMAL(18,2) NOT NULL DEFAULT 0,
    SaldoFinal             DECIMAL(18,2) NOT NULL,
    InteresesAcumulados    DECIMAL(18,2) NOT NULL DEFAULT 0,
    CantidadRetiros        INT NOT NULL DEFAULT 0,
    CantidadDepositos      INT NOT NULL DEFAULT 0,
    CantidadSinpeEntrantes INT NOT NULL DEFAULT 0,
    CantidadSinpeSalientes INT NOT NULL DEFAULT 0,
    FOREIGN KEY (IdCuenta) REFERENCES dbo.Cuenta(IdCuenta)
);
GO

/* =========================================
   10. USUARIO
   ========================================= */
CREATE TABLE dbo.Usuario (
    IdUsuario       INT IDENTITY(1,1) PRIMARY KEY,
    [User]          VARCHAR(64) NOT NULL UNIQUE,
    Pass            VARCHAR(255) NOT NULL,
    EsAdministrador BIT NOT NULL DEFAULT 0,
    IdPersona       INT NOT NULL,
    FOREIGN KEY (IdPersona) REFERENCES dbo.Persona(IdPersona)
);
GO

/* =========================================
   11. USUARIO - CUENTA
   ========================================= */
CREATE TABLE dbo.UsuarioCuenta (
    IdUsuarioCuenta INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario       INT NOT NULL,
    IdCuenta        INT NOT NULL,
    FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuario(IdUsuario),
    FOREIGN KEY (IdCuenta)  REFERENCES dbo.Cuenta(IdCuenta)
);
GO

/* =========================================
   12. BITACORA
   ========================================= */
CREATE TABLE dbo.Bitacora (
    IdBitacora      BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario       INT NOT NULL,
    IdTipoOperacion INT NOT NULL,
    IP              VARCHAR(64) NULL,
    JsonAntes       NVARCHAR(MAX) NULL,
    JsonDespues     NVARCHAR(MAX) NULL,
    FechaHora       DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (IdUsuario)       REFERENCES dbo.Usuario(IdUsuario),
    FOREIGN KEY (IdTipoOperacion) REFERENCES dbo.TipoOperaciones(Id)
);
GO