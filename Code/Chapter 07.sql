--CREATE DATABASE Chapter7
--go
--Use Chapter7
--go

Use Chapter7
GO

DROP TABLE IF EXISTS Music.Album, Music.Publisher, Music.Artist;
GO
DROP SCHEMA IF EXISTS Music;
GO

---Check Constraints

CREATE SCHEMA Music;
GO
CREATE TABLE Music.Artist
(
   ArtistId int NOT NULL,
   Name varchar(60) NOT NULL,

   CONSTRAINT PKArtist PRIMARY KEY CLUSTERED (ArtistId),
   CONSTRAINT PKArtist_Name UNIQUE NONCLUSTERED (Name)
);
CREATE TABLE Music.Publisher
(
        PublisherId              int CONSTRAINT PKPublisher PRIMARY KEY,
        Name                     varchar(20),
        CatalogNumberMask        varchar(100)
        CONSTRAINT DFLTPublisher_CatalogNumberMask DEFAULT ('%'),
        CONSTRAINT AKPublisher_Name UNIQUE NONCLUSTERED (Name),
);

CREATE TABLE Music.Album
(
       AlbumId int NOT NULL,
       Name varchar(60) NOT NULL,
       ArtistId int NOT NULL,
       CatalogNumber varchar(20) NOT NULL,
       PublisherId int NOT NULL 

       CONSTRAINT PKAlbum PRIMARY KEY CLUSTERED(AlbumId),
       CONSTRAINT AKAlbum_Name UNIQUE NONCLUSTERED (Name),
       CONSTRAINT FKArtist$records$Music_Album
            FOREIGN KEY (ArtistId) REFERENCES Music.Artist(ArtistId),
       CONSTRAINT FKPublisher$Published$Music_Album
            FOREIGN KEY (PublisherId) REFERENCES Music.Publisher(PublisherId)
);
GO

INSERT  INTO Music.Publisher (PublisherId, Name, CatalogNumberMask)
VALUES (1,'Capitol',
        '[0-9][0-9][0-9]-[0-9][0-9][0-9a-z][0-9a-z][0-9a-z]-[0-9][0-9]'),
        (2,'MCA', '[a-z][a-z][0-9][0-9][0-9][0-9][0-9]');

INSERT  INTO Music.Artist(ArtistId, Name)
VALUES (1, 'The Beatles'),(2, 'The Who');

INSERT INTO Music.Album (AlbumId, Name, ArtistId, PublisherId, CatalogNumber)
VALUES (1, 'The White Album',1,1,'433-43ASD-33'),
       (2, 'Revolver',1,1,'111-11111-11'),
       (3, 'Quadrophenia',2,2,'CD12345');
GO


ALTER TABLE Music.Artist WITH CHECK
   ADD CONSTRAINT CHKArtist$Name$NoPetShopNames
           CHECK (Name NOT LIKE '%Pet%Shop%');
GO

INSERT INTO Music.Artist(ArtistId, Name)
VALUES (3, 'Pet Shop Boys');
GO

INSERT INTO Music.Artist(ArtistId, Name)
VALUES (3, 'Madonna');
GO

ALTER TABLE Music.Artist WITH CHECK
   ADD CONSTRAINT CHKArtist$Name$noMadonnaNames
           CHECK (Name NOT LIKE '%Madonna%');
GO

ALTER TABLE Music.Artist WITH NOCHECK
   ADD CONSTRAINT CHKArtist$Name$noMadonnaNames
           CHECK (Name NOT LIKE '%Madonna%');
GO

UPDATE Music.Artist
SET Name = Name;
GO


SELECT definition, is_not_trusted
FROM   sys.check_constraints
WHERE  object_schema_name(object_id) = 'Music'
  AND  name = 'CHKArtist$Name$noMadonnaNames';
GO


ALTER TABLE Music.Artist WITH CHECK CHECK CONSTRAINT CHKArtist$Name$noMadonnaNames;
GO

DELETE FROM  Music.Artist
WHERE  Name = 'Madonna';
GO

ALTER TABLE Music.Artist NOCHECK CONSTRAINT CHKArtist$Name$noMadonnaNames;
GO


