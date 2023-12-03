-- Funciones auxiliares

CREATE FUNCTION DATA_TEAM.Calcular_cuatri(@fecha smalldatetime)
RETURNS INT
AS
BEGIN
	DECLARE @cuatri INT
	SET @cuatri = CEILING((MONTH(@fecha) / 4.0))
	RETURN @cuatri
END
GO

CREATE FUNCTION DATA_TEAM.ObtenerRangoEtario(@fechaNacimiento DATE)
RETURNS INT
AS
BEGIN
    DECLARE @rangoEtario INT

    SELECT @rangoEtario = RANGO_ETARIO_ID
    FROM (
        SELECT RANGO_ETARIO_ID, CAST(EDAD_INICIO AS INT) AS EdadInicio, CAST(EDAD_FIN AS INT) AS EdadFin
        FROM DATA_TEAM.BI_D_RANGO_ETARIO
    ) AS Rangos
    WHERE DATEDIFF(YEAR, @fechaNacimiento, GETDATE()) >= EdadInicio AND DATEDIFF(YEAR, @fechaNacimiento, GETDATE()) < EdadFin

    RETURN @rangoEtario
END
GO

CREATE FUNCTION DATA_TEAM.ObtenerRangoMetros(@superficie numeric(18,2))
RETURNS INT
AS
BEGIN
    DECLARE @rangoMetros INT

    SELECT @rangoMetros = RANGO_METROS_ID
    FROM (
        SELECT RANGO_METROS_ID, RANGO_METROS_INICIO AS RangoInicio, RANGO_METROS_FIN AS RangoFin
        FROM DATA_TEAM.BI_D_RANGO_METROS
    ) AS Rangos
    WHERE @superficie >= RangoInicio AND @superficie < RangoFin

    RETURN @rangoMetros
END
GO


-- Creación de Tablas


-- *** TABLAS DIMENSIONALES ***

CREATE TABLE DATA_TEAM.BI_D_TIEMPO (
    TIEMPO_ANIO int NOT NULL,
    TIEMPO_MES int NOT NULL,
    TIEMPO_CUATRI int NOT NULL
)
GO

ALTER TABLE DATA_TEAM.BI_D_TIEMPO ADD CONSTRAINT PK_BI_D_TIEMPO PRIMARY KEY (
	TIEMPO_ANIO,
	TIEMPO_CUATRI,
	TIEMPO_MES
)

CREATE TABLE DATA_TEAM.BI_D_Provincia (
    PROVINCIA NVARCHAR(100) PRIMARY KEY,
);
GO

CREATE TABLE DATA_TEAM.BI_D_LOCALIDAD (
    LOCALIDAD_NOMBRE NVARCHAR(100) PRIMARY KEY,
    LOCALIDAD_PROVINCIA NVARCHAR(100) FOREIGN KEY REFERENCES DATA_TEAM.BI_D_PROVINCIA
)
GO

CREATE TABLE DATA_TEAM.BI_D_RANGO_ETARIO (
    RANGO_ETARIO_ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EDAD_INICIO decimal(18,0),
    EDAD_FIN decimal(18,0)
)
GO

CREATE TABLE DATA_TEAM.BI_D_TIPO_INMUEBLE (
    TIPO_INMUEBLE NVARCHAR(100) PRIMARY KEY
)
GO

CREATE TABLE DATA_TEAM.BI_D_TIPO_OPERACION (
    TIPO_OPERACION NVARCHAR(100) PRIMARY KEY
)
GO

CREATE TABLE DATA_TEAM.BI_D_RANGO_METROS (
    RANGO_METROS_ID int IDENTITY(1,1) PRIMARY KEY,
    RANGO_METROS_INICIO numeric(18,2),
    RANGO_METROS_FIN numeric(18,2)
)
GO

CREATE TABLE DATA_TEAM.BI_D_MONEDA (
    MONEDA NVARCHAR(100) PRIMARY KEY
)
GO

CREATE TABLE DATA_TEAM.BI_D_Sucursal (
    SUCURSAL_CODIGO NUMERIC(18,0) PRIMARY KEY,
    SUCURSAL_NOMBRE NVARCHAR(100),
    SUCURSAL_DIRECCION NVARCHAR(100),
    SUCURSAL_TELEFONO NVARCHAR(100),
);
GO

