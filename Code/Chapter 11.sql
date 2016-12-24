--OS and Hardware Concerns
--Transactions
--Transaction Overview
BEGIN TRANSACTION one;
ROLLBACK TRANSACTION one;
GO

BEGIN TRANSACTION one;
BEGIN TRANSACTION two;
ROLLBACK TRANSACTION two;  
GO

SELECT @@TRANCOUNT;
GO

USE Master;
GO

SET RECOVERY FULL;
GO

EXEC sp_addumpdevice 'disk', 'TestWideWorldImporters ',
                              'C:\temp\WideWorldImporters.bak';
EXEC sp_addumpdevice 'disk', 'TestWideWorldImportersLog',
                              'C:\temp\WideWorldImportersLog.bak'  ;
GO

SELECT  recovery_model_desc
FROM    sys.databases
WHERE   name = 'WideWorldImporters';
GO

EXEC sys.sp_dropdevice @logicalname = '<name>';
WideWorldImporters
WideWorldImporters
WideWorldImporters
USE WideWorldImporters;
GO
SELECT COUNT(*)
FROM   Sales.SpecialDeals

BEGIN TRANSACTION Test WITH MARK 'Test';
DELETE Sales.SpecialDeals;
COMMIT TRANSACTION;  
SpecialDeals
WideWorldImporters
WideWorldImportersLog
USE Master
GO
WideWorldImporters
WideWorldImporters
                                                WITH REPLACE, NORECOVERY;

WideWorldImporters
WideWorldImportersLog
                                                WITH STOPBEFOREMARK = 'Test', RECOVERY  ;
USE WideWorldImporters;
GO
SELECT COUNT(*)
FROM   Sales.SpecialDeals  ;  
Nested Transactions
BEGIN TRANSACTION;
    BEGIN TRANSACTION;
       BEGIN TRANSACTION;
SELECT @@TRANCOUNT AS zeroDeep;
BEGIN TRANSACTION;
SELECT @@TRANCOUNT AS oneDeep;
BEGIN TRANSACTION;
SELECT @@TRANCOUNT AS twoDeep;
COMMIT TRANSACTION; --commits previous transaction started with BEGIN TRANSACTION  
SELECT @@TRANCOUNT AS oneDeep;
COMMIT TRANSACTION;
SELECT @@TRANCOUNT AS zeroDeep;
BEGIN TRANSACTION;
BEGIN TRANSACTION;
BEGIN TRANSACTION;
BEGIN TRANSACTION;
BEGIN TRANSACTION;
BEGIN TRANSACTION;
BEGIN TRANSACTION;
SELECT @@trancount as InTran;

ROLLBACK TRANSACTION;
SELECT @@trancount as OutTran  ;  
SELECT @@TRANCOUNT;
COMMIT TRANSACTION;  
Autonomous Transactions
SEQUENCE
IDENTITY
SEQUENCE
IDENTITY
ROLLBACK
SEQUENCE
TABLE
CREATE SCHEMA Magic;
GO
CREATE SEQUENCE Magic.Trick_SEQUENCE AS int START WITH 1;
GO
CREATE TABLE Magic.Trick
(
        TrickId int NOT NULL IDENTITY,
        Value int CONSTRAINT DFLTTrick_Value DEFAULT (NEXT VALUE FOR Magic.Trick_SEQUENCE)
)  
BEGIN TRANSACTION;
INSERT INTO Magic.Trick DEFAULT VALUES; --just use the default values from table
SELECT * FROM Magic.Trick  ;
ROLLBACK TRANSACTION;  
IDENTITY
SEQUENCE
INSERT
Savepoints
SAVE TRANSACTION <savePointName>; --savepoint names must follow the same rules for
                                 --identifiers as other objects
CREATE SCHEMA Arts;
GO
CREATE TABLE Arts.Performer
(
    PerformerId int IDENTITY CONSTRAINT PKPeformer PRIMARY KEY,
    Name varchar(100)
 );
GO  

BEGIN TRANSACTION;
INSERT INTO Arts.Performer(Name) VALUES ('Elvis Costello');

SAVE TRANSACTION savePoint; --the savepoint name is case sensitive, even if instance is not
                            --if you do the same savepoint twice, the rollback is to latest 

INSERT INTO Arts.Performer(Name) VALUES ('Air Supply');

--don't insert Air Supply, yuck! ...
ROLLBACK TRANSACTION savePoint;

