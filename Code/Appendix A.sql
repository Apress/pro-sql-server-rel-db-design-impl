--=============================
-- Integer Values

SELECT 1/2;
GO

SELECT CAST(.99999999 AS integer);
GO

SELECT 305 / 100, 305 % 100;
GO

SELECT  CAST(305 AS numeric)/ 100, (305 * 1.0) / 100;
GO

DECLARE @testvar decimal(3,1)
GO





SELECT name, system_type_id
FROM   sys.types
WHERE  name IN ('decimal','numeric');
GO


DECLARE @testvar decimal(3,1)
SELECT @testvar = -10.155555555;
SELECT @testvar;
GO

SET NUMERIC_ROUNDABORT ON;
DECLARE @testvar decimal(3,1);
SELECT @testvar = -10.155555555;
SET NUMERIC_ROUNDABORT OFF ;--this setting persists for a connection
GO

CREATE TABLE dbo.TestMoney
(
    MoneyValue money
);
go

INSERT INTO dbo.TestMoney
VALUES ($100);
INSERT INTO dbo.TestMoney
VALUES (100);
INSERT INTO dbo.TestMoney
VALUES (£100);
GO

SELECT * FROM dbo.TestMoney;
GO

DECLARE @money1 money  = 1.00,
        @money2 money  = 800.00;

SELECT CAST(@money1/@money2 AS money);


DECLARE @decimal1 decimal(19,4) = 1.00,
        @decimal2 decimal(19,4) = 800.00;

SELECT  CAST(@decimal1/@decimal2 AS decimal(19,4));

SELECT  @money1/@money2;
SELECT  @decimal1/@decimal2;
GO


DECLARE @LocalTime DateTimeOffset;
SET @LocalTime = SYSDATETIMEOFFSET();
SELECT @LocalTime;
SELECT SWITCHOFFSET(@LocalTime, '+00:00') AS UTCTime;
GO

DECLARE @time1 date = '20111231',
        @time2 date = '20120102';
SELECT DATEDIFF(yy,@time1,@time2);
GO

DECLARE @time1 date = '20110101',
        @time2 date = '20121231';
SELECT DATEDIFF(yy,@time1,@time2);
GO

SELECT CAST('2013-01-01' AS date) AS dateOnly;
SELECT CAST('2013-01-01 14:23:00.003' AS datetime) AS withTime;
GO

SELECT CAST ('20130101' AS date) AS dateOnly;
SELECT CAST('2013-01-01T14:23:00.120' AS datetime) AS withTime;
GO

DECLARE @DateValue datetime2(3) = '2012-05-21 15:45:01.456'
SELECT @DateValue AS Unformatted,
       FORMAT(@DateValue,'yyyyMMdd') AS IsoUnseperated, 
       FORMAT(@DateValue,'yyyy-MM-ddThh:mm:ss') AS IsoDateTime, 
       FORMAT(@DateValue,'D','en-US' ) AS USRegional,
       FORMAT(@DateValue,'D','en-GB' ) AS GBRegional,
       FORMAT(@DateValue,'D','fr-fr' ) AS FRRegional;
GO

