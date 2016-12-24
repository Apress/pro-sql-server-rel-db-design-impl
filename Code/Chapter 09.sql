--Database Access 
---Guidelines for Host Server Security Configuration
----Principals and Securables

CREATE LOGIN [DomainName\Louis] FROM WINDOWS --square brackets required for WinAuth login
    WITH DEFAULT_DATABASE=tempdb, DEFAULT_LANGUAGE=us_english;
GO

CREATE LOGIN Fred WITH PASSWORD=N'password' MUST_CHANGE, DEFAULT_DATABASE=tempdb,
     DEFAULT_LANGUAGE=us_english, CHECK_EXPIRATION=ON, CHECK_POLICY=ON;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER [DomainUser\Louis];
GO

GRANT VIEW SERVER STATE to Fred;
GO

CREATE SERVER ROLE SupportViewServer;
GO

GRANT  VIEW SERVER STATE to SupportViewServer; --run DMVs
GRANT  VIEW ANY DATABASE to SupportViewServer; --see any database
GRANT  CONNECT ANY DATABASE to SupportViewServer; --set context to any database
GRANT  SELECT ALL USER SECURABLES to SupportViewServer; --see any data in databases
GO

ALTER SERVER ROLE SupportViewServer ADD MEMBER Fred;
GO

CREATE DATABASE ClassicSecurityExample;
GO

CREATE LOGIN Barney WITH PASSWORD=N'password', DEFAULT_DATABASE=[tempdb], 
             DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
GO

/* diff connection: change to use Barney as the security context */

USE ClassicSecurityExample;
GO

/* as sysadmin */
USE ClassicSecurityExample;
GO
GRANT CONNECT TO guest;
GO

/* diff connection: change to use Barney as the security context */
USE ClassicSecurityExample;
GO


REVOKE CONNECT TO guest;

/* change to use Barney as the security context */

SELECT 'hi';

/* as sysadmin */

USE ClassicSecurityExample;
GO
CREATE USER BarneyUser FROM LOGIN Barney;
GO
GRANT CONNECT to BarneyUser;

/* change to use Barney as the security context */

USE ClassicSecurityExample;
GO
SELECT SUSER_SNAME() as server_principal_name, USER_NAME() as database_principal_name;

---Using the Contained Database Model

EXECUTE sp_configure 'contained database authentication', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO

CREATE DATABASE ContainedDBSecurityExample CONTAINMENT = PARTIAL;
GO

-- set the contained database to be partial 
ALTER DATABASE ContainedDBSecurityExample SET CONTAINMENT = PARTIAL;
GO

USE ContainedDBSecurityExample;
GO
CREATE USER WilmaContainedUser WITH PASSWORD = 'p@ssword1';
GO

CREATE LOGIN Pebbles WITH PASSWORD = 'BamBam01$';
GO
CREATE USER PebblesUnContainedUser FROM LOGIN Pebbles;
GO

USE Master;
GO
ALTER DATABASE ContainedDbSecurityExample  SET CONTAINMENT = NONE;
GO
SELECT name
FROM   ContainedDBSecurityExample.sys.database_principals
WHERE  authentication_type_desc = 'DATABASE';

---Impersonation

USE master;
GO
CREATE LOGIN SlateSystemAdmin WITH PASSWORD = 'tooHardToEnterAndNoOneKnowsIt',CHECK_POLICY=OFF;
ALTER SERVER ROLE sysadmin ADD MEMBER SlateSystemAdmin;
GO

CREATE LOGIN Slate with PASSWORD = 'reasonable', DEFAULT_DATABASE=tempdb,CHECK_POLICY=OFF;

--Must execute in master Database
GRANT IMPERSONATE ON LOGIN::SlateSystemAdmin TO Slate;
GO

/* Connect as system_admin user */


SELECT  class_desc AS permission_type, 
        OBJECT_SCHEMA_NAME(major_id) + '.' + OBJECT_NAME(major_id) AS object_name, 
        permission_name, state_desc, USER_NAME(grantee_principal_id) AS grantee
FROM   sys.database_permissions;
GO

--Must execute in master Database
GRANT IMPERSONATE ON LOGIN::SlateSystemAdmin TO Slate;
GO

USE ClassicSecurityExample;
GO

EXECUTE AS LOGIN = 'SlateSystemAdmin';
GO
USE    ClassicSecurityExample;
GO

SELECT user as [user], system_user as [system_user],
       original_login() as [original_login];
REVERT; --go back to previous security context
USE tempdb;
GO
REVERT;
GO
SELECT user as [user], SYSTEM_USER as [system_user],
       ORIGINAL_LOGIN() as [original_login];
GO

---Database Object Securables

SELECT  class_desc AS permission_type, 
        OBJECT_SCHEMA_NAME(major_id) + '.' + OBJECT_NAME(major_id) AS object_name, 
        permission_name, state_desc, USER_NAME(grantee_principal_id) AS grantee
FROM   sys.database_permissions;

---Table Security
USE ClassicSecurityExample;
GO
--start with a new schema for this test and create a table for our demonstrations
CREATE SCHEMA TestPerms;
GO

CREATE TABLE TestPerms.TableExample
(
    TableExampleId int identity(1,1)
                   CONSTRAINT PKTableExample PRIMARY KEY,
    Value   varchar(10)
);
GO


CREATE USER Tony WITHOUT LOGIN;
GO

EXECUTE AS USER = 'Tony';

INSERT INTO TestPerms.TableExample(Value)
VALUES ('a row');
GO

REVERT; --return to admin user context
GRANT INSERT ON TestPerms.TableExample TO Tony;
GO

EXECUTE AS USER = 'Tony';

INSERT INTO TestPerms.TableExample(Value)
VALUES ('a row');
GO

SELECT TableExampleId, value
FROM   TestPerms.TableExample;
GO



REVERT;
GRANT SELECT ON TestPerms.TableExample TO Tony;
GO

EXECUTE AS USER = 'Tony';

SELECT TableExampleId, Value
FROM   TestPerms.TableExample;

REVERT;
GO

---Column-Level Security

CREATE USER Employee WITHOUT LOGIN;
CREATE USER Manager WITHOUT LOGIN;
GO

