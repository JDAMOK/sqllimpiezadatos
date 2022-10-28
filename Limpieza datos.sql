/*
Ejercicio de limpieza de datos. Eliminando espacios y números de cadenas de texto. Dividir un campo de texto que contiene
3 informaciones en 3 campos cada uno con su información específica. Eliminar filas con información duplicada
*/

create database pruebas_db;
use pruebas_db;

create table dirtytable (
id int,
texto varchar(200)
primary key(id)
);

create table customers (
id int identity(1,1),
Name varchar(100),
Age varchar(50),
Region varchar(200)
primary key(id)
);

--Creamos una tabla con datos sucios que hay que limpiar, quitar caracteres y espacios sobrantes
insert into dirtytable (id,texto)
values(1,'  Pedro  Gueva2ra1  , 58, Jalisco '),(2,'  Juan  Sandova1l   , 80, Colima'),
	(3,'  Karla Hinojosa  , 71,  Jalisco'),(4,'  Luis Gonzalez  , 15, Colima');

--Declaramos todas las variables que necesitaremos para este proceso
DECLARE @i int = 0
DECLARE @count int = (select count(id) from dirtytable)
DECLARE @text varchar(200)
DECLARE @tableToClean Table(Id int, Field varchar(200))
DECLARE @Name varchar(100)
DECLARE @Age varchar(100)
DECLARE @Region varchar(100)
--La siguiente variable la usaremos para ver en qué posición se encuentra el primer nº en una cadena y así quitaremos
--los números que encontremos en los nombres
DECLARE @NumberPattern varchar(10) = '%[0-9]%'

--Creamos un bucle para limpiar la tabla y dividir el campo texto en varios campos con la información que corresponda
While @i < @count
begin
	--Recorremos todas las filas de la tabla y vamos almacenando en @text el campo texto
	set @text = (select[texto] from dirtytable
				order by id
				offset @i rows
				fetch next 1 rows only)

	--Con Row_number creamos un valor autoincremental para crear un indice indice
	--Con string_split separamos cada palabra del campo Texto y con trim quitamos los espacios del principio y final
	insert into @tableToClean(Id, Field)
	select ROW_NUMBER() over(order by(select 1)), value from string_split(TRIM(@text), ',')
	
	--Ya que el nombre se está añadiendo en la fila 1, edad en la 2 y región en la 3, lo identificamos
	set @Name = (select top(1) Field from @tableToClean
				where id = 1)
	set @Age = (select top(1) Field from @tableToClean
				where id = 2)
	set @Region = (select top(1) Field from @tableToClean
				where id = 3)

	--El nombre tiene muchos espacios en distintas posiciones que eliminaremos con trim y replace
	set @Name = (select trim(replace(replace(replace(@Name, ' ', '<>'),'><',''),'<>',' ')))

	--Indicamos que si hay un nº en @Name corte con stuff en la posición indicada por @NumberPattern sólo 1 caracter y lo
	--reemplace por ''
	WHILE PATINDEX(@NumberPattern, @Name) > 0
		SET @Name = STUFF(@Name, PATINDEX(@NumberPattern, @Name), 1, '')

	set @Age = trim(@Age)
	set @Region = trim(@Region)	

	--Insertamos los datos limpios a nuestra tabla final
	insert into customers([Name],Age,Region)
	values(@Name, @Age, @Region)
	
	delete from @tableToClean
	set @i=@i+1
end

--Eliminando filas duplicadas
--Añadimos el campo dni a la tabla customers para nuestro siguiente ejercicio

Alter table customers add dni varchar(30);

--Rellenamos el campo dni y añadimos algún dato más mirando de repetirlo para posteriormente corregirlo

update customers set dni = '44444444D' where id = 4

insert into customers(Name,Age,Region,dni)
values('Pepelu',37,'Madrid','55555555E'),('Pepelu',37,'Madrid','55555555E'),
		('Pepeland',40,'Madrid','66666666F');

--Eliminamos datos duplicados de la tabla
--Primero identificamos los duplicados, en este caso utilizamos el campo dni para identificarlos

select dni, count(*)id
from customers
group by dni
having count(*)>1

--Identificamos con cual de los datos duplicados nos vamos a quedar o NO vamos a eliminar

Select * from (
select *,
ROW_NUMBER()over(partition by dni order by dni desc) N
from customers
where dni in(
	select dni
	from customers
	group by dni
	having count(*)>1)
	)T01
where N=1

--Guardamos un único representante de cada fila duplicada en una tabla temporal

select * into Temporal from(
select * from(
select *, ROW_NUMBER()over(partition by dni order by dni desc) N
from customers
where dni in(
	select dni
	from customers
	group by dni
	having count(*)>1)
	)T01
where N=1
)T02

--Eliminamos todas las filas duplicadas de la tabla original

Delete from customers
where dni in(
	select dni 
	from customers
	group by dni
	having count(*)>1)

--Insertamos en la tabla customers los duplicados con los que nos quedamos que habíamos guardado en Temporal

insert into customers select Name, Age, Region,dni from Temporal;

select * from customers

--Por último borramos la tabla temporal tras comprobar que la tabla customers queda como queríamos
drop table Temporal



