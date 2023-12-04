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
    WHERE @superficie >= RangoInicio AND @superficie <= RangoFin

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
    LOCALIDAD NVARCHAR(100) NOT NULL,
    LOCALIDAD_PROVINCIA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_PROVINCIA
)
GO

ALTER TABLE DATA_TEAM.BI_D_LOCALIDAD ADD CONSTRAINT PK_BI_D_LOCALIDAD PRIMARY KEY (LOCALIDAD, LOCALIDAD_PROVINCIA)

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
    BARRIO NVARCHAR(100) NOT NULL,
	BARRIO_LOCALIDAD NVARCHAR(100) NOT NULL,
    BARRIO_PROVINCIA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_PROVINCIA
)
GO

ALTER TABLE DATA_TEAM.BI_D_BARRIO ADD CONSTRAINT PK_BI_D_BARRIO PRIMARY KEY (BARRIO, BARRIO_LOCALIDAD, BARRIO_PROVINCIA)
ALTER TABLE DATA_TEAM.BI_D_BARRIO ADD CONSTRAINT FK_BI_D_BARRIO_LOCALIDAD FOREIGN KEY(BARRIO_LOCALIDAD, BARRIO_PROVINCIA) REFERENCES DATA_TEAM.BI_D_LOCALIDAD(LOCALIDAD, LOCALIDAD_PROVINCIA)


CREATE TABLE DATA_TEAM.BI_D_AMBIENTES (
    AMBIENTES NVARCHAR(100) PRIMARY KEY
)
GO

-- *** TABLAS DE HECHOS ***

CREATE TABLE DATA_TEAM.BI_H_ANUNCIO (
    ANUNCIO_BARRIO NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_BARRIO,
    ANUNCIO_LOCALIDAD NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_LOCALIDAD,
    ANUNCIO_PROVINCIA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_PROVINCIA,
	ANUNCIO_SUCURSAL NUMERIC(18,0) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_SUCURSAL,
    ANUNCIO_TIPO_INMUEBLE NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_INMUEBLE,
    ANUNCIO_MONEDA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_MONEDA,
    ANUNCIO_TIPO_OPERACION NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_OPERACION,
    ANUNCIO_RANGO_METROS int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_METROS,
	ANUNCIO_RANGO_ETARIO INT NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_ETARIO,
    ANUNCIO_ANIO INT NOT NULL,
	ANUNCIO_CUATRI INT NOT NULL,
    ANUNCIO_MES INT NOT NULL,
    ANUNCIO_AMBIENTES NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_AMBIENTES,
    TOTAL_TIEMPO_ALTA decimal(12,2),
    PRECIO_PROMEDIO decimal(12,2),
	CANTIDAD_ANUNCIOS INT,
	CANTIDAD_OPERACIONES INT,
	COMISION_PROMEDIO DECIMAL(12,2),
	MONTO_OPERACIONES DECIMAL(12,2)
)
GO
-- Agrego la Primary Key de la tabla de hechos, que se compone de todas sus dimensiones.
ALTER TABLE DATA_TEAM.BI_H_ANUNCIO ADD CONSTRAINT PK_BI_H_ANUNCIO PRIMARY KEY (
    ANUNCIO_BARRIO,
	ANUNCIO_LOCALIDAD,
	ANUNCIO_PROVINCIA,
	ANUNCIO_SUCURSAL,
    ANUNCIO_TIPO_INMUEBLE,
    ANUNCIO_MONEDA,
    ANUNCIO_TIPO_OPERACION,
    ANUNCIO_RANGO_METROS,
	ANUNCIO_RANGO_ETARIO,
    ANUNCIO_ANIO,
	ANUNCIO_CUATRI,
    ANUNCIO_MES,
    ANUNCIO_AMBIENTES
)

ALTER TABLE DATA_TEAM.BI_H_ANUNCIO ADD CONSTRAINT FK_BI_H_ANUNCIO_TIEMPO FOREIGN KEY(ANUNCIO_ANIO, ANUNCIO_CUATRI, ANUNCIO_MES) REFERENCES DATA_TEAM.BI_D_TIEMPO(TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)
ALTER TABLE DATA_TEAM.BI_H_ANUNCIO ADD CONSTRAINT FK_BI_H_ANUNCIO_BARRIO FOREIGN KEY(ANUNCIO_BARRIO, ANUNCIO_LOCALIDAD, ANUNCIO_PROVINCIA) REFERENCES DATA_TEAM.BI_D_BARRIO(BARRIO, BARRIO_LOCALIDAD, BARRIO_PROVINCIA)
ALTER TABLE DATA_TEAM.BI_H_ANUNCIO ADD CONSTRAINT FK_BI_H_ANUNCIO_LOCALIDAD FOREIGN KEY(ANUNCIO_LOCALIDAD, ANUNCIO_PROVINCIA) REFERENCES DATA_TEAM.BI_D_LOCALIDAD(LOCALIDAD, LOCALIDAD_PROVINCIA)