CREATE SCHEMA Products;
GO
CREATE TABLE Products.Product
(
    ProductId   int identity CONSTRAINT PKProduct PRIMARY KEY,
    ProductCode varchar(10) CONSTRAINT AKProduct_ProductCode UNIQUE,
    Description varchar(20),
    UnitPrice   decimal(10,4),
    ActualCost  decimal(10,4)
);
INSERT INTO Products.Product(ProductCode, Description, UnitPrice, ActualCost)
VALUES ('widget12','widget number 12',10.50,8.50),
       ('snurf98','Snurfulator',99.99,2.50);
GO

GRANT SELECT on Products.Product to employee,manager;
DENY SELECT on Products.Product (ActualCost) to employee;
GO

EXECUTE AS USER = 'manager';
SELECT  *
FROM    Products.Product;
GO

REVERT;--revert back to SA level user or you will get an error that the
       --user cannot do this operation because the manager user doesn't
       --have rights to impersonate the employee
GO

EXECUTE AS USER = 'employee';
GO
SELECT *
FROM   Products.Product;
GO

SELECT ProductId, ProductCode, Description, UnitPrice
FROM   Products.Product;
REVERT;

--Roles
---User-Defined Database Roles

SELECT IS_MEMBER('HRManager');
GO

IF (SELECT IS_MEMBER('HRManager')) = 0 or (SELECT IS_MEMBER('HRManager')) IS NULL
       SELECT 'I..DON''T THINK SO!';
GO

CREATE USER Frank WITHOUT LOGIN;
CREATE USER Julie WITHOUT LOGIN;
CREATE USER Rie WITHOUT LOGIN;
GO

CREATE ROLE HRWorkers;

ALTER ROLE HRWorkers ADD MEMBER Julie;
ALTER ROLE HRWorkers ADD MEMBER Rie;
GO

CREATE SCHEMA Payroll;
GO
CREATE TABLE Payroll.EmployeeSalary
(
    EmployeeId  int NOT NULL CONSTRAINT PKEmployeeSalary PRIMARY KEY,
    SalaryAmount decimal(12,2) NOT NULL
);
GRANT SELECT ON Payroll.EmployeeSalary to HRWorkers;
GO

EXECUTE AS USER = 'Frank';

SELECT *
FROM   Payroll.EmployeeSalary;
GO


REVERT;
EXECUTE AS USER = 'Julie';

SELECT *
FROM   Payroll.EmployeeSalary;
GO

REVERT;
DENY SELECT ON payroll.employeeSalary TO Rie;
GO

EXECUTE AS USER = 'Rie';
SELECT *
FROM   Payroll.EmployeeSalary;
GO

REVERT ;
EXECUTE AS USER = 'Julie';

--note, this query only returns rows for tables where the user has SOME rights
SELECT  TABLE_SCHEMA + '.' + TABLE_NAME as tableName,
        HAS_PERMS_BY_NAME(TABLE_SCHEMA + '.' + TABLE_NAME, 'OBJECT', 'SELECT')
                                                                 as allowSelect,
        HAS_PERMS_BY_NAME(TABLE_SCHEMA + '.' + TABLE_NAME, 'OBJECT', 'INSERT')
                                                                 as allowInsert
FROM    INFORMATION_SCHEMA.TABLES;
REVERT ; --so you will be back to sysadmin rights for next code
GO

---Application Roles

CREATE TABLE TestPerms.BobCan
(
    BobCanId int NOT NULL identity(1,1) CONSTRAINT PKBobCan PRIMARY KEY,
    Value varchar(10) NOT NULL
);
CREATE TABLE TestPerms.AppCan
(
    AppCanId int NOT NULL identity(1,1) CONSTRAINT PKAppCan PRIMARY KEY,
    Value varchar(10) NOT NULL
);
GO
CREATE USER Bob WITHOUT LOGIN;
GO

GRANT SELECT on TestPerms.BobCan to Bob;
GO

CREATE APPLICATION ROLE AppCan_application with password = '39292LjAsll2$3';
GO

GRANT SELECT on TestPerms.AppCan to AppCan_application;
GO

EXECUTE AS USER = 'Bob';
SELECT * FROM TestPerms.BobCan;
GO

SELECT * FROM TestPerms.AppCan;
GO


EXECUTE sp_setapprole 'AppCan_application', '39292LjAsll2$3';
GO

SELECT * FROM TestPerms.BobCan;
GO

SELECT * from TestPerms.AppCan;
GO

SELECT user as userName, system_user as login;
REVERT;

USE ClassicSecurityExample; --Since you probably had to reconnect :)
GO


--Note that this must be executed as a single batch because of the variable
--for the cookie
DECLARE @cookie varbinary(8000);
EXECUTE sp_setapprole 'AppCan_application', '39292LjAsll2$3'
              , @fCreateCookie = true, @cookie = @cookie OUTPUT;

SELECT @cookie as cookie;
SELECT USER as beforeUnsetApprole;

EXEC sp_unsetapprole @cookie;

SELECT USER as afterUnsetApprole;

REVERT; --done with this user
GO

---Schemas
USE WideWorldImporters; --or whatever name you have given it
GO
SELECT  SCHEMA_NAME(schema_id) AS schema_name, type_desc, COUNT(*)
FROM    sys.objects
WHERE   type_desc IN ('SQL_STORED_PROCEDURE','CLR_STORED_PROCEDURE',
                      'SQL_SCALAR_FUNCTION','CLR_SCALAR_FUNCTION',
                      'CLR_TABLE_VALUED_FUNCTION','SYNONYM',
                      'SQL_INLINE_TABLE_VALUED_FUNCTION',
                      'SQL_TABLE_VALUED_FUNCTION','USER_TABLE','VIEW')
GROUP BY  SCHEMA_NAME(schema_id), type_desc
ORDER BY schema_name;
GO
USE ClassicSecurityExample; 
GO

GRANT EXECUTE on SCHEMA::Customer to CustomerSupport;

GO


USE ClassicSecurityExample;
GO
CREATE USER Tom WITHOUT LOGIN;
GRANT SELECT ON SCHEMA::TestPerms TO Tom;
GO

EXECUTE AS USER = 'Tom';
GO
SELECT * FROM TestPerms.AppCan;
GO
REVERT;

CREATE TABLE TestPerms.SchemaGrant
(
    SchemaGrantId int primary key
);
GO
EXECUTE AS USER = 'Tom';
GO
SELECT * FROM TestPerms.schemaGrant;
GO