SELECT definition, is_not_trusted, is_disabled
FROM   sys.check_constraints
WHERE  object_schema_name(object_id) = 'Music'
  AND  name = 'CHKArtist$Name$noMadonnaNames';
GO

ALTER TABLE Music.Artist WITH CHECK CHECK CONSTRAINT CHKArtist$Name$noMadonnaNames;
GO


-----CHECK Constraints Based on Simple Expressions

ALTER TABLE Music.Album WITH CHECK
   ADD CONSTRAINT CHKAlbum$Name$noEmptyString
           CHECK (LEN(Name) > 0); --note,len does a trim by default, so any string 
                                  --of all space characters will return 0

GO

INSERT INTO Music.Album ( AlbumId, Name, ArtistId, PublisherId, CatalogNumber )
VALUES ( 4, '', 1, 1,'dummy value' );

----CHECK Constraints Using Functions

CREATE FUNCTION Music.Publisher$CatalogNumberValidate
(
   @CatalogNumber char(12),
   @PublisherId int --now based on the Artist ID
)

RETURNS bit
AS
BEGIN
   DECLARE @LogicalValue bit, @CatalogNumberMask varchar(100);

   SELECT @LogicalValue = CASE WHEN @CatalogNumber LIKE CatalogNumberMask
                                      THEN 1
                               ELSE 0  END
   FROM   Music.Publisher
   WHERE  PublisherId = @PublisherId;

   RETURN @LogicalValue;
END; 
GO


SELECT Album.CatalogNumber, Publisher.CatalogNumberMask
FROM   Music.Album
         JOIN Music.Publisher as Publisher
            ON Album.PublisherId = Publisher.PublisherId;
GO

ALTER TABLE Music.Album
   WITH CHECK ADD CONSTRAINT
       CHKAlbum$CatalogNumber$CatalogNumberValidate
             CHECK (Music.Publisher$CatalogNumberValidate
                          (CatalogNumber,PublisherId) = 1);
GO

SELECT Album.Name, Album.CatalogNumber, Publisher.CatalogNumberMask
FROM Music.Album 
       JOIN Music.Publisher 
         ON Publisher.PublisherId = Album.PublisherId
WHERE Music.Publisher$CatalogNumberValidate(Album.CatalogNumber,Album.PublisherId) <> 1;
GO

INSERT  Music.Album(AlbumId, Name, ArtistId, PublisherId, CatalogNumber)
VALUES  (4,'Who''s Next',2,2,'1');
GO

INSERT  Music.Album(AlbumId, Name, ArtistId, CatalogNumber, PublisherId)
VALUES  (4,'Who''s Next',2,'AC12345',2);
GO

SELECT * FROM Music.Album;
GO

SELECT *
FROM   Music.Album AS Album
          JOIN Music.Publisher AS Publisher
                ON Publisher.PublisherId = Album.PublisherId
WHERE  Music.Publisher$CatalogNumberValidate
                        (Album.CatalogNumber, Album.PublisherId) <> 1;


----Enhancing Errors Caused by Constraints

CREATE SCHEMA ErrorHandling; --used to hold objects for error management purposes
GO
CREATE TABLE ErrorHandling.ErrorMap
(
    ConstraintName sysname NOT NULL CONSTRAINT PKErrorMap PRIMARY KEY,
    Message         varchar(2000) NOT NULL
);
GO

INSERT ErrorHandling.ErrorMap(constraintName, message)
VALUES ('CHKAlbum$CatalogNumber$CatalogNumberValidate',
        'The catalog number does not match the format set up by the Publisher');
GO

