--Numbers Table

;WITH digits (I) AS 
            (--set up a set of numbers from 0-9
              SELECT I
              FROM  (VALUES (0),(1),(2),(3),(4),
                            (5),(6),(7),(8),(9)) AS digits (I))
,integers (I) AS (
        SELECT D1.I + (10*D2.I) + (100*D3.I) + (1000*D4.I)
              -- + (10000*D5.I) + (100000*D6.I)
        FROM digits AS D1 CROSS JOIN digits AS D2 CROSS JOIN digits AS D3
                CROSS JOIN digits AS D4
              --CROSS JOIN digits AS D5 CROSS JOIN digits AS D6
                )
SELECT I
FROM   integers
ORDER  BY I;
GO

;WITH digits (I) AS 
            (--set up a set of numbers from 0-9
              SELECT I
              FROM  (VALUES (0),(1),(2),(3),(4),
                            (5),(6),(7),(8),(9)) AS digits (I))
,integers (I) AS (
        SELECT D1.I + (10*D2.I) + (100*D3.I) + (1000*D4.I)
               + (10000*D5.I) + (100000*D6.I)
        FROM digits AS D1 CROSS JOIN digits AS D2 CROSS JOIN digits AS D3
                CROSS JOIN digits AS D4
                CROSS JOIN digits AS D5 CROSS JOIN digits AS D6
                )
SELECT I
FROM   integers
ORDER  BY I;
GO

