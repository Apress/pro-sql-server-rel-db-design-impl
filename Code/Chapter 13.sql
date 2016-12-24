--Choosing the Engine for Your Needs
---Ad Hoc SQL
----Advantages
-----Runtime Control over Queries
CREATE SCHEMA Sales;
GO
CREATE TABLE Sales.Contact
(
    ContactId   int CONSTRAINT PKContact PRIMARY KEY,
    FirstName   varchar(30),
    LastName    varchar(30),
    LompanyName varchar(100),
    SalesLevelId  int, --real table would implement as a foreign key
    ContactNotes  varchar(max),
    CONSTRAINT AKContact UNIQUE (FirstName, LastName, CompanyName)
);
--a few rows to show some output from queries
INSERT INTO Sales.Contact
            (ContactId, FirstName, Lastname, CompanyName, SaleslevelId, ContactNotes)
VALUES( 1,'Drue','Karry','SeeBeeEss',1, 
           REPLICATE ('Blah...',10) + 'Called and discussed new ideas'),
      ( 2,'Jon','Rettre','Daughter Inc',2,
           REPLICATE ('Yada...',10) + 'Called, but he had passed on');
GO


SELECT  ContactId, FirstName, LastName, CompanyName, 
        RIGHT(ContactNotes,30) as NotesEnd
FROM    Sales.Contact;
GO

SELECT ContactId, FirstName, LastName, CompanyName 
FROM Sales.Contact;
GO

CREATE TABLE Sales.Purchase
(
    PurchaseId int CONSTRAINT PKPurchase PRIMARY KEY,
    Amount      numeric(10,2),
    PurchaseDate date,
    ContactId   int
        CONSTRAINT FKContact$hasPurchasesIn$Sales_Purchase
            REFERENCES Sales.Contact(ContactId)
);
GO
INSERT INTO Sales.Purchase(PurchaseId, Amount, PurchaseDate, ContactId)
VALUES (1,100.00,'2016-05-12',1),(2,200.00,'2016-05-10',1),
       (3,100.00,'2016-05-12',2),(4,300.00,'2016-05-12',1),
       (5,100.00,'2016-04-11',1),(6,5500.00,'2016-05-14',2),
       (7,100.00,'2016-04-01',1),(8,1020.00,'2016-06-03',2);
GO


SELECT  Contact.ContactId, Contact.FirstName, Contact.LastName
        ,Sales.YearToDateSales, Sales.LastSaleDate
FROM   Sales.Contact as Contact
          LEFT OUTER JOIN
             (SELECT ContactId,
                     SUM(Amount) AS YearToDateSales,
                     MAX(PurchaseDate) AS LastSaleDate
              FROM   Sales.Purchase
              WHERE  PurchaseDate >= --the first day of the current year
                        DATEADD(day, 0, DATEDIFF(day, 0, SYSDATETIME() ) 
                          - DATEPART(dayofyear,SYSDATETIME() ) + 1)
              GROUP  by ContactId) AS sales
              ON Contact.ContactId = Sales.ContactId
WHERE   Contact.LastName like 'Rett%';
GO


SELECT  Contact.ContactId, Contact.FirstName, Contact.LastName
        --,Sales.YearToDateSales, Sales.LastSaleDate
FROM   Sales.Contact as Contact
          --LEFT OUTER JOIN
          --   (SELECT ContactId,
          --           SUM(Amount) AS YearToDateSales,
          --           MAX(PurchaseDate) AS LastSaleDate
          --    FROM   Sales.Purchase
          --    WHERE  PurchaseDate >= --the first day of the current year
          --              DATEADD(day, 0, DATEDIFF(day, 0, SYSDATETIME() ) 
          --                - DATEPART(dayofyear,SYSDATETIME() ) + 1)
          --    GROUP  by ContactId) AS sales
          --    ON Contact.ContactId = Sales.ContactId
WHERE   Contact.LastName like 'Karr%';