CREATE TABLE DATA_TEAM.BI_H_VENTA (
    VENTA_SUCURSAL NUMERIC(18,0) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_SUCURSAL,
    VENTA_LOCALIDAD NVARCHAR(100) NOT NULL,
    VENTA_PROVINCIA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_PROVINCIA,
    VENTA_RANGO_ETARIO int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_ETARIO,
    VENTA_TIPO_INMUEBLE NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_INMUEBLE,
	VENTA_TIPO_OPERACION NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_OPERACION,
    VENTA_MONEDA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_MONEDA,
    VENTA_RANGO_METROS int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_METROS,
    VENTA_ANIO INT NOT NULL,
    VENTA_CUATRI INT NOT NULL,
    VENTA_MES INT NOT NULL,
    PRECIO_PROMEDIO_M2 decimal(12,2),
    CANTIDAD_VENTAS decimal(12,0),
	PROMEDIO_COMISION DECIMAL(12,2)
)
GO

ALTER TABLE DATA_TEAM.BI_H_VENTA ADD CONSTRAINT PK_BI_H_VENTA PRIMARY KEY (
    VENTA_SUCURSAL,
    VENTA_LOCALIDAD,
	VENTA_PROVINCIA,
    VENTA_RANGO_ETARIO,
    VENTA_TIPO_INMUEBLE,
    VENTA_MONEDA,
    VENTA_RANGO_METROS,
    VENTA_ANIO,
    VENTA_CUATRI,
    VENTA_MES
)

ALTER TABLE DATA_TEAM.BI_H_VENTA ADD CONSTRAINT FK_BI_H_VENTA_TIEMPO FOREIGN KEY(VENTA_ANIO, VENTA_CUATRI, VENTA_MES) REFERENCES DATA_TEAM.BI_D_TIEMPO(TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)
ALTER TABLE DATA_TEAM.BI_H_VENTA ADD CONSTRAINT FK_BI_H_VENTA_LOCALIDAD FOREIGN KEY(VENTA_LOCALIDAD, VENTA_PROVINCIA) REFERENCES DATA_TEAM.BI_D_LOCALIDAD(LOCALIDAD, LOCALIDAD_PROVINCIA)

CREATE TABLE DATA_TEAM.BI_H_ALQUILER (
    ALQUILER_SUCURSAL NUMERIC(18,0) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_SUCURSAL,
    ALQUILER_BARRIO NVARCHAR(100) NOT NULL,
    ALQUILER_LOCALIDAD NVARCHAR(100) NOT NULL,
    ALQUILER_PROVINCIA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_PROVINCIA,
    ALQUILER_RANGO_ETARIO int NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_RANGO_ETARIO,
    ALQUILER_MONEDA NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_MONEDA,
    ALQUILER_TIPO_OPERACION NVARCHAR(100) NOT NULL FOREIGN KEY REFERENCES DATA_TEAM.BI_D_TIPO_OPERACION,
    ALQUILER_ANIO INT NOT NULL,
    ALQUILER_CUATRI INT NOT NULL,
    ALQUILER_MES INT NOT NULL,
    TOTAL_PAGOS decimal(12,2),
    TOTAL_ALTAS_ALQUILER decimal(12,2),
	COMISION_PROMEDIO decimal(12,2),
	CANTIDAD_INCUMPLIMIENTOS decimal(12,0),
	TOTAL_INCREMENTO decimal(12,2),
)
GO

ALTER TABLE DATA_TEAM.BI_H_ALQUILER ADD CONSTRAINT PK_BI_H_ALQUILER PRIMARY KEY (
    ALQUILER_SUCURSAL,
    ALQUILER_BARRIO,
	ALQUILER_LOCALIDAD,
    ALQUILER_PROVINCIA,
    ALQUILER_RANGO_ETARIO,
    ALQUILER_MONEDA,
    ALQUILER_TIPO_OPERACION,
    ALQUILER_ANIO,
    ALQUILER_CUATRI,
    ALQUILER_MES
);

ALTER TABLE DATA_TEAM.BI_H_ALQUILER ADD CONSTRAINT FK_BI_H_ALQUILER_TIEMPO FOREIGN KEY(ALQUILER_ANIO, ALQUILER_CUATRI, ALQUILER_MES) REFERENCES DATA_TEAM.BI_D_TIEMPO(TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)
ALTER TABLE DATA_TEAM.BI_H_ALQUILER ADD CONSTRAINT FK_BI_H_ALQUILER_BARRIO FOREIGN KEY(ALQUILER_BARRIO, ALQUILER_LOCALIDAD, ALQUILER_PROVINCIA) REFERENCES DATA_TEAM.BI_D_BARRIO(BARRIO, BARRIO_LOCALIDAD, BARRIO_PROVINCIA)
ALTER TABLE DATA_TEAM.BI_H_ALQUILER ADD CONSTRAINT FK_BI_H_ALQUILER_LOCALIDAD FOREIGN KEY(ALQUILER_LOCALIDAD, ALQUILER_PROVINCIA) REFERENCES DATA_TEAM.BI_D_LOCALIDAD(LOCALIDAD, LOCALIDAD_PROVINCIA) 