REVERT;

---Row-Level Security

--CREATE TABLE Products.Product
--(
--    ProductId   int NOT NULL IDENTITY CONSTRAINT PKProduct PRIMARY KEY,
--    ProductCode varchar(10) NOT NULL CONSTRAINT AKProduct_ProductCode UNIQUE,
--    Description varchar(20) NOT NULL,
--    UnitPrice   decimal(10,4) NOT NULL,
--    ActualCost  decimal(10,4) NOT NULL
--);
ALTER TABLE Products.Product
   ADD ProductType varchar(20) NOT NULL 
                        CONSTRAINT DFLTProduct_ProductType DEFAULT ('not set');
GO
UPDATE Products.Product
SET    ProductType = 'widget'
WHERE  ProductCode = 'widget12';
GO
UPDATE Products.Product
SET    ProductType = 'snurf'
WHERE  ProductCode = 'snurf98';
GO


---Using Specific Purpose Views to Provide Row-Level Security

CREATE VIEW Products.WidgetProduct
AS
SELECT ProductId, ProductCode, Description, UnitPrice, ActualCost, ProductType
FROM   Products.Product
WHERE  ProductType = 'widget'
WITH   CHECK OPTION; --This prevents the user from INSERTING/UPDATING data that would not
                     --match the view's criteria
GO

CREATE USER chrissy WITHOUT LOGIN;
GRANT SELECT ON Products.WidgetProduct TO chrissy;
GO

EXECUTE AS USER = 'chrissy';
SELECT *
FROM   Products.WidgetProduct;

SELECT *
FROM   Products.Product;
GO
REVERT;
GO

/*
Extended information-INSERT UPDATE DELETE IN THE VIEW
*/
GRANT INSERT, UPDATE, DELETE ON Products.WidgetProduct TO chrissy;
GO

EXECUTE AS USER = 'chrissy';

INSERT INTO Products.WidgetProduct (ProductCode, Description, UnitPrice, ActualCost,ProductType)
VALUES  ('Test' , 'Test' , 100 , 100  , 'NotWidget')

/*
Msg 550, Level 16, State 1, Line 439
The attempted insert or update failed because the target view either specifies WITH CHECK OPTION or spans a view that specifies WITH CHECK OPTION and one or more rows resulting from the operation did not qualify under the CHECK OPTION constraint.
The statement has been terminated.
*/

INSERT INTO Products.WidgetProduct (ProductCode, Description, UnitPrice, ActualCost,ProductType)
VALUES  ('Test' , 'Test' , 100 , 100  , 'widget')

SELECT *
FROM   Products.WidgetProduct

/*
ProductId   ProductCode Description          UnitPrice                               ActualCost                              ProductType
----------- ----------- -------------------- --------------------------------------- --------------------------------------- --------------------
1           widget12    widget number 12     10.5000                                 8.5000                                  widget
4           Test        Test                 100.0000                                100.0000                                widget
*/

UPDATE Products.WidgetProduct
SET ProductType = 'NotWidget'
WHERE ProductCode = 'Test';

/*
Msg 550, Level 16, State 1, Line 461
The attempted insert or update failed because the target view either specifies WITH CHECK OPTION or spans a view that specifies WITH CHECK OPTION and one or more rows resulting from the operation did not qualify under the CHECK OPTION constraint.
The statement has been terminated.
*/

UPDATE Products.WidgetProduct
SET ProductType = 'widget',
	ProductCode = 'Test2'
WHERE ProductCode = 'Test';


SELECT *
FROM   Products.WidgetProduct;
GO

/*
ProductId   ProductCode Description          UnitPrice                               ActualCost                              ProductType
----------- ----------- -------------------- --------------------------------------- --------------------------------------- --------------------
1           widget12    widget number 12     10.5000                                 8.5000                                  widget
4           Test2       Test                 100.0000                                100.0000                                widget
*/

DELETE Products.WidgetProduct
WHERE  ProductId = 3;

/*
(0 row(s) affected)

Can't see it, doesn't even try to delete it
*/

DELETE Products.WidgetProduct
WHERE  ProductCode = 'Test2';

/*
(1 row(s) affected)
*/

SELECT *
FROM  Products.WidgetProduct;

/*
ProductId   ProductCode Description          UnitPrice                               ActualCost                              ProductType
----------- ----------- -------------------- --------------------------------------- --------------------------------------- --------------------
1           widget12    widget number 12     10.5000                                 8.5000                                  widget
*/

REVERT;

/*
Back to your regularly scheduled querying.
*/

CREATE VIEW Products.ProductSelective
AS
SELECT ProductId, ProductCode, Description, UnitPrice, ActualCost, ProductType
FROM   Products.Product
WHERE  ProductType <> 'snurf'
   or  (IS_MEMBER('snurfViewer') = 1)
   or  (IS_MEMBER('db_owner') = 1) --can't add db_owner to a role
WITH CHECK OPTION;
GO

GRANT SELECT ON Products.ProductSelective to public;
GO

CREATE ROLE snurfViewer;
GO

EXECUTE AS USER = 'chrissy';
SELECT * FROM Products.ProductSelective;
REVERT;
GO

ALTER ROLE snurfViewer ADD MEMBER chrissy;
GO

EXECUTE AS USER = 'chrissy';
SELECT * 
FROM Products.ProductSelective;

REVERT;
GO

---Using Row-Level Security Feature to Provide Row-Level Security

CREATE SCHEMA RowLevelSecurity;
GO

CREATE FUNCTION RowLevelSecurity.Products_Product$SecurityPredicate 
                                                (@ProductType AS varchar(20)) 
    RETURNS TABLE 
WITH SCHEMABINDING --not required, but a good idea nevertheless
AS 
    RETURN (SELECT 1 AS Products_Product$SecurityPredicate  
            WHERE  @ProductType <> 'snurf'
                           OR  (IS_MEMBER('snurfViewer') = 1)
                           OR (IS_MEMBER('db_owner') = 1));
GO
CREATE USER valerie WITHOUT LOGIN;
GO
GRANT SELECT ON RowLevelSecurity.Products_Product$SecurityPredicate TO valerie;
GO