CREATE PROCEDURE ErrorHandling.ErrorMap$MapError
(
    @ErrorNumber  int = NULL,
    @ErrorMessage nvarchar(2000) = NULL,
    @ErrorSeverity INT= NULL

) AS
  BEGIN
    SET NOCOUNT ON

    --use values in ERROR_ functions unless the user passes in values
    SET @ErrorNumber = Coalesce(@ErrorNumber, ERROR_NUMBER());
    SET @ErrorMessage = Coalesce(@ErrorMessage, ERROR_MESSAGE());
    SET @ErrorSeverity = Coalesce(@ErrorSeverity, ERROR_SEVERITY());

    --strip the constraint name out of the error message
    DECLARE @constraintName sysname;
    SET @constraintName = substring( @ErrorMessage,
                             CHARINDEX('constraint "',@ErrorMessage) + 12,
                             CHARINDEX('"',substring(@ErrorMessage,
                             CHARINDEX('constraint "',@ErrorMessage) +
                                                                12,2000))-1)
    --store off original message in case no custom message found
    DECLARE @originalMessage nvarchar(2000);
    SET @originalMessage = ERROR_MESSAGE();

    IF @ErrorNumber = 547 --constraint error
      BEGIN
        SET @ErrorMessage =
                        (SELECT message
                         FROM   ErrorHandling.ErrorMap
                         WHERE  constraintName = @constraintName); 
      END

    --if the error was not found, get the original message with generic 50000 error number
    SET @ErrorMessage = ISNULL(@ErrorMessage, @originalMessage);
    THROW  50000, @ErrorMessage, @ErrorSeverity;
  END
GO


BEGIN TRY
     INSERT  Music.Album(AlbumId, Name, ArtistId, CatalogNumber, PublisherId)
     VALUES  (5,'who are you',2,'badnumber',2);
END TRY
BEGIN CATCH
    EXEC ErrorHandling.ErrorMap$MapError;
END CATCH

----DML Triggers
-----AFTER Triggers
-------Range Checks on Multiple Rows
CREATE SCHEMA Accounting;
GO
CREATE TABLE Accounting.Account
(
        AccountNumber        char(10) NOT NULL
                  CONSTRAINT PKAccount PRIMARY KEY
        --would have other columns
);

CREATE TABLE Accounting.AccountActivity
(
        AccountNumber                char(10) NOT NULL
            CONSTRAINT FKAccount$has$Accounting_AccountActivity
                       FOREIGN KEY REFERENCES Accounting.Account(AccountNumber),
       --this might be a value that each ATM/Teller generates
        TransactionNumber            char(20) NOT NULL,
        Date                         datetime2(3) NOT NULL,
        TransactionAmount            numeric(12,2) NOT NULL,
        CONSTRAINT PKAccountActivity
                      PRIMARY KEY (AccountNumber, TransactionNumber)
);
GO


CREATE TRIGGER Accounting.AccountActivity$insertTrigger
ON Accounting.AccountActivity
AFTER INSERT AS
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

   --[validation section]
   --disallow Transactions that would put balance into negatives
   IF EXISTS ( SELECT AccountNumber
               FROM Accounting.AccountActivity AS AccountActivity
               WHERE EXISTS (SELECT *
                             FROM   inserted
                             WHERE  inserted.AccountNumber =
                               AccountActivity.AccountNumber)
                   GROUP BY AccountNumber
                   HAVING SUM(TransactionAmount) < 0)
      BEGIN
         IF @rowsAffected = 1
             SELECT @msg = CONCAT('Account: ', AccountNumber,
                  ' TransactionNumber:',TransactionNumber, ' for amount: ', TransactionAmount,
                  ' cannot be processed as it will cause a negative balance')
             FROM   inserted;
        ELSE
          SELECT @msg = 'One of the rows caused a negative balance';
          THROW  50000, @msg, 16;
      END

   --[modification section]
   END TRY
   BEGIN CATCH
              IF @@trancount > 0
                  ROLLBACK TRANSACTION;

              THROW; --will halt the batch or be caught by the caller's catch block

     END CATCH
END;
GO

SELECT AccountNumber
FROM Accounting.AccountActivity AS AccountActivity
GROUP BY AccountNumber
HAVING SUM(TransactionAmount) < 0;
GO


--create some set up test data
INSERT INTO Accounting.Account(AccountNumber)
VALUES ('1111111111');

INSERT INTO Accounting.AccountActivity(AccountNumber, TransactionNumber,
                                         Date, TransactionAmount)
VALUES ('1111111111','A0000000000000000001','20050712',100),
       ('1111111111','A0000000000000000002','20050713',100);
GO