COMMIT TRANSACTION;

SELECT *
FROM Arts.Performer  ;  
Distributed Transactions 
BEGIN TRY
    BEGIN DISTRIBUTED TRANSACTION;

    --remote server is a server set up as a linked server

    UPDATE remoteServer.dbName.schemaName.tableName
    SET value = 'new value'
    WHERE keyColumn = 'value';

    --local server
    UPDATE dbName.schemaName.tableName
    SET value = 'new value'
    WHERE keyColumn = 'value';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ERRORMessage varchar(2000);
    SET @ERRORMessage = ERROR_MESSAGE();
    THROW 50000, @ERRORMessage,16;
END CATCH
'remote proc trans'
BEGIN TRANSACTION
BEGIN DISTRIBUTED TRANSACTION
Transaction State
XACT_STATE(
1
@@TRANCOUNT
0
-1
CREATE SCHEMA Menu;
GO
CREATE TABLE Menu.FoodItem
(
    FoodItemId int NOT NULL IDENTITY(1,1)
        CONSTRAINT PKFoodItem PRIMARY KEY,
    Name varchar(30) NOT NULL
        CONSTRAINT AKFoodItem_Name UNIQUE,
    Description varchar(60) NOT NULL,
        CONSTRAINT CHKFoodItem_Name CHECK (LEN(Name) > 0),
        CONSTRAINT CHKFoodItem_Description CHECK (LEN(Description) > 0)
);    
CREATE TRIGGER Menu.FoodItem$InsertTrigger
ON Menu.FoodItem
AFTER INSERT
AS --Note, minimalist code for demo. Chapter 7 and Appendix B 
   --have more details on complete trigger writing
BEGIN
   BEGIN TRY
                IF EXISTS (SELECT *
                                        FROM Inserted
                                        WHERE Description LIKE '%Yucky%')
        THROW 50000, 'No ''yucky'' food desired here',1;
   END TRY
   BEGIN CATCH
       IF XACT_STATE() <> 0
          ROLLBACK TRANSACTION;
       THROW;
   END CATCH;
END
GO    
ROLLBACK
XACT_ABORT
SET XACT_ABORT ON;  
  
BEGIN TRY  
    BEGIN TRANSACTION;  

        --insert the row to be tested
        INSERT INTO Menu.FoodItem(Name, Description)
        VALUES ('Hot Chicken','Nashville specialty, super spicy');
  
        SELECT  XACT_STATE() AS [XACT_STATE], 'Success, commit'  AS Description;
    COMMIT TRANSACTION;  
END TRY  
BEGIN CATCH  
        IF XACT_STATE() = -1 --transaction not doomed, but open
          BEGIN 
                SELECT -1 AS [XACT_STATE], 'Doomed transaction'  AS Description; 
                ROLLBACK TRANSACTION;
          END
        ELSE IF XACT_STATE() = 0 --transaction not doomed, but open
          BEGIN 
                SELECT 0 AS [XACT_STATE], 'No Transaction'  AS Description;;
          END  
        ELSE IF XACT_STATE() = 1 --transaction still active
          BEGIN 
                SELECT 1 AS [XACT_STATE], 
                       'Transction Still Active After Error'  AS Description;
                ROLLBACK TRANSACTION; 
          END  
END CATCH  ;  
INSERT INTO Menu.FoodItem(Name, Description)
VALUES ('Ethiopian Mexican Vegan Fusion',''  );  
INSERT INTO Menu.FoodItem(Name, Description)
VALUES ('Vegan Cheese','Yucky imitation for the real thing');
ALTER TRIGGER Menu.FoodItem$InsertTrigger
ON Menu.FoodItem
AFTER INSERT
AS --Note, minimalist code for demo. Chapter 7 and Appendix B 
   --have more details on complete trigger writing
BEGIN
                IF EXISTS (SELECT *
                                        FROM Inserted
                                        WHERE Description LIKE '%Yucky%')
        THROW 50000, 'No ''yucky'' food desired here',1;

END;  
XACT_ABORT 
ON
OFF
Explicit vs. Implicit Transactions
CREATE TABLE
ALTER INDEX
SQL Server Concurrency Methods 
Isolation Levels
BEGIN TRANSACTION;
UPDATE tableA
SET status = 'UPDATED'
WHERE tableAId = 'value';
BEGIN TRANSACTION;
INSERT tableA (tableAID, Status)
VALUES (100,'NEW');
BEGIN TRANSACTION;
SELECT *
FROM   tableA;
READ COMMITTED
SNAPSHOT
SELECT  CASE transaction_isolation_level
            WHEN 1 THEN 'Read Uncomitted'      WHEN 2 THEN 'Read Committed'
            WHEN 3 THEN 'Repeatable Read'      WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot'             ELSE 'Something is afoot'
         END
FROM    sys.dm_exec_sessions 
WHERE  session_id = @@spid;  
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  
Pessimistic Concurrency Enforcement
Lock Types
SERIALIZABLE
Lock Modes
FROM    table1 [WITH] (<tableHintList>)
             join table2 [WITH] (<tableHintList>)
SNAPSHOT
Isolation levels and locking
CREATE SCHEMA Art;
GO
CREATE TABLE Art.Artist
(
    ArtistId int CONSTRAINT PKArtist PRIMARY KEY
    ,Name varchar(30) --no key on value for demo purposes
    ,Padding char(4000) default (replicate('a',4000)) --so all rows not on single page

); 
INSERT INTO Art.Artist(ArtistId, Name)
VALUES (1,'da Vinci'),(2,'Micheangelo'), (3,'Donatello'), 
       (4,'Picasso'),(5,'Dali'), (6,'Jones');  
GO
CREATE TABLE Art.ArtWork
(
    ArtWorkId int CONSTRAINT PKArtWork PRIMARY KEY
    ,ArtistId int NOT NULL 
           CONSTRAINT FKArtwork$wasDoneBy$Art_Artist REFERENCES Art.Artist (ArtistId)
    ,Name varchar(30) 
    ,Padding char(4000) default (replicate('a',4000)) --so all rows not on single page
    ,CONSTRAINT AKArtwork UNIQUE (ArtistId, Name)
); 
INSERT Art.Artwork (ArtworkId, ArtistId, Name)
VALUES (1,1,'Last Supper'),(2,1,'Mona Lisa'),(3,6,'Rabbit Fire');
GO    
READ UNCOMMITTED
READ UNCOMMITTED
Art.Artist
--CONNECTION A
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; --this is the default, just 
                                               --setting for emphasis
BEGIN TRANSACTION;
INSERT INTO Art.Artist(ArtistId, Name)
VALUES (7, 'McCartney'  );
--CONNECTION B
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT ArtistId, Name
FROM Art.Artist
WHERE Name = 'McCartney'  ;
--CONNECTION B
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT ArtistId, Name
FROM Art.Artist
WHERE Name = 'McCartney'  ;
--CONNECTION A
ROLLBACK TRANSACTION;
--CONNECTION A
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;
SELECT ArtistId, Name FROM Art.Artist WHERE ArtistId = 7;
--CONNECTION B
INSERT INTO Art.Artist(ArtistId, Name)
VALUES (7, 'McCartney');
--CONNECTION A
SELECT ArtistId, Name FROM Art.Artist WHERE ArtistId = 7;
--CONNECTION B
UPDATE Art.Artist SET Name = 'Starr' WHERE ArtistId = 7;
--CONNECTION A
SELECT ArtistId, Name FROM Art.Artist WHERE ArtistId = 7;
COMMIT TRANSACTION;
--CONNECTION A
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRANSACTION;
SELECT ArtistId, Name FROM Art.Artist WHERE ArtistId >= 6;
--CONNECTION B
INSERT INTO Art.Artist(ArtistId, Name)
VALUES (8, 'McCartney');
--CONNECTION B
DELETE Art.Artist
WHERE  ArtistId = 6  ;
SELECT *
FROM dbo.testIsolationLevel
--CONNECTION A
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRANSACTION;
SELECT ArtistId, Name FROM Art.Artist;
--CONNECTION B
INSERT INTO Art.Artist(ArtistId, Name)
VALUES (9, 'Vuurmann'); --Misspelled on purpose. Used in later example
--CONNECTION A
COMMIT TRANSACTION;
SELECT ArtistId, Name FROM Art.Artist;
Interesting cases
--CONNECTION A
BEGIN TRANSACTION;
INSERT INTO Art.ArtWork(ArtWorkId, ArtistId, Name)
VALUES (4,9,'Revolver Album Cover');
--CONNECTION B
DELETE FROM Art.Artist WHERE ArtistId = 9;
-- CONNECTION A
COMMIT TRANSACTION;
--CONNECTION A
BEGIN TRANSACTION;
INSERT INTO Art.ArtWork(ArtWorkId, ArtistId, Name)
VALUES (5,9,'Liverpool Rascals'  );
--CONNECTION B
UPDATE Art.Artist
SET  Name = 'Voorman'
WHERE artistId = 9;
--CONNECTION A
ROLLBACK TRANSACTION;
SELECT * FROM Art.Artwork WHERE ArtistId = 9  ;
@LockOwner
Session
sp_releaseAppLock
--CONNECTION A

BEGIN TRANSACTION;
   DECLARE @result int;
   EXEC @result = sp_getapplock @Resource = 'invoiceId=1', @LockMode = 'Exclusive';
   SELECT @result;
APPLOCK_MODE()
SELECT APPLOCK_MODE('public','invoiceId=1');
Exclusive
--CONNECTION B
BEGIN TRANSACTION;
   DECLARE @result int;
   EXEC @result = sp_getapplock @Resource = 'invoiceId=1', @LockMode = 'Exclusive';
   SELECT @result;
--CONNECTION B
BEGIN TRANSACTION;
SELECT  APPLOCK_TEST('public','invoiceId=1','Exclusive','Transaction') as CanTakeLock
ROLLBACK TRANSACTION  ;
CREATE SCHEMA Demo;
GO
CREATE TABLE Demo.Applock
(
    ApplockId int CONSTRAINT PKApplock PRIMARY KEY,  
                                --the value that we will be generating 
                                --with the procedure
    ConnectionId int,           --holds the spid of the connection so you can 
                                --who creates the row
    InsertTime datetime2(3) DEFAULT (SYSDATETIME()) --the time the row was created, so 
                                                    --you can see the progression
);
CREATE PROCEDURE Demo.Applock$test
(
    @ConnectionId int,
    @UseApplockFlag bit = 1,
    @StepDelay varchar(10) = '00:00:00'
) AS
SET NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION
        DECLARE @retval int = 1;
        IF @UseApplockFlag = 1 --turns on and off the applock for testing
            BEGIN
                EXEC @retval = sp_getAppLock @Resource = 'applock$test', 
                                                    @LockMode = 'exclusive'; 
                IF @retval < 0 
                    BEGIN
                        DECLARE @errorMessage nvarchar(200);
                        SET @errorMessage = 
                                CASE @retval
                                    WHEN -1 THEN 'Applock request timed out.'
                                    WHEN -2 THEN 'Applock request canceled.'
                                    WHEN -3 THEN 'Applock involved in deadlock'
                                    ELSE 'Parameter validation or other call error.'
                                END;
                        THROW 50000,@errorMessage,16;
                    END;
            END;

    --get the next primary key value. Reality case is a far more complex number generator
    --that couldn't be done with a sequence or identity
    DECLARE @ApplockId int;   
    SET @ApplockId = COALESCE((SELECT MAX(ApplockId) FROM Demo.Applock),0) + 1;

    --delay for parameterized amount of time to slow down operations 
    --and guarantee concurrency problems
    WAITFOR DELAY @stepDelay; 

    --insert the next value
    INSERT INTO Demo.Applock(ApplockId, connectionId)
    VALUES (@ApplockId, @ConnectionId); 

    --won't have much effect on this code, since the row will now be 
    --exclusively locked, and the max will need to see the new row to 
    --be of any effect.
    IF @useApplockFlag = 1 --turns on and off the applock for testing
        EXEC @retval = sp_releaseApplock @Resource = 'applock$test'; 

    --this releases the applock too
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    --if there is an error, roll back and display it.
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
        SELECT CAST(ERROR_NUMBER() as varchar(10)) + ':' + ERROR_MESSAGE();
END CATCH; 
--test on multiple connections
WAITFOR TIME '21:47';  --set for a time to run so multiple batches 
                       --can simultaneously execute
go
EXEC Demo.Applock$test   @connectionId = @@spid
              ,@useApplockFlag = 0 -- <1=use applock, 0 = don't use applock>
              ,@stepDelay = '00:00:00.001'--'delay in hours:minutes:seconds.parts of seconds';
GO 10000 --runs the batch 10000 times in SSMS  
    SET @applockId = 
          COALESCE((SELECT MAX(applockId) 
                    FROM APPLOCK WITH (UPDLOCK,PAGLOCK)),0) + 1; 
Optimistic Concurrency Enforcement
Optimistic Concurrency Enforcement in On-Disk Tables
ALTER DATABASE Chapter11
     SET ALLOW_SNAPSHOT_ISOLATION ON;
Art.Artist
--CONNECTION A
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
SELECT ArtistId, Name FROM Art.Artist;
--CONNECTION B
INSERT INTO Art.Artist(ArtistId, Name)
VALUES (10, 'Disney');
--CONNECTION B
DELETE FROM Art.Artist
WHERE  ArtistId = 3;
--CONNECTION A
SELECT ArtistId, Name FROM Art.Artist  ;




--CONNECTION A
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

UPDATE Art.Artist
SET    Name = 'Duh Vinci'
WHERE  ArtistId = 1;
--CONNECTION B
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

UPDATE Art.Artist
SET    Name = 'Dah Vinci'
WHERE  ArtistId = 1;
--CONNECTION A
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
SELECT *
FROM   Art.Artist;

--CONNECTION B
UPDATE Art.Artist
SET    Name = 'Dah Vinci'
WHERE  ArtistId = 1;
--CONNECTION A
UPDATE Art.Artist
SET    Name = 'Duh Vinci'
WHERE  ArtistId = 1;
READ COMMITTED
--must be no active connections other than the connection executing
--this ALTER command
ALTER DATABASE Chapter11
    SET READ_COMMITTED_SNAPSHOT ON;
BEGIN TRANSACTION
SELECT column FROM table1
--midpoint
SELECT column FROM table1
COMMIT TRANSACTION
--CONNECTION A
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
SELECT ArtistId, Name FROM Art.Artist;
--CONNECTION B
BEGIN TRANSACTION;
INSERT INTO Art.Artist (ArtistId, Name)  
VALUES  (11, 'Freling' )

--CONNECTION A
SELECT ArtistId, Name FROM Art.Artist;  


--CONNECTION B (still in a transaction)
UPDATE Art.Artist 
SET  Name = UPPER(Name)

--CONNECTION A
SELECT ArtistId, Name FROM Art.Artist;
--CONNECTION B
COMMIT;

--CONNECTION A
SELECT ArtistId, Name FROM Art.Artist;
COMMIT;
Optimistic Concurrency Enforcement in In-Memory OLTP Tables
CONNECTION B
TableNameId
'Canada'
CONNECTION B
CONNECTION B
CONNECTION A
CONNECTION A
Country='USA'
CONNECTION A
SNAPSHOT
REPEATABLE READ
SERIALIZABLE
REPEATABLE READ
SERIALIZABLE
SNAPSHOT
COMMIT
SNAPSHOT
--The download will include the code to add an in-memory filegroup 

CREATE SCHEMA Art_InMem;
GO
CREATE TABLE Art_InMem.Artist
(
    ArtistId int CONSTRAINT PKArtist PRIMARY KEY  
                                       NONCLUSTERED HASH  WITH (BUCKET_COUNT=100)
    ,Name varchar(30) --no key on value for demo purposes, just like on-disk example
    ,Padding char(4000) --can't use REPLICATE in in-memory OLTP, so will use in INSERT

) WITH ( MEMORY_OPTIMIZED = ON ); 

INSERT INTO Art_InMem.Artist(ArtistId, Name,Padding)
VALUES (1,'da Vinci',REPLICATE('a',4000)),(2,'Micheangelo',REPLICATE('a',4000)), 
       (3,'Donatello',REPLICATE('a',4000)),(4,'Picasso',REPLICATE('a',4000)),
           (5,'Dali',REPLICATE('a',4000)), (6,'Jones',REPLICATE('a',4000));     
GO

CREATE TABLE Art_InMem.ArtWork
(
    ArtWorkId int CONSTRAINT PKArtWork PRIMARY KEY 
                                         NONCLUSTERED HASH  WITH (BUCKET_COUNT=100)
    ,ArtistId int NOT NULL 
        CONSTRAINT FKArtwork$wasDoneBy$Art_Artist REFERENCES Art_InMem.Artist (ArtistId)
    ,Name varchar(30) 
    ,Padding char(4000) --can't use REPLICATE in in-memory OLTP, so will use in INSERT
    ,CONSTRAINT AKArtwork UNIQUE NONCLUSTERED (ArtistId, Name)
) WITH ( MEMORY_OPTIMIZED = ON ); 

INSERT Art_InMem.Artwork (ArtworkId, ArtistId, Name,Padding)
VALUES (1,1,'Last Supper',REPLICATE('a',4000)),(2,1,'Mona Lisa',REPLICATE('a',4000)),
       (3,6,'Rabbit Fire',REPLICATE('a',4000  ));
INSERT INTO InMemTable
SELECT *
FROM DBOtherThanTempdb.SchemaName.Tablename;
SELECT ArtistId, Name
FROM   Art_Inmem.Artist;
BEGIN TRANSACTION;
SELECT ArtistId, Name
FROM   Art_Inmem.Artist;
COMMIT TRANSACTION  ;
REPEATABLE READ
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION;
SELECT ArtistId, Name
FROM   Art_Inmem.Artist WITH (REPEATABLEREAD  );
COMMIT TRANSACTION;
BEGIN TRANSACTION;
SELECT ArtistId, Name
FROM   Art_Inmem.Artist WITH (SNAPSHOT);
COMMIT TRANSACTION;
ALTER DATABASE LetMeFinish
  SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT ON;
SNAPSHOT
REPEATABLE READ
SERIALIZABLE
SNAPSHOT
CONNECTION A
CONNECTION B
--CONNECTION A
BEGIN TRANSACTION;

--CONNECTION B
INSERT INTO Art_InMem.Artist(ArtistId, Name)
VALUES (7, 'McCartney');
--CONNECTION A
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 5;
BEGIN TRANSACTION
Artist
CONNECTION B
ArtistId = 6
--CONNECTION B
INSERT INTO Art_InMem.Artist(ArtistId, Name)
VALUES (8, 'Starr');

INSERT INTO Art_InMem.Artwork(ArtworkId, ArtistId, Name)
VALUES (4,7,'The Kiss');

DELETE FROM Art_InMem.Artist WHERE ArtistId = 5;
--CONNECTION A
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 5;

SELECT COUNT(*)
FROM  Art_InMem.Artwork WITH (SNAPSHOT);
COMMIT
ROLLBACK
CONNECTION A
--CONNECTION A
COMMIT;

SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 5;

SELECT COUNT(*)
FROM  Art_InMem.Artwork WITH (SNAPSHOT);
CONNECTION A
CONNECTION B
CONNECTION B
CONNECTION B
REPEATABLE READ
--CONNECTION A
BEGIN TRANSACTION;
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (REPEATABLEREAD)
WHERE ArtistId >= 8;
--CONNECTION B
INSERT INTO Art_InMem.Artist(ArtistId, Name)
VALUES (9,'Groening'); 
--CONNECTION A
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 8;
COMMIT;
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 8;
CONNECTION A
--CONNECTION A
BEGIN TRANSACTION;
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (REPEATABLEREAD)
WHERE ArtistId >= 8;

--CONNECTION B
DELETE FROM Art_InMem.Artist WHERE ArtistId = 9; --Not because I don't love Matt!
--CONNECTION A
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 8;
COMMIT;
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 8;
REPEATABLE READ
--CONNECTION A
BEGIN TRANSACTION;
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SERIALIZABLE)
WHERE ArtistId >= 8;
--CONNECTION B
INSERT INTO Art_InMem.Artist(ArtistId, Name)
VALUES (9,'Groening'); --See, brought him back!
--CONNECTION A
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId >= 8;
COMMIT;
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SERIALIZABLE)
WHERE ArtistId >= 8;
Name
CONNECTION A
--CONNECTION A
BEGIN TRANSACTION;
SELECT ArtistId, Name
FROM  Art_InMem.Artist WITH (SERIALIZABLE)
WHERE Name = 'Starr';
--CONNECTION B
UPDATE Art_InMem.Artist WITH (SNAPSHOT) --default to snapshot, but the change itself
                                        --behaves the same in any isolation level
