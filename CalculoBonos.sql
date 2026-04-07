USE CTEs;

-- Tabla de Vendedores
CREATE TABLE dbo.Vendedores (
    VendedorID INT PRIMARY KEY,
    Nombre VARCHAR(50),
    Ciudad VARCHAR(50)
);

-- Tabla de Ventas (Transaccional)
CREATE TABLE dbo.Ventas (
    VentaID INT PRIMARY KEY,
    VendedorID INT,
    Monto DECIMAL(10,2),
    Fecha DATE
);

-- Insertar Datos
INSERT INTO dbo.Vendedores 
VALUES 
(1, 'Carlos Rivas', 'Madrid'), 
(2, 'Elena Sanz', 'Barcelona'), 
(3, 'Mario Gil', 'Madrid');

INSERT INTO dbo.Ventas 
VALUES 
(1, 1, 5000.00, '2026-03-01'), 
(2, 1, 3000.00, '2026-03-05'),
(3, 2, 9000.00, '2026-03-02'), 
(4, 3, 2000.00, '2026-03-10'),
(5, 3, 1500.00, '2026-03-12'), 
(6, 2, 4000.00, '2026-03-15');
GO

---------------------------------------------------------------------------------------------------------------
--View de ambas tablas
---------------------------------------------------------------------------------------------------------------

SELECT *
FROM Vendedores;

SELECT *
FROM Ventas;


---------------------------------------------------------------------------------------------------------------
--CTEs Anidados:

--Sumar las ventas totales por vendedor (Limpieza/Agregación).

--Calcular el porcentaje de participacion en el total de ventas de toda la empresa (Referencia).

--Identificar quiénes superan el promedio y calcularles una comisión del 10% (Lógica de Negocio).

---------------------------------------------------------------------------------------------------------------

WITH VentasPorVendedor AS (
    -- CTE 1: Agregamos las ventas brutas
    SELECT 
        VendedorID, 
        SUM(Monto) AS TotalVendido
    FROM Ventas
    GROUP BY VendedorID
),
VentasGenerales AS(
    SELECT 
        SUM(TotalVendido) AS TotalGeneral
    FROM VentasPorVendedor
),
MetricasGlobales AS (
    -- CTE 2: Basada en la CTE 1, sacamos el promedio de los totales
    SELECT AVG(TotalVendido) AS PromedioEmpresa 
    FROM VentasPorVendedor
)
-- Reporte Final: Aplicamos el CAST y el formato contable
SELECT 
    vend.Nombre,
    vend.Ciudad,
    CAST(vv.TotalVendido AS DECIMAL(8,0)) AS VentasTotales,
    CAST(mg.PromedioEmpresa AS DECIMAL(10,2)) AS PromedioVendedor,
    CAST((vv.TotalVendido / vg.TotalGeneral) * 100 AS DECIMAL(8,2)) AS PorcentajeParticipacion,
    CAST(vv.TotalVendido * 0.10 AS DECIMAL(8,0)) AS BonoComision
FROM Vendedores vend
JOIN VentasPorVendedor vv
  ON vend.VendedorID = vv.VendedorID
CROSS JOIN MetricasGlobales mg
CROSS JOIN VentasGenerales vg
ORDER BY BonoComision;