INSERT  INTO Accounting.AccountActivity(AccountNumber, TransactionNumber,
                                         Date, TransactionAmount)
VALUES ('1111111111','A0000000000000000003','20050713',-300);
INSERT  INTO Accounting.Account(AccountNumber)
VALUES ('2222222222');
GO

--Now, this data will violate the constraint for the new Account:
INSERT  INTO Accounting.AccountActivity(AccountNumber, TransactionNumber,
                                        Date, TransactionAmount)
VALUES ('1111111111','A0000000000000000004','20050714',100),
       ('2222222222','A0000000000000000005','20050715',100),
       ('2222222222','A0000000000000000006','20050715',100),
       ('2222222222','A0000000000000000007','20050715',-201);
GO

SELECT trigger_events.type_desc
FROM sys.trigger_events
         JOIN sys.triggers
                  ON sys.triggers.object_id = sys.trigger_events.object_id
WHERE  triggers.name = 'AccountActivity$insertTrigger';
GO


ALTER TABLE Accounting.Account 
   ADD BalanceAmount numeric(12,2) NOT NULL
      CONSTRAINT DFLTAccount_BalanceAmount DEFAULT (0.00); 
GO

SELECT  Account.AccountNumber,
        SUM(COALESCE(AccountActivity.TransactionAmount,0.00)) AS NewBalance
FROM   Accounting.Account
         LEFT OUTER JOIN Accounting.AccountActivity
            ON Account.AccountNumber = AccountActivity.AccountNumber
GROUP  BY Account.AccountNumber;
GO

WITH  UpdateCTE AS (
SELECT  Account.AccountNumber,
        SUM(coalesce(TransactionAmount,0.00)) AS NewBalance
FROM   Accounting.Account
        LEFT OUTER JOIN Accounting.AccountActivity
            On Account.AccountNumber = AccountActivity.AccountNumber
GROUP  BY Account.AccountNumber)
UPDATE Account
SET    BalanceAmount = UpdateCTE.NewBalance
FROM   Accounting.Account
         JOIN UpdateCTE
                ON Account.AccountNumber = UpdateCTE.AccountNumber;
GO


ALTER TRIGGER Accounting.AccountActivity$insertTrigger
ON Accounting.AccountActivity
AFTER INSERT AS
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

   BEGIN TRY

   --[validation section]
   --disallow Transactions that would put balance into negatives
   IF EXISTS ( SELECT AccountNumber
               FROM Accounting.AccountActivity as AccountActivity
               WHERE EXISTS (SELECT *
                             FROM   inserted
                             WHERE  inserted.AccountNumber =
                               AccountActivity.AccountNumber)
                   GROUP BY AccountNumber
                   HAVING SUM(TransactionAmount) < 0)
      BEGIN
         IF @rowsAffected = 1
             SELECT @msg = 'Account: ' + AccountNumber +
                  ' TransactionNumber:' +
                   cast(TransactionNumber as varchar(36)) +
                   ' for amount: ' + cast(TransactionAmount as varchar(10))+
                   ' cannot be processed as it will cause a negative balance'
             FROM   inserted;
        ELSE
          SELECT @msg = 'One of the rows caused a negative balance';

          THROW  50000, @msg, 16;
      END;

    --[modification section]
    IF UPDATE (TransactionAmount)
      BEGIN
        ;WITH  Updater as (
        SELECT  Account.AccountNumber,
                SUM(coalesce(TransactionAmount,0.00)) AS NewBalance
        FROM   Accounting.Account
                LEFT OUTER JOIN Accounting.AccountActivity
                    On Account.AccountNumber = AccountActivity.AccountNumber
               --This where clause limits the summarizations to those rows
               --that were modified by the DML statement that caused
               --this trigger to fire.
        WHERE  EXISTS (SELECT *
                       FROM   Inserted
                       WHERE  Account.AccountNumber = Inserted.AccountNumber)
        GROUP  BY Account.AccountNumber)

        UPDATE Account
        SET    BalanceAmount = Updater.NewBalance
        FROM   Accounting.Account
                  JOIN Updater
                      ON Account.AccountNumber = Updater.AccountNumber;
      END;


   END TRY
   BEGIN CATCH
              IF @@trancount > 0
                  ROLLBACK TRANSACTION;

              THROW; --will halt the batch or be caught by the caller's catch block

   END CATCH;