--CREACION TABLA DE HECHOS DE PAGO ALQUILER
CREATE TABLE DATA_TEAM.BI_H_PAGO_ALQUILER (
	PAGO_ALQUILER_ANIO INT,
	PAGO_ALQUILER_CUATRI INT,
	PAGO_ALQUILER_MES INT,
	PAGO_ALQUILER_CANT_PAGOS numeric(18,0),
	PAGO_ALQUILER_PORCENTAJE_INCUMPLI numeric(18,2),
	PAGO_ALQUILER_PORCENTAJE_AUMENTO numeric(18,2)
)

ALTER TABLE DATA_TEAM.BI_H_PAGO_ALQUILER ADD CONSTRAINT FK_PAGO_ALQUILER_TIEMPO FOREIGN KEY(PAGO_ALQUILER_ANIO, PAGO_ALQUILER_CUATRI, PAGO_ALQUILER_MES) REFERENCES DATA_TEAM.BI_D_TIEMPO(TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)

GO

-- *** MIGRACION DE TABLAS DIMENSIONALES ***

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_AMBIENTES
AS
BEGIN
	INSERT INTO DATA_TEAM.BI_D_AMBIENTES(AMBIENTES)
	SELECT CANT_AMBIENTES FROM DATA_TEAM.Cant_ambientes
END
GO

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
    INSERT INTO DATA_TEAM.BI_D_LOCALIDAD(LOCALIDAD, LOCALIDAD_PROVINCIA)
    SELECT LOCALIDAD, LOCALIDAD_PROVINCIA FROM DATA_TEAM.LOCALIDAD
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_BARRIO
AS
BEGIN
    INSERT INTO DATA_TEAM.BI_D_BARRIO(BARRIO, BARRIO_LOCALIDAD, BARRIO_PROVINCIA)
    SELECT BARRIO, BARRIO_LOCALIDAD, BARRIO_PROVINCIA FROM DATA_TEAM.BARRIO
END
GO

CREATE PROCEDURE DATA_TEAM.MIGRAR_D_TIEMPO
AS
BEGIN
		INSERT INTO DATA_TEAM.BI_D_TIEMPO (TIEMPO_ANIO, TIEMPO_CUATRI, TIEMPO_MES)
            SELECT DISTINCT YEAR(PAGO_ALQUILER_FECHA), DATA_TEAM.Calcular_cuatri(PAGO_ALQUILER_FECHA),MONTH(PAGO_ALQUILER_FECHA)
            FROM gd_esquema.Maestra
            WHERE ALQUILER_FECHA_INICIO IS NOT NULL AND
                NOT EXISTS (SELECT 1 FROM DATA_TEAM.BI_D_TIEMPO p WHERE p.TIEMPO_ANIO+p.TIEMPO_CUATRI+p.TIEMPO_MES = YEAR(ALQUILER_FECHA_INICIO)+DATA_TEAM.Calcular_cuatri(ALQUILER_FECHA_INICIO)+MONTH(ALQUILER_FECHA_INICIO))
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
	(-9999, 0),
    (0,35),
    (35,55),
    (55,75),
    (75,100),
	(75,9999)
END
GO