CREATE TABLE DATA_TEAM.BI_D_BARRIO ( 
    BARRIO_NOMBRE NVARCHAR(100) PRIMARY KEY,
	BARRIO_LOCALIDAD NVARCHAR(100) FOREIGN KEY REFERENCES DATA_TEAM.BI_D_Localidad
)
GO

CREATE TABLE DATA_TEAM.BI_D_AMBIENTES (
    AMBIENTES INT PRIMARY KEY
)
GO

-- *** TABLAS DE HECHOS ***

CREATE TABLE DATA_TEAM.BI_H_ANUNCIO (
    ANUNCIO_BARRIO NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_BARRIO,
    ANUNCIO_TIPO_INMUEBLE NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_INMUEBLE,
    ANUNCIO_MONEDA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_MONEDA,
    ANUNCIO_TIPO_OPERACION NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_OPERACION,
    ANUNCIO_RANGO_METROS int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_METROS,
    ANUNCIO_ANIO INT NOT NULL,
	ANUNCIO_CUATRI INT NOT NULL,
    ANUNCIO_MES INT NOT NULL,
    ANUNCIO_AMBIENTES INT NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_AMBIENTES,
    TOTAL_TIEMPO_ALTA decimal(12,2),
    TOTAL_PRECIO decimal(12,2)
)
GO
-- Agrego la Primary Key de la tabla de hechos, que se compone de todas sus dimensiones.
ALTER TABLE DATA_TEAM.BI_H_ANUNCIO ADD CONSTRAINT PK_BI_H_ANUNCIO PRIMARY KEY (
    ANUNCIO_BARRIO,
    ANUNCIO_TIPO_INMUEBLE,
    ANUNCIO_MONEDA,
    ANUNCIO_TIPO_OPERACION,
    ANUNCIO_RANGO_METROS,
    ANUNCIO_ANIO,
	ANUNCIO_CUATRI,
    ANUNCIO_MES,
    ANUNCIO_AMBIENTES
)

ALTER TABLE DATA_TEAM.BI_H_ANUNCIO ADD CONSTRAINT FK_BI_H_ANUNCIO_TIEMPO FOREIGN KEY(ANUNCIO_ANIO, ANUNCIO_CUATRI, ANUNCIO_MES) REFERENCES DATA_TEAM.BI_D_TIEMPO(TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)

CREATE TABLE DATA_TEAM.BI_H_VENTA (
    VENTA_SUCURSAL NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_BARRIO,
    VENTA_LOCALIDAD NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_LOCALIDAD,
    VENTA_RANGO_ETARIO int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_ETARIO,
    VENTA_TIPO_INMUEBLE NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_INMUEBLE,
	VENTA_TIPO_OPERACION NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_OPERACION,
    VENTA_MONEDA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_MONEDA,
    VENTA_RANGO_METROS int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_METROS,
    VENTA_ANIO INT NOT NULL,
    VENTA_CUATRI INT NOT NULL,
    VENTA_MES INT NOT NULL,
    TOTAL_VENTAS decimal(12,2),
    TOTAL_COMISION decimal(12,2),
    CANTIDAD_VENTAS decimal(12,0)
)
GO

ALTER TABLE DATA_TEAM.BI_H_VENTA ADD CONSTRAINT PK_BI_H_VENTA PRIMARY KEY (
    VENTA_SUCURSAL,
    VENTA_LOCALIDAD,
    VENTA_RANGO_ETARIO,
    VENTA_TIPO_INMUEBLE,
    VENTA_MONEDA,
    VENTA_RANGO_METROS,
    VENTA_ANIO,
    VENTA_CUATRI,
    VENTA_MES
)

ALTER TABLE DATA_TEAM.BI_H_VENTA ADD CONSTRAINT FK_BI_H_VENTA_TIEMPO FOREIGN KEY(VENTA_ANIO, VENTA_CUATRI, VENTA_MES) REFERENCES DATA_TEAM.BI_D_TIEMPO(TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)

CREATE TABLE DATA_TEAM.BI_H_ALQUILER (
    ALQUILER_SUCURSAL NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_BARRIO,
    ALQUILER_BARRIO NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_BARRIO,
    ALQUILER_RANGO_ETARIO int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_ETARIO,
    ALQUILER_MONEDA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_MONEDA,
    ALQUILER_TIPO_OPERACION NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_OPERACION,
    ALQUILER_ANIO INT NOT NULL,
    ALQUILER_CUATRI INT NOT NULL,
    ALQUILER_MES INT NOT NULL,
    TOTAL_PAGOS decimal(12,2),
    TOTAL_ALTAS_ALQUILER decimal(12,2),
    CANTIDAD_INCUMPLIMIENTOS decimal(12,0),
    TOTAL_INCREMENTO decimal(12,2)
)
GO