END;
GO

INSERT  INTO Accounting.AccountActivity(AccountNumber, TransactionNumber,
                                        Date, TransactionAmount)
VALUES ('1111111111','A0000000000000000004','20050714',100);
GO

SELECT  Account.AccountNumber,Account.BalanceAmount,
        SUM(coalesce(AccountActivity.TransactionAmount,0.00)) AS SummedBalance
FROM   Accounting.Account
        LEFT OUTER JOIN Accounting.AccountActivity
            ON Account.AccountNumber = AccountActivity.AccountNumber
GROUP  BY Account.AccountNumber,Account.BalanceAmount;
GO


INSERT  into Accounting.AccountActivity(AccountNumber, TransactionNumber,
                                        Date, TransactionAmount)
VALUES ('1111111111','A0000000000000000005','20050714',100),
       ('2222222222','A0000000000000000006','20050715',100),
       ('2222222222','A0000000000000000007','20050715',100);

----Cascading Inserts

CREATE SCHEMA Internet;
GO
CREATE TABLE Internet.Url
(
    UrlId int NOT NULL IDENTITY(1,1) CONSTRAINT PKUrl primary key,
    Name  varchar(60) NOT NULL CONSTRAINT AKUrl_Name UNIQUE,
    Url   varchar(200) NOT NULL CONSTRAINT AKUrl_Url UNIQUE
);
GO

--Not a user manageable table, so not using identity key (as discussed in
--Chapter 6 when I discussed choosing keys) in this one table.  Others are
--using identity-based keys in this example.
CREATE TABLE Internet.UrlStatusType
(
        UrlStatusTypeId  int NOT NULL
                      CONSTRAINT PKUrlStatusType PRIMARY KEY,
        Name varchar(20) NOT NULL
                      CONSTRAINT AKUrlStatusType UNIQUE,
        DefaultFlag bit NOT NULL,
        DisplayOnSiteFlag bit NOT NULL
); 

CREATE TABLE Internet.UrlStatus
(
        UrlStatusId int NOT NULL IDENTITY(1,1)
                      CONSTRAINT PKUrlStatus PRIMARY KEY,
        UrlStatusTypeId int NOT NULL
                      CONSTRAINT
               FKUrlStatusType$defines_status_type_of$Internet_UrlStatus
                      REFERENCES Internet.UrlStatusType(UrlStatusTypeId),
        UrlId int NOT NULL
          CONSTRAINT FKUrl$has_status_history_in$Internet_UrlStatus
                      REFERENCES Internet.Url(UrlId),
        ActiveTime        datetime2(3),
        CONSTRAINT AKUrlStatus_statusUrlDate
                      UNIQUE (UrlStatusTypeId, UrlId, ActiveTime)
);

--set up status types
INSERT  Internet.UrlStatusType (UrlStatusTypeId, Name,
                                   DefaultFlag, DisplayOnSiteFlag)
VALUES (1, 'Unverified',1,0),
       (2, 'Verified',0,1),
       (3, 'Unable to locate',0,0);
GO

CREATE TRIGGER Internet.Url$insertTrigger
ON Internet.Url
AFTER INSERT AS
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

   BEGIN TRY
          --[validation section]

          --[modification section]
          --add a row to the UrlStatus table to tell it that the new row
          --should start out as the default status
          INSERT INTO Internet.UrlStatus (UrlId, UrlStatusTypeId, ActiveTime)
          SELECT inserted.UrlId, UrlStatusType.UrlStatusTypeId,
                  SYSDATETIME()
          FROM inserted
                CROSS JOIN (SELECT UrlStatusTypeId
                            FROM   UrlStatusType
                            WHERE  DefaultFlag = 1)  as UrlStatusType;
                                           --use cross join to apply this one row to 
                                           --rows in inserted
   END TRY
   BEGIN CATCH
              IF @@TRANCOUNT > 0
                  ROLLBACK TRANSACTION;
              THROW; --will halt the batch or be caught by the caller's catch block

     END CATCH;
