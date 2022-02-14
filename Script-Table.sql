
drop table if exists dbo.Script_table_tester;
drop table if exists dbo.Script_table_tester_b;
drop table if exists dbo.Script_table_tester_c;

create table dbo.Script_table_tester_b 
(
	id1 int not null
	, id2 int not null
	, primary key(id1,id2)
);

create table dbo.Script_table_tester_c 
(
	id3 int not null
	, id4 int not null
	, primary key(id3,id4)
);

create table dbo.Script_table_tester
(
	xxxx	int not null   identity (2,3)
	, yyy	char(10) not null

	, col_uniqueidentifier		uniqueidentifier
	, col_date					date
	, col_time					time
	, col_datetime2				datetime2
	, col_tinyint					tinyint
	, col_int						int
	, col2_int						int
	, col_smalldatetime			smalldatetime
	, col_real					real
	, col_money					money
	, col_datetime				datetime
	, col_float					float
	, col_sql_variant				sql_variant
	, col_bit						bit
	, col_decimal					decimal (18,4)
	, col_numeric					numeric (19,5)
	, col_smallmoney				smallmoney
	, col_bigint					bigint
	, col_varbinary				varbinary (10)
	, col_varchar					varchar (20)
	, col_binary					binary (30)
	, col_char					char (40)
	, col_timestamp				timestamp
	, col_nvarchar				nvarchar (50)
	, col_nchar					nchar(60)
	, col_xml						xml
	, col_sysname					sysname

	, constraint PK_Script_table_tester primary key (xxxx,yyy)
	, constraint check_1 check (col_numeric > 123.456)
	, constraint check_2 check (col_char in ('ccc','ddd'))
	, constraint unique_1 unique (col_char, col_nchar)
	, constraint unique_2 unique (col_tinyint, col_binary)
	, constraint foreign_key_1 foreign key (xxxx, col_int) references Script_table_tester_b (id1, id2)
	, constraint foreign_key_2 foreign key ( col2_int,col_int) references Script_table_tester_c (id3, id4)
)
go


--exec sp_help Script_table_tester



CREATE PROCEDURE table_details @table_name varchar(128)
AS



drop table if exists #col_info

create table #col_info (

TABLE_QUALIFIER varchar(256),
TABLE_OWNER varchar(256),
TABLE_NAME varchar(256),
COLUMN_NAME varchar (256),
DATA_TYPE int,
TYPE_NAME varchar(256),
PRECISION int,
LENGTH int,
SCALE varchar(50),
RADIX varchar(50),
NULLABLE bit,
REMARKS varchar(50),
COLUMN_DEF varchar(50),
SQL_DATA_TYPE int,
SQL_DATETIME_SUB smallint,
CHAR_OCTET_LENGTH int,
ORDINAL_POSITION int,
IS_NULLABLE	varchar(5),
SS_DATA_TYPE int

)


insert into #col_info  
EXEC sp_columns @table_name  = @table_name 



--- the solution --------------------------------------------------


DECLARE @combinedString VARCHAR(MAX) =''

SELECT @combinedString = @combinedString + ', '  + COLUMN_NAME + '   ' + 
						case when TYPE_NAME = 'char' or TYPE_NAME = 'varchar' or TYPE_NAME = 'binary' or TYPE_NAME = 'varbinary' then TYPE_NAME +'(' + cast(LENGTH as varchar(50)) + ')' 
						     when TYPE_NAME = 'nvarchar' or TYPE_NAME = 'nchar' then TYPE_NAME +'(' + cast(PRECISION as varchar(50)) + ')' 
							 when TYPE_NAME =  'decimal' or TYPE_NAME = 'numeric' then TYPE_NAME + '(' + cast(PRECISION as varchar(50)) + ', ' + cast(SCALE as varchar(50)) + ')' 
							 when TYPE_NAME = 'int identity' then TYPE_NAME + (SELECT '(' + cast(seed_value as varchar(50)) + ', ' + cast(increment_value as varchar(50)) + ')'
																			 FROM sys.identity_columns
																			 WHERE OBJECT_NAME(object_id) = @table_name and name = COLUMN_NAME ) 

							 else TYPE_NAME end +
						  ' ' +
						case when IS_NULLABLE ='No' then 'NOT NULL'
						     when IS_NULLABLE ='YES' then 'NULL' end + char(13) + char(10)
FROM #col_info


--SELECT @combinedString

----------------------------------------------------------------------------------



DECLARE @col_nams_pk VARCHAR(MAX) =''

select @col_nams_pk = @col_nams_pk + ', '  + COLUMN_NAME 
FROM (

SELECT inf.TABLE_NAME, inf.COLUMN_NAME, inf.CONSTRAINT_NAME, so.type_desc
FROM  INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE inf
inner join  sys.objects so
on  inf.CONSTRAINT_NAME = so.name 
WHERE so.type_desc = 'PRIMARY_KEY_CONSTRAINT' and inf.TABLE_NAME like @table_name
) as v



DECLARE @primary_key_con VARCHAR(MAX) =''

SELECT @primary_key_con = 'CONSTRAINT' + ' ' + CONSTRAINT_NAME + ' '+ 'PRIMARY KEY' +  ' ' +   '(' + stuff(@col_nams_pk, 1, 2, '') + ')'

