CREATE DATABASE PagosVSFacturacion;

CREATE TABLE Facturas (
    FacturaID INT,
    ClienteNombre VARCHAR(100),
    FechaEmision VARCHAR(50), -- Formatos mixtos para limpiar
    MontoBruto VARCHAR(50),    -- Algunos tienen texto o nulos
    Estado VARCHAR(20)
);

-- Script para insertar 100 filas (Ejemplo de las primeras 10 con errores)
INSERT INTO Facturas (FacturaID, ClienteNombre, FechaEmision, MontoBruto, Estado)
VALUES 
(1001, '  Corporacion Delta ', '2024-01-15', '4500.00', 'Pagada'),
(1001, '  Corporacion Delta ', '2024-01-15', '4500.00', 'Pagada'), -- DUPLICADO
(1002, 'Inversiones Alpha', '02/20/2024', 'ERROR', 'Pendiente'),     -- ERROR DE DATO
(1003, 'Suministros Beta', '2024-03-01', NULL, 'Cancelada'),         -- NULO
(1004, ' Garcia & Asociados', '15-03-2024', '1250.75', 'Pagada'),    -- ESPACIOS
(1005, 'TecnoMundo SA', '2024-04-10', '3200.00', 'Pendiente'),
(1006, 'Delta Corp', '2024-04-12', '1500.00', 'Pagada'),             -- CLIENTE SIMILAR A ID 1001
(1007, NULL, '2024-05-01', '800.00', 'Pendiente'),                   -- NOMBRE NULO
(1008, 'Distribuidora Norte', '05/15/2024', '2100.50', 'Pagada'),
(1009, 'Consultoria Integral', '2024-06-20', '5000.00', 'Pendiente');

-- (Para completar las 100, puedes repetir el patrón o usar una herramienta como Mockaroo)

CREATE TABLE Pagos (
    PagoID INT PRIMARY KEY IDENTITY(1,1),
    ReferenciaFactura INT, -- Relacionado con FacturaID
    FechaPago VARCHAR(50),
    MontoPagado DECIMAL(18,2),
    MetodoPago VARCHAR(50)
);

INSERT INTO Pagos (ReferenciaFactura, FechaPago, MontoPagado, MetodoPago)
VALUES 
(1001, '2024-01-20', 4500.00, 'Transferencia'),
(1004, '2024-03-18', 1250.75, 'Cheque'),
(1006, '2024-04-15', 1500.00, 'Transferencia'),
(9999, '2024-04-20', 500.00, 'Efectivo'), -- PAGO SIN FACTURA (Error de conciliación)
(1008, '2024-05-20', 2100.50, 'Tarjeta'),
(1010, '2024-06-25', 1000.00, 'Transferencia'); -- FACTURA QUE NO ESTÁ EN EL DATASET 1


-- Limpieza de Datos Tabla Facturas

SELECT *
FROM Facturas;

-- UPDATE COLUMNA CLIENTE NOMBRE 

SELECT ClienteNombre,
       ISNULL(TRIM(ClienteNombre), 'N/A') AS Correciones_NomCliente -- ISNULL + TRIM Para remover espacios en blanco y corregir nulos y asignar un valor fijo
FROM Facturas;

BEGIN TRANSACTION;
UPDATE Facturas
SET ClienteNombre = ISNULL(TRIM(ClienteNombre), 'N/A');

ROLLBACK;

COMMIT;

-- UPDATE COLUMNA Fecha Emision

SELECT FechaEmision,
       ISNULL(TRY_CAST(FechaEmision AS DATE), '2024-03-15') AS FormatoFecha_Correcto -- ISNULL + TRY_CAST Permite cambiar el formato de texto a fecha estandar, adicional ISNULL nos permite sustituir la fecha con formato por error a estandar
FROM Facturas
ORDER BY FormatoFecha_Correcto;

BEGIN TRANSACTION;
UPDATE Facturas
SET FechaEmision = ISNULL(TRY_CAST(FechaEmision AS DATE), '2024-03-15');

ROLLBACK;

ALTER TABLE Facturas
ALTER COLUMN FechaEmision DATE; -- Despues de cambiar el formato de los datos, ya se puede declarar la columna justo por el tipo de datos que la contiene

COMMIT;

-- UPDATE COLUMNA Monto Bruto