CREATE PROC DATA_TEAM.MIGRAR_H_ANUNCIO AS
BEGIN
    INSERT INTO DATA_TEAM.BI_H_ANUNCIO(
		ANUNCIO_BARRIO,
		ANUNCIO_LOCALIDAD,
		ANUNCIO_PROVINCIA,
		ANUNCIO_SUCURSAL,
		ANUNCIO_TIPO_INMUEBLE,
		ANUNCIO_MONEDA,
		ANUNCIO_TIPO_OPERACION,
		ANUNCIO_RANGO_METROS,
		ANUNCIO_RANGO_ETARIO,
		ANUNCIO_ANIO,
		ANUNCIO_CUATRI,
		ANUNCIO_MES,
		ANUNCIO_AMBIENTES,
		PRECIO_PROMEDIO,
		TOTAL_TIEMPO_ALTA,
		CANTIDAD_ANUNCIOS,
		CANTIDAD_OPERACIONES,
		COMISION_PROMEDIO,
		MONTO_OPERACIONES
	)
	SELECT
	INMUEBLE_BARRIO,
	INMUEBLE_LOCALIDAD,
	INMUEBLE_PROVINCIA,
	AGENTE_SUCURSAL,
	INMUEBLE_TIPO_INMUEBLE,
	ANUNCIO_MONEDA,
	ANUNCIO_TIPO_OPERACION,
    DATA_TEAM.ObtenerRangoMetros(INMUEBLE_SUPERFICIETOTAL) AS 'Rango de m2',
	DATA_TEAM.ObtenerRangoEtario(AGENTE_FECHA_NAC) AS 'Rango Etario',
	YEAR(ANUNCIO_FECHA_PUBLICACION) AS 'Año de Publicacion',
	DATA_TEAM.Calcular_cuatri(ANUNCIO_FECHA_PUBLICACION) AS 'Cuatri de Publicacion',
	MONTH(ANUNCIO_FECHA_PUBLICACION) AS 'Mes de Publicacion',
	INMUEBLE_CANT_AMBIENTES,
	AVG(ANUNCIO_COSTO_ANUNCIO) AS 'Precio promedio de los anuncios',
	AVG(DATEDIFF(DAY, ANUNCIO_FECHA_PUBLICACION, ANUNCIO_FECHA_FINALIZACION)) AS 'TIEMPO DE ALTA',
	COUNT(*) AS 'CANTIDAD DE ANUNCIOS',
	SUM(CASE WHEN ALQUILER_CODIGO IS NOT NULL OR VENTA_CODIGO IS NOT NULL THEN 1 ELSE 0 END) AS 'Cantidad operaciones concretadas',
	AVG(ISNULL((CASE WHEN ANUNCIO_TIPO_OPERACION = 'Tipo Operación Alquiler Contrato' THEN ALQUILER_COMISION WHEN ANUNCIO_TIPO_OPERACION = 'Tipo Operación Alquiler Temporario' THEN ALQUILER_COMISION WHEN ANUNCIO_TIPO_OPERACION = 'Tipo Operación Venta' THEN VENTA_COMISION ELSE 0 END),0)) AS 'Promedio Comision',
	SUM(CASE WHEN ALQUILER_CODIGO IS NOT NULL OR VENTA_CODIGO IS NOT NULL THEN ANUNCIO_PRECIO_PUBLICADO ELSE 0 END) AS 'Monto de operaciones concretadas'
	FROM DATA_TEAM.Anuncio
	JOIN DATA_TEAM.Inmueble ON INMUEBLE_CODIGO = ANUNCIO_INMUEBLE
	JOIN DATA_TEAM.Agente ON AGENTE_DNI = ANUNCIO_AGENTE
	LEFT JOIN DATA_TEAM.Venta ON VENTA_ANUNCIO = ANUNCIO_CODIGO
	LEFT JOIN DATA_TEAM.Alquiler ON ANUNCIO_CODIGO = ALQUILER_ANUNCIO
	GROUP BY
	INMUEBLE_BARRIO,
	INMUEBLE_LOCALIDAD,
	INMUEBLE_PROVINCIA,
	AGENTE_SUCURSAL,
	INMUEBLE_TIPO_INMUEBLE,
	ANUNCIO_MONEDA,
	ANUNCIO_TIPO_OPERACION,
    DATA_TEAM.ObtenerRangoMetros(INMUEBLE_SUPERFICIETOTAL),
	DATA_TEAM.ObtenerRangoEtario(AGENTE_FECHA_NAC),
	YEAR(ANUNCIO_FECHA_PUBLICACION),
	DATA_TEAM.Calcular_cuatri(ANUNCIO_FECHA_PUBLICACION),
	MONTH(ANUNCIO_FECHA_PUBLICACION),
	INMUEBLE_CANT_AMBIENTES
END
GO

CREATE PROC DATA_TEAM.MIGRAR_H_VENTA AS
BEGIN
    INSERT INTO DATA_TEAM.BI_H_VENTA(
		VENTA_LOCALIDAD,
		VENTA_PROVINCIA,
		VENTA_TIPO_INMUEBLE,
		VENTA_MONEDA,
		VENTA_RANGO_METROS,
		VENTA_ANIO,
		VENTA_CUATRI,
		VENTA_MES,
		VENTA_TIPO_OPERACION,
		CANTIDAD_VENTAS,
		PRECIO_PROMEDIO_M2,
		PROMEDIO_COMISION
	)
	SELECT 
	INMUEBLE_LOCALIDAD,
	INMUEBLE_PROVINCIA,
	INMUEBLE_TIPO_INMUEBLE,
	VENTA_MONEDA,
	DATA_TEAM.ObtenerRangoMetros(INMUEBLE_SUPERFICIETOTAL),
	YEAR(VENTA_FECHA),
	DATA_TEAM.Calcular_cuatri(VENTA_FECHA),
	MONTH(VENTA_FECHA),
	ANUNCIO_TIPO_OPERACION,
	COUNT(DISTINCT VENTA_CODIGO) as 'Cantidad de ventas',
	AVG(VENTA_PRECIO_VENTA / INMUEBLE_SUPERFICIETOTAL),
	AVG(VENTA_COMISION)
	FROM DATA_TEAM.Venta
	JOIN DATA_TEAM.Anuncio ON VENTA_ANUNCIO = ANUNCIO_CODIGO
	JOIN DATA_TEAM.Inmueble ON ANUNCIO_INMUEBLE = INMUEBLE_CODIGO
	GROUP BY
	INMUEBLE_LOCALIDAD,
	INMUEBLE_PROVINCIA,
	INMUEBLE_TIPO_INMUEBLE,
	VENTA_MONEDA,
	DATA_TEAM.ObtenerRangoMetros(INMUEBLE_SUPERFICIETOTAL),
	YEAR(VENTA_FECHA),
	DATA_TEAM.Calcular_cuatri(VENTA_FECHA),
	MONTH(VENTA_FECHA),
	ANUNCIO_TIPO_OPERACION