FROM (


SELECT inf.TABLE_NAME, inf.COLUMN_NAME, inf.CONSTRAINT_NAME, so.type_desc
FROM  INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE inf
inner join  sys.objects so
on  inf.CONSTRAINT_NAME = so.name 
WHERE so.type_desc = 'PRIMARY_KEY_CONSTRAINT' and inf.TABLE_NAME like @table_name

) as p


--select @primary_key_con

-----------------------------------------------------------------------------------

drop table if exists #MyTempTable;
create table #MyTempTable 
(
	CONSTRAINT_NAME varchar(30)
	, ref varchar(30)
	, col_nams_fk varchar(30)  
	, col_nams_refrence varchar(30)  
);



;with fkkey as
(

select CONSTRAINT_NAME =OBJECT_NAME(constraint_object_id)
, parent =OBJECT_NAME(parent_object_id)
, par_column = par_col.name
,ref=OBJECT_NAME(referenced_object_id)
, ref_column = ref_col.name
from sys.foreign_key_columns col
join sys.columns par_col on parent_object_id = par_col.object_id and parent_column_id = par_col.column_id  
join sys.columns ref_col on referenced_object_id = ref_col.object_id and referenced_column_id = ref_col.column_id  

) 
INSERT INTO #MyTempTable 

select CONSTRAINT_NAME, ref
,col_nams_fk  = STRING_AGG(par_column, ', ') 
, col_nams_refrence  = STRING_AGG(ref_column, ', ') 
from fkkey as fk
where parent = @table_name 
group by CONSTRAINT_NAME, ref

----------------------------------------------------------------


DECLARE @foreign_key_con VARCHAR(MAX) =''


SELECT @foreign_key_con = @foreign_key_con + ',' +  char(13) + char(10) + 'CONSTRAINT' + ' ' + CONSTRAINT_NAME + ' '+ 'FOREIGN KEY' +  ' ' +
					 '(' + col_nams_fk + ')' + ' ' + 'REFERENCES'+ ' ' + ref  +'(' + col_nams_refrence + ')'
FROM (

select *
from #MyTempTable my 

) as p

--select @foreign_key_con


----------------------------------------------------------------------------------------



DECLARE @unique_con VARCHAR(MAX) =''

select @unique_con =  @unique_con + ',' +  char(13) + char(10) + 'CONSTRAINT' + ' ' + CONSTRAINT_NAME + ' '+ 'UNIQUE' +  ' ' + '(' + Column_Name +')'
FROM (

select Column_Name  = STRING_AGG(COLUMN_NAME, ', ') , a1.CONSTRAINT_NAME
from INFORMATION_SCHEMA.TABLE_CONSTRAINTS a1
inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE a2
on a1.CONSTRAINT_NAME = a2.CONSTRAINT_NAME
where a1.CONSTRAINT_TYPE = 'Unique' and a1.TABLE_NAME = @table_name
group by a1.CONSTRAINT_NAME
)as x


--select @unique_con



----------------------------------------------------------------------------------------

DECLARE @default_con VARCHAR(MAX) =''

SELECT @default_con = 'CONSTRAINT' + ' ' + @default_con + ConstraintName + ' '+ 'DEFAULT' +  ' ' +
					 Definition +'FOR' +' '+ ColumnName  
FROM (
select
st.Name as TableName,
co.Name as ColumnName ,
dc.Name as  ConstraintName,
dc.definition as Definition
FROM sys.tables st
INNER JOIN sys.default_constraints dc 
ON st.object_id = dc.parent_object_id
INNER JOIN sys.columns co 
ON dc.parent_object_id = co.object_id AND co.column_id = dc.parent_column_id
WHERE st.Name = @table_name
) as a

--SELECT @default_con

------------------------------------------------------------------------------------
 
DECLARE @check_con VARCHAR(MAX) = ''

SELECT   @check_con =  @check_con + ',' +  char(13) + char(10) + 'CONSTRAINT' + ' ' +  ConstraintName + ' '+ 'CHECK' +  ' ' + Definition 
FROM (

select
st.Name as TableName,  
co.Name as ColumnName ,
dc.Name as  ConstraintName,
dc.definition as Definition
FROM sys.tables st
INNER JOIN sys.check_constraints dc 
ON st.object_id = dc.parent_object_id
INNER JOIN sys.columns co 
ON dc.parent_object_id = co.object_id AND co.column_id = dc.parent_column_id
WHERE st.Name = @table_name
) as b

--select stuff(@check_con, 1, 2, '')

--------------------------------------------------------------------------------

select @combinedString = stuff(@combinedString, 1, 2, '')

SELECT 'Create table'+ ' '+ @table_name + ' ' + char(13) + char(10) +  '(' + @combinedString + ', '+ 
 case when @primary_key_con <>'' then  @primary_key_con + ', ' + char(13) + char(10) else '' end + 
 case when @foreign_key_con   <>'' then  stuff(@foreign_key_con, 1, 2, '')  + ', ' + char(13) + char(10) else '' end+
 case when @default_con  <>'' then @default_con  + ', '+ char(13) + char(10) else ''end  +
 case when @unique_con  <>'' then stuff(@unique_con, 1, 2, '')  + ', '+ char(13) + char(10) else ''end  +
 case when  @check_con  <>'' then  stuff(@check_con, 1, 2, '')   + char(13) + char(10) else '' end  + ')'

    
    
go



 EXEC table_details @table_name = 'Script_table_tester'
   
----------------------------------------------------------------------------------------------------------------