EXECUTE AS USER = 'valerie';
GO
SELECT 'snurf' AS ProductType,*
FROM   rowLevelSecurity.Products_Product$SecurityPredicate('snurf')
UNION ALL
SELECT 'widget' AS ProductType,*
FROM   rowLevelSecurity.Products_Product$SecurityPredicate('widget');
REVERT;
GO


REVOKE SELECT ON RowLevelSecurity.Products_Product$SecurityPredicate TO valerie;
GO

CREATE SECURITY POLICY RowLevelSecurity.Products_Product_SecurityPolicy 
    ADD FILTER PREDICATE rowLevelSecurity.Products_Product$SecurityPredicate(ProductType) 
    ON Products.Product
    WITH (STATE = ON, SCHEMABINDING = ON); 
GO

CREATE SECURITY POLICY rowLevelSecurity.Products_Product_SecurityPolicy2
    ADD FILTER PREDICATE rowLevelSecurity.Products_Product$SecurityPredicate(ProductType) 
    ON Products.Product
    WITH (STATE = ON, SCHEMABINDING= ON); 
GRANT SELECT, INSERT, UPDATE, DELETE ON Products.Product TO valerie;
GO


EXECUTE AS USER = 'valerie';
GO
SELECT * 
FROM   Products.Product;

REVERT;
GO

EXECUTE AS USER = 'valerie';

DELETE Products.Product
WHERE  ProductType = 'snurf';

REVERT;
GO

--back as dbo user
SELECT *
FROM   Products.Product
WHERE  ProductType = 'snurf';
GO

EXECUTE AS USER = 'valerie';

INSERT INTO Products.Product (ProductCode, Description, UnitPrice, ActualCost,ProductType)
VALUES  ('Test' , 'Test' , 100 , 100  , 'snurf');

SELECT *
FROM   Products.Product
WHERE  ProductType = 'snurf';

REVERT;
GO

SELECT *
FROM   Products.Product
WHERE  ProductType = 'snurf';
GO

--Note that you can alter a security policy, but it seems easier 
--to drop and recreate in most cases.
DROP SECURITY POLICY rowLevelSecurity.Products_Product_SecurityPolicy;

CREATE SECURITY POLICY rowLevelSecurity.Products_Product_SecurityPolicy
    ADD FILTER PREDICATE rowLevelSecurity.Products_Product$SecurityPredicate(ProductType) 
    ON Products.Product,
    ADD BLOCK PREDICATE rowLevelSecurity.Products_Product$SecurityPredicate(ProductType) 
    ON Products.Product AFTER INSERT
    WITH (STATE = ON, SCHEMABINDING = ON); 
GO

EXECUTE AS USER = 'valerie';

INSERT INTO Products.Product (ProductCode, Description, UnitPrice, ActualCost,ProductType)
VALUES  ('Test2' , 'Test2' , 100 , 100  , 'snurf');

REVERT;
GO

DROP SECURITY POLICY rowLevelSecurity.Products_Product_SecurityPolicy;

CREATE SECURITY POLICY rowLevelSecurity.Products_Product_SecurityPolicy
    ADD BLOCK PREDICATE rowLevelSecurity.Products_Product$SecurityPredicate(ProductType) ON Products.Product AFTER INSERT,
    ADD BLOCK PREDICATE rowLevelSecurity.Products_Product$SecurityPredicate(ProductType) ON Products.Product BEFORE UPDATE,
    ADD BLOCK PREDICATE rowLevelSecurity.Products_Product$SecurityPredicate(ProductType) ON Products.Product BEFORE DELETE
    WITH (STATE = ON, SCHEMABINDING = ON); 
GO
EXECUTE AS USER = 'valerie';
GO

SELECT *
FROM   Products.Product;
GO

DELETE Products.Product
WHERE    ProductCode = 'Test';
GO


BEFORE UPDATE
UPDATE Products.Product
SET    ProductType = 'snurf'
WHERE  ProductTYpe = 'widget';

--We cannot update the row back, even though we can see it:

UPDATE Products.Product
SET    ProductType = 'widget'
WHERE  ProductTYpe = 'snurf';

GO

---Using Data Driven Row-Level Security

CREATE TABLE Products.ProductSecurity
(
    ProductType varchar(20), --at this point you probably will create a
                             --ProductType domain table, but this keeps the
                             --example a bit simpler
    DatabaseRole    sysname,
    CONSTRAINT PKProductsSecurity PRIMARY KEY(ProductType, DatabaseRole)
);
GO

INSERT INTO Products.ProductSecurity(ProductType, DatabaseRole)
VALUES ('widget','public');
GO

ALTER VIEW Products.ProductSelective
AS
SELECT Product.ProductId, Product.ProductCode, Product.Description,
       Product.UnitPrice, Product.ActualCost, Product.ProductType
FROM   Products.Product as Product
         JOIN Products.ProductSecurity as ProductSecurity
            on  (Product.ProductType = ProductSecurity.ProductType
                and is_member(ProductSecurity.DatabaseRole) = 1)
                or is_member('db_owner') = 1; --don't leave out the dbo!
GO

ALTER FUNCTION RowLevelSecurity.Products_Product$SecurityPredicate
                                                (@ProductType AS varchar(20)) 
    RETURNS TABLE 
WITH SCHEMABINDING --not required, but a good idea nevertheless
AS 
    RETURN (SELECT 1 AS Products_Product$SecurityPredicate  
            WHERE is_member('db_owner') = 1
               OR  EXISTS (SELECT 1
                           FROM   Products.ProductSecurity
                           WHERE  ProductType = @ProductType
                             AND  IS_MEMBER(DatabaseRole) = 1));
GO


---Controlling Access to Data via T-SQL–Coded Objects

----Stored Procedures and Scalar Functions
CREATE USER ProcUser WITHOUT LOGIN;
GO

CREATE SCHEMA ProcTest;
GO
CREATE TABLE ProcTest.Misc
(
    GeneralValue varchar(20),
    SecretValue varchar(20)
);
GO
INSERT INTO ProcTest.Misc (GeneralValue, SecretValue)
VALUES ('somevalue','secret'),
       ('anothervalue','secret');
GO

CREATE PROCEDURE ProcTest.Misc$Select
AS
    SELECT GeneralValue
    FROM   ProcTest.Misc;
GO
GRANT EXECUTE on ProcTest.Misc$Select to ProcUser;
GO