END
GO

CREATE PROC DATA_TEAM.MIGRAR_H_ALQUILER AS
BEGIN
	INSERT INTO DATA_TEAM.BI_H_ALQUILER(
		ALQUILER_SUCURSAL,
		ALQUILER_BARRIO,
		ALQUILER_LOCALIDAD,
		ALQUILER_PROVINCIA,
		ALQUILER_RANGO_ETARIO,
		ALQUILER_MONEDA,
		ALQUILER_TIPO_OPERACION,
		ALQUILER_ANIO,
		ALQUILER_CUATRI,
		ALQUILER_MES,
		COMISION_PROMEDIO
	)
	SELECT 
		ALQUILER_SUCURSAL,
		INMUEBLE_BARRIO,
		INMUEBLE_LOCALIDAD,
		INMUEBLE_PROVINCIA,
		DATA_TEAM.ObtenerRangoEtario(INQUILINO_FECHA_NAC),
		ANUNCIO_MONEDA,
		ANUNCIO_TIPO_OPERACION,
		YEAR(ALQUILER_FECHA_INICIO),
		DATA_TEAM.Calcular_cuatri(ALQUILER_FECHA_INICIO),
		MONTH(ALQUILER_FECHA_INICIO),
		AVG(ALQUILER_COMISION) AS 'Promedio Comision'
	FROM DATA_TEAM.Alquiler
	JOIN DATA_TEAM.Anuncio ON ALQUILER_ANUNCIO = ANUNCIO_CODIGO
	JOIN DATA_TEAM.Inmueble ON ANUNCIO_INMUEBLE = INMUEBLE_CODIGO
	JOIN DATA_TEAM.Inquilino ON ALQUILER_INQUILINO = INQUILINO_DNI
	WHERE
		ALQUILER_SUCURSAL IS NOT NULL AND
		INMUEBLE_BARRIO IS NOT NULL AND
		INMUEBLE_LOCALIDAD IS NOT NULL AND
		INMUEBLE_PROVINCIA IS NOT NULL AND
		ANUNCIO_MONEDA IS NOT NULL AND
		ANUNCIO_TIPO_OPERACION IS NOT NULL AND
		ALQUILER_FECHA_INICIO IS NOT NULL AND
		YEAR(ALQUILER_FECHA_INICIO)IS NOT NULL AND
		DATA_TEAM.Calcular_cuatri(ALQUILER_FECHA_INICIO) IS NOT NULL AND
		MONTH(ALQUILER_FECHA_INICIO) IS NOT NULL
    GROUP BY
		ALQUILER_SUCURSAL,
		INMUEBLE_BARRIO,
		INMUEBLE_LOCALIDAD,
		INMUEBLE_PROVINCIA,
		DATA_TEAM.ObtenerRangoEtario(INQUILINO_FECHA_NAC),
		ANUNCIO_MONEDA,
		ANUNCIO_TIPO_OPERACION,
		YEAR(ALQUILER_FECHA_INICIO),
		DATA_TEAM.Calcular_cuatri(ALQUILER_FECHA_INICIO),
		MONTH(ALQUILER_FECHA_INICIO)
END
GO