END;
GO


INSERT  Internet.Url(Name, Url)
VALUES ('Author''s Website',
        'http://drsql.org');
GO



SELECT Url.Url,Url.Name,UrlStatusType.Name as Status, UrlStatus.ActiveTime
FROM   Internet.Url
          JOIN Internet.UrlStatus
             ON Url.UrlId = UrlStatus.UrlId
          JOIN Internet.UrlStatusType
             ON UrlStatusType.UrlStatusTypeId = UrlStatus.UrlStatusTypeId;


-----Cascading from Child to Parent

CREATE SCHEMA Entertainment;
GO
CREATE TABLE Entertainment.GamePlatform
(
    GamePlatformId int NOT NULL CONSTRAINT PKGamePlatform PRIMARY KEY,
    Name  varchar(50) NOT NULL CONSTRAINT AKGamePlatform_Name UNIQUE
);
CREATE TABLE Entertainment.Game
(
    GameId  int NOT NULL CONSTRAINT PKGame PRIMARY KEY,
    Name    varchar(50) NOT NULL CONSTRAINT AKGame_Name UNIQUE
    --more details that are common to all platforms
);

--associative entity with cascade relationships back to Game and GamePlatform
CREATE TABLE Entertainment.GameInstance
(
    GamePlatformId int NOT NULL,
    GameId int NOT NULL,
    PurchaseDate date NOT NULL,
    CONSTRAINT PKGameInstance PRIMARY KEY (GamePlatformId, GameId),
    CONSTRAINT FKGame$is_owned_on_platform_by$EntertainmentGameInstance
                  FOREIGN KEY (GameId) 
                           REFERENCES Entertainment.Game(GameId) ON DELETE CASCADE,
      CONSTRAINT FKGamePlatform$is_linked_to$EntertainmentGameInstance
                  FOREIGN KEY (GamePlatformId)
                           REFERENCES Entertainment.GamePlatform(GamePlatformId)
                ON DELETE CASCADE
);
GO

INSERT  Entertainment.Game (GameId, Name)
VALUES (1,'Disney Infinity'),
       (2,'Super Mario Bros');

INSERT  Entertainment.GamePlatform(GamePlatformId, Name)
VALUES (1,'Nintendo WiiU'),   --Yes, as a matter of fact I am still a
       (2,'Nintendo 3DS');     --Nintendo Fanboy, why do you ask?

INSERT  Entertainment.GameInstance(GamePlatformId, GameId, PurchaseDate)
VALUES (1,1,'20140804'),
       (1,2,'20140810'),
       (2,2,'20150604');

--the full outer joins ensure that all rows are returned from all sets, leaving
--nulls where data is missing
SELECT  GamePlatform.Name as Platform, Game.Name as Game, GameInstance. PurchaseDate
FROM    Entertainment.Game as Game
            FULL OUTER JOIN Entertainment.GameInstance as GameInstance
                    ON Game.GameId = GameInstance.GameId
            FULL OUTER JOIN Entertainment.GamePlatform
                    ON GamePlatform.GamePlatformId = GameInstance.GamePlatformId;
GO

CREATE TRIGGER Entertainment.GameInstance$deleteTrigger
ON Entertainment.GameInstance
AFTER DELETE AS
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
   --        @rowsAffected int = (SELECT COUNT(*) FROM inserted);
             @rowsAffected int = (SELECT COUNT(*) FROM deleted);

   BEGIN TRY
        --[validation section] 

        --[modification section]
                         --delete all Games
        DELETE Game      --where the GameInstance was deleted
        WHERE  GameId IN (SELECT deleted.GameId
                          FROM   deleted     --and there are no GameInstances left
                          WHERE  NOT EXISTS (SELECT  *     
                                              FROM    GameInstance
                                              WHERE   GameInstance.GameId =
                                                               deleted.GameId));
   END TRY
   BEGIN CATCH
              IF @@TRANCOUNT > 0
                  ROLLBACK TRANSACTION;
              THROW; --will halt the batch or be caught by the caller's catch block

   END CATCH;
END;
DELETE  Entertainment.GameInstance
WHERE   GamePlatformId = 1;
GO

