
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

---------------------------------------------------------------------------------------------------------------
--FUNCIONES DE LIMPIEZA DE DATOS
---------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

-- Limpieza de Texto

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

SELECT *
FROM Empleados;

-- Hacemos cambios en los Nombres de Columna de Español a Ingles

BEGIN TRANSACTION;

EXEC sp_rename 'Empleados.EmpleadoID', 'EmployeeID';

EXEC sp_rename 'Empleados.NombreCompleto', 'FullName';

EXEC sp_rename 'Empleados.Departamento', 'Department';

EXEC sp_rename 'Empleados.SalarioMensual', 'Salary';

EXEC sp_rename 'Empleados.FechaIngreso', 'EntryDate';

ROLLBACK;

COMMIT;

-- 1er Ejemplo

SELECT FullName,
       TRIM(REPLACE(REPLACE(FullName, '  ANDRES RODRIGUEZ', 'Andres Rodriguez'), '@', 'a')) AS Nombre_Limpio --TRIM -> Quita espacios en blanco al principio y al final
FROM Empleados;

-- 2do Ejemplo

SELECT Department,
       REPLACE(REPLACE(Department, 'CONTABILIDAD', 'Contabilidad'), 'ventas', 'Ventas') AS DepartamentoCorrecto --REPLACE -> Cambia un texto por otro
FROM Empleados;

-- 3er Ejemplo

SELECT FullName,
       TRANSLATE(TRANSLATE(FullName, 'é', 'e'), '@', 'a') AS CambioCaracterEspecial --TRANSLATE -> Cambia varios caracteres de una vez
FROM Empleados;

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

-- Conversion y Validacion

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

-- Paso de verificación: ¿Cuántas filas se afectaron?
SELECT * 
FROM dbo.Empleados;

BEGIN TRANSACTION; -- Iniciamos el "modo prueba"

-- Si se comete algun error:
ROLLBACK; -- Deshace todo y vuelve al estado inicial

-- Si todo está bien:
COMMIT; -- Guarda los cambios permanentemente


---------------------------------------------------------------------------------------------------------------

-- Limpieza de Datos Completa Tabla Empleados

---------------------------------------------------------------------------------------------------------------

UPDATE Empleados
SET FullName = TRIM(REPLACE(REPLACE(FullName, '  ANDRES RODRIGUEZ', 'Andres Rodriguez'), '@', 'a'));

UPDATE Empleados
SET FullName = REPLACE(ISNULL(REPLACE(FullName, 'JUAN RIVAS', 'Juan Rivas'), 'Null'), 'é', 'e');

UPDATE Empleados
SET FullName = REPLACE(FullName, 'Null', 'Por Asignar');

UPDATE Empleados
SET Department = REPLACE(REPLACE(Department, 'CONTABILIDAD', 'Contabilidad'), 'ventas', 'Ventas');

UPDATE Empleados
SET Department = 'IT'
WHERE Department = 'SISTEMAS';

UPDATE Empleados
SET Salary = ISNULL(TRY_CAST(Salary AS DECIMAL(10,2)), 0); 

UPDATE Empleados
SET EntryDate = REPLACE(REPLACE(EntryDate, '02/20/2024', '2024-02-20'), '15-04-2024', '2024-04-15');

UPDATE Empleados
SET Email = ISNULL(REPLACE(REPLACE(TRY_CAST(Email AS VARCHAR(100)), 'm.lopez@gmail.com', 'mlopez@empresa.com'), 'andres@empresa.com', 'arodriguez@empresa.com'),'lsanz@empresa.com');

WITH Limpieza_Duplicados AS(
   SELECT EmployeeID,
          FullName,
          ROW_NUMBER() OVER(PARTITION BY EmployeeID, FullName, Department, EntryDate, Email ORDER BY EmployeeID) AS NumeroFila
   FROM Empleados
)
DELETE FROM Limpieza_Duplicados
WHERE NumeroFila > 1;

SELECT * 
FROM dbo.Empleados;

---------------------------------------------------------------------------------------------------------------

-- Ranking Salarios x Departamento

---------------------------------------------------------------------------------------------------------------

-- Cambiamos de VARCHAR a DECIMAL(Esto nos permitira hacer Funciones Agregadas en un Futuro con esta tabla a partir de su Columna Salary)

ALTER TABLE Empleados
ALTER COLUMN Salary DECIMAL(10,2);


-- Total Ranking x Depto

WITH SalarioporDepartamento AS(
   SELECT Department,
          SUM(Salary) AS TotalxDepto
   FROM Empleados
   GROUP BY Department
)
SELECT Department,
       TotalxDepto,
       ROW_NUMBER() OVER(ORDER BY TotalxDepto DESC) AS RankingxDepto
FROM SalarioporDepartamento;