CREATE PROC DATA_TEAM.MIGRAR_H_PAGO_ALQUILER AS
BEGIN
	INSERT INTO DATA_TEAM.BI_H_PAGO_ALQUILER (
		PAGO_ALQUILER_ANIO,
		PAGO_ALQUILER_CUATRI,
		PAGO_ALQUILER_MES,
		PAGO_ALQUILER_CANT_PAGOS,
		PAGO_ALQUILER_PORCENTAJE_INCUMPLI,
		PAGO_ALQUILER_PORCENTAJE_AUMENTO
	)
	SELECT
	YEAR(alquileresActuales.PAGO_ALQUILER_FECHA) AS 'Año del pago',
	DATA_TEAM.Calcular_cuatri(alquileresActuales.PAGO_ALQUILER_FECHA) AS 'Cuatri del pago',
	MONTH(alquileresActuales.PAGO_ALQUILER_FECHA) AS 'Mes del pago',
	COUNT(*) AS 'Cantidad de pagos',
	SUM(CASE WHEN (DATEDIFF(DAY, alquileresActuales.PAGO_ALQUILER_FECHA, alquileresActuales.PAGO_ALQUILER_FECHA_VENCIMIENTO) < 0) THEN 1 ELSE 0 END) / COUNT(*) * 100 AS 'Porcentaje Incumplimiento',
	SUM((alquileresActuales.PAGO_ALQUILER_IMPORTE - alquileresPasados.PAGO_ALQUILER_IMPORTE)/alquileresPasados.PAGO_ALQUILER_IMPORTE*100)/ COUNT(*) AS 'Promedio Porcentaje Aumento'
	FROM
	DATA_TEAM.Pago_alquiler alquileresActuales
	JOIN DATA_TEAM.Pago_alquiler alquileresPasados ON alquileresPasados.PAGO_ALQUILER_ALQ = alquileresActuales.PAGO_ALQUILER_ALQ AND DATEDIFF(MONTH, alquileresPasados.PAGO_ALQUILER_FECHA, alquileresActuales.PAGO_ALQUILER_FECHA) = 1
	GROUP BY
	YEAR(alquileresActuales.PAGO_ALQUILER_FECHA),
	DATA_TEAM.Calcular_cuatri(alquileresActuales.PAGO_ALQUILER_FECHA),
	MONTH(alquileresActuales.PAGO_ALQUILER_FECHA)

END
GO

------------------- Creacion de vistas

 ---------------  1   ---- ok
/*Duración promedio (en días) que se encuentran publicados los anuncios
según el tipo de operación (alquiler, venta, etc), barrio y ambientes para cada
cuatrimestre de cada año. Se consideran todos los anuncios que se dieron de alta
en ese cuatrimestre. La duración se calcula teniendo en cuenta la fecha de alta y
la fecha de ?nalización.*/

GO
CREATE VIEW DATA_TEAM.VistaDuracionPromedio AS
	SELECT
		ba.ANUNCIO_TIPO_OPERACION AS TipoOperacion,
		ba.ANUNCIO_BARRIO AS Barrio,
		ba.ANUNCIO_AMBIENTES AS Ambientes,
		ba.ANUNCIO_ANIO AS Anio,
		ba.ANUNCIO_CUATRI AS Cuatrimestre,
		AVG(ba.TOTAL_TIEMPO_ALTA) AS DuracionPromedioEnDias
	FROM DATA_TEAM.BI_H_ANUNCIO ba 
	GROUP BY
		ba.ANUNCIO_TIPO_OPERACION,
		ba.ANUNCIO_BARRIO,
		ba.ANUNCIO_AMBIENTES,
		ba.ANUNCIO_ANIO,
		ba.ANUNCIO_CUATRI;
GO


 ---------------  2                 ---- ok
 /* Precio promedio de los anuncios de inmuebles según el tipo de operación
(alquiler, venta, etc), tipo de inmueble y rango m2 para cada cuatrimestre/año.
Se consideran todos los anuncios que se dieron de alta en ese cuatrimestre. El
precio se debe expresar en el tipo de moneda que corresponda, identi?cando de
cuál se trata.*/

GO
CREATE VIEW DATA_TEAM.VistaPrecioPromedio AS
	SELECT
		ba.ANUNCIO_TIPO_OPERACION AS TipoOperacion,
		ba.ANUNCIO_TIPO_INMUEBLE AS TipoInmueble,
		ba.ANUNCIO_RANGO_METROS AS RangoMetros,
		ba.ANUNCIO_ANIO AS Anio,
		ba.ANUNCIO_CUATRI AS Cuatrimestre,
		ba.ANUNCIO_MONEDA AS Moneda,
		AVG(TOTAL_PRECIO) AS PrecioPromedio
	FROM DATA_TEAM.BI_H_ANUNCIO ba 
	JOIN DATA_TEAM.Anuncio a ON DATA_TEAM.Calcular_cuatri(a.ANUNCIO_FECHA_PUBLICACION) = ba.ANUNCIO_CUATRI
	WHERE YEAR(a.ANUNCIO_FECHA_PUBLICACION) = ba.ANUNCIO_ANIO
	GROUP BY
		ba.ANUNCIO_TIPO_OPERACION,
		ba.ANUNCIO_ANIO,
		ba.ANUNCIO_CUATRI,
		ba.ANUNCIO_TIPO_INMUEBLE,
		ba.ANUNCIO_RANGO_METROS,
		ba.ANUNCIO_MONEDA;

  ---------------  3          
  /* Los 5 barrios más elegidos para alquilar en función del rango etario de los
inquilinos para cada cuatrimestre/año. Se calcula en función de los alquileres
dados de alta en dicho periodo.*/

-- Considerar solo los alquileres dados de alta en dicho periodo
GO
CREATE VIEW DATA_TEAM.Top5BarriosAlquiler AS
SELECT
    TOP 5 WITH TIES
	ALQUILER_BARRIO,
    ALQUILER_RANGO_ETARIO AS RangoEtario,
    ALQUILER_ANIO AS Anio,
    ALQUILER_CUATRI AS Cuatrimestre,
	SUM(TOTAL_ALTAS_ALQUILER) AS TotalAltasAlquiler