ALTER TABLE DATA_TEAM.BI_H_ALQUILER ADD CONSTRAINT PK_BI_H_ALQUILER PRIMARY KEY (
    ALQUILER_SUCURSAL,
    ALQUILER_BARRIO,
    ALQUILER_RANGO_ETARIO,
    ALQUILER_MONEDA,
    ALQUILER_TIPO_OPERACION,
    ALQUILER_ANIO,
    ALQUILER_CUATRI,
    ALQUILER_MES
);

ALTER TABLE DATA_TEAM.BI_H_ALQUILER ADD CONSTRAINT FK_BI_H_ALQUILER_TIEMPO FOREIGN KEY(ALQUILER_ANIO, ALQUILER_CUATRI, ALQUILER_MES) REFERENCES DATA_TEAM.BI_D_TIEMPO(TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)

-- *** MIGRACION DE TABLAS DIMENSIONALES ***

CREATE PROC DATA_TEAM.MIGRAR_D_PROVINCIA
AS
BEGIN
    INSERT INTO DATA_TEAM.BI_D_PROVINCIA(PROVINCIA)
	SELECT PROVINCIA FROM DATA_TEAM.Provincia
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_LOCALIDAD
AS
BEGIN
    INSERT INTO DATA_TEAM.BI_D_LOCALIDAD(LOCALIDAD_NOMBRE, LOCALIDAD_PROVINCIA)
    SELECT LOCALIDAD, LOCALIDAD_PROVINCIA FROM DATA_TEAM.LOCALIDAD
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_BARRIO
AS
BEGIN
    INSERT INTO DATA_TEAM.BI_D_BARRIO(BARRIO_NOMBRE, BARRIO_LOCALIDAD)
    SELECT BARRIO_NOMBRE, BARRIO_LOCALIDAD FROM DATA_TEAM.BARRIO
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_AMBIENTES
AS
BEGIN
	INSERT INTO DATA_TEAM.BI_D_AMBIENTES(AMBIENTES)
	SELECT CANT_AMBIENTES FROM DATA_TEAM.Cant_ambientes
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_MONEDA AS
BEGIN
	INSERT INTO DATA_TEAM.BI_D_MONEDA(MONEDA)
	SELECT MONEDA FROM DATA_TEAM.Moneda
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_SUCURSAL AS
BEGIN
	INSERT INTO DATA_TEAM.BI_D_Sucursal(SUCURSAL_CODIGO, SUCURSAL_NOMBRE, SUCURSAL_DIRECCION, SUCURSAL_TELEFONO)
	SELECT SUCURSAL_CODIGO, SUCURSAL_NOMBRE, SUCURSAL_DIRECCION, SUCURSAL_TELEFONO FROM DATA_TEAM.Sucursal
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_TIPO_INMUEBLE AS
BEGIN
	INSERT INTO DATA_TEAM.BI_D_TIPO_INMUEBLE(TIPO_INMUEBLE)
	SELECT TIPO_INMUEBLE FROM DATA_TEAM.Tipo_inmueble
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_TIPO_OPERACION AS
BEGIN
	INSERT INTO DATA_TEAM.BI_D_TIPO_OPERACION(TIPO_OPERACION)
	SELECT TIPO_OPERACION FROM DATA_TEAM.Tipo_operacion
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_RANGO_ETARIO
AS
BEGIN
    INSERT INTO DATA_TEAM.BI_D_RANGO_ETARIO(EDAD_INICIO, EDAD_FIN) VALUES
    (0,25),
    (25,35),
    (35,50),
    (50,100)
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_RANGO_METROS
AS
BEGIN
    INSERT INTO DATA_TEAM.BI_D_RANGO_METROS(RANGO_METROS_INICIO, RANGO_METROS_FIN) VALUES
    (0,35),
    (35,55),
    (55,75),
    (75,100)
END
GO

