-- Proyecto de Limpieza y Exploracion de Datos

CREATE TABLE dbo.Empleados (
    EmpleadoID INT,
    NombreCompleto VARCHAR(150),
    Departamento VARCHAR(50),
    SalarioMensual VARCHAR(50), -- Error: Guardado como texto
    FechaIngreso VARCHAR(50),   -- Error: Formatos mixtos (ISO, USA, Local)
    Email VARCHAR(100)
);

INSERT INTO dbo.Empleados VALUES 
(101, '  ANDRES RODRIGUEZ', 'CONTABILIDAD', '4500.00', '2024-01-15', 'andres@empresa.com'),
(101, '  ANDRES RODRIGUEZ', 'CONTABILIDAD', '4500.00', '2024-01-15', 'andres@empresa.com'), -- DUPLICADO EXACTO
(102, 'M@ria Lopez ', 'Contabilidad', '5200.50', '02/20/2024', 'm.lopez@gmail.com'), -- ESPACIO AL FINAL Y FECHA USA
(103, 'C@rlos Peréz', 'SISTEMAS', 'ERROR_SISTEMA', '2024-03-01', 'cperez@empresa.com'), -- TEXTO EN CAMPO NUMÉRICO
(104, 'Luci@ Sanz', 'ventas', '3800', '2024-03-15', NULL), -- DEPARTAMENTO EN MINÚSCULAS Y EMAIL NULO
(105, 'JUAN RIVAS', 'Ventas', '4100', '15-04-2024', 'jrivas@empresa.com'), -- FECHA EN FORMATO LOCAL
(106, NULL, 'SISTEMAS', '6000', '2024-05-01', 'admin_it@empresa.com'), -- NOMBRE NULO
(107, 'Roberto Gomez', 'Recursos Humanos', '3500.00', '2024-05-10', 'rgomez@empresa.com '); -- ESPACIO EN EMAIL

-- Consultamos la tabla para ver los valores insertados

SELECT *
FROM Empleados;

-- Cambiamos los nombres de columna(Opcional)

EXEC sp_rename 'Empleados.EmpleadoID', 'EmployeeId';

EXEC sp_rename 'Empleados.NombreCompleto', 'FullName';

EXEC sp_rename 'Empleados.Departamento', 'Department';

EXEC sp_rename 'Empleados.FechaIngreso', 'EntryDate';

EXEC sp_rename 'Empleados.SalarioMensual', 'Salary';

-- Revisamos los valores duplicados por Columna

SELECT EmployeeId,
       COUNT(EmployeeId) AS Duplicated_Items -- Duplicated Items in Column FullName
FROM Empleados
GROUP BY EmployeeId
HAVING COUNT(*) > 1;

SELECT FullName,
       COUNT(FullName) AS Duplicated_Items -- Duplicated Items in Column FullName
FROM Empleados
GROUP BY FullName
HAVING COUNT(*) > 1;

SELECT Email,
       COUNT(*) AS Duplicated_Items -- Duplicated Items in Column Email
FROM Empleados
GROUP BY Email
HAVING COUNT(*) > 1;

-- Revisamos valores nulos en la tabla por columna

SELECT COUNT(CASE WHEN FullName IS NULL THEN 1 END) AS Null_FullName,
       COUNT(CASE WHEN Email IS NULL THEN 1 END) AS Null_Email,
       COUNT(CASE WHEN EntryDate IS NULL THEN 1 END) AS Null_EntryDate,
       COUNT(CASE WHEN Salary IS NULL THEN 1 END) AS Null_Salary
FROM Empleados;

-- UPDATE a problemas de formato en columna FullName

SELECT FullName,
       TRIM(REPLACE(TRANSLATE(TRANSLATE(REPLACE(FullName, '  ANDRES RODRIGUEZ', 'Andres Rodriguez'), '@', 'a'), 'é', 'e'), 'JUAN RIVAS', 'Juan Rivas')) AS Formato_FullName
FROM Empleados;

SELECT FullName,
       ISNULL(FullName, 'Por Asignar') AS Manejo_Nulls 
FROM Empleados;