FROM
    DATA_TEAM.BI_H_ALQUILER A
GROUP BY
	ALQUILER_BARRIO,
    ALQUILER_RANGO_ETARIO,
    ALQUILER_ANIO,
    ALQUILER_CUATRI,
	TOTAL_ALTAS_ALQUILER
ORDER BY
    ALQUILER_ANIO,
    ALQUILER_CUATRI,
	TOTAL_ALTAS_ALQUILER
GO


    ---------------  4          -------- VERIFICAR
/* Porcentaje de incumplimiento de pagos de alquileres en término por cada
mes/año. Se calcula en función de las fechas de pago y fecha de vencimiento del
mismo. El porcentaje es en función del total de pagos en dicho periodo.*/

GO
CREATE VIEW DATA_TEAM.PorcentajeIncumplimientoPagos AS
SELECT
    PAGO_ALQUILER_ANIO AS Anio,
    PAGO_ALQUILER_MES AS Mes,
    SUM(PAGO_ALQUILER_PORCENTAJE_INCUMPLI * PAGO_ALQUILER_CANT_PAGOS) / SUM(PAGO_ALQUILER_CANT_PAGOS) AS PorcentajeIncumplimiento
FROM
    DATA_TEAM.BI_H_PAGO_ALQUILER PA
GROUP BY
    PAGO_ALQUILER_PORCENTAJE_INCUMPLI,
    PAGO_ALQUILER_ANIO,
    PAGO_ALQUILER_MES;

    ---------------  5 --------- ok 
/* Porcentaje promedio de incremento del valor de los alquileres para los
contratos en curso por mes/año. Se calcula tomando en cuenta el último pago
con respecto al del mes en curso, únicamente de aquellos alquileres que hayan
tenido aumento y están activos.*/
GO
CREATE VIEW DATA_TEAM.PorcentajePromedioIncremento AS
SELECT
    PAGO_ALQUILER_ANIO AS Anio,
    PAGO_ALQUILER_MES AS Mes,
    SUM(PAGO_ALQUILER_CANT_PAGOS * PAGO_ALQUILER_PORCENTAJE_AUMENTO) /
	SUM(PAGO_ALQUILER_CANT_PAGOS) AS PorcentajeIncremento
FROM
    DATA_TEAM.BI_H_PAGO_ALQUILER
GROUP BY 
	PAGO_ALQUILER_ANIO,
	PAGO_ALQUILER_MES

 ---------------------------------- Discrepancia detectada:  tabla Tabla Pago_alquiler no tiene una FK llamada Pago_alquiler_detalle que haga FK a la Tabla Detalle_importe_alquiler 
 ---------------------------------------- Charlarlo con  fede! urgente ! 


------------- 6
/*Precio promedio de m2 de la venta de inmuebles según el tipo de inmueble y
la localidad para cada cuatrimestre/año. Se calcula en función de las ventas
concretadas.*/

GO
CREATE VIEW DATA_TEAM.PrecioPromedioPorMetroCuadrado AS
SELECT
    VENTA_TIPO_INMUEBLE AS TipoInmueble,
    VENTA_LOCALIDAD AS Localidad,
    VENTA_ANIO AS Anio,
    VENTA_CUATRI AS Cuatrimestre,
    SUM(PRECIO_PROMEDIO_M2 * CANTIDAD_VENTAS) / SUM(CANTIDAD_VENTAS) AS PrecioPromedioPorMetroCuadrado
FROM
    DATA_TEAM.BI_H_VENTA 
GROUP BY
    	VENTA_TIPO_INMUEBLE,
    	VENTA_LOCALIDAD,
    	VENTA_ANIO,
    	VENTA_CUATRI;

    ---------------  7
    /* Valor promedio de la comisión según el tipo de operación (alquiler, venta, etc)
y sucursal para cada cuatrimestre/año. Se calcula en función de los alquileres y
ventas concretadas dentro del periodo. 
*/
--- Le falta a la comision dividirla por la cantidad de operaciones del venta y alquiler en dicha fecha
GO
CREATE VIEW DATA_TEAM.ValorPromedioComision AS
	SELECT 
		A.ANUNCIO_TIPO_OPERACION,
		A.ANUNCIO_MES AS MES,
		A.ANUNCIO_CUATRI AS CUATRIMESTRE,
		A.ANUNCIO_SUCURSAL AS SUCURSAL,
		AVG(A.COMISION_PROMEDIO) AS ComisionPromedio
	FROM 
		DATA_TEAM.BI_H_ANUNCIO A
	GROUP BY 
		A.ANUNCIO_TIPO_OPERACION,
		A.ANUNCIO_MES,
		A.ANUNCIO_CUATRI,
		A.ANUNCIO_SUCURSAL;

	--------------- 8
	/* Porcentaje de operaciones concretadas (tanto de alquileres como ventas) por
cada sucursal, según el rango etario de los empleados por año en función de la
cantidad de anuncios publicados en ese mismo año.*/
GO
CREATE VIEW DATA_TEAM.PorcentajeoperacionesConcretadas AS
SELECT 
	ANUNCIO_TIPO_OPERACION AS TipoOperacion,
    ANUNCIO_SUCURSAL AS Sucursal,
    ANUNCIO_RANGO_ETARIO AS RangoEtario,
    ANUNCIO_ANIO AS Anio,
	(100.0 * SUM(CANTIDAD_OPERACIONES) / SUM(CANTIDAD_ANUNCIOS)) AS PorcentajeConcretadas