SELECT  GamePlatform.Name AS Platform, Game.Name AS Game, GameInstance. PurchaseDate
FROM    Entertainment.Game AS Game
            FULL OUTER JOIN Entertainment.GameInstance as GameInstance
                    ON Game.GameId = GameInstance.GameId
            FULL OUTER JOIN Entertainment.GamePlatform
                    ON GamePlatform.GamePlatformId = GameInstance.GamePlatformId;
GO

-----INSTEAD OF Triggers
---Redirecting Invalid Data to an Exception Table
CREATE SCHEMA Measurements;
GO
CREATE TABLE Measurements.WeatherReading
(
    WeatherReadingId int NOT NULL IDENTITY 
          CONSTRAINT PKWeatherReading PRIMARY KEY,
    ReadingTime   datetime2(3) NOT NULL
          CONSTRAINT AKWeatherReading_Date UNIQUE,
    Temperature     float NOT NULL
          CONSTRAINT CHKWeatherReading_Temperature
                      CHECK(Temperature BETWEEN -80 and 150)
                      --raised from last edition for global warming
);
GO


INSERT  INTO Measurements.WeatherReading (ReadingTime, Temperature)
VALUES ('20160101 0:00',82.00), ('20160101 0:01',89.22),
       ('20160101 0:02',600.32),('20160101 0:03',88.22),
       ('20160101 0:04',99.01);
GO

CREATE TABLE Measurements.WeatherReading_exception
(
    WeatherReadingId  int NOT NULL IDENTITY,
          CONSTRAINT PKWeatherReading_exception PRIMARY KEY
    ReadingTime       datetime2(3) NOT NULL,
    Temperature       float NULL
);
GO


CREATE TRIGGER Measurements.WeatherReading$InsteadOfInsertTrigger
ON Measurements.WeatherReading
INSTEAD OF INSERT AS
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

   BEGIN TRY
          --[validation section]
          --[modification section]

          --<perform action>

           --BAD data
          INSERT Measurements.WeatherReading_exception (ReadingTime, Temperature)
          SELECT ReadingTime, Temperature
          FROM   inserted
          WHERE  NOT(Temperature BETWEEN -80 and 150);

           --GOOD data
          INSERT Measurements.WeatherReading (ReadingTime, Temperature)
          SELECT ReadingTime, Temperature
          FROM   inserted
          WHERE  (Temperature BETWEEN -80 and 150);
   END TRY
   BEGIN CATCH
              IF @@trancount > 0
                  ROLLBACK TRANSACTION;

              THROW; --will halt the batch or be caught by the caller's catch block

     END CATCH
END;
GO


INSERT  INTO Measurements.WeatherReading (ReadingTime, Temperature)
VALUES ('20160101 0:00',82.00), ('20160101 0:01',89.22),
       ('20160101 0:02',600.32),('20160101 0:03',88.22),
       ('20160101 0:04',99.01);

SELECT *
FROM Measurements.WeatherReading;
GO
SELECT *
FROM   Measurements.WeatherReading_exception;
GO

SELECT SCOPE_IDENTITY();
GO

---Forcing No Action to Be Performed on a Table

CREATE SCHEMA System;
GO
CREATE TABLE System.Version
(
    DatabaseVersion varchar(10)
);
INSERT  INTO System.Version (DatabaseVersion)
VALUES ('1.0.12');
GO


CREATE TRIGGER System.Version$InsteadOfInsertUpdateDeleteTrigger
ON System.Version
INSTEAD OF INSERT, UPDATE, DELETE AS
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

   IF @rowsAffected = 0 SET @rowsAffected = (SELECT COUNT(*) FROM deleted);

   --no need to complain if no rows affected
   IF @rowsAffected = 0 RETURN;

   --No error handling necessary, just the message.
   --We just put the kibosh on the action.
   THROW 50000, 'The System.Version table may not be modified in production', 16;
END;
GO


UPDATE System.Version
SET    DatabaseVersion = '1.1.1';
GO
SELECT *
FROM   System.Version;
GO

Returns: 
ALTER TABLE system.version
    DISABLE TRIGGER version$InsteadOfInsertUpdateDeleteTrigger;
 GO