USE Tempdb;
GO
CREATE SCHEMA Tools;
GO
CREATE TABLE Tools.Number
(
    I   int CONSTRAINT PKNumber PRIMARY KEY
);
GO
;WITH digits (I) AS (--set up a set of numbers from 0-9
        SELECT I
        FROM   (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS digits (I))
--builds a table from 0 to 99999
,Integers (I) AS (
        SELECT D1.I + (10*D2.I) + (100*D3.I) + (1000*D4.I) + (10000*D5.I)
               --+ (100000*D6.I)
        FROM digits AS D1 CROSS JOIN digits AS D2 CROSS JOIN digits AS D3
                CROSS JOIN digits AS D4 CROSS JOIN digits AS D5
                /* CROSS JOIN digits AS D6 */)
INSERT INTO Tools.Number(I)
SELECT I
FROM   Integers;
GO

SELECT I, CHAR(I)
FROM   Tools.Number
WHERE  I >=0 and I <= 255;
GO

SELECT I, NCHAR(I)
FROM   Tools.Number
WHERE  I >=0 and I <= 65535;
GO

DECLARE @value varchar(max) = REPLICATE('X',8000) + REPLICATE('X',8000);
SELECT LEN(@value);
GO

DECLARE @value varchar(max) = REPLICATE(cast('X' AS varchar(max)),8000) 
                              + REPLICATE(cast('X' AS varchar(max)),8000);
SELECT LEN(@value);
GO

SELECT N'Unicode Value';
GO

SELECT I, NCHAR(I)
FROM   Tools.Number
WHERE  I >=0 and I <= 65535;
GO

DECLARE @value binary(10)  = CAST('helloworld' AS binary(10));
SELECT @value;
GO

SELECT CAST(0x68656C6C6F776F726C64 AS varchar(10));
GO

DECLARE @value binary(10)  = CAST('HELLOWORLD' AS binary(10));
SELECT @value;
GO

SELECT CAST ('True' AS bit) AS True, CAST('False' AS bit) AS False
GO


SET NOCOUNT ON;
CREATE TABLE dbo.TestRowversion
(
   Value   varchar(20) NOT NULL,
   Auto_rv   rowversion NOT NULL
);

INSERT INTO dbo.TestRowversion (Value) 
VALUES('Insert');

SELECT Value, Auto_rv 
FROM dbo.testRowversion;

UPDATE dbo.TestRowversion
SET Value = 'First Update';

SELECT Value, Auto_rv 
FROM dbo.TestRowversion;

UPDATE dbo.TestRowversion
SET Value = 'Last Update'; 

SELECT value, auto_rv
FROM dbo.TestRowversion;
GO

DECLARE @guidVar uniqueidentifier = NEWID();

SELECT @guidVar AS guidVar;
GO

CREATE TABLE dbo.GuidPrimaryKey
(
   GuidPrimaryKeyId uniqueidentifier NOT NULL ROWGUIDCOL PRIMARY KEY DEFAULT NEWID(),
   Value varchar(10)
);
GO

INSERT INTO dbo.GuidPrimaryKey(Value)
VALUES ('Test');
GO

SELECT *
FROM   dbo.GuidPrimaryKey;
GO

DROP TABLE dbo.GuidPrimaryKey;
GO
CREATE TABLE dbo.GuidPrimaryKey
(
   GuidPrimaryKeyId uniqueidentifier NOT NULL
                    ROWGUIDCOL DEFAULT NEWSEQUENTIALID()
					CONSTRAINT PKGuidPrimaryKey PRIMARY KEY,
   Value varchar(10)
);
GO
INSERT INTO dbo.GuidPrimaryKey(value)
VALUES('Test'),  
      ('Test1'),
      ('Test2');
GO

SELECT *
FROM   GuidPrimaryKey;
GO

DECLARE @tableVar TABLE
(
   Id int IDENTITY PRIMARY KEY,
   Value varchar(100)
);
INSERT INTO @tableVar (Value)
VALUES ('This is a cool test');

SELECT Id, Value
FROM @tableVar;
GO

CREATE FUNCTION dbo.Table$TestFunction
(
   @returnValue varchar(100)

)
RETURNS @tableVar table
(
     Value varchar(100)
)
AS
BEGIN
   INSERT INTO @tableVar (Value)
   VALUES (@returnValue);

   RETURN;
END;
GO

SELECT *
FROM dbo.Table$testFunction('testValue');
GO

DECLARE @tableVar TABLE
(
   Id int IDENTITY,
   Value varchar(100)
);
BEGIN TRANSACTION;

INSERT INTO @tableVar (Value)
VALUES ('This will still be there');

ROLLBACK TRANSACTION;

SELECT Id, Value
FROM @tableVar;
GO

USE WideWorldImporters;
GO
CREATE TYPE GenericIdList AS TABLE
(
    Id Int Primary Key
);
GO

DECLARE @PeopleIdList GenericIdList;
INSERT INTO @PeopleIdList
VALUES (2),(3),(4);

SELECT PersonId, FullName
FROM   Application.People
         JOIN @PeopleIdList as list
            on People.PersonId = List.Id;
GO

--database must support in-memory with in-mem filegrou
CREATE TYPE GenericIdList_InMem AS TABLE
(
    Id Int PRIMARY KEY NONCLUSTERED --Use nonclustered here, 
	                                --as it should be fine for 
									--typical uses

) WITH (MEMORY_OPTIMIZED = ON);
GO

DECLARE @PeopleIdList GenericIdList_InMem;
INSERT INTO @PeopleIdList
VALUES (2),(3),(4);

SELECT PersonId, FullName
FROM   Application.People
         JOIN @PeopleIdList as list
            on People.PersonId = List.Id;
GO

CREATE PROCEDURE Application.People$List
(
    @PeopleIdList GenericIdList READONLY
)
AS
SELECT PersonId, FullName
FROM   Application.People
         JOIN @PeopleIdList as list
            on People.PersonId = List.Id;

GO

DECLARE @PeopleIdList GenericIdList;

INSERT INTO @PeopleIdList
VALUES (2),(3),(4);

EXEC Application.People$List @PeopleIdList;
GO

CREATE PROCEDURE Application.People$List_InMemTableVar
(
    @PeopleIdList GenericIdList_InMem READONLY
)
AS
SELECT PersonId, FullName
FROM   Application.People
         JOIN @PeopleIdList as list
            on People.PersonId = List.Id;

GO

DECLARE @PeopleIdList GenericIdList_InMem;

INSERT INTO @PeopleIdList
VALUES (2),(3),(4);

EXEC Application.People$List_InMemTableVar @PeopleIdList;
GO

DECLARE @numericVariant sql_variant = 123456.789;

SELECT @numericVariant AS numericVariant,
   SQL_VARIANT_PROPERTY(@numericVariant,'BaseType') AS baseType,
   SQL_VARIANT_PROPERTY(@numericVariant,'Precision') AS precision,
   SQL_VARIANT_PROPERTY(@numericVariant,'Scale') AS scale;


------------------------
--SQL Variant

DECLARE @varcharVariant sql_variant = '1234567890';

SELECT @varcharVariant AS varcharVariant,
   SQL_VARIANT_PROPERTY(@varcharVariant,'BaseType') AS baseType,
   SQL_VARIANT_PROPERTY(@varcharVariant,'MaxLength') AS maxLength,
   SQL_VARIANT_PROPERTY(@varcharVariant,'Collation') AS collation;