SET    Padding = REPLICATE('a',4000) --just make a change
WHERE  Name = 'McCartney'; 
--CONNECTION A  
COMMIT;
ALTER TABLE Art_InMem.Artist
  ADD CONSTRAINT AKArtist UNIQUE NONCLUSTERED (Name) --A string column may be used to 
                                                     --do ordered scans,
                                                     --particularly one like name
CONNECTION A
CONNECTION B
--CONNECTION A
BEGIN TRANSACTION;
UPDATE Art_InMem.Artist WITH (SNAPSHOT)
SET    Padding = REPLICATE('a',4000) --just make a change
WHERE  Name = 'McCartney'; 
CONNECTION B
--CONNECTION B
BEGIN TRANSACTION;
UPDATE Art_InMem.Artist WITH (SNAPSHOT)
SET    Padding = REPLICATE('a',4000) --just make a change
WHERE  Name = 'McCartney'; 
--CONNECTION A
ROLLBACK TRANSACTION --from previous example
BEGIN TRANSACTION
INSERT INTO Art_InMem.Artist (ArtistId, Name)
VALUES  (11,'Wright');

--CONNECTION B
BEGIN TRANSACTION;
INSERT INTO Art_InMem.Artist (ArtistId, Name)
VALUES  (12,'Wright');
--CONNECTION A
COMMIT;
--CONNECTION B
COMMIT;
UNIQUE
INSERT
--CONNECTION A
BEGIN TRANSACTION;
DELETE FROM Art_InMem.Artist WITH (SNAPSHOT)
WHERE ArtistId = 4;
--CONNECTION B --in or out of transaction
INSERT INTO Art_InMem.Artist (ArtistId, Name)
VALUES (4,'Picasso')
Name
PRIMARY KEY
ROLLBACK
--CONNECTION A
ROLLBACK; --We like Picasso  
--CONNECTION A
BEGIN TRANSACTION
INSERT INTO Art_InMem.Artwork(ArtworkId, ArtistId, Name)
VALUES (5,4,'The Old Guitarist');
--CONNECTION B
UPDATE Art_InMem.Artist WITH (SNAPSHOT)
SET    Padding = REPLICATE('a',4000) --just make a change
WHERE ArtistId = 4;
--CONNECTION A
COMMIT;
Coding for Ascynronous Contention
UPDATE
Row-Based Change Detection
Adding Validation Columns
CREATE SCHEMA Hr;
GO
CREATE TABLE Hr.person
(
     PersonId int IDENTITY(1,1) CONSTRAINT PKPerson primary key,
     FirstName varchar(60) NOT NULL,
     MiddleName varchar(60) NOT NULL,
     LastName varchar(60) NOT NULL,

     DateOfBirth date NOT NULL,
     RowLastModifyTime datetime2(3) NOT NULL
         CONSTRAINT DFLTPerson_RowLastModifyTime DEFAULT (SYSDATETIME()),
     RowModifiedByUserIdentifier nvarchar(128) NOT NULL
         CONSTRAINT DFLTPerson_RowModifiedByUserIdentifier DEFAULT suser_sname()

);
UPDATE
CREATE TRIGGER Hr.Person$InsteadOfUpdateTrigger
ON Hr.Person
INSTEAD OF UPDATE AS
BEGIN

    --stores the number of rows affected
   DECLARE @rowsAffected int = @@rowcount,
           @msg varchar(2000) = '';    --used to hold the error message

      --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   SET NOCOUNT ON; --to avoid the rowcount messages
   SET ROWCOUNT 0; --in case the client has modified the rowcount

   BEGIN TRY
          --[validation blocks]
          --[modification blocks]
          --remember to update ALL columns when building instead of triggers
          UPDATE Hr.Person
          SET    FirstName = inserted.FirstName,
                 MiddleName = inserted.MiddleName,
                 LastName = inserted.LastName,
                 DateOfBirth = inserted.DateOfBirth,
                 RowLastModifyTime = default, -- set the value to the default
                 RowModifiedByUserIdentifier = default 
          FROM   Hr.Person                              
                     JOIN inserted
                             on Person.PersonId = inserted.PersonId;
   END TRY
      BEGIN CATCH
              IF XACT_STATE() > 0
                  ROLLBACK TRANSACTION;

              THROW; --will halt the batch or be caught by the caller's catch block

     END CATCH;