CREATE PROC DATA_TEAM.MIGRAR_H_ANUNCIO AS
BEGIN
    INSERT INTO DATA_TEAM.BI_H_ANUNCIO(
		ANUNCIO_BARRIO,
		ANUNCIO_TIPO_INMUEBLE,
		ANUNCIO_MONEDA,
		ANUNCIO_TIPO_OPERACION,
		ANUNCIO_RANGO_METROS,
		ANUNCIO_ANIO,
		ANUNCIO_CUATRI,
		ANUNCIO_MES,
		ANUNCIO_AMBIENTES,
		TOTAL_PRECIO,
		TOTAL_TIEMPO_ALTA
	)
	SELECT INMUEBLE_BARRIO,
	INMUEBLE_TIPO_INMUEBLE,
	ANUNCIO_MONEDA,
	ANUNCIO_TIPO_OPERACION,
	YEAR(ANUNCIO_FECHA_PUBLICACION),
	DATA_TEAM.Calcular_cuatri(ANUNCIO_FECHA_PUBLICACION),
	MONTH(ANUNCIO_FECHA_PUBLICACION),
	INMUEBLE_CANT_AMBIENTES,
	SUM(ANUNCIO_COSTO_ANUNCIO),
	DATEDIFF(DAY, ANUNCIO_FECHA_PUBLICACION, ANUNCIO_FECHA_FINALIZACION)
	FROM DATA_TEAM.Anuncio
	JOIN DATA_TEAM.Inmueble ON INMUEBLE_CODIGO = ANUNCIO_INMUEBLE
	GROUP BY
	INMUEBLE_BARRIO,
	INMUEBLE_TIPO_INMUEBLE,
	ANUNCIO_MONEDA,
	ANUNCIO_TIPO_OPERACION,
	YEAR(ANUNCIO_FECHA_PUBLICACION),
	DATA_TEAM.Calcular_cuatri(ANUNCIO_FECHA_PUBLICACION),
	MONTH(ANUNCIO_FECHA_PUBLICACION),
	INMUEBLE_CANT_AMBIENTES
END
GO

CREATE PROC DATA_TEAM.MIGRAR_H_VENTA AS
BEGIN
    INSERT INTO DATA_TEAM.BI_H_VENTA(
		VENTA_SUCURSAL,
		VENTA_LOCALIDAD,
		VENTA_RANGO_ETARIO,
		VENTA_TIPO_INMUEBLE,
		VENTA_MONEDA,
		VENTA_RANGO_METROS,
		VENTA_ANIO,
		VENTA_CUATRI,
		VENTA_MES,
		TOTAL_VENTAS,
		TOTAL_COMISION,
		CANTIDAD_VENTAS
	)
	SELECT 
	SUCURSAL_CODIGO,
	SUCURSAL_LOCALIDAD,
	DATA_TEAM.ObtenerRangoEtario(AGENTE_FECHA_NAC),
	INMUEBLE_TIPO_INMUEBLE,
	VENTA_MONEDA,
	DATA_TEAM.ObtenerRangoMetros(INMUEBLE_SUPERFICIETOTAL),
	YEAR(VENTA_FECHA),
	DATA_TEAM.Calcular_cuatri(VENTA_FECHA),
	MONTH(VENTA_FECHA),
	SUM(VENTA_PRECIO_VENTA),
	SUM(VENTA_COMISION),
	COUNT(DISTINCT VENTA_CODIGO)
	FROM DATA_TEAM.Venta
	JOIN DATA_TEAM.Anuncio ON VENTA_ANUNCIO = ANUNCIO_CODIGO
	JOIN DATA_TEAM.Agente ON ANUNCIO_AGENTE = AGENTE_DNI
	JOIN DATA_TEAM.Sucursal ON AGENTE_SUCURSAL = SUCURSAL_CODIGO
	JOIN DATA_TEAM.Inmueble ON ANUNCIO_INMUEBLE = INMUEBLE_CODIGO
	GROUP BY
	SUCURSAL_CODIGO,
	SUCURSAL_LOCALIDAD,
	DATA_TEAM.ObtenerRangoEtario(AGENTE_FECHA_NAC),
	INMUEBLE_TIPO_INMUEBLE,
	VENTA_MONEDA,
	DATA_TEAM.ObtenerRangoMetros(INMUEBLE_SUPERFICIETOTAL),
	YEAR(VENTA_FECHA),
	DATA_TEAM.Calcular_cuatri(VENTA_FECHA),
	MONTH(VENTA_FECHA)
END
GO