EXECUTE AS USER = 'ProcUser';
GO
SELECT GeneralValue , SecretValue
FROM   ProcTest.Misc;
GO

EXECUTE ProcTest.Misc$Select;

SELECT schema_name(schema_id) +'.' + name AS procedure_name
FROM   sys.procedures;
 
REVERT;

---Impersonation within Objects

--this will be the owner of the primary schema
CREATE USER SchemaOwner WITHOUT LOGIN;
GRANT CREATE SCHEMA TO SchemaOwner;
GRANT CREATE TABLE TO SchemaOwner;

--this will be the procedure creator
CREATE USER ProcedureOwner WITHOUT LOGIN;
GRANT CREATE SCHEMA TO ProcedureOwner;
GRANT CREATE PROCEDURE TO ProcedureOwner;
GRANT CREATE TABLE TO ProcedureOwner;
GO

--this will be the average user who needs to access data
CREATE USER AveSchlub WITHOUT LOGIN;
GO


EXECUTE AS USER = 'SchemaOwner';
GO
CREATE SCHEMA SchemaOwnersSchema;
GO
CREATE TABLE SchemaOwnersSchema.Person
(
    PersonId    int constraint PKPerson primary key,
    FirstName   varchar(20),
    LastName    varchar(20)
);
GO
INSERT INTO SchemaOwnersSchema.Person
VALUES (1, 'Phil','Mutayblin'),
       (2, 'Del','Eets');
GO


GRANT SELECT on SchemaOwnersSchema.Person TO ProcedureOwner;
GO

REVERT --we can step back on the stack of principals, but we can't change directly        
       --to procedureOwner without giving ShemaOwner impersonation rights. Here I 
       --step back to the db_owner user you have used throughout the chapter
GO
EXECUTE AS USER = 'ProcedureOwner';
GO

CREATE SCHEMA ProcedureOwnerSchema;
GO
CREATE TABLE ProcedureOwnerSchema.OtherPerson
(
    PersonId    int CONSTRAINT PKOtherPerson PRIMARY KEY,
    FirstName   varchar(20),
    LastName    varchar(20)
);
GO
INSERT INTO ProcedureOwnerSchema.OtherPerson
VALUES (1, 'DB','Smith');
INSERT INTO ProcedureOwnerSchema.OtherPerson
VALUES (2, 'Dee','Leater');
GO


REVERT;

SELECT tables.name as [table], schemas.name as [schema],
       database_principals.name as [owner]
FROM   sys.tables
         JOIN sys.schemas
            ON tables.schema_id = schemas.schema_id
         JOIN sys.database_principals
            ON database_principals.principal_id = schemas.principal_id
WHERE  tables.name in ('Person','OtherPerson');
GO

EXECUTE AS USER = 'ProcedureOwner';
GO

CREATE PROCEDURE ProcedureOwnerSchema.Person$asCaller
WITH EXECUTE AS CALLER --this is the default
AS
BEGIN
   SELECT  PersonId, FirstName, LastName
   FROM    ProcedureOwnerSchema.OtherPerson; --<-- ownership same as proc

   SELECT  PersonId, FirstName, LastName
   FROM    SchemaOwnersSchema.Person;  --<-- breaks ownership chain
END;
GO

CREATE PROCEDURE ProcedureOwnerSchema.Person$asSelf
WITH EXECUTE AS SELF --now this runs in context of procedureOwner,
                     --since it created it
AS
BEGIN
   SELECT  PersonId, FirstName, LastName
   FROM    ProcedureOwnerSchema.OtherPerson; --<-- ownership same as proc

   SELECT  PersonId, FirstName, LastName
   FROM    SchemaOwnersSchema.Person;  --<-- breaks ownership chain
END;
GO

GRANT EXECUTE ON ProcedureOwnerSchema.Person$asCaller TO AveSchlub;
GRANT EXECUTE ON ProcedureOwnerSchema.Person$asSelf TO AveSchlub;
GO

REVERT; EXECUTE AS USER = 'AveSchlub'; --If you receive error about not being able to 
                  --impersonate another user, it means you are not executing as dbo..
GO

--this proc is in context of the caller, in this case, AveSchlub
EXECUTE ProcedureOwnerSchema.Person$asCaller;
GO

--procedureOwner, so it works
EXECUTE ProcedureOwnerSchema.Person$asSelf;
GO

REVERT;
GO
CREATE PROCEDURE dbo.TestDboRights
AS
 BEGIN
    CREATE TABLE dbo.test
    (
        testId int
    );
 END;
GO

CREATE USER Leroy WITHOUT LOGIN;
GRANT EXECUTE on dbo.TestDboRights to Leroy;
GO

EXECUTE AS USER = 'Leroy';
EXECUTE dbo.TestDboRights;
GO
REVERT;
GO
ALTER PROCEDURE dbo.TestDboRights
WITH EXECUTE AS 'dbo'
AS
 BEGIN
    CREATE TABLE dbo.test
    (
        testId int
    );
 END;
GO
EXECUTE AS USER = 'Leroy';
EXECUTE dbo.TestDboRights;
GO
REVERT;
GO

CREATE TABLE dbo.TestRowLevelChaining
(
        Value    int CONSTRAINT PKTestRowLevelChaining PRIMARY KEY
)
INSERT dbo.TestRowLevelChaining (Value)
VALUES  (1),(2),(3),(4),(5);
GO

CREATE FUNCTION RowLevelSecurity.dbo_TestRowLevelChaining$SecurityPredicate 
                                        (@Value AS int) 
RETURNS TABLE WITH SCHEMABINDING 
AS RETURN (SELECT 1 AS dbo_TestRowLevelChaining$SecurityPredicate 
            WHERE  @Value > 3 OR  USER_NAME() = 'dbo');
GO

CREATE SECURITY POLICY RowLevelSecurity.dbo_TestRowLevelChaining_SecurityPolicy
    ADD FILTER PREDICATE RowLevelSecurity.dbo_TestRowLevelChaining$SecurityPredicate (Value)
    ON dbo.TestRowLevelChaining WITH (STATE = ON, SCHEMABINDING = ON); 
GO

CREATE PROCEDURE dbo.TestRowLevelChaining_asCaller
AS
SELECT * FROM dbo.TestRowLevelChaining;
GO

