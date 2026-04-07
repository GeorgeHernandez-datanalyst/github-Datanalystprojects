--CTEs Example

CREATE DATABASE CTEs


-- Tabla Maestra: Departamentos
CREATE TABLE Departamentos (
    DeptoID INT PRIMARY KEY,
    NombreDepto VARCHAR(50)
);

-- Tabla de Detalle: Gastos Operativos
CREATE TABLE Gastos (
    GastoID INT PRIMARY KEY,
    DeptoID INT FOREIGN KEY (DeptoID) REFERENCES Departamentos(DeptoID),
    Monto DECIMAL(10,2),
    Fecha_Gasto DATE
);

-- Inserción de datos de práctica
INSERT INTO Departamentos 
VALUES 
(1, 'IT'), 
(2, 'Ventas'), 
(3, 'Recursos Humanos');

INSERT INTO Gastos 
VALUES 
(101, 1, 1500.00, '2026-01-10'),
(102, 2, 800.00,  '2026-01-12'),
(103, 1, 2200.00, '2026-02-05'),
(104, 3, 500.00,  '2026-02-15'),
(105, 2, 1200.00, '2026-02-20');

--primer consulta

SELECT *
FROM Departamentos;

SELECT *
FROM Gastos;

---------------------------------------------------------------------------------------------------------------

--CTEs Anidados - resumen de gastos x departmento:

--1.1 Mostrar los Gastos totales por departamento.

--1.2 Calcular el porcentaje de participacion por departamento de los Gastos de toda la empresa (Referencia).

--1.3 Identificar quiénes superan el promedio del 30% en Gastos permitidos por la empresa.

---------------------------------------------------------------------------------------------------------------
--1.1 Mostrar los Gastos totales por departamento

--Tabla GastosporDepto creada a partir de un CTE
WITH GastosporDepto AS(
SELECT DeptoID,
       CAST(SUM(Monto) AS DECIMAL(8,0)) AS TotalporDepto
FROM Gastos
GROUP BY DeptoID
),
--Tabla TotalGastos creada a partir de un CTE
TotalGastos AS(
SELECT 
       SUM(TotalporDepto) AS TotalGeneral
FROM GastosporDepto
)
--Union de Tablas Departamentos + GastosporDepto + TotalGastos
SELECT d.NombreDepto,
       gd.TotalporDepto,
       CAST((gd.TotalporDepto / tg.TotalGeneral) * 100 AS DECIMAL(8,0)) AS PorcentajeParticipacion
FROM Departamentos d
CROSS JOIN TotalGastos tg
JOIN GastosporDepto gd
  ON d.DeptoId = gd.DeptoId
ORDER BY PorcentajeParticipacion DESC;