UPDATE Sales.Contact
SET    FirstName = 'Drew',
       LastName = 'Carey',
       SalesLevelId = 1, --no change
       CompanyName = 'CBS', 
       ContactNotes = 'Blah...Blah...Blah...Blah...Blah...Blah...Blah...Blah...Blah...'         
                      + 'Blah...Called and discussed new ideas' --no change
WHERE ContactId = 1;
GO

UPDATE Sales.Contact
SET    FirstName = 'John',
       LastName = 'Ritter'
WHERE  ContactId = 2;
GO

SELECT FirstName, LastName, CompanyName
FROM   Sales.Contact
WHERE  FirstName LIKE 'J%'
  AND  LastName LIKE  'R%';
GO

SELECT FirstName, LastName, CompanyName
FROM   Sales.Contact
WHERE  FirstName LIKE '%'
  AND  LastName LIKE 'Carey%';
GO


SELECT FirstName, LastName, CompanyName
FROM   Sales.Contact
WHERE  LastName LIKE 'Carey%';
GO

IF @FirstNameValue <> '%'
        SELECT FirstName, LastName, CompanyName
        FROM   Sales.Contact
        WHERE  FirstName LIKE @FirstNameLike
          AND  LastName LIKE @LastNameLike;
ELSE
        SELECT FirstName, LastName, CompanyName
        FROM   Sales.Contact
        WHERE  FirstName LIKE @FirstNameLike;
GO

---Flexibility over Shared Plans and Parameterization
USE WideWorldImporters;
GO
SET SHOWPLAN_TEXT ON
GO
SELECT People.FullName, Orders.OrderDate
FROM   Sales.Orders
                 JOIN Application.People 
                        ON Orders.ContactPersonID = People.PersonID
WHERE  People.FullName = N'Bala Dixit';
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON
GO
SELECT People.FullName, Orders.OrderDate
FROM   Sales.Orders 
                 JOIN Application.People 
                        on Orders.ContactPersonID = People.PersonID
WHERE  People.FullName = N'Bala Dixit';
GO
SET SHOWPLAN_TEXT OFF
GO


SELECT  *
FROM    (SELECT qs.execution_count,
                SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1, 
                                ((CASE qs.statement_end_offset
                       WHEN -1 THEN DATALENGTH(st.text)
                       ELSE qs.statement_end_offset
                  END - qs.statement_start_offset) / 2) + 1) AS statement_text
         FROM   sys.dm_exec_query_stats AS qs
                CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
        ) AS queryStats
WHERE   queryStats.statement_text LIKE 'SELECT People.FullName, Orders.OrderDate%';
GO

SET SHOWPLAN_TEXT ON
GO
SELECT People.FullName
FROM   Application.People 
WHERE  People.FullName = N'Bala Dixit';
GO
SET SHOWPLAN_TEXT OFF
GO


SET SHOWPLAN_TEXT ON
GO

SELECT address.AddressLine1, address.AddressLine2,
        address.City, state.StateProvinceCode, address.PostalCode
FROM   Person.Address AS address
         JOIN Person.StateProvince AS state
                ON address.StateProvinceID = state.StateProvinceID
WHERE  address.AddressLine1 ='1, rue Pierre-Demoulin';
SET SHOWPLAN_TEXT OFF
GO


ALTER DATABASE WideWorldImporters
    SET PARAMETERIZATION FORCED;

SET SHOWPLAN_TEXT ON
GO
SELECT address.AddressLine1, address.AddressLine2,
        address.City, state.StateProvinceCode, address.PostalCode
FROM   Person.Address AS address
         JOIN Person.StateProvince as state
                ON address.StateProvinceID = state.StateProvinceID
WHERE  address.AddressLine1 like '1, rue Pierre-Demoulin';
SET SHOWPLAN_TEXT OFF
GO

DECLARE @FullName nvarchar(60) = N'Bala Dixit',
            @Query nvarchar(500),
        @Parameters nvarchar(500)

SET @Query= N'SELECT People.FullName, Orders.OrderDate
                        FROM   Sales.Orders 
                                         JOIN Application.People 
                                                on Orders.ContactPersonID = People.PersonID
                        WHERE  People.FullName LIKE @FullName';;