UPDATE Empleados
SET FullName = TRIM(REPLACE(TRANSLATE(TRANSLATE(REPLACE(FullName, '  ANDRES RODRIGUEZ', 'Andres Rodriguez'), '@', 'a'), 'é', 'e'), 'JUAN RIVAS', 'Juan Rivas'));

UPDATE Empleados
SET FullName = ISNULL(FullName, 'Por Asignar');

-- UPDATE a problemas de formato en columna Department

SELECT Department,
       REPLACE(REPLACE(REPLACE(Department, 'CONTABILIDAD', 'Contabilidad'), 'ventas', 'Ventas'), 'SISTEMAS', 'IT') AS Formato_Department
FROM Empleados;

UPDATE Empleados
SET Department = REPLACE(REPLACE(REPLACE(Department, 'CONTABILIDAD', 'Contabilidad'), 'ventas', 'Ventas'), 'SISTEMAS', 'IT')

-- UPDATE a problemas de formato en columna Salary

SELECT Salary,
       ISNULL(TRY_CAST(Salary AS DECIMAL(10,2)), 0) AS Formato_Valor_Salary 
FROM Empleados;

UPDATE Empleados
SET Salary = ISNULL(TRY_CAST(Salary AS DECIMAL(10,2)), 0);

-- Cambiamos de VARCHAR a DECIMAL(Esto nos permitira hacer Funciones Agregadas en un Futuro con esta tabla a partir de su Columna Salary)

ALTER TABLE Empleados
ALTER COLUMN Salary DECIMAL(10,2);

-- UPDATE a problemas de formato en columna EntryDate

SELECT EntryDate,
       ISNULL(TRY_CAST(EntryDate AS DATE), '2024-04-15') AS Formato_EntryDate 
FROM Empleados;

BEGIN TRANSACTION;
UPDATE Empleados
SET EntryDate = ISNULL(TRY_CAST(EntryDate AS DATE), '2024-04-15');

-- Cambiamos de VARCHAR a DATE(Esto nos permitira hacer ordenar la columna por Fecha)

ALTER TABLE Empleados
ALTER COLUMN EntryDate DATE;

-- UPDATE a problemas de formato en columna Email

SELECT Email,
       ISNULL(REPLACE(REPLACE(TRY_CAST(Email AS VARCHAR(100)), 'm.lopez@gmail.com', 'mlopez@empresa.com'), 'andres@empresa.com', 'arodriguez@empresa.com'),'lsanz@empresa.com') AS Formato_Email
FROM Empleados;

UPDATE Empleados
SET Email = ISNULL(REPLACE(REPLACE(TRY_CAST(Email AS VARCHAR(100)), 'm.lopez@gmail.com', 'mlopez@empresa.com'), 'andres@empresa.com', 'arodriguez@empresa.com'),'lsanz@empresa.com');

-- UPDATE a problemas con items duplicados de la tabla 

WITH Duplicated_Items AS( 
   SELECT EmployeeId,
          FullName,
          ROW_NUMBER() OVER(PARTITION BY EmployeeId, FullName, Department, Salary, EntryDate, Email ORDER BY EmployeeId) AS NumeroFila -- CTE 1: Particiona la columna para segmentar los datos duplicados por fila individual
   FROM Empleados
)
DELETE FROM Duplicated_Items -- Utilizamos DELETE + WHERE para borrar la filas duplicadas de la tabla Empleados
WHERE NumeroFila > 1;

SELECT *
FROM Empleados; -- Comprobamos todos los Updates y cambios hechos en la tabla

---------------------------------------------------------------------------------------------------------------

-- Ranking Salarios x Departamento

---------------------------------------------------------------------------------------------------------------

-- Total Ranking x Depto

WITH Salario_Departamento AS(
   SELECT Department,
          SUM(Salary) AS TotalxDepto
   FROM Empleados
   GROUP BY Department
),
Salario_Total_General AS(
   SELECT 
        SUM(TotalxDepto) AS TotalGeneral
   FROM Salario_Departamento
)
SELECT
       e.Department,
       sd.TotalxDepto,
       CAST((sd.TotalxDepto / stg.TotalGeneral) * 100 AS DECIMAL(10,0)) AS Pct_Gasto_Salarial 
FROM Empleados e
JOIN Salario_Departamento sd
CROSS JOIN Salario_Total_General stg
        ON e.Department = sd.Department;