CREATE PROC DATA_TEAM.MIGRAR_H_ALQUILER AS
BEGIN
	INSERT INTO DATA_TEAM.BI_H_ALQUILER(
		ALQUILER_SUCURSAL,
		ALQUILER_BARRIO,
		ALQUILER_RANGO_ETARIO,
		ALQUILER_MONEDA,
		ALQUILER_TIPO_OPERACION,
		ALQUILER_ANIO,
		ALQUILER_CUATRI,
		ALQUILER_MES,
		TOTAL_PAGOS,
		TOTAL_ALTAS_ALQUILER,
		CANTIDAD_INCUMPLIMIENTOS,
		TOTAL_INCREMENTO
	)
	SELECT 
		ALQUILER_SUCURSAL,
		INMUEBLE_BARRIO,
		DATA_TEAM.ObtenerRangoEtario(INQUILINO_FECHA_NAC),
		ANUNCIO_MONEDA,
		ANUNCIO_TIPO_OPERACION,
		YEAR(ALQUILER_FECHA_INICIO),
		DATA_TEAM.Calcular_cuatri(ALQUILER_FECHA_INICIO),
		MONTH(ALQUILER_FECHA_INICIO),
		SUM(PAGO_ALQUILER_IMPORTE)
    GROUP BY
    	ALQUILER_SUCURSAL,
		INMUEBLE_BARRIO,
		DATA_TEAM.ObtenerRangoEtario(INQUILINO_FECHA_NAC),
		ANUNCIO_MONEDA,
		ANUNCIO_TIPO_OPERACION,
		YEAR(ALQUILER_FECHA_INICIO),
		DATA_TEAM.Calcular_cuatri(ALQUILER_FECHA_INICIO),
		MONTH(ALQUILER_FECHA_INICIO),
	FROM DATA_TEAM.Alquiler
	JOIN DATA_TEAM.Anuncio ON ALQUILER_ANUNCIO = ANUNCIO_CODIGO
	JOIN DATA_TEAM.Inmueble ON ANUNCIO_INMUEBLE = INMUEBLE_CODIGO
	JOIN DATA_TEAM.Inquilino ON ALQUILER_INQUILINO = INQUILINO_DNI
	JOIN DATA_TEAM.Pago_alquiler ON PAGO_ALQUILER_ALQ = ALQUILER_CODIGO
END
GO

------------------- Creacion de vistas

 ---------------  1 
/*Duración promedio (en días) que se encuentran publicados los anuncios
según el tipo de operación (alquiler, venta, etc), barrio y ambientes para cada
cuatrimestre de cada año. Se consideran todos los anuncios que se dieron de alta
en ese cuatrimestre. La duración se calcula teniendo en cuenta la fecha de alta y
la fecha de ﬁnalización.*/

-- TOMA DE DECISION: Empleo la función COALESCE para gestionar los anuncios que no han concluido su publicación. En caso de que la fecha de finalización (ANUNCIO_FECHA_FINALIZACION) sea NULL, lo que indica que el anuncio está activo, se considera la fecha actual del sistema (GETDATE()) para calcular la duración hasta la fecha presente del anuncio en curso.

GO
CREATE VIEW VistaDuracionPromedio AS
SELECT
    ANUNCIO_CODIGO,
    ANUNCIO_TIPO_OPERACION AS TipoOperacion,
    ANUNCIO_BARRIO AS Barrio,
    ANUNCIO_AMBIENTES AS Ambientes,
    ANUNCIO_ANIO AS Anio,
    ANUNCIO_CUATRI AS Cuatrimestre,
    DATEDIFF(day, ANUNCIO_FECHA_PUBLICACION, COALESCE(ANUNCIO_FECHA_FINALIZACION, GETDATE())) AS DuracionEnDias,
    AVG(DATEDIFF(day, ANUNCIO_FECHA_PUBLICACION, COALESCE(ANUNCIO_FECHA_FINALIZACION, GETDATE()))) AS DuracionPromedioEnDias
FROM DATA_TEAM.Anuncio
GROUP BY
    ANUNCIO_CODIGO,
    ANUNCIO_TIPO_OPERACION,
    ANUNCIO_BARRIO,
    ANUNCIO_AMBIENTES,
    ANUNCIO_ANIO,
    ANUNCIO_CUATRI;

 ---------------  2 
 /* Precio promedio de los anuncios de inmuebles según el tipo de operación
(alquiler, venta, etc), tipo de inmueble y rango m2 para cada cuatrimestre/año.
Se consideran todos los anuncios que se dieron de alta en ese cuatrimestre. El
precio se debe expresar en el tipo de moneda que corresponda, identiﬁcando de
cuál se trata.*/