END;
INSERT INTO Hr.Person (FirstName, MiddleName, LastName, DateOfBirth)
VALUES ('Paige','O','Anxtent','19691212');

SELECT *
FROM   Hr.Person;
UPDATE Hr.Person
SET    MiddleName = 'Ona'
WHERE  PersonId = 1;

SELECT RowLastModifyTime
FROM   Hr.Person;
INSERT
rowversion
ALTER TABLE hr.person
     ADD RowVersion rowversion;
GO
SELECT PersonId, RowVersion
FROM   Hr.Person;
UPDATE  Hr.Person
SET     FirstName = 'Paige' --no actual change occurs
WHERE   PersonId = 1;
Coding for Row-Level Change Detection
UPDATE  Hr.Person
SET     FirstName = 'Headley'
WHERE   PersonId = 1  --include the key, even when changing the key value if allowed
  --non-key columns
  and   FirstName = 'Paige'
  and   MiddleName = 'ona'
  and   LastName = 'Anxtent'
  and   DateOfBirth = '19691212'  ;
IF EXISTS ( SELECT *
            FROM   Hr.Person
            WHERE  PersonId = 1) --check for existence of the primary key
  --raise an error stating that the row no longer exists
ELSE
  --raise an error stating that another user has changed the row
UPDATE  Hr.Person
SET     FirstName = 'Fred'
WHERE   PersonId = 1  --include the key
  AND   RowLastModifyTime = '2016-06-11 14:52:50.154';