;WITH digits (I) AS (--set up a set of numbers from 0-9
        SELECT i
        FROM   (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS digits (I))
SELECT D1.I AS D1I, 10*D2.I AS D2I, D1.I + (10*D2.I) AS [Sum]
FROM digits AS D1 CROSS JOIN digits AS D2
ORDER BY [Sum];
GO

USE WideWorldImporters;
GO
CREATE SCHEMA Tools;
GO
CREATE TABLE Tools.Number
(
    I   int CONSTRAINT PKTools_Number PRIMARY KEY
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

SELECT COUNT(*) 
FROM   Tools.Number 
WHERE  I between 1 and 1000;
GO

SELECT COUNT(*) 
FROM   Tools.Number 
WHERE  I BETWEEN 1 AND 1000
  AND  (I % 9 = 0 OR I % 7 = 0);
GO

DECLARE @string varchar(20) = 'Hello nurse!'

SELECT Number.I as Position,
       SUBSTRING(split.value,Number.I,1) AS [Character],
       UNICODE(SUBSTRING(split.value,Number.I,1)) AS [Unicode]
FROM   Tools.Number
         CROSS JOIN (SELECT @string AS value) AS split
WHERE  Number.I > 0 --No zeroth position
  AND  Number.I <= LEN(@string)
ORDER BY Position;
GO

SELECT People.FullName, Number.I AS position,
              SUBSTRING(People.FullName,Number.I,1) AS [char],
              UNICODE(SUBSTRING(People.FullName, Number.I,1)) AS [Unicode]
FROM   /*WideWorldImporters.*/ Application.People
         JOIN Tools.Number
               ON Number.I <= LEN(People.FullName )
                   AND  UNICODE(SUBSTRING(People.FullName, Number.I,1)) IS NOT NULL
ORDER  BY FullName;
GO

SELECT People.FullName, Number.I AS position,
              SUBSTRING(People.FullName,Number.I,1) AS [char],
              UNICODE(SUBSTRING(People.FullName, Number.I,1)) AS [Unicode]
FROM   /*WideWorldImporters.*/ Application.People
         JOIN Tools.Number
               ON Number.I <= LEN(People.FullName )
                   AND  UNICODE(SUBSTRING(People.FullName, Number.I,1)) IS NOT NULL
WHERE  SUBSTRING(People.FullName, Number.I,1) NOT LIKE '[a-zA-Z ~''~-]' ESCAPE '~'
ORDER  BY FullName;
GO


SELECT  MIN(PersonId) AS MinValue, MAX(PersonId) AS MaxValue,
	MAX(PersonId) - MIN(PersonId) + 1 AS ExpectedNumberOfRows, 
	COUNT(*) AS NumberOfRows,
	MAX(PersonId) - COUNT(*) AS MissingRows
FROM    /*WideWorldImporters.*/ Application.People;

SELECT Number.I
FROM   Tools.Number
WHERE  I BETWEEN 1 AND 3261
EXCEPT 
SELECT PersonId
FROM    /*WideWorldImporters.*/ Application.People;
GO


SELECT *
FROM   STRING_SPLIT('1,2,3',',');
GO

DECLARE @delimitedList VARCHAR(100) = '1,2,3'

SELECT SUBSTRING(',' + @delimitedList + ',',I + 1,
          CHARINDEX(',',',' + @delimitedList + ',',I + 1) - I - 1) AS value
FROM Tools.Number
WHERE I >= 1 
  AND I < LEN(',' + @delimitedList + ',') - 1
  AND SUBSTRING(',' + @delimitedList + ',', I, 1) = ','
ORDER BY I;

DECLARE @delimitedList VARCHAR(100) = '1,2,3';

SELECT I
FROM Tools.Number
WHERE I >= 1
  AND I < LEN(',' + @delimitedList + ',') - 1
  AND SUBSTRING(',' + @delimitedList + ',', I, 1) = ','
ORDER BY I;
GO

CREATE TABLE dbo.poorDesign
(
    poorDesignId    int,
    badValue        varchar(20)
);
INSERT INTO dbo.poorDesign
VALUES (1,'1,3,56,7,3,6'),
       (2,'22,3'),
       (3,'1');
GO

SELECT poorDesign.poorDesignId AS betterDesignId,
       SUBSTRING(',' + poorDesign.badValue + ',',I + 1,
               CHARINDEX(',',',' + poorDesign.badValue + ',', I + 1) - I - 1)
                                       AS betterScalarValue
FROM   dbo.poorDesign
         JOIN Tools.Number
            ON I >= 1
              AND I < LEN(',' + poorDesign.badValue + ',') - 1
              AND SUBSTRING(',' + + poorDesign.badValue  + ',', I, 1) = ',';
GO

SELECT poorDesign.poorDesignId, stringSplit.value
FROM   dbo.poorDesign
		  CROSS APPLY STRING_SPLIT(badValue,',') AS stringSplit
GO

DROP TABLE dbo.poorDesign;
GO

----------------------------------------------
--Calendar table

CREATE TABLE Tools.Calendar
(
        DateValue date NOT NULL CONSTRAINT PKtools_calendar PRIMARY KEY,
        DayName varchar(10) NOT NULL,
        MonthName varchar(10) NOT NULL,
        Year varchar(60) NOT NULL,
        Day tinyint NOT NULL,
        DayOfTheYear smallint NOT NULL,
        Month smallint NOT NULL,
        Quarter tinyint NOT NULL
);
GO

WITH dates (newDateValue) AS (
        SELECT DATEADD(day,I,'17530101') AS newDateValue
        FROM Tools.Number
)
INSERT Tools.Calendar
        (DateValue ,DayName
        ,MonthName ,Year ,Day
        ,DayOfTheYear ,Month ,Quarter
)
SELECT
        dates.newDateValue as DateValue,
        DATENAME (dw,dates.newDateValue) As DayName,
        DATENAME (mm,dates.newDateValue) AS MonthName,
        DATENAME (yy,dates.newDateValue) AS Year,
        DATEPART(day,dates.newDateValue) AS Day,
        DATEPART(dy,dates.newDateValue) AS DayOfTheYear,
        DATEPART(m,dates.newDateValue) AS Month,
        DATEPART(qq,dates.newDateValue) AS Quarter

FROM    dates
WHERE   dates.newDateValue BETWEEN '20000101' AND '20200101' --set the date range
ORDER   BY DateValue;
GO

SELECT Calendar.DayName, COUNT(*) as OrderCount
FROM   /*WideWorldImporters.*/ Sales.Orders
         JOIN Tools.Calendar
               --note, the cast here could be a real performance killer
               --consider using date columns where possible
            ON CAST(Orders.OrderDate as date) = Calendar.DateValue
GROUP BY Calendar.DayName
ORDER BY Calendar.DayName;
GO

;WITH onlyWednesdays AS --get all Wednesdays
(
    SELECT *,
           ROW_NUMBER()  OVER (PARTITION BY Calendar.Year, Calendar.Month
                               ORDER BY Calendar.Day) AS wedRowNbr
    FROM   Tools.Calendar
    WHERE  DayName = 'Wednesday'
),
secondWednesdays AS --limit to second Wednesdays of the month
(
    SELECT *
    FROM   onlyWednesdays
    WHERE  wedRowNbr = 2
)
,finallyTuesdays AS --finally limit to the Tuesdays after the second wed
(
    SELECT Calendar.*,
           ROW_NUMBER() OVER (PARTITION BY Calendar.Year, Calendar.Month
                              ORDER by Calendar.Day) AS rowNbr
    FROM   secondWednesdays
             JOIN Tools.Calendar
                ON secondWednesdays.Year = Calendar.Year
                    AND secondWednesdays.Month = Calendar.Month
    WHERE  Calendar.DayName = 'Tuesday'
      AND  Calendar.Day > secondWednesdays.Day
)
--and in the final query, just get the one month
SELECT Year, MonthName, Day
FROM   finallyTuesdays
WHERE  Year = 2016
  AND  rowNbr = 1;
GO


DROP TABLE Tools.Calendar;
GO
CREATE TABLE Tools.Calendar
(
        DateValue date NOT NULL CONSTRAINT PKtools_calendar PRIMARY KEY,
        DayName varchar(10) NOT NULL,
        MonthName varchar(10) NOT NULL,
        Year varchar(60) NOT NULL,
        Day tinyint NOT NULL,
        DayOfTheYear smallint NOT NULL,
        Month smallint NOT NULL,
        Quarter tinyint NOT NULL,
	WeekendFlag bit NOT NULL,

        --start of fiscal year configurable in the load process, currently
        --only supports fiscal months that match the calendar months.
        FiscalYear smallint NOT NULL,
        FiscalMonth tinyint NULL,
        FiscalQuarter tinyint NOT NULL,

        --used to give relative positioning, such as the previous 10 months
        --which can be annoying due to month boundaries
        RelativeDayCount int NOT NULL,
        RelativeWeekCount int NOT NULL,
        RelativeMonthCount int NOT NULL
);
GO

;WITH dates (newDateValue) AS (
        SELECT DATEADD(day,I,'17530101') AS newDateValue
        FROM Tools.Number
)
INSERT Tools.Calendar
        (DateValue ,DayName
        ,MonthName ,Year ,Day
        ,DayOfTheYear ,Month ,Quarter
        ,WeekendFlag ,FiscalYear ,FiscalMonth
        ,FiscalQuarter ,RelativeDayCount,RelativeWeekCount
        ,RelativeMonthCount)
SELECT
        dates.newDateValue AS DateValue,
        DATENAME (dw,dates.newDateValue) AS DayName,
        DATENAME (mm,dates.newDateValue) AS MonthName,
        DATENAME (yy,dates.newDateValue) AS Year,
        DATEPART(day,dates.newDateValue) AS Day,
        DATEPART(dy,dates.newDateValue) AS DayOfTheYear,
        DATEPART(m,dates.newDateValue) AS Month,
        CASE
                WHEN MONTH( dates.newDateValue) <= 3 THEN 1
                WHEN MONTH( dates.newDateValue) <= 6 THEN 2
                When MONTH( dates.newDateValue) <= 9 THEN 3
        ELSE 4 END AS quarter,

        CASE WHEN DATENAME (dw,dates.newDateValue) IN ('Saturday','Sunday')
                THEN 1
                ELSE 0
        END AS weekendFlag,

        ------------------------------------------------
        --the next three blocks assume a fiscal year starting in July.
        --change if your fiscal periods are different
        ------------------------------------------------
        CASE
                WHEN MONTH(dates.newDateValue) <= 6
                THEN YEAR(dates.newDateValue)
                ELSE YEAR (dates.newDateValue) + 1
        END AS fiscalYear,

        CASE
                WHEN MONTH(dates.newDateValue) <= 6
                THEN MONTH(dates.newDateValue) + 6
                ELSE MONTH(dates.newDateValue) - 6
         END AS fiscalMonth,

        CASE
                WHEN MONTH(dates.newDateValue) <= 3 then 3
                WHEN MONTH(dates.newDateValue) <= 6 then 4
                WHEN MONTH(dates.newDateValue) <= 9 then 1
        ELSE 2 END AS fiscalQuarter,

        ------------------------------------------------
        --end of fiscal quarter = july
        ------------------------------------------------

        --these values can be anything, as long as they
        --provide contiguous values on year, month, and week boundaries
        DATEDIFF(day,'20000101',dates.newDateValue) AS RelativeDayCount,
        DATEDIFF(week,'20000101',dates.newDateValue) AS RelativeWeekCount,
        DATEDIFF(month,'20000101',dates.newDateValue) AS RelativeMonthCount

FROM    dates
WHERE  dates.newDateValue BETWEEN '20000101' AND '20200101'; --set the date range
GO

SELECT Calendar.FiscalYear, COUNT(*) AS OrderCount
FROM   /*WideWorldImporters.*/ Sales.Orders
         JOIN Tools.Calendar
               --note, the cast here could be a real performance killer
               --consider using a persisted calculated column here
            ON CAST(Orders.OrderDate as date) = Calendar.DateValue
WHERE    WeekendFlag = 1
GROUP BY Calendar.FiscalYear
ORDER BY Calendar.FiscalYear;
GO


DECLARE @interestingDate date = '20140509';

SELECT Calendar.DateValue as PreviousTwoWeeks, CurrentDate.DateValue AS Today,
        Calendar.RelativeWeekCount
FROM   Tools.Calendar
           JOIN (SELECT *
                 FROM Tools.Calendar
                 WHERE DateValue = @interestingDate) AS CurrentDate
              ON  Calendar.RelativeWeekCount < (CurrentDate.RelativeWeekCount)
                  and Calendar.RelativeWeekCount >=
                                         (CurrentDate.RelativeWeekCount -2);
GO

DECLARE @interestingDate date = '20140509'

SELECT MIN(Calendar.DateValue) AS MinDate, MAX(Calendar.DateValue) AS MaxDate
FROM   Tools.Calendar
           JOIN (SELECT *
                 FROM Tools.Calendar
                 WHERE DateValue = @interestingDate) as CurrentDate
              ON  Calendar.RelativeMonthCount < (CurrentDate.RelativeMonthCount)
                  AND Calendar.RelativeMonthCount >=
                                       (CurrentDate.RelativeMonthCount -12);
GO

DECLARE @interestingDate date = '20140509'

SELECT Calendar.Year, Calendar.Month, COUNT(*) AS OrderCount
FROM   /*WorldWideImporters.*/ Sales.Orders
         JOIN Tools.Calendar
           JOIN (SELECT *
                 FROM Tools.Calendar
                 WHERE DateValue = @interestingDate) as CurrentDate
                   ON  Calendar.RelativeMonthCount <=
                                           (CurrentDate.RelativeMonthCount )
                    AND Calendar.RelativeMonthCount >=
                                           (CurrentDate.RelativeMonthCount -10)
            ON Orders.ExpectedDeliveryDate = Calendar.DateValue
GROUP BY Calendar.Year, Calendar.Month	
ORDER BY Calendar.Year, Calendar.Month;
GO

-----------------------------------------------
-- Utility Objects

CREATE SCHEMA Monitor;
GO

CREATE TABLE Monitor.TableRowCount
(
	SchemaName  sysname NOT NULL,
	TableName	sysname NOT NULL,
	CaptureDate date    NOT NULL,
	Rows   	integer NOT NULL, --proper name, rowcount is reserved
	ObjectType	sysname NOT NULL,
	Constraint PKTableRowCount PRIMARY KEY (SchemaName, TableName, CaptureDate)
);
GO

CREATE PROCEDURE Monitor.TableRowCount$captureRowcounts
AS
-- ----------------------------------------------------------------
-- Monitor the row counts of all tables in the database on a daily basis
-- Error handling not included for example clarity
--
-- NOTE: This code expects the Monitor.TableRowCount to be in the same db as the 
--       tables being monitored. Rework would be needed if this is not a possibility
--
-- 2016 Louis Davidson – drsql@hotmail.com – drsql.org
-- ----------------------------------------------------------------

-- The CTE is used to set upthe set of rows to put into the Monitor.TableRowCount table
WITH CurrentRowcount AS (
SELECT OBJECT_SCHEMA_NAME(partitions.object_id) AS SchemaName, 
       OBJECT_NAME(partitions.object_id) AS TableName, 
       CAST(getdate() AS date) AS CaptureDate,
       SUM(rows) AS Rows,
       objects.type_desc AS ObjectType
FROM   sys.partitions
          JOIN sys.objects
               ON partitions.object_id = objects.object_id
WHERE  index_id in (0,1) --Heap 0 or Clustered 1 “indexes”
AND    object_schema_name(partitions.object_id) NOT IN ('sys')
--the GROUP BY handles partitioned tables with > 1 partition
GROUP BY partitions.object_id, objects.type_desc)

--MERGE allows this procedure to be run > 1 a day without concern, it will update if the row
--for the day exists
MERGE  Monitor.TableRowCount
USING  (SELECT SchemaName, TableName, CaptureDate, Rows, ObjectType 
        FROM CurrentRowcount) AS Source 
               ON (Source.SchemaName = TableRowCount.SchemaName
                   AND Source.TableName = TableRowCount.TableName
                   AND Source.CaptureDate = TableRowCount.CaptureDate)
WHEN MATCHED THEN  
        UPDATE SET Rows = Source.Rows
WHEN NOT MATCHED THEN
        INSERT (SchemaName, TableName, CaptureDate, Rows, ObjectType) 
        VALUES (Source.SchemaName, Source.TableName, Source.CaptureDate, 
                Source.Rows, Source.ObjectType);
GO

EXEC Monitor.TableRowCount$CaptureRowcounts;
GO

SELECT *
FROM   Monitor.TableRowCount
WHERE  SchemaName = 'Purchasing'
ORDER BY SchemaName, TableName;
GO

CREATE SCHEMA Utility;
GO
CREATE PROCEDURE Utility.Constraints$ResetEnableAndTrustedStatus
(
    @table_name sysname = '%', 
    @table_schema sysname = '%',
    @doFkFlag bit = 1,
    @doCkFlag bit = 1
) as
-- ----------------------------------------------------------------
-- Enables disabled foreign key and check constraints, and sets
-- trusted status so optimizer can use them
--
-- NOTE: This code expects the Monitor.TableRowCount to be in the same db as the 
--       tables being monitored. Rework would be needed if this is not a possibility
--
-- 2016 Louis Davidson – drsql@hotmail.com – drsql.org 
-- ----------------------------------------------------------------

 BEGIN
 
      SET NOCOUNT ON;
      DECLARE @statements cursor; --use to loop through constraints to execute one 
                                 --constraint for individual DDL calls
      SET @statements = cursor for 
           WITH FKandCHK AS (SELECT OBJECT_SCHEMA_NAME(parent_object_id) AS schemaName,                                       
                                    OBJECT_NAME(parent_object_id) AS tableName,
                                    NAME AS constraintName, Type_desc AS constraintType, 
                                    is_disabled AS DisabledFlag, 
                                    (is_not_trusted + 1) % 2 AS TrustedFlag
                             FROM   sys.foreign_keys
                             UNION ALL 
                             SELECT OBJECT_SCHEMA_NAME(parent_object_id) AS schemaName, 
                                    OBJECT_NAME(parent_object_id) AS tableName,
                                    NAME AS constraintName, Type_desc AS constraintType, 
                                    is_disabled AS DisabledFlag, 
                                    (is_not_trusted + 1) % 2 AS TrustedFlag
                             FROM   sys.check_constraints )
           SELECT schemaName, tableName, constraintName, constraintType, 
                  DisabledFlag, TrustedFlag 
           FROM   FKandCHK
           WHERE  (TrustedFlag = 0 OR DisabledFlag = 1)
             AND  ((constraintType = 'FOREIGN_KEY_CONSTRAINT' AND @doFkFlag = 1)
                    OR (constraintType = 'CHECK_CONSTRAINT' AND @doCkFlag = 1))
             AND  schemaName LIKE @table_Schema
             AND  tableName LIKE @table_Name;

      OPEN @statements;

      DECLARE @statement varchar(1000), @schemaName sysname, 
              @tableName sysname, @constraintName sysname, 
              @constraintType sysname,@disabledFlag bit, @trustedFlag bit;

      WHILE 1=1
         BEGIN
              FETCH FROM @statements INTO @schemaName, @tableName, @constraintName,                 
                                          @constraintType, @disabledFlag, @trustedFlag;
               IF @@FETCH_STATUS <> 0
                    BREAK;

               BEGIN TRY -- will output an error if it occurs but will keep on going 
                        --so other constraints will be adjusted

                 IF @constraintType = 'CHECK_CONSTRAINT'

                            SELECT @statement = 'ALTER TABLE ' + @schemaName + '.' 
                                            + @tableName + ' WITH CHECK CHECK CONSTRAINT ' 
                                            + @constraintName;
                  ELSE IF @constraintType = 'FOREIGN_KEY_CONSTRAINT'
                            SELECT @statement = 'ALTER TABLE ' + @schemaName + '.' 
                                            + @tableName + ' WITH CHECK CHECK CONSTRAINT ' 
                                            + @constraintName;
                  EXEC (@statement);                                 
              END TRY
              BEGIN CATCH --output statement that was executed along with the error number
                  select 'Error occurred: ' + cast(error_number() as varchar(10))+ ':' +  
                          error_message() + char(13) + char(10) +  'Statement executed: ' +  
                          @statement;
              END CATCH
        END;

   END;
GO

-------------------------------------
--Logging


CREATE SCHEMA ErrorHandling;
GO
CREATE TABLE ErrorHandling.ErrorLog(
        ErrorLogId int NOT NULL IDENTITY CONSTRAINT PKErrorLog PRIMARY KEY,
		Number int NOT NULL,
        Location sysname NOT NULL,
        Message varchar(4000) NOT NULL,
        LogTime datetime2(3) NULL
              CONSTRAINT DFLTErrorLog_error_date  DEFAULT (SYSDATETIME()),
        ServerPrincipal sysname NOT NULL
              --use original_login to capture the user name of the actual user
              --not a user they have impersonated
              CONSTRAINT DFLTErrorLog_error_user_name DEFAULT (ORIGINAL_LOGIN())
);
GO

CREATE PROCEDURE ErrorHandling.ErrorLog$Insert
(
        @ERROR_NUMBER int,
        @ERROR_LOCATION sysname,
        @ERROR_MESSAGE varchar(4000)
) AS
-- ----------------------------------------------------------------
-- Writes a row to the error log. If an error occurs in the call (such as a NULL value)
-- It writes a row to the error table. If that call fails an error will be returned
--
-- 2016 Louis Davidson – drsql@hotmail.com – drsql.org 
-- ----------------------------------------------------------------

 BEGIN
        SET NOCOUNT ON;
        BEGIN TRY
           INSERT INTO ErrorHandling.ErrorLog(Number, Location,Message)
           SELECT @ERROR_NUMBER,COALESCE(@ERROR_LOCATION,'No Object'),@ERROR_MESSAGE;
        END TRY
        BEGIN CATCH
           INSERT INTO ErrorHandling.ErrorLog(Number, Location, Message)
           VALUES (-100, 'Utility.ErrorLog$insert',
                        'An invalid call was made to the error log procedure ' +  
                                     ERROR_MESSAGE());
        END CATCH
END;
GO

--test the error block we will use
BEGIN TRY
    THROW 50000,'Test error',16;
END TRY
BEGIN CATCH
    IF @@trancount > 0
        ROLLBACK TRANSACTION;

    --[Error logging section]
	DECLARE @ERROR_NUMBER int = ERROR_NUMBER(),
                @ERROR_PROCEDURE sysname = ERROR_PROCEDURE(),
	        @ERROR_MESSAGE varchar(4000) = ERROR_MESSAGE();
	EXEC ErrorHandling.ErrorLog$Insert @ERROR_NUMBER,@ERROR_PROCEDURE,@ERROR_MESSAGE;

    THROW; --will halt the batch or be caught by the caller's catch block

END CATCH;
GO

SELECT *
FROM  ErrorHandling.ErrorLog;



/************************************************************
In-Memory Alternate Versions
************************************************************/
USE WideWorldImporters;
GO
CREATE SCHEMA Tools_InMem;
GO
CREATE TABLE Tools_InMem.Number
(
    I   int CONSTRAINT PKTools_Number_InMem PRIMARY KEY NONCLUSTERED
) WITH (MEMORY_OPTIMIZED = ON); 
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
INSERT INTO Tools_InMem.Number(I)
SELECT I
FROM   Integers;

GO

SELECT COUNT(*) 
FROM   Tools_InMem.Number
WHERE  I between 1 and 1000;
GO

SELECT COUNT(*) 
FROM   Tools_InMem.Number 
WHERE  I BETWEEN 1 AND 1000
  AND  (I % 9 = 0 OR I % 7 = 0);
GO

DECLARE @string varchar(20) = 'Hello nurse!'

SELECT Number.I as Position,
       SUBSTRING(split.value,Number.I,1) AS [Character],
       UNICODE(SUBSTRING(split.value,Number.I,1)) AS [Unicode]
FROM   Tools_InMem.Number
         CROSS JOIN (SELECT @string AS value) AS split
WHERE  Number.I > 0 --No zeroth position
  AND  Number.I <= LEN(@string)
ORDER BY Position;
GO

SELECT People.FullName, Number.I AS position,
              SUBSTRING(People.FullName,Number.I,1) AS [char],
              UNICODE(SUBSTRING(People.FullName, Number.I,1)) AS [Unicode]
FROM   /*WideWorldImporters.*/ Application.People
         JOIN Tools_InMem.Number
               ON Number.I <= LEN(People.FullName )
                   AND  UNICODE(SUBSTRING(People.FullName, Number.I,1)) IS NOT NULL
ORDER  BY FullName;
GO

SELECT People.FullName, Number.I AS position,
              SUBSTRING(People.FullName,Number.I,1) AS [char],
              UNICODE(SUBSTRING(People.FullName, Number.I,1)) AS [Unicode]
FROM   /*WideWorldImporters.*/ Application.People
         JOIN Tools.Number
               ON Number.I <= LEN(People.FullName )
                   AND  UNICODE(SUBSTRING(People.FullName, Number.I,1)) IS NOT NULL
WHERE  SUBSTRING(People.FullName, Number.I,1) NOT LIKE '[a-zA-Z ~''~-]' ESCAPE '~'
ORDER  BY FullName;
GO


SELECT  MIN(PersonId) AS MinValue, MAX(PersonId) AS MaxValue,
	MAX(PersonId) - MIN(PersonId) + 1 AS ExpectedNumberOfRows, 
	COUNT(*) AS NumberOfRows,
	MAX(PersonId) - COUNT(*) AS MissingRows
FROM    /*WideWorldImporters.*/ Application.People;

SELECT Number.I
FROM   Tools_InMem.Number
WHERE  I BETWEEN 1 AND 3261
EXCEPT 
SELECT PersonId
FROM    /*WideWorldImporters.*/ Application.People;
GO


SELECT *
FROM   STRING_SPLIT('1,2,3',',');
GO

DECLARE @delimitedList VARCHAR(100) = '1,2,3'

SELECT SUBSTRING(',' + @delimitedList + ',',I + 1,
          CHARINDEX(',',',' + @delimitedList + ',',I + 1) - I - 1) AS value
FROM Tools_InMem.Number
WHERE I >= 1 
  AND I < LEN(',' + @delimitedList + ',') - 1
  AND SUBSTRING(',' + @delimitedList + ',', I, 1) = ','
ORDER BY I;

DECLARE @delimitedList VARCHAR(100) = '1,2,3';

SELECT I
FROM Tools_InMem.Number
WHERE I >= 1
  AND I < LEN(',' + @delimitedList + ',') - 1
  AND SUBSTRING(',' + @delimitedList + ',', I, 1) = ','
ORDER BY I;
GO

CREATE SCHEMA dbo_InMem;
GO

CREATE TABLE dbo_InMem.poorDesign
(
    poorDesignId    int PRIMARY KEY NONCLUSTERED,
    badValue        varchar(20)
) WITH (MEMORY_OPTIMIZED = ON);

INSERT INTO dbo_InMem.poorDesign
VALUES (1,'1,3,56,7,3,6'),
       (2,'22,3'),
       (3,'1');
GO

SELECT poorDesign.poorDesignId AS betterDesignId,
       SUBSTRING(',' + poorDesign.badValue + ',',I + 1,
               CHARINDEX(',',',' + poorDesign.badValue + ',', I + 1) - I - 1)
                                       AS betterScalarValue
FROM   dbo_InMem.poorDesign
         JOIN Tools_InMem.Number
            ON I >= 1
              AND I < LEN(',' + poorDesign.badValue + ',') - 1
              AND SUBSTRING(',' + + poorDesign.badValue  + ',', I, 1) = ',';
GO

SELECT poorDesign.poorDesignId, stringSplit.value
FROM    dbo_InMem.poorDesign
		  CROSS APPLY STRING_SPLIT(badValue,',') AS stringSplit
GO

DROP TABLE  dbo_InMem.poorDesign;
GO
