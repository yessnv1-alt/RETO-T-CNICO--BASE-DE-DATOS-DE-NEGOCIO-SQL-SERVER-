-- ==========================================================================================
-- 1. CREACIÓN DE LA ESTRUCTURA (Base de Datos y Tablas)
-- ==========================================================================================
CREATE DATABASE GestionNegocio;
GO
USE GestionNegocio;
GO

-- Tabla para el registro de auditoría (Triggers)
CREATE TABLE Auditoria (
    IdLog INT PRIMARY KEY IDENTITY(1,1),
    Tabla VARCHAR(50),
    Accion VARCHAR(20),
    Fecha DATETIME DEFAULT GETDATE(),
    Usuario VARCHAR(50) DEFAULT SYSTEM_USER
);

CREATE TABLE Producto (
    IdProducto INT PRIMARY KEY IDENTITY(1,1),
    Nombre VARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL CHECK (Precio > 0),
    Stock INT NOT NULL CHECK (Stock >= 0)
);

CREATE TABLE Pedido (
    IdPedido INT PRIMARY KEY IDENTITY(1,1),
    Fecha DATETIME DEFAULT GETDATE(),
    Cliente VARCHAR(100) NOT NULL,
    IdProducto INT FOREIGN KEY REFERENCES Producto(IdProducto),
    Cantidad INT NOT NULL CHECK (Cantidad > 0)
);

CREATE TABLE Despacho (
    IdDespacho INT PRIMARY KEY IDENTITY(1,1),
    IdPedido INT FOREIGN KEY REFERENCES Pedido(IdPedido),
    FechaDespacho DATETIME DEFAULT GETDATE(),
    Estado VARCHAR(20) DEFAULT 'Pendiente'
);
GO

-- ==========================================================================================
-- 2. INSERCIÓN DE DATOS INICIALES (Mínimo 5 registros)
-- ==========================================================================================
INSERT INTO Producto (Nombre, Precio, Stock) VALUES 
('Laptop Dell', 1200.00, 10), 
('Mouse Pro', 25.00, 50), 
('Teclado Mecanico', 80.00, 30), 
('Monitor 4K', 400.00, 15), 
('Cable HDMI', 10.00, 100);

INSERT INTO Pedido (Cliente, IdProducto, Cantidad) VALUES 
('Juan Perez', 1, 1), 
('Maria Lopez', 2, 5), 
('Carlos Ruiz', 1, 2), 
('Ana Gomez', 4, 1), 
('Luis Sosa', 3, 2);

INSERT INTO Despacho (IdPedido, Estado) VALUES 
(1, 'Enviado'), 
(2, 'Pendiente'), 
(3, 'Entregado'), 
(4, 'Pendiente'), 
(5, 'Enviado');
GO

-- ==========================================================================================
-- 3. TRIGGERS DE AUDITORÍA
-- ==========================================================================================
CREATE TRIGGER trg_AuditoriaInsert ON Producto AFTER INSERT AS
BEGIN
    INSERT INTO Auditoria (Tabla, Accion) VALUES ('Producto', 'INSERT');
END;
GO

CREATE TRIGGER trg_AuditoriaUpdate ON Producto AFTER UPDATE AS
BEGIN
    INSERT INTO Auditoria (Tabla, Accion) VALUES ('Producto', 'UPDATE');
END;
GO

CREATE TRIGGER trg_AuditoriaDelete ON Producto AFTER DELETE AS
BEGIN
    INSERT INTO Auditoria (Tabla, Accion) VALUES ('Producto', 'DELETE');
END;
GO

-- ==========================================================================================
-- 4. STORED PROCEDURES (CRUD con Validaciones)
-- ==========================================================================================
CREATE PROCEDURE sp_InsertarProducto 
    @Nombre VARCHAR(100), @Precio DECIMAL(10,2), @Stock INT
AS
BEGIN
    IF @Stock < 0 
        THROW 50000, 'Error: El stock no puede ser negativo', 1;
    ELSE
        INSERT INTO Producto (Nombre, Precio, Stock) VALUES (@Nombre, @Precio, @Stock);
END;
GO

CREATE PROCEDURE sp_InsertarPedido
    @Cliente VARCHAR(100), @IdProd INT, @Cant INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Producto WHERE IdProducto = @IdProd)
        THROW 50000, 'Error: El producto no existe', 1;
    ELSE
        INSERT INTO Pedido (Cliente, IdProducto, Cantidad) VALUES (@Cliente, @IdProd, @Cant);
END;
GO

-- ==========================================================================================
-- 5. VISTAS (Reportes descriptivos)
-- ==========================================================================================
CREATE VIEW vw_ReporteGeneral AS
SELECT 
    Pe.Cliente,
    Pr.Nombre AS Producto,
    Pe.Cantidad,
    Pr.Precio AS PrecioUnitario,
    (Pe.Cantidad * Pr.Precio) AS TotalFacturado,
    ISNULL(De.Estado, 'Sin Despacho') AS EstadoDespacho
FROM Pedido Pe
JOIN Producto Pr ON Pe.IdProducto = Pr.IdProducto
LEFT JOIN Despacho De ON Pe.IdPedido = De.IdPedido;
GO

-- ==========================================================================================
-- 6. CONSULTAS DE PRUEBA (Para tus capturas de pantalla)
-- ==========================================================================================
-- Ver reporte general
SELECT * FROM vw_ReporteGeneral;

-- Probar Auditoría (Hacer un cambio)
UPDATE Producto SET Stock = 8 WHERE IdProducto = 1;

-- Ver si se registró el cambio en Auditoría
SELECT * FROM Auditoria;