FROM 
    DATA_TEAM.BI_H_ANUNCIO
GROUP BY 
	ANUNCIO_TIPO_OPERACION,
    ANUNCIO_SUCURSAL,
    ANUNCIO_RANGO_ETARIO,
    ANUNCIO_ANIO;


	---------------- 9
	/*
	 Monto total de cierre de contratos por tipo de operación (tanto de alquileres
	como ventas) por cada cuatrimestre y sucursal, diferenciando el tipo de moneda.
	*/
GO
CREATE VIEW DATA_TEAM.MontoTotalCierre AS
SELECT 
    ANUNCIO_TIPO_OPERACION AS TipoOperacion,
    ANUNCIO_SUCURSAL AS Sucursal,
    ANUNCIO_MONEDA AS Moneda,
    ANUNCIO_CUATRI AS Cuatrimestre,
    SUM(MONTO_OPERACIONES) AS MontoTotalCierre
FROM 
    DATA_TEAM.BI_H_ANUNCIO
GROUP BY 
    ANUNCIO_TIPO_OPERACION,
    ANUNCIO_SUCURSAL,
    ANUNCIO_MONEDA,
    ANUNCIO_CUATRI;
GO
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

/*
DROP PROCEDURE DATA_TEAM.MIGRAR_D_TIEMPO;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_PROVINCIA;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_LOCALIDAD;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_BARRIO;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_AMBIENTES;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_MONEDA;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_SUCURSAL;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_TIPO_INMUEBLE;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_TIPO_OPERACION;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_RANGO_ETARIO;
DROP PROCEDURE DATA_TEAM.MIGRAR_D_RANGO_METROS;
DROP PROCEDURE DATA_TEAM.MIGRAR_H_ANUNCIO;
DROP PROCEDURE DATA_TEAM.MIGRAR_H_VENTA;
DROP PROCEDURE DATA_TEAM.MIGRAR_H_ALQUILER;
*/

/*
DROP FUNCTION DATA_TEAM.Calcular_cuatri;
DROP FUNCTION DATA_TEAM.ObtenerRangoEtario;
DROP FUNCTION DATA_TEAM.ObtenerRangoMetros;
*/
/*
-- Eliminar vistas
DROP VIEW IF EXISTS DATA_TEAM.VistaDuracionPromedio;
DROP VIEW IF EXISTS DATA_TEAM.VistaPrecioPromedio;
DROP VIEW IF EXISTS DATA_TEAM.Top5BarriosAlquiler;
DROP VIEW IF EXISTS DATA_TEAM.PorcentajeIncumplimientoPagos;
DROP VIEW IF EXISTS DATA_TEAM.PorcentajeIncrementoAlquileres;
DROP VIEW IF EXISTS DATA_TEAM.PrecioPromedioM2;
DROP VIEW IF EXISTS DATA_TEAM.PromedioComision;
DROP VIEW IF EXISTS DATA_TEAM.PorcentajeOperacionesCompletadas;
*/

EXEC DATA_TEAM.MIGRAR_D_TIEMPO
EXEC DATA_TEAM.MIGRAR_D_MONEDA
EXEC DATA_TEAM.MIGRAR_D_PROVINCIA
EXEC DATA_TEAM.MIGRAR_D_LOCALIDAD
EXEC DATA_TEAM.MIGRAR_D_BARRIO
EXEC DATA_TEAM.MIGRAR_D_AMBIENTES
EXEC DATA_TEAM.MIGRAR_D_SUCURSAL
EXEC DATA_TEAM.MIGRAR_D_RANGO_ETARIO
EXEC DATA_TEAM.MIGRAR_D_RANGO_METROS
EXEC DATA_TEAM.MIGRAR_D_TIPO_INMUEBLE
EXEC DATA_TEAM.MIGRAR_D_TIPO_OPERACION
EXEC DATA_TEAM.MIGRAR_H_ALQUILER
EXEC DATA_TEAM.MIGRAR_H_VENTA
EXEC DATA_TEAM.MIGRAR_H_ANUNCIO
EXEC DATA_TEAM.MIGRAR_H_PAGO_ALQUILER