SET @Parameters = N'@FullName nvarchar(60)';

EXECUTE sp_executesql @Query, @Parameters, @FullName = @FullName;
GO


DECLARE @Query nvarchar(500),
        @Parameters nvarchar(500),
        @Handle int
SET @Query= N'SELECT People.FullName, Orders.OrderDate
              FROM   Sales.Orders 
                         JOIN Application.People 
                                ON Orders.ContactPersonID = People.PersonID
              WHERE  People.FullName LIKE @FullName';
SET @Parameters = N'@FullName nvarchar(60)';
GO

EXECUTE sp_prepare @Handle output, @Parameters, @Query;
SELECT @handle;

DECLARE  @FullName nvarchar(60) = N'Bala Dixit';
EXECUTE sp_execute 1, @FullName;
SET @FullName = N'Bala%';
EXECUTE sp_execute 1, @FullName;



--Security Issues
----SQL Injection
DECLARE @value varchar(30) = 'O''Malley'; 
SELECT 'SELECT '''+ @value + '''';
EXECUTE ('SELECT '''+ @value + '''');

DECLARE @value varchar(30) = 'O''Malley', @query nvarchar(300);
SELECT @query = 'SELECT ' + QUOTENAME(@value,'''');
SELECT @query;
EXECUTE (@query );
GO


DECLARE @value varchar(30) = 'O''; SELECT ''badness',
        @query nvarchar(300);