CREATE PROCEDURE dbo.TestRowLevelChaining_asDbo
WITH EXECUTE AS  'dbo'
AS
SELECT * FROM dbo.TestRowLevelChaining;
GO

CREATE USER Bobby WITHOUT LOGIN;
GRANT EXECUTE ON dbo.TestRowLevelChaining_asCaller TO Bobby;
GRANT EXECUTE ON dbo.TestRowLevelChaining_asDbo TO Bobby;
GO

EXECUTE AS USER = 'Bobby'
GO
EXECUTE  dbo.TestRowLevelChaining_asCaller;
GO
EXECUTE  dbo.TestRowLevelChaining_asDbo;
GO

---Views and Table-Valued Functions

SELECT *
FROM   Products.Product;
GO


CREATE VIEW Products.AllProducts
AS
SELECT ProductId,ProductCode, Description, UnitPrice, ActualCost, ProductType
FROM   Products.Product;
GO

CREATE VIEW Products.WarehouseProducts
AS
SELECT ProductId,ProductCode, Description
FROM   Products.Product;
GO

CREATE FUNCTION Products.ProductsLessThanPrice
(
    @UnitPrice  decimal(10,4)
)
RETURNS table
AS
     RETURN ( SELECT ProductId, ProductCode, Description, UnitPrice
              FROM   Products.Product
              WHERE  UnitPrice <= @UnitPrice);
GO
SELECT * FROM Products.ProductsLessThanPrice(20);
GO

/* Bonus, not in book. Using a function with IS_MEMBER to return only some data*/
CREATE FUNCTION Products.ProductsLessThanPrice_GroupEnforced
(
    @UnitPrice  decimal(10,4)
)
RETURNS @output table (ProductId int,
                       ProductCode varchar(10),
                       Description varchar(20),
                       UnitPrice decimal(10,4))
AS
 BEGIN
    --cannot raise an error, so you have to implement your own
    --signal, or perhaps simply return no data.
    IF @UnitPrice > 100 and (
                             IS_MEMBER('HighPriceProductViewer') = 0
                             or IS_MEMBER('HighPriceProductViewer') IS NULL)
        INSERT @output
        SELECT -1,'ERROR','',-1;
    ELSE
        INSERT @output
        SELECT ProductId, ProductCode, Description, UnitPrice
        FROM   Products.Product
        WHERE  UnitPrice <= @UnitPrice;
    RETURN;
 END;
 GO

CREATE ROLE HighPriceProductViewer;
CREATE ROLE ProductViewer;
GO
CREATE USER HighGuy WITHOUT LOGIN;
CREATE USER LowGuy WITHOUT LOGIN;
GO
ALTER ROLE HighPriceProductViewer ADD MEMBER HighGuy;
ALTER ROLE ProductViewer ADD MEMBER HighGuy;
ALTER ROLE ProductViewer ADD MEMBER LowGuy;
GO


---Crossing Database Lines
-----Using Cross-Database Chaining
CREATE DATABASE ExternalDb;
GO
USE ExternalDb;
GO
                                       --smurf theme song :)
CREATE LOGIN PapaSmurf WITH PASSWORD = 'La la, la la la la, la, la la la la';
CREATE USER  PapaSmurf FROM LOGIN PapaSmurf;
CREATE TABLE dbo.Table1 ( Value int );
GO


CREATE DATABASE LocalDb;
GO
USE LocalDb;
GO
CREATE USER PapaSmurf FROM LOGIN PapaSmurf;
GO

ALTER AUTHORIZATION ON DATABASE::ExternalDb TO sa;
ALTER AUTHORIZATION ON DATABASE::LocalDb TO sa;
GO

SELECT name,suser_sname(owner_sid) AS owner
FROM   sys.databases
WHERE  name IN ('ExternalDb','LocalDb');
GO

CREATE PROCEDURE dbo.ExternalDb$TestCrossDatabase
AS
SELECT Value
FROM   ExternalDb.dbo.Table1;
GO
GRANT EXECUTE ON dbo.ExternalDb$TestCrossDatabase TO PapaSmurf;
GO

EXECUTE dbo.ExternalDb$TestCrossDatabase;
GO

EXECUTE AS USER = 'PapaSmurf';
GO
EXECUTE dbo.ExternalDb$TestCrossDatabase;
GO
REVERT;
GO

ALTER DATABASE localDb
   SET DB_CHAINING ON;
ALTER DATABASE localDb
   SET TRUSTWORTHY ON;

ALTER DATABASE externalDb --It does not need to be trustworthy since it is not reaching out
   SET DB_CHAINING ON;
GO

EXECUTE AS USER = 'PapaSmurf';
GO
EXECUTE dbo.ExternalDb$TestCrossDatabase;
GO
REVERT;
GO

SELECT name, is_trustworthy_on, is_db_chaining_on
FROM   sys.databases
WHERE  name IN ('ExternalDb','LocalDb');
GO

ALTER DATABASE LocalDB  SET CONTAINMENT = PARTIAL;
GO

EXECUTE AS USER = 'PapaSmurf';
go
EXECUTE dbo.ExternalDb$TestCrossDatabase;
GO
REVERT;
GO

CREATE USER Gargamel WITH PASSWORD = 'Nasty1$';
GO 
GRANT EXECUTE ON dbo.ExternalDb$TestCrossDatabase to Gargamel;
GO

EXECUTE AS USER = 'Gargamel';
GO

USE ExternalDb;
GO

EXECUTE dbo.ExternalDb$TestCrossDatabase;
GO
REVERT;
GO

SELECT  object_name(major_id) as object_name,statement_line_number, 
        statement_type, feature_name, feature_type_name
FROM    sys.dm_db_uncontained_entities 
WHERE   class_desc = 'OBJECT_OR_COLUMN';
GO

SELECT  USER_NAME(major_id) AS USER_NAME
FROM    sys.dm_db_uncontained_entities 
WHERE   class_desc = 'DATABASE_PRINCIPAL'
  and   USER_NAME(major_id) <> 'dbo';
GO

DROP USER Gargamel;
GO
USE Master;
GO
ALTER DATABASE localDB  SET CONTAINMENT = NONE;
GO
USE LocalDb;
GO

---Using Impersonation to Cross Database Lines
ALTER DATABASE localDb
   SET DB_CHAINING OFF;