SELECT MontoBruto,
       ISNULL(TRY_CAST(MontoBruto AS DECIMAL(10,2)), 0) AS FormatoMonto_Correcto --ISNULL + TRY_CAST combinan a la perfeccion cuando se trata de valores Nulos y numericos en formato de texto
FROM Facturas;

BEGIN TRANSACTION;
UPDATE Facturas
SET MontoBruto = ISNULL(TRY_CAST(MontoBruto AS DECIMAL(10,2)), 0);

ROLLBACK;

ALTER TABLE Facturas
ALTER COLUMN MontoBruto DECIMAL(10,2); -- Despues de cambiar el formato de los datos, ya se puede declarar la columna justo por el tipo de datos que la contiene

COMMIT;

-- UPDATE COLUMNA CLIENTE NOMBRE con Duplicados

WITH Limpieza_Duplicados AS(
   SELECT FacturaID,
          ClienteNombre,
          ROW_NUMBER() OVER(PARTITION BY FacturaID, ClienteNombre, FechaEmision, MontoBruto, Estado ORDER BY FacturaID) AS NumeroFila -- Se divide por medio del PARTITION BY las columnas duplicadas en filas individuales, para poder eliminar una de la misma forma
   FROM Facturas
)
DELETE FROM Limpieza_Duplicados -- Gracias al CTE creado, podemos eliminar por individual filas duplicadas en la tabla facturas
WHERE NumeroFila > 1;

SELECT *
FROM Facturas; -- A raiz de este Query podemos corroborar que la tabla facturas ya esta completamente lista para explorar sus datos limpios

-- Limpieza de Datos Tabla Pagos

SELECT *
FROM Pagos;

BEGIN TRANSACTION;

ALTER TABLE Pagos
ALTER COLUMN FechaPago DATE;

COMMIT;

-- Exploracion de Datos Pagos vs Facturacion

SELECT *
FROM Facturas;

SELECT *
FROM Pagos;

-- 1. Conciliación: Facturas "Pagadas" con respaldo bancario

SELECT 
    f.FacturaID, 
    f.ClienteNombre, 
    f.MontoBruto, 
    f.Estado,
    p.PagoID AS ID_Pago_Banco -- Si sale NULL, hay una inconsistencia
FROM Facturas f
JOIN Pagos p ON f.FacturaID = p.ReferenciaFactura
WHERE f.Estado = 'Pagada' OR p.PagoID IS NOT NULL;

-- 2. Análisis de Cartera Vencida (Aging Report)

SELECT 
    FacturaID,
    ClienteNombre,
    FechaEmision,
    Estado,
    -- Si está pagada, días hasta el pago. Si no, días hasta hoy.
    DATEDIFF(DAY, FechaEmision, GETDATE()) AS Dias_Transcurridos,
    CASE 
        WHEN DATEDIFF(DAY, FechaEmision, GETDATE()) > 90 THEN 'Crítico (+90 días)'
        WHEN DATEDIFF(DAY, FechaEmision, GETDATE()) > 30 THEN 'Vencido (+30 días)'
        ELSE 'Corriente'
    END AS Categoria_Vencimiento
FROM Facturas
WHERE Estado = 'Pendiente';


-- 3. Resumen Ejecutivo (KPIs Financieros)

SELECT 
    SUM(CAST(MontoBruto AS DECIMAL(18,2))) AS Total_Facturado,
    (SELECT SUM(MontoPagado) FROM Pagos) AS Total_Recaudado,
    -- Porcentaje de Morosidad
    CAST(
        SUM(CASE WHEN Estado = 'Pendiente' THEN CAST(MontoBruto AS DECIMAL(18,2)) ELSE 0 END) / 
        SUM(CAST(MontoBruto AS DECIMAL(18,2))) * 100 
    AS DECIMAL(10,2)) AS Porcentaje_Morosidad
FROM Facturas;

-- 4. Top 5 Clientes por Facturación

SELECT TOP 5
    ClienteNombre,
    SUM(CAST(MontoBruto AS DECIMAL(18,2))) AS Volumen_Ventas,
    COUNT(FacturaID) AS Cantidad_Facturas
FROM Facturas
GROUP BY ClienteNombre
ORDER BY Volumen_Ventas DESC;
       
       