GO
CREATE VIEW VistaPrecioPromedio AS
SELECT
    ANUNCIO_TIPO_OPERACION AS TipoOperacion,
    ANUNCIO_TIPO_INMUEBLE AS TipoInmueble,
    ANUNCIO_RANGO_METROS AS RangoMetros,
    ANUNCIO_ANIO AS Anio,
    ANUNCIO_CUATRI AS Cuatrimestre,
    ANUNCIO_MONEDA AS Moneda,
    AVG(TOTAL_PRECIO) AS PrecioPromedio
FROM
    DATA_TEAM.BI_H_ANUNCIO
GROUP BY
    ANUNCIO_TIPO_OPERACION,
    ANUNCIO_TIPO_INMUEBLE,
    ANUNCIO_RANGO_METROS,
    ANUNCIO_ANIO,
    ANUNCIO_CUATRI,
    ANUNCIO_MONEDA;

  ---------------  3
  /* Los 5 barrios más elegidos para alquilar en función del rango etario de los
inquilinos para cada cuatrimestre/año. Se calcula en función de los alquileres
dados de alta en dicho periodo.*/

-- Considerar solo los alquileres dados de alta en dicho periodo
  CREATE VIEW Top5BarriosAlquiler AS
SELECT
    TOP 5 WITH TIES
    ALQUILER_BARRIO AS Barrio,
    RANGO_ETARIO_ID AS RangoEtario,
    ALQUILER_ANIO AS Anio,
    ALQUILER_CUATRI AS Cuatrimestre,
    COUNT(*) AS TotalAlquileres
FROM
    DATA_TEAM.BI_H_ALQUILER A
JOIN
    DATA_TEAM.BI_D_RANGO_ETARIO R ON A.ALQUILER_RANGO_ETARIO = R.RANGO_ETARIO_ID
GROUP BY
    ALQUILER_BARRIO,
    RANGO_ETARIO_ID,
    ALQUILER_ANIO,
    ALQUILER_CUATRI
ORDER BY
    ALQUILER_ANIO,
    ALQUILER_CUATRI,
    TotalAlquileres DESC;

    ---------------  4
/* Porcentaje de incumplimiento de pagos de alquileres en término por cada
mes/año. Se calcula en función de las fechas de pago y fecha de vencimiento del
mismo. El porcentaje es en función del total de pagos en dicho periodo.*/

CREATE VIEW PorcentajeIncumplimientoPagos AS
SELECT
    A.ALQUILER_CODIGO,
    YEAR(PA.PAGO_ALQUILER_FECHA) AS Anio,
    MONTH(PA.PAGO_ALQUILER_FECHA) AS Mes,
    100.0 * SUM(CASE WHEN PA.PAGO_ALQUILER_FECHA > PA.PAGO_ALQUILER_FECHA_VENCIMIENTO THEN 1 ELSE 0 END) / COUNT(*) AS PorcentajeIncumplimiento
FROM
    DATA_TEAM.Alquiler A
INNER JOIN
    DATA_TEAM.Pago_alquiler PA ON A.ALQUILER_CODIGO = PA.ALQUILER_CODIGO
GROUP BY
    A.ALQUILER_CODIGO,
    YEAR(PA.PAGO_ALQUILER_FECHA),
    MONTH(PA.PAGO_ALQUILER_FECHA);


    ---------------  5
/* Porcentaje promedio de incremento del valor de los alquileres para los
contratos en curso por mes/año. Se calcula tomando en cuenta el último pago
con respecto al del mes en curso, únicamente de aquellos alquileres que hayan
tenido aumento y están activos.*/

SELECT 
    A.ALQUILER_CODIGO,
    YEAR(PA_ACTUAL.PAGO_ALQUILER_FECHA) AS ALQUILER_ANIO,
    MONTH(PA_ACTUAL.PAGO_ALQUILER_FECHA) AS ALQUILER_MES,
    AVG((PA_ACTUAL.PAGO_ALQUILER_IMPORTE - PA_ANTERIOR.PAGO_ALQUILER_IMPORTE) / PA_ANTERIOR.PAGO_ALQUILER_IMPORTE) AS Porcentaje_Incremento