UPDATE System.Version
SET    DatabaseVersion = '1.1.1';
GO

SELECT *
FROM   System.Version;
GO

ALTER TABLE System.Version
    ENABLE TRIGGER Version$InsteadOfInsertUpdateDeleteTrigger;
GO

----Dealing with Trigger and Constraint Errors 
CREATE SCHEMA alt;
GO
CREATE TABLE alt.errorHandlingTest
(
    errorHandlingTestId   int CONSTRAINT PKerrorHandlingTest PRIMARY KEY,
    CONSTRAINT CHKerrorHandlingTest_errorHandlingTestId_greaterThanZero
           CHECK (errorHandlingTestId > 0)
);
GO

CREATE TRIGGER alt.errorHandlingTest$insertTrigger
ON alt.errorHandlingTest
AFTER INSERT
AS
    BEGIN TRY
THROW 50000, 'Test Error',16;
    END TRY
    BEGIN CATCH
         IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
         THROW; 
    END CATCH;
GO


--NO Transaction, Constraint Error
INSERT alt.errorHandlingTest
VALUES (-1);
SELECT 'continues';
GO

INSERT alt.errorHandlingTest
VALUES (1);
SELECT 'continues';
GO

BEGIN TRY
    BEGIN TRANSACTION
    INSERT alt.errorHandlingTest
    VALUES (-1);
    COMMIT;
END TRY
BEGIN CATCH
    SELECT  CASE XACT_STATE()
                WHEN 1 THEN 'Committable'
                WHEN 0 THEN 'No transaction'
                ELSE 'Uncommitable tran' END as XACT_STATE
            ,ERROR_NUMBER() AS ErrorNumber
            ,ERROR_MESSAGE() as ErrorMessage;
    IF @@TRANCOUNT > 0
          ROLLBACK TRANSACTION;
END CATCH;
GO


BEGIN TRANSACTION
   BEGIN TRY
        INSERT alt.errorHandlingTest
        VALUES (1);
        COMMIT TRANSACTION;
   END TRY
BEGIN CATCH
    SELECT  CASE XACT_STATE()
                WHEN 1 THEN 'Committable'
                WHEN 0 THEN 'No transaction'
                ELSE 'Uncommitable tran' END as XACT_STATE
            ,ERROR_NUMBER() AS ErrorNumber
            ,ERROR_MESSAGE() as ErrorMessage;
    IF @@TRANCOUNT > 0
          ROLLBACK TRANSACTION;
END CATCH;
GO

ALTER TRIGGER alt.errorHandlingTest$insertTrigger 
ON alt.errorHandlingTest
AFTER INSERT
AS
    BEGIN TRY
          THROW 50000, 'Test Error',16;
    END TRY
    BEGIN CATCH
         --Commented out for test purposes
         --IF @@TRANCOUNT > 0
         --    ROLLBACK TRANSACTION;

         THROW;
    END CATCH;
BEGIN TRY
    BEGIN TRANSACTION
    INSERT alt.errorHandlingTest
    VALUES (1);
    COMMIT TRANSACTION;
END TRY
GO


BEGIN CATCH
    SELECT  CASE XACT_STATE()
                WHEN 1 THEN 'Committable'
                WHEN 0 THEN 'No transaction'
                ELSE 'Uncommitable tran' END as XACT_STATE
            ,ERROR_NUMBER() AS ErrorNumber
            ,ERROR_MESSAGE() as ErrorMessage;
     IF @@TRANCOUNT > 0
          ROLLBACK TRANSACTION;
END CATCH;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @errorMessage nvarchar(4000) = 'Error inserting data into alt.errorHandlingTest';
    INSERT alt.errorHandlingTest
    VALUES (-1);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    --I also add in the stored procedure or trigger where the error
    --occurred also when in a coded object
    SET @errorMessage = CONCAT( COALESCE(@errorMessage,''), ' ( System Error: ', 
                                ERROR_NUMBER(),':',ERROR_MESSAGE(),
                                ' : Line Number:',ERROR_LINE());
        THROW 50000,@errorMessage,16;
END CATCH;
GO