ALTER DATABASE localDb
   SET TRUSTWORTHY ON;
GO

ALTER DATABASE externalDb
   SET DB_CHAINING OFF;
GO
CREATE PROCEDURE dbo.ExternalDb$testCrossDatabase_Impersonation
WITH EXECUTE AS SELF --as procedure creator, who is the same as the db owner
AS
SELECT Value
FROM   ExternalDb.dbo.Table1;
GO

GRANT EXECUTE ON dbo.ExternalDb$TestCrossDatabase_Impersonation to PapaSmurf;
GO

EXECUTE AS USER = 'PapaSmurf';
GO
EXECUTE dbo.ExternalDb$TestCrossDatabase_Impersonation;
GO
REVERT;
GO


ALTER DATABASE localDb  SET TRUSTWORTHY OFF;
GO
EXECUTE dbo.ExternalDb$TestCrossDatabase_Impersonation;
GO


ALTER DATABASE LocalDb  SET TRUSTWORTHY ON;
GO
ALTER DATABASE LocalDB  SET CONTAINMENT = PARTIAL;
GO
CREATE USER Gargamel WITH PASSWORD = 'Nasty1$';
GO 
GRANT EXECUTE ON ExternalDb$testCrossDatabase_Impersonation TO Gargamel;
GO

EXECUTE AS USER = 'Gargamel';
GO
EXECUTE dbo.ExternalDb$TestCrossDatabase_Impersonation;
GO
REVERT;
GO


DROP USER Gargamel;
GO
USE Master;
GO
ALTER DATABASE localDB  SET CONTAINMENT = NONE;
GO
USE LocalDb;


----Using a Certificate-Based Trust

USE LocalDb;
GO
ALTER DATABASE LocalDb
   SET TRUSTWORTHY OFF;
GO

SELECT name,
       SUSER_SNAME(owner_sid) AS owner,
       is_trustworthy_on, is_db_chaining_on
FROM   sys.databases 
WHERE name IN ('LocalDb','ExternalDb');
GO

CREATE PROCEDURE dbo.ExternalDb$TestCrossDatabase_Certificate
AS
SELECT Value
FROM   ExternalDb.dbo.Table1;
GO
GRANT EXECUTE on dbo.ExternalDb$TestCrossDatabase_Certificate to PapaSmurf;
GO

CREATE CERTIFICATE ProcedureExecution ENCRYPTION BY PASSWORD = 'jsaflajOIo9jcCMd;SdpSljc'
 WITH SUBJECT =
         'Used to sign procedure:ExternalDb$TestCrossDatabase_Certificate';
GO

ADD SIGNATURE TO dbo.ExternalDb$TestCrossDatabase_Certificate
     BY CERTIFICATE ProcedureExecution WITH PASSWORD = 'jsaflajOIo9jcCMd;SdpSljc';
GO

BACKUP CERTIFICATE ProcedureExecution TO FILE = 'c:\temp\procedureExecution.cer';
GO

USE ExternalDb;
GO
CREATE CERTIFICATE ProcedureExecution FROM FILE = 'c:\temp\procedureExecution.cer';
GO


CREATE USER ProcCertificate FOR CERTIFICATE ProcedureExecution;
GO
GRANT SELECT on dbo.Table1 TO ProcCertificate;
GO

USE LocalDb;
GO
EXECUTE AS LOGIN = 'PapaSmurf';
EXECUTE dbo.ExternalDb$TestCrossDatabase_Certificate;
REVERT;
GO

/* Bonus code, trying certificate access with containment) */

REVERT;
GO
ALTER DATABASE LocalDB  SET CONTAINMENT = PARTIAL;
GO
CREATE USER Gargamel WITH PASSWORD = 'Nasty1$';
GO 
GRANT EXECUTE ON ExternalDb$testCrossDatabase_Certificate to Gargamel;

-- Now execute the procedure in the context of the contained user:

EXECUTE AS USER = 'Gargamel';
GO
EXECUTE dbo.ExternalDb$TestCrossDatabase_Certificate;
GO
REVERT;

/*
Msg 916, Level 14, State 1, Procedure ExternalDb$TestCrossDatabase_Certificate, Line 3 [Batch Start Line 1286]
The server principal "S-1-9-3-1960074283-1335963625-2662708368-3478804206" is not able to access the database "ExternalDb" under the current security context.
*/


--Back to book code:

REVERT;
GO
USE MASTER;
GO
DROP DATABASE externalDb;
DROP DATABASE localDb;
GO
USE ClassicSecurityExample;


----Using Dynamic Data Masking to Hide Data from Users

CREATE SCHEMA Demo; 
GO 
CREATE TABLE Demo.Person --warning, I am using very small column datatypes in this 
                         --example to make looking at the output easier, not as proper sizes
( 
    PersonId    int NOT NULL CONSTRAINT PKPerson PRIMARY KEY, 
    FirstName    nvarchar(10) NULL, 
    LastName    nvarchar(10) NULL, 
    PersonNumber varchar(10) NOT NULL, 
    StatusCode    varchar(10) CONSTRAINT DFLTPersonStatus DEFAULT ('New') 
                            CONSTRAINT CHKPersonStatus CHECK (StatusCode in ('Active','Inactive','New')), 
    EmailAddress nvarchar(30) NULL, 
    InceptionTime date NOT NULL, --Time we first saw this person. Usually the row create time, but not always 
    --a number that I didn't feel could insult anyone of any origin, ability, etc that I could put in this table 
    YachtCount   tinyint NOT NULL CONSTRAINT DFLTPersonYachtCount DEFAULT (0) 
                            CONSTRAINT CHKPersonYachtCount CHECK (YachtCount >= 0), 
);
GO

ALTER TABLE Demo.Person ALTER COLUMN PersonNumber 
    ADD MASKED WITH (Function = 'default()'); 
ALTER TABLE Demo.Person ALTER COLUMN StatusCode 
    ADD MASKED WITH (Function = 'default()'); 
ALTER TABLE Demo.Person ALTER COLUMN EmailAddress 
    ADD MASKED WITH (Function = 'default()'); 
ALTER TABLE Demo.Person ALTER COLUMN InceptionTime 
    ADD MASKED WITH (Function = 'default()'); 