FROM DATA_TEAM.Alquiler A
JOIN DATA_TEAM.Pago_alquiler PA_ACTUAL ON A.ALQUILER_CODIGO = PA_ACTUAL.PAGO_ALQUILER_CODIGO
LEFT JOIN DATA_TEAM.Pago_alquiler PA_ANTERIOR ON A.ALQUILER_CODIGO = PA_ANTERIOR.PAGO_ALQUILER_CODIGO
    AND PA_ACTUAL.PAGO_ALQUILER_FECHA > PA_ANTERIOR.PAGO_ALQUILER_FECHA
WHERE 
    A.ALQUILER_ESTADO = 'Alquilado' -- Alquileres activos
    AND PA_ANTERIOR.PAGO_ALQUILER_CODIGO IS NOT NULL -- Verifico que tengan al menos dos pagos
    AND PA_ACTUAL.PAGO_ALQUILER_IMPORTE > PA_ANTERIOR.PAGO_ALQUILER_IMPORTE -- Alquileres con incremento, el resto descarto
GROUP BY 
    A.ALQUILER_CODIGO,
    YEAR(PA_ACTUAL.PAGO_ALQUILER_FECHA),
    MONTH(PA_ACTUAL.PAGO_ALQUILER_FECHA)
ORDER BY 
    ALQUILER_ANIO, ALQUILER_MES;

    ---------------  6
    /* Valor promedio de la comisión según el tipo de operación (alquiler, venta, etc)
y sucursal para cada cuatrimestre/año. Se calcula en función de los alquileres y
ventas concretadas dentro del periodo. 
 COALESCE DEVUELVE EL PRIMER ELEMENTO NO NULL entre ellos dos*/
    SELECT 
        CASE 
            WHEN V.VENTA_TIPO_OPERACION IS NOT NULL THEN 'Venta'
            WHEN A.ALQUILER_TIPO_OPERACION IS NOT NULL THEN 'Alquiler'
            ELSE 'Otro' 
        END AS Tipo_Operacion,
        COALESCE(V.VENTA_SUCURSAL, A.ALQUILER_SUCURSAL) AS Sucursal,
        COALESCE(V.VENTA_ANIO, A.ALQUILER_ANIO) AS Anio,
        COALESCE(V.VENTA_CUATRI, A.ALQUILER_CUATRI) AS Cuatrimestre,
        AVG(COALESCE(V.TOTAL_COMISION, A.TOTAL_PAGOS)) AS Promedio_Comision
FROM DATA_TEAM.BI_H_VENTA V
FULL JOIN DATA_TEAM.BI_H_ALQUILER A
    ON V.VENTA_SUCURSAL = A.ALQUILER_SUCURSAL
    AND V.VENTA_ANIO = A.ALQUILER_ANIO
    AND V.VENTA_CUATRI = A.ALQUILER_CUATRI
GROUP BY 
    CASE 
        WHEN V.VENTA_TIPO_OPERACION IS NOT NULL THEN 'Venta'
        WHEN A.ALQUILER_TIPO_OPERACION IS NOT NULL THEN 'Alquiler'
        ELSE 'Otro' 
    END,
    COALESCE(V.VENTA_SUCURSAL, A.ALQUILER_SUCURSAL),
    COALESCE(V.VENTA_ANIO, A.ALQUILER_ANIO),
    COALESCE(V.VENTA_CUATRI, A.ALQUILER_CUATRI)
ORDER BY Anio, Cuatrimestre, Sucursal, Tipo_Operacion;

    ---------------  7
   

/* 
DROP TABLE DATA_TEAM.BI_D_AMBIENTES
DROP TABLE DATA_TEAM.BI_D_BARRIO
DROP TABLE DATA_TEAM.BI_D_LOCALIDAD
DROP TABLE DATA_TEAM.BI_D_MONEDA
DROP TABLE DATA_TEAM.BI_D_PROVINCIA
DROP TABLE DATA_TEAM.BI_D_RANGO_ETARIO
DROP TABLE DATA_TEAM.BI_D_RANGO_METROS
DROP TABLE DATA_TEAM.BI_D_Sucursal
DROP TABLE DATA_TEAM.BI_D_TIEMPO
DROP TABLE DATA_TEAM.BI_D_TIPO_INMUEBLE
DROP TABLE DATA_TEAM.BI_D_TIPO_OPERACION
DROP TABLE DATA_TEAM.BI_H_ALQUILER
DROP TABLE DATA_TEAM.BI_H_ANUNCIO
DROP TABLE DATA_TEAM.BI_H_VENTA
*/