SELECT  @query = 'SELECT ' + QUOTENAME(@value,'''');
SELECT  @query;
EXECUTE (@query );
GO


DECLARE @value varchar(30) = 'O''; SELECT ''badness',
        @query nvarchar(300),
        @parameters nvarchar(200) = N'@value varchar(30)';
SELECT  @query = 'SELECT ' + QUOTENAME(@value,'''');
SELECT  @query;
EXECUTE sp_executesql @Query, @Parameters, @value = @value;
GO

CREATE PROCEDURE Sales.Orders$Select
(
        @FullNameLike nvarchar(100) = '%',
        @OrderDateRangeStart date = '1900-01-01',
        @OrderDateRangeEnd date = '9999-12-31'
) AS
BEGIN
      SELECT People.FullName, Orders.OrderDate
      FROM   Sales.Orders 
               JOIN Application.People 
                  ON Orders.ContactPersonID = People.PersonID
      WHERE  People.FullName LIKE @FullNameLike
             --Inclusive since using Date type
        AND  OrderDate BETWEEN @OrderDateRangeStart 
                                 AND @OrderDateRangeEnd
END;
GO
EXECUTE Sales.Orders$Select @FullNameLike = 'Bala Dixit', 
                    @OrderDateRangeStart = '2016-01-01',
                    @OrderDateRangeEnd = '2016-12-31';
GO

---Advantages
-----Encapsulation
--pseudocode:
CREATE PROCEDURE Sales.Orders$Select
...

EXECUTE Sales.Orders$Select @FullNameLike = 'Bala Dixit', 
                    @OrderDateRangeStart = '2016-01-01',
                    @OrderDateRangeEnd = '2016-12-31';
GO
EXECUTE sp_describe_first_result_set 
           N'Sales.Orders$Select;'
GO

EXECUTE sp_describe_first_result_set 
           N'Sales.Orders$Select @FullNameLike = ''Bala Dixit'';'
GO

CREATE PROCEDURE dbo.Test (@Value int = 1)
AS 
IF @value = 1 
    SELECT 'FRED' as Name;
ELSE 
    SELECT 200 as Name;        
GO

EXECUTE sp_describe_first_result_set N'dbo.Test'

---Dynamic Procedures

ALTER PROCEDURE Sales.Orders$Select
(
        @FullNameLike nvarchar(100) = '%',
        @OrderDateRangeStart date = '1900-01-01',
        @OrderDateRangeEnd date = '9999-12-31'
) AS
BEGIN
        DECLARE @query varchar(max) =
        CONCAT('
          SELECT People.FullName, Orders.OrderDate
          FROM   Sales.Orders 
                                 JOIN Application.People 
                                        ON Orders.ContactPersonID = People.PersonID
          WHERE  OrderDate BETWEEN ''', @OrderDateRangeStart, ''' 
                               AND ''', @OrderDateRangeEnd,'''
                                           AND People.FullName LIKE ''', @FullNameLike, '''' );
         SELECT @query; --for testing
         EXECUTE (@query);
END;
GO
EXECUTE Sales.Orders$Select @FullNameLike = '~;''select name from sysusers--', 
                                    @OrderDateRangeStart = '2016-01-01';
GO

ALTER PROCEDURE Sales.Orders$Select
(
        @FullNameLike nvarchar(100) = '%',
        @OrderDateRangeStart date = '1900-01-01',
        @OrderDateRangeEnd date = '9999-12-31'
) AS
BEGIN
        DECLARE @query varchar(max) =
        CONCAT('
      SELECT People.FullName, Orders.OrderDate
          FROM   Sales.Orders 
                   JOIN Application.People 
                      ON Orders.ContactPersonID = People.PersonID
          WHERE  People.FullName LIKE ', QUOTENAME(@FullNameLike,''''), '
                AND  OrderDate BETWEEN ', QUOTENAME(@OrderDateRangeStart,''''), ' 
                                       AND ', QUOTENAME(@OrderDateRangeEnd,''''));
         SELECT @query; --for testing
         EXECUTE (@query);
END;
GO

ALTER PROCEDURE Sales.Orders$Select
(
        @FullNameLike nvarchar(100) = '%',
        @OrderDateRangeStart date = '1900-01-01',
        @OrderDateRangeEnd date = '9999-12-31'
) AS
BEGIN
        DECLARE @query varchar(max) =
        CONCAT('
      SELECT People.FullName, Orders.OrderDate
          FROM   Sales.Orders 
                   JOIN Application.People 
                      ON Orders.ContactPersonID = People.PersonID
          WHERE  1=1
          ',
           --ignore @FullNameLike parameter when it is set to all
           CASE WHEN @FullNameLike <> '%' THEN
                 CONCAT(' AND  People.FullName LIKE ', QUOTENAME(@FullNameLike,''''))
           ELSE '' END,
           --ignore @date parameters when it is set to all


           CASE WHEN @OrderDateRangeStart <> '1900-01-01' OR
                      @OrderDateRangeEnd <> '9999-12-31' 
                        THEN
           CONCAT('AND  OrderDate BETWEEN ', QUOTENAME(@OrderDateRangeStart,''''), ' 
                                       AND ', QUOTENAME(@OrderDateRangeEnd,''''))
                        ELSE '' END);
         SELECT @query; --for testing
          EXECUTE (@query);
END;
GO

---Security
CREATE PROCEDURE dbo.TestChaining
AS
EXECUTE ('SELECT CustomerID, StoreID, AccountNumber 
          FROM   Sales.Customer');
GO
GO

GRANT EXECUTE ON testChaining TO fred;
GO

EXECUTE AS USER = 'Fred';
EXECUTE dbo.testChaining;
REVERT;
GO

ALTER PROCEDURE dbo.testChaining
WITH EXECUTE AS SELF
AS
EXECUTE ('SELECT CustomerID, StoreId, AccountNumber 
          FROM Sales.Customer');
GO

CREATE PROCEDURE dbo.YouCanDoAnything_ButDontDoThis
(
    @query nvarchar(4000)
)
WITH EXECUTE AS SELF
AS
EXECUTE (@query);
GO

---Performance
-------Ability to use the In-Memory Engine to its Fullest
USE WideWorldImporters;
GO
CREATE PROCEDURE Warehouse.VehicleTemperatures$Select  
(
        @TemperatureLowRange decimal(10,2) = -99999999.99,
        @TemperatureHighRange decimal(10,2) = 99999999.99
)
WITH SCHEMABINDING, NATIVE_COMPILATION  AS  
  BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')  
        SELECT VehicleTemperatureID, VehicleRegistration,
               RecordedWhen, Temperature
        FROM   Warehouse.VehicleTemperatures
        WHERE  Temperature BETWEEN @TemperatureLowRange AND @TemperatureHighRange
    ORDER BY RecordedWhen DESC; --Most Recent First
  END;  
GO

EXECUTE Warehouse.VehicleTemperatures$Select ;
EXECUTE Warehouse.VehicleTemperatures$Select @TemperatureLowRange = 4;
EXECUTE Warehouse.VehicleTemperatures$Select @TemperatureLowRange = 4.1,
                                             @TemperatureHighRange = 4.1;
GO


CREATE PROCEDURE Warehouse.VehicleTemperatures$FixTemperature  
(
        @VehicleTemperatureID int,
        @Temperature decimal(10,2)
)
WITH SCHEMABINDING, NATIVE_COMPILATION AS  
--Simulating a procedure you might write to fix a temperature that was found to be 
--outside of reasonability
  BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')  
    BEGIN TRY
                --Update the temperature
                UPDATE Warehouse.VehicleTemperatures
                SET       Temperature = @Temperature
                WHERE  VehicleTemperatureID = @VehicleTemperatureID;
        
                --give the ability to crash the procedure for demo
                --Note, actually doing 1/0 is stopped by the compiler
                DECLARE @CauseFailure int
                SET @CauseFailure =  1/@Temperature;

                --return data if not a fail
                SELECT 'Success' AS Status, VehicleTemperatureID, 
                           Temperature
                FROM   Warehouse.VehicleTemperatures
                WHERE  VehicleTemperatureID = @VehicleTemperatureID;
        END TRY
        BEGIN CATCH
                --return data for the fail
                SELECT 'Failure' AS Status, VehicleTemperatureID, 
                           Temperature
                FROM   Warehouse.VehicleTemperatures
                WHERE  VehicleTemperatureID = @VehicleTemperatureID;

                THROW; --This will cause the batch to stop, and will cause this
                       --transaction to not be committed. Cannot use ROLLBACK
                           --does not necessarily end the transaction, even if it ends
                           --the batch.
        END CATCH
  END; 
GO
   
--Show original value of temperature for a given row
SELECT Temperature
FROM   Warehouse.VehicleTemperatures
WHERE  VehicleTemperatureID = 65994;
GO

EXECUTE Warehouse.VehicleTemperatures$FixTemperature
                                    @VehicleTemperatureId = 65994,
                                    @Temperature = 4.2;
GO

EXECUTE Warehouse.VehicleTemperatures$FixTemperature                                                                    
                               @VehicleTemperatureId = 65994,                                                 
                               @Temperature = 0;
GO

EXECUTE Warehouse.VehicleTemperatures$FixTemperature                                                                    
                               @VehicleTemperatureId = 65994,                                                 
                               @Temperature = 0,
                               @ThrowErrorFlag = 0;
GO

SELECT @@TRANCOUNT AS TranStart;
BEGIN TRANSACTION
EXECUTE Warehouse.VehicleTemperatures$FixTemperature                                                                 
                             @VehicleTemperatureId = 65994,                                     
                             @Temperature = 0,
                             @ThrowErrorFlag = 1;
GO
SELECT @@TRANCOUNT AS TranEnd;
GO
SELECT Temperature
FROM   Warehouse.VehicleTemperatures
WHERE  VehicleTemperatureID = 65994;
GO



---Difficulty Affecting Only Certain Columns in an Operation
CREATE PROCEDURE Sales.Contact$Update
(
    @ContactId   int,
    @FirstName   varchar(30),
    @LastName    varchar(30),
    @CompanyName varchar(100),
    @SalesLevelId  int,
    @ContactNotes  varchar(max)
)
AS
    DECLARE @entryTrancount int = @@trancount;

    BEGIN TRY
          UPDATE Sales.Contact
          SET    FirstName = @FirstName,
                 LastName = @LastName,
                 CompanyName = @CompanyName,
                 SalesLevelId = @SalesLevelId,
                 ContactNotes = @ContactNotes
          WHERE  ContactId = @ContactId;
    END TRY
    BEGIN CATCH
      IF @@trancount > 0
           ROLLBACK TRANSACTION;

      DECLARE @ERRORmessage nvarchar(4000)
      SET @ERRORmessage = 'Error occurred in procedure ''' + 
                  OBJECT_NAME(@@procid) + ''', Original Message: ''' 
                 + ERROR_MESSAGE() + '''';
      THROW 50000,@ERRORmessage,1;
   END CATCH;
GO

ALTER PROCEDURE Sales.Contact$update
(
    @ContactId   int,
    @FirstName   varchar(30),
    @LastName    varchar(30),
    @CompanyName varchar(100),
    @SalesLevelId  int,
    @ContactNotes  varchar(max)
)
WITH EXECUTE AS SELF
AS
    DECLARE @entryTrancount int = @@trancount;

    BEGIN TRY
       --declare variable to use to tell whether to include the sales level
       DECLARE @salesOrderIdChangedFlag bit = 
                       CASE WHEN (SELECT SalesLevelId 
                                  FROM   Sales.Contact
                                  WHERE  ContactId = @ContactId) =
                                                             @SalesLevelId
                            THEN 0 ELSE 1 END;
    
        DECLARE @query nvarchar(max);
        SET @query = '
        UPDATE Sales.Contact
        SET    FirstName = ' + QUOTENAME (@FirstName,'''') + ',
               LastName = ' + QUOTENAME(@LastName,'''') + ',
               CompanyName = ' + QUOTENAME(@CompanyName, '''') + ',
                '+ CASE WHEN @salesOrderIdChangedFlag = 1 THEN 
                'SalesLevelId = ' + QUOTENAME(@SalesLevelId, '''') + ',
                     ' else '' END + ',
                    ContactNotes = ' + QUOTENAME(@ContactNotes,'''') + '

         WHERE  ContactId = ' + CAST(@ContactId AS varchar(10)) ;
         EXECUTE (@query);
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0
           ROLLBACK TRANSACTION;

      DECLARE @ERRORmessage nvarchar(4000)
      SET @ERRORmessage = 'Error occurred in procedure ''' + 
                  OBJECT_NAME(@@procid) + ''', Original Message: ''' 
                 + ERROR_MESSAGE() + '''';
      THROW 50000,@ERRORmessage,1;
   END CATCH;
GO

CREATE TRIGGER Sales.Contact$insteadOfUpdate
ON Sales.Contact
INSTEAD OF UPDATE
AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; --in case the client has modified the rowcount
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (SELECT COUNT(*) FROM inserted);
   --           @rowsAffected int = (SELECT COUNT(*) FROM deleted);
   
   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
          --[validation blocks]
          --[modification blocks]
          --<perform action>
         
          UPDATE Contact
          SET    FirstName = inserted.FirstName,
                 LastName = inserted.LastName,
                 CompanyName = inserted.CompanyName,
                 PersonalNotes = inserted.PersonalNotes,
                 ContactNotes = inserted.ContactNotes
          FROM   Sales.Ccontact AS Contact
                    JOIN inserted
                        ON inserted.ContactId = Contact.ContactId


          IF UPDATE(SalesLevelId) --this column requires heavy validation
                                  --only want to update if necessary
               UPDATE Contact
               SET    SalesLevelId = inserted.SalesLevelId
               FROM   Sales.Contact 
                         JOIN inserted
                              ON inserted.ContactId = Contact.ContactId

              --this correlated subquery checks for rows that have changed
              WHERE  EXISTS (SELECT *
                             FROM   deleted
                             WHERE  deleted.ContactId = 
                                             inserted.ContactId
                               AND  deleted.SalesLevelId <> 
                                             inserted.SalesLevelId)
   END TRY
   BEGIN CATCH
               IF @@trancount > 0
                     ROLLBACK TRANSACTION;

              THROW;

     END CATCH
END;
GO