ALTER TABLE Demo.Person ALTER COLUMN YachtCount 
    ADD MASKED WITH (Function = 'default()'); 
GO

INSERT INTO Demo.Person (PersonId,FirstName,LastName,PersonNumber, StatusCode, EmailAddress, InceptionTime,YachtCount) 
VALUES(1,'Fred','Washington','0000000014','Active','fred.washington@ttt.net','1/1/1959',0), 
      (2,'Barney','Lincoln','0000000032','Active','barneylincoln@aol.com','8/1/1960',1), 
      (3,'Wilma','Reagan','0000000102','Active',NULL, '1/1/1959', 1);
GO

CREATE USER MaskedMarauder WITHOUT LOGIN;
GRANT SELECT ON Demo.Person TO MaskedMarauder ;

SELECT PersonId, PersonNumber, StatusCode, EmailAddress, InceptionTime, YachtCount
FROM   Demo.Person;

EXECUTE AS USER = 'MaskedMarauder'

SELECT PersonId, PersonNumber, StatusCode, EmailAddress, InceptionTime, YachtCount
FROM   Demo.Person;

REVERT
GO

ALTER TABLE Demo.Person ALTER COLUMN EmailAddress 
    ADD MASKED WITH (Function = 'email()'); 

EXECUTE AS USER = 'MaskedMarauder'

SELECT PersonId, PersonNumber, StatusCode, EmailAddress, InceptionTime, YachtCount
FROM   Demo.Person;

REVERT;
GO

ALTER TABLE Demo.Person ALTER COLUMN YachtCount 
    ADD MASKED WITH (Function = 'random(1,100)'); --make the value between 1 and 100. 
GO

EXECUTE AS USER = 'MaskedMarauder'

SELECT PersonId, PersonNumber, StatusCode, EmailAddress, InceptionTime, YachtCount
FROM   Demo.Person;

REVERT;
GO

ALTER TABLE Demo.Person ALTER COLUMN PersonNumber 
    ADD MASKED WITH (Function = 'partial(1,"-------",2)'); --note the double quotes on the text
ALTER TABLE Demo.Person ALTER COLUMN StatusCode 
    ADD MASKED WITH (Function = 'partial(0,"Unknown",0)');
GO

EXECUTE AS USER = 'MaskedMarauder'

SELECT PersonId, PersonNumber, StatusCode, EmailAddress, InceptionTime, YachtCount
FROM   Demo.Person;

REVERT;
GO

---Auditing SQL Server Use
-----Defining an Audit Specification
USE master;
GO
CREATE SERVER AUDIT ProSQLServerDatabaseDesign_Audit
TO FILE                      --choose your own directory, I expect most people
(     FILEPATH = N'c:\temp\' --have a temp directory on their system drive
      ,MAXSIZE = 15 MB
      ,MAX_ROLLOVER_FILES = 0 --unlimited
)
WITH
(
     ON_FAILURE = SHUTDOWN --if the file cannot be written to,
                           --shut down the server
);
GO

CREATE SERVER AUDIT SPECIFICATION ProSQLServerDatabaseDesign_Server_Audit
    FOR SERVER AUDIT ProSQLServerDatabaseDesign_Audit
    WITH (STATE = OFF); --disabled. I will enable it later
GO

ALTER SERVER AUDIT SPECIFICATION ProSQLServerDatabaseDesign_Server_Audit
    ADD (SERVER_PRINCIPAL_CHANGE_GROUP);
GO

USE ClassicSecurityExample;
GO
CREATE DATABASE AUDIT SPECIFICATION
                   ProSQLServerDatabaseDesign_Database_Audit
    FOR SERVER AUDIT ProSQLServerDatabaseDesign_Audit
    WITH (STATE = OFF);
GO

ALTER DATABASE AUDIT SPECIFICATION
    ProSQLServerDatabaseDesign_Database_Audit
    ADD (SELECT ON Products.Product BY Employee, Manager),
    ADD (SELECT ON Products.AllProducts BY Employee, Manager);
GO

---Enabling an Audit Specification
USE master;
GO
ALTER SERVER AUDIT ProSQLServerDatabaseDesign_Audit
    WITH (STATE = ON);
ALTER SERVER AUDIT SPECIFICATION ProSQLServerDatabaseDesign_Server_Audit
    WITH (STATE = ON);
GO
USE ClassicSecurityExample;
GO
ALTER DATABASE AUDIT SPECIFICATION ProSQLServerDatabaseDesign_Database_Audit
    WITH (STATE = ON);
GO

----Viewing the Audit Trail
CREATE LOGIN MrSmith WITH PASSWORD = 'Not a good password';
GO
USE ClassicSecurityExample;
GO
EXECUTE AS USER = 'Manager';
GO
SELECT *
FROM   Products.Product;
GO
SELECT  *
FROM    Products.AllProducts; --Permissions will fail
GO
REVERT
GO
EXECUTE AS USER = 'employee';
GO
SELECT  *
FROM    Products.AllProducts; --Permissions will fail
GO
REVERT;
GO

SELECT event_time, succeeded,
       database_principal_name, statement
FROM sys.fn_get_audit_file ('c:\temp\*', DEFAULT, DEFAULT);

--- Viewing the Audit Configuration


SELECT  sas.name as audit_specification_name,
        audit_action_name
FROM    sys.server_audits AS sa
          JOIN sys.server_audit_specifications AS sas
             ON sa.audit_guid = sas.audit_guid
          JOIN sys.server_audit_specification_details AS sasd
             ON sas.server_specification_id = sasd.server_specification_id
WHERE  sa.name = 'ProSQLServerDatabaseDesign_Audit';
GO

SELECT audit_action_name,dp.name as [principal],
       SCHEMA_NAME(o.schema_id) + '.' + o.name AS object
FROM   sys.server_audits as sa
         join sys.database_audit_specifications AS sas
             on sa.audit_guid = sas.audit_guid
         join sys.database_audit_specification_details AS sasd
             on sas.database_specification_id = sasd.database_specification_id
         join sys.database_principals AS dp
             on dp.principal_id = sasd.audited_principal_id
         join sys.objects AS o
             on o.object_id = sasd.major_id
WHERE  sa.name = 'ProSQLServerDatabaseDesign_Audit'
  and  sasd.minor_id = 0; --need another query for column level audits
GO