UPDATE  Hr.Person
SET     FirstName = 'Fred'
WHERE   PersonId = 1
  and   RowVersion = 0x00000000000007D4;
DELETE FROM Hr.Person
WHERE  PersonId = 1
  And  Rowversion = 0x00000000000007D5;
Coding for Logical Unit of Work Change Detection
CREATE SCHEMA Invoicing;
GO
--leaving off who invoice is for, like an account or person name
CREATE TABLE Invoicing.Invoice
(
     InvoiceId int IDENTITY(1,1),
     Number varchar(20) NOT NULL,
     ObjectVersion rowversion not null,
     CONSTRAINT PKInvoice PRIMARY KEY (InvoiceId)
);
--also ignoring what product that the line item is for
CREATE TABLE Invoicing.InvoiceLineItem

(
     InvoiceLineItemId int NOT NULL,
     InvoiceId int NULL,
     ItemCount int NOT NULL,
     Cost int NOT NULL,
     CONSTRAINT PKInvoiceLineItem primary key (invoiceLineItemId),
     CONSTRAINT FKInvoiceLineItem$references$Invoicing_Invoice
            FOREIGN KEY (InvoiceId) REFERENCES Invoicing.Invoice(InvoiceId)
);
CREATE PROCEDURE InvoiceLineItem$del
(
    @InvoiceId int, --we pass this because the client should have it
                    --with the invoiceLineItem row
    @InvoiceLineItemId int,
    @ObjectVersion rowversion
) as
  BEGIN
    --gives us a unique savepoint name, trim it to 125
    --characters if the user named it really large
    DECLARE @savepoint nvarchar(128) = 
                          CAST(OBJECT_NAME(@@procid) AS nvarchar(125)) +
                                         CAST(@@nestlevel AS nvarchar(3));
    --get initial entry level, so we can do a rollback on a doomed transaction
    DECLARE @entryTrancount int = @@trancount;

    BEGIN TRY
        BEGIN TRANSACTION;
        SAVE TRANSACTION @savepoint;

        --tweak the ObjectVersion on the Invoice Table
        UPDATE  Invoicing.Invoice
        SET     Number = Number
        WHERE   InvoiceId = @InvoiceId
          And   ObjectVersion = @ObjectVersion;

        IF @@Rowcount = 0
           THROW 50000,'The InvoiceId no longer exists or has been changed',1;

        DELETE  Invoicing.InvoiceLineItem
        FROM    InvoiceLineItem
        WHERE   InvoiceLineItemId = @InvoiceLineItemId;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        --if the tran is doomed, and the entryTrancount was 0,
        --we can roll back    
        IF XACT_STATE ()= -1 AND @entryTrancount = 0 
            ROLLBACK TRANSACTION;

        --otherwise, we can still save the other activities in the
       --transaction.
       ELSE IF XACT_STATE() = 1 --transaction not doomed, but open
         BEGIN
             ROLLBACK TRANSACTION @savepoint;
             COMMIT TRANSACTION;
         END;

        DECLARE @ERRORmessage nvarchar(4000)
        SET @ERRORmessage = 'Error occurred in procedure ''' + 
              OBJECT_NAME (@@procid) + ''', Original Message: ''' 
              + ERROR_MESSAGE() + '''';
        THROW 50000,@ERRORmessage,1;
        RETURN -100;

     END CATCH;
 END  ;
Best Practices
Summary
