Use ConferenceMessaging
GO
/*
ALTER DATABASE [ConferenceMessaging] ADD FILEGROUP [ConferenceMessaging_MemoryOptimized] CONTAINS MEMORY_OPTIMIZED_DATA 
GO
ALTER DATABASE [ConferenceMessaging] ADD FILE ( NAME = N'ConferenceMessaging_MemoryOptimized', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ConferenceMessaging_MemoryOptimized' ) TO FILEGROUP [ConferenceMessaging_MemoryOptimized]
GO
*/

DROP TABLE IF EXISTS Attendees_InMem.UserConnection, Messages_InMem.MessageTopic,Messages_InMem.Topic,Messages_InMem.Message, Attendees_InMem.MessagingUser,Attendees_InMem.AttendeeType;
DROP SEQUENCE IF EXISTS Messages_InMem.TopicIdGenerator;
DROP TYPE IF EXISTS Base_InMem.Surrogate
GO

DROP SCHEMA IF EXISTS Attendees_InMem;
DROP SCHEMA IF EXISTS Messages_InMem;
DROP SCHEMA IF EXISTS Base_InMem;
GO

CREATE SCHEMA Messages_InMem; --tables pertaining to the messages being sent
GO
CREATE SCHEMA Attendees_InMem; --tables pertaining to the attendees and how they can send messages
GO
ALTER AUTHORIZATION ON SCHEMA::Messages To DBO;
GO
ALTER AUTHORIZATION ON SCHEMA::Attendees To DBO;
GO

--CREATE SEQUENCE Messages_InMem.TopicIdGenerator
--AS INT    
--MINVALUE 10000 --starting value
--NO MAXVALUE --technically will max out at max int
--START WITH 10000 --value where the sequence will start, differs from min based on 
--             --cycle property
--INCREMENT BY 1 --number that is added the previous value
--NO CYCLE --if setting is cycle, when it reaches max value it starts over
--CACHE 100; --Use adjust number of values that SQL Server caches. Cached values would
--          --be lost if the server is restarted, but keeping them in RAM makes access faster;

--GO
CREATE TABLE Attendees_InMem.AttendeeType ( 
        AttendeeType         varchar(20)  NOT NULL ,
        Description          varchar(60)  NOT NULL ,
		CONSTRAINT PKAttendeeType 
			PRIMARY KEY NONCLUSTERED HASH (AttendeeType) WITH (BUCKET_COUNT=10)
)WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

--As this is a non-editable table, we load the data here to
--start with
INSERT INTO Attendees_InMem.AttendeeType
VALUES ('Regular', 'Typical conference attendee'),
           ('Speaker', 'Person scheduled to speak'),
           ('Administrator','Manages System');

CREATE TABLE Attendees_InMem.MessagingUser ( 
        MessagingUserId      int IDENTITY ( 1,1 ) ,
        UserHandle           varchar(20)  NOT NULL ,
        AccessKeyValue       char(10)  NOT NULL ,
        AttendeeNumber       char(8)  NOT NULL ,
        FirstName            nvarchar(50)  NULL ,
        LastName             nvarchar(50)  NULL ,
        AttendeeType         varchar(20)  NOT NULL ,
        DisabledFlag         bit  NOT NULL ,
        RowCreateTime        datetime2(0)  NOT NULL ,
        RowLastUpdateTime    datetime2(0)  NOT NULL ,
		CONSTRAINT PKMessagingUser PRIMARY KEY NONCLUSTERED HASH (MessagingUserId) WITH (BUCKET_COUNT=10000)
)WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

CREATE TABLE Attendees_InMem.UserConnection
( 
        UserConnectionId     int NOT NULL IDENTITY ( 1,1 ) ,
        ConnectedToMessagingUserId int  NOT NULL ,
        MessagingUserId      int  NOT NULL ,
        RowCreateTime        datetime2(0)  NOT NULL ,
        RowLastUpdateTime    datetime2(0)  NOT NULL ,
		CONSTRAINT PKUserConnection PRIMARY KEY NONCLUSTERED HASH (UserConnectionId) WITH (BUCKET_COUNT=10000)
)WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

CREATE TABLE Messages_InMem.Message ( 
        MessageId            int NOT NULL IDENTITY ( 1,1 ) ,
        
		RoundedMessageTime datetime2(0) NOT NULL, 

		--can't have computed columns in 2016
        --RoundedMessageTime as (dateadd(hour,datepart(hour,MessageTime),
        --                               CAST(CAST(MessageTime as date)as datetime2(0)) ))
        --                               PERSISTED,
        SentToMessagingUserId int  NULL ,
        MessagingUserId      int  NOT NULL ,
        Text                 nvarchar(200)  NOT NULL ,
        MessageTime          datetime2(0)  NOT NULL ,
        RowCreateTime        datetime2(0)  NOT NULL ,
        RowLastUpdateTime    datetime2(0)  NOT NULL ,
		CONSTRAINT PKMessage PRIMARY KEY NONCLUSTERED HASH (MessageId) WITH (BUCKET_COUNT=10000)
)WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

CREATE TABLE Messages_InMem.MessageTopic ( 
        MessageTopicId       int NOT NULL IDENTITY ( 1,1 ) ,
        MessageId            int  NOT NULL ,
        UserDefinedTopicName nvarchar(30)  NULL ,
        TopicId              int  NOT NULL ,
        RowCreateTime        datetime2(0)  NOT NULL ,
        RowLastUpdateTime    datetime2(0)  NOT NULL,
		CONSTRAINT PKMessageTopic PRIMARY KEY NONCLUSTERED HASH (MessageTopicId) WITH (BUCKET_COUNT=10000) 
)WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);

CREATE TABLE Messages_InMem.Topic ( 
        --TopicId int NOT NULL CONSTRAINT DFLTTopic_TopicId 
        --                        DEFAULT(NEXT VALUE FOR  Messages_InMem.TopicIdGenerator),
		TopicId int NOT NULL IDENTITY(1,1),
        Name                 nvarchar(30)  NOT NULL ,
        Description          varchar(60)  NOT NULL ,
        RowCreateTime        datetime2(0)  NOT NULL ,
        RowLastUpdateTime    datetime2(0)  NOT NULL ,
		CONSTRAINT PKTopic PRIMARY KEY NONCLUSTERED HASH (TopicId) WITH (BUCKET_COUNT=10000)
)WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

--PRIMARY KEY's placed inline with table, as each table needs a primary key

--ALTER TABLE Attendees_InMem.AttendeeType
--     ADD CONSTRAINT PKAttendeeType PRIMARY KEY CLUSTERED (AttendeeType);

--ALTER TABLE Attendees_InMem.MessagingUser
--     ADD CONSTRAINT PKMessagingUser PRIMARY KEY CLUSTERED (MessagingUserId);

--ALTER TABLE Attendees_InMem.UserConnection
--     ADD CONSTRAINT PKUserConnection PRIMARY KEY CLUSTERED (UserConnectionId);
     
--ALTER TABLE Messages_InMem.Message
--     ADD CONSTRAINT PKMessage PRIMARY KEY CLUSTERED (MessageId);

--ALTER TABLE Messages_InMem.MessageTopic
--     ADD CONSTRAINT PKMessageTopic PRIMARY KEY CLUSTERED (MessageTopicId);

--ALTER TABLE Messages_InMem.Topic
--     ADD CONSTRAINT PKTopic PRIMARY KEY CLUSTERED (TopicId);
GO


ALTER TABLE Messages_InMem.Message
     ADD CONSTRAINT AKMessage_TimeUserAndText UNIQUE
      (RoundedMessageTime, MessagingUserId, Text);

ALTER TABLE Messages_InMem.Topic
     ADD CONSTRAINT AKTopic_Name UNIQUE (Name);

ALTER TABLE Messages_InMem.MessageTopic
     ADD CONSTRAINT AKMessageTopic_TopicAndMessage UNIQUE
      (MessageId, TopicId, UserDefinedTopicName);

ALTER TABLE Attendees_InMem.MessagingUser
     ADD CONSTRAINT AKMessagingUser_UserHandle UNIQUE HASH (UserHandle) WITH (BUCKET_COUNT=10000);

ALTER TABLE Attendees_InMem.MessagingUser
     ADD CONSTRAINT AKMessagingUser_AttendeeNumber UNIQUE HASH 
     (AttendeeNumber) WITH (BUCKET_COUNT=10000);
     
ALTER TABLE Attendees_InMem.UserConnection
     ADD CONSTRAINT AKUserConnection_Users UNIQUE HASH
     (MessagingUserId, ConnectedToMessagingUserId) WITH (BUCKET_COUNT=10000);
GO
SELECT CONCAT(OBJECT_SCHEMA_NAME(object_id),'.',
              OBJECT_NAME(object_id)) as object_name,
              name,is_primary_key, is_unique_constraint
FROM   sys.indexes
WHERE  OBJECT_SCHEMA_NAME(object_id) <> 'sys'
  AND  is_primary_key = 1 or is_unique_constraint = 1
ORDER BY object_name, is_primary_key DESC, name
GO

ALTER TABLE Attendees_InMem.MessagingUser
   ADD CONSTRAINT DFLTMessagingUser_DisabledFlag
   DEFAULT (0) FOR DisabledFlag;
GO

SELECT CONCAT('ALTER TABLE ',TABLE_SCHEMA,'.',TABLE_NAME,CHAR(13),CHAR(10),
               '    ADD CONSTRAINT DFLT', TABLE_NAME, '_' ,
               COLUMN_NAME, CHAR(13), CHAR(10),
       '    DEFAULT (SYSDATETIME()) FOR ', COLUMN_NAME,';')
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  COLUMN_NAME in ('RowCreateTime', 'RowLastUpdateTime')
  and  TABLE_SCHEMA in ('Messages_InMem','Attendees_InMem')
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;


GO
ALTER TABLE Attendees_InMem.MessagingUser
    ADD CONSTRAINT DFLTMessagingUser_RowCreateTime
    DEFAULT (SYSDATETIME()) FOR RowCreateTime;
ALTER TABLE Attendees_InMem.MessagingUser
    ADD CONSTRAINT DFLTMessagingUser_RowLastUpdateTime
    DEFAULT (SYSDATETIME()) FOR RowLastUpdateTime;
ALTER TABLE Attendees_InMem.UserConnection
    ADD CONSTRAINT DFLTUserConnection_RowCreateTime
    DEFAULT (SYSDATETIME()) FOR RowCreateTime;
ALTER TABLE Attendees_InMem.UserConnection
    ADD CONSTRAINT DFLTUserConnection_RowLastUpdateTime
    DEFAULT (SYSDATETIME()) FOR RowLastUpdateTime;
ALTER TABLE Messages_InMem.Message
    ADD CONSTRAINT DFLTMessage_RowCreateTime
    DEFAULT (SYSDATETIME()) FOR RowCreateTime;
ALTER TABLE Messages_InMem.Message
    ADD CONSTRAINT DFLTMessage_RowLastUpdateTime
    DEFAULT (SYSDATETIME()) FOR RowLastUpdateTime;
ALTER TABLE Messages_InMem.MessageTopic
    ADD CONSTRAINT DFLTMessageTopic_RowCreateTime
    DEFAULT (SYSDATETIME()) FOR RowCreateTime;
ALTER TABLE Messages_InMem.MessageTopic
    ADD CONSTRAINT DFLTMessageTopic_RowLastUpdateTime
    DEFAULT (SYSDATETIME()) FOR RowLastUpdateTime;
ALTER TABLE Messages_InMem.Topic
    ADD CONSTRAINT DFLTTopic_RowCreateTime
    DEFAULT (SYSDATETIME()) FOR RowCreateTime;
ALTER TABLE Messages_InMem.Topic
    ADD CONSTRAINT DFLTTopic_RowLastUpdateTime
    DEFAULT (SYSDATETIME()) FOR RowLastUpdateTime;
GO

ALTER TABLE Attendees_InMem.MessagingUser
       ADD CONSTRAINT FKMessagingUser$IsSent$Messages_Message
            FOREIGN KEY (AttendeeType) REFERENCES Attendees_InMem.AttendeeType(AttendeeType)
            --ON UPDATE CASCADE
            ON DELETE NO ACTION;
GO

--no cascade anyhow, so this example doesn't make sense anymore.
--ALTER TABLE Attendees_InMem.UserConnection
--        ADD CONSTRAINT 
--          FKMessagingUser$ConnectsToUserVia$Attendees_UserConnection 
--        FOREIGN KEY (MessagingUserId) REFERENCES Attendees_InMem.MessagingUser(MessagingUserId)
--        ON UPDATE NO ACTION
--        ON DELETE CASCADE;

--ALTER TABLE Attendees_InMem.UserConnection
--        ADD CONSTRAINT 
--          FKMessagingUser$IsConnectedToUserVia$Attendees_UserConnection 
--        FOREIGN KEY  (ConnectedToMessagingUserId) 
--                              REFERENCES Attendees_InMem.MessagingUser(MessagingUserId)
--        ON UPDATE NO ACTION
--        ON DELETE CASCADE;
--GO
--PRINT 'you should have received an error from the second ALTER TABLE'
--GO

--ALTER TABLE Attendees_InMem.UserConnection
--        DROP CONSTRAINT 
--          FKMessagingUser$ConnectsToUserVia$Attendees_UserConnection;
--GO

ALTER TABLE Attendees_InMem.UserConnection
        ADD CONSTRAINT 
          FKMessagingUser$ConnectsToUserVia$Attendees_UserConnection 
        FOREIGN KEY (MessagingUserId) REFERENCES Attendees_InMem.MessagingUser(MessagingUserId)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION;

ALTER TABLE Attendees_InMem.UserConnection
        ADD CONSTRAINT 
          FKMessagingUser$IsConnectedToUserVia$Attendees_UserConnection 
        FOREIGN KEY  (ConnectedToMessagingUserId) 
                              REFERENCES Attendees_InMem.MessagingUser(MessagingUserId)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION;
GO


ALTER TABLE Messages_InMem.MessageTopic
        ADD CONSTRAINT 
           FKTopic$CategorizesMessagesVia$Messages_MessageTopic FOREIGN KEY 
             (TopicId) REFERENCES Messages_InMem.Topic(TopicId)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION;
GO
ALTER TABLE Messages_InMem.MessageTopic
        ADD CONSTRAINT FKMessage$isCategorizedVia$MessageTopic FOREIGN KEY 
            (MessageId) REFERENCES Messages_InMem.Message(MessageId)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION;
GO

ALTER TABLE Messages_InMem.Topic
   ADD CONSTRAINT CHKTopic_Name_NotEmpty
       CHECK (LEN(RTRIM(Name)) > 0);

ALTER TABLE Messages_InMem.MessageTopic
   ADD CONSTRAINT CHKMessageTopic_UserDefinedTopicName_NotEmpty
       CHECK (LEN(RTRIM(UserDefinedTopicName)) > 0);
GO

--use trigger instead? May not be possible.
--ALTER TABLE Attendees_InMem.MessagingUser 
--  ADD CONSTRAINT CHKMessagingUser_UserHandle_LengthAndStart
--     CHECK (LEN(Rtrim(UserHandle)) >= 5 
--             AND LTRIM(UserHandle) LIKE '[a-z]' +
--                            REPLICATE('[a-z1-9]',LEN(RTRIM(UserHandle)) -1));
--GO
--Msg 10794, Level 16, State 95, Line 282
--The function 'replicate' is not supported with memory optimized tables.
--Msg 10794, Level 16, State 95, Line 282
--The function 'like' is not supported with memory optimized tables.

ALTER TABLE Attendees_InMem.MessagingUser 
  ADD CONSTRAINT CHKMessagingUser_UserHandle_Length
		CHECK (LEN(Rtrim(UserHandle)) >= 5 )
GO

--identity insert instead of sequence, for the user defined topic
set identity_insert Messages_InMem.Topic ON
INSERT INTO Messages_InMem.Topic(TopicId, Name, Description)
VALUES (0,'User Defined','User Enters Their Own User Defined Topic');
set identity_insert Messages_InMem.Topic OFF
GO

ALTER TABLE Messages_InMem.MessageTopic
  ADD CONSTRAINT CHKMessageTopic_UserDefinedTopicName_NullUnlessUserDefined
   CHECK ((UserDefinedTopicName is NULL and TopicId <> 0)
              or (TopicId = 0 and UserDefinedTopicName is NOT NULL));
GO

------------------------
--Triggers
------------------------
-- SQL Server Syntax
-- Trigger on an INSERT, UPDATE, or DELETE statement to a 
-- table (DML Trigger on memory-optimized tables)
GO
CREATE SCHEMA Base_InMem;
GO
CREATE TYPE Base_InMem.Surrogate AS TABLE(
  SurrogateId int,

  INDEX TT_SurrogateId HASH (SurrogateId) WITH ( BUCKET_COUNT = 32)
)
WITH ( MEMORY_OPTIMIZED = ON );
GO

--Triggers need to be updated to use row at a time processing
CREATE TRIGGER Messages_InMem.MessageTopic$AfterInsertTrigger
ON Messages_InMem.MessageTopic
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER INSERT AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]
          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT MessageTopicId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Messages_InMem.MessageTopic 
		        SET    RowCreateTime = DEFAULT,
				       RowLastUpdateTime = DEFAULT
				WHERE  MessageTopicId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO

--Triggers need to be updated to use row at a time processing
CREATE TRIGGER Messages_InMem.MessageTopic$AfterUpdateTrigger
ON Messages_InMem.MessageTopic
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER UPDATE AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]
          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate,
				  @PreviousRowCreateTime datetime2(0);

		  INSERT INTO @SurrogateKey
		  SELECT MessageTopicId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				SELECT @PreviousRowCreateTime = RowCreateTime
				FROM   deleted
				WHERE  MessageTopicId = @SurrogateId

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Messages_InMem.MessageTopic 
		        SET    RowCreateTime = @PreviousRowCreateTime, --Make sure no change will be saved.
				       RowLastUpdateTime = DEFAULT
				WHERE  MessageTopicId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO




--Triggers need to be updated to use row at a time processing
CREATE TRIGGER Message$AfterInsertTrigger
ON Messages_InMem.Message
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER INSERT AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]
          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT MessageId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Messages_InMem.Message 
		        SET    RowCreateTime = DEFAULT,
				       RowLastUpdateTime = DEFAULT,
					   RoundedMessageTime = CAST((DATEADD(HOUR,DATEPART(HOUR,MessageTime),
                                       CAST(CAST(MessageTime AS date) as datetime2(0)) )) AS datetime2(0))
				WHERE  MessageId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO

--Triggers need to be updated to use row at a time processing
CREATE TRIGGER Message$AfterUpdateTrigger
ON Messages_InMem.Message
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER UPDATE AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]
          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT MessageId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Messages_InMem.Message 
		        SET    RowCreateTime = RowCreateTime,
				       RowLastUpdateTime = DEFAULT,
					   RoundedMessageTime = CAST((DATEADD(HOUR,DATEPART(HOUR,MessageTime),
                                       CAST(CAST(MessageTime as date) AS datetime2(0)) )) AS datetime2(0))
				WHERE  MessageId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO



--Triggers need to be updated to use row at a time processing
CREATE TRIGGER MessagingUser$AfterInsertTrigger
ON Attendees_InMem.MessagingUser
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER INSERT AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]

		  --todo:
		 	--ALTER TABLE Attendees_InMem.MessagingUser 
			--  ADD CONSTRAINT CHKMessagingUser_UserHandle_LengthAndStart
			--     CHECK  LTRIM(UserHandle) LIKE '[a-z]' +
			--                            REPLICATE('[a-z1-9]',LEN(RTRIM(UserHandle)) -1));


          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT MessagingUserId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Attendees_InMem.MessagingUser 
		        SET    RowCreateTime = DEFAULT,
				       RowLastUpdateTime = DEFAULT
				WHERE  MessagingUserId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO

--Triggers need to be updated to use row at a time processing
CREATE TRIGGER MessagingUser$AfterUpdateTrigger
ON Attendees_InMem.MessagingUser
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER UPDATE AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]

		  --todo:
		 	--ALTER TABLE Attendees_InMem.MessagingUser 
			--  ADD CONSTRAINT CHKMessagingUser_UserHandle_LengthAndStart
			--     CHECK  LTRIM(UserHandle) LIKE '[a-z]' +
			--                            REPLICATE('[a-z1-9]',LEN(RTRIM(UserHandle)) -1));


          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT MessagingUserId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Attendees_InMem.MessagingUser 
		        SET    RowCreateTime = RowCreateTime,
				       RowLastUpdateTime = DEFAULT
				WHERE  MessagingUserId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO




--Triggers need to be updated to use row at a time processing
CREATE TRIGGER UserConnection$AfterInsertTrigger
ON Attendees_InMem.UserConnection
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER INSERT AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]

          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT UserConnectionId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Attendees_InMem.UserConnection 
		        SET    RowCreateTime = DEFAULT,
				       RowLastUpdateTime = DEFAULT
				WHERE  UserConnectionId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO


--Triggers need to be updated to use row at a time processing
CREATE TRIGGER UserConnection$AfterUpdateTrigger
ON Attendees_InMem.UserConnection
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER UPDATE AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]

          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT UserConnectionId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Attendees_InMem.UserConnection 
		        SET    RowCreateTime = RowCreateTime,
				       RowLastUpdateTime = DEFAULT
				WHERE  UserConnectionId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO

  --Triggers need to be updated to use row at a time processing
CREATE TRIGGER Topic$AfterInsertTrigger
ON Messages_InMem.Topic
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER INSERT AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]

          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT TopicId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Messages_InMem.Topic 
		        SET    RowCreateTime = DEFAULT,
				       RowLastUpdateTime = DEFAULT
				WHERE  TopicId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH;
END;
GO

 --Triggers need to be updated to use row at a time processing
CREATE TRIGGER Topic$AfterUpdateTrigger
ON Messages_InMem.Topic
WITH NATIVE_COMPILATION, SCHEMABINDING
AFTER UPDATE AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')

   DECLARE @msg varchar(2000),    --used to hold the error message
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger
           @rowsAffected int = (select count(*) from inserted)
   --@rowsAffected = (select count(*) from deleted)

   --no need to continue on if no rows affected
   IF @rowsAffected = 0 RETURN;

   BEGIN TRY
		  
		  --[validation section]

          --[modification section]

		  --update the RowTimes
		  DECLARE @SurrogateId int,
		          @ContinueLoop bit = 1,
                  @SurrogateKey Base_InMem.Surrogate;

		  INSERT INTO @SurrogateKey
		  SELECT TopicId
		  FROM   INSERTED;

          WHILE (@ContinueLoop=1) -- There will always be a row if you reach here
		    BEGIN
			    SELECT TOP(1) @SurrogateId = SurrogateId
				FROM   @SurrogateKey;

				IF @@RowCount = 0 SET @ContinueLoop = 0;

				DELETE FROM @SurrogateKey 
				WHERE SurrogateId = @SurrogateId;

				UPDATE Messages_InMem.Topic 
		        SET    RowCreateTime = RowCreateTime,
				       RowLastUpdateTime = DEFAULT
				WHERE  TopicId = @SurrogateId;
			END

   END TRY
   BEGIN CATCH
      THROW; --will halt the batch or be caught by the caller's catch block
  END CATCH
END
GO



----------------------------------
-- Extended Properties
----------------------------------

--Messages schema 
EXEC sp_addextendedproperty @name = 'Description',
   @value = 'Messaging objects for In-Memory Version',
   @level0type = 'Schema', @level0name = 'Messages_InMem';

----Messages_InMem.Topic table
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = ' Pre-defined topics for messages',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Topic';

----Messages_InMem.Topic.TopicId 
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Surrogate key representing a Topic',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Topic',
--   @level2type = 'Column', @level2name = 'TopicId';

----Messages_InMem.Topic.Name
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'The name of the topic',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Topic',
--   @level2type = 'Column', @level2name = 'Name';

----Messages_InMem.Topic.Description
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Description of the purpose and utilization of the topics',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Topic',
--   @level2type = 'Column', @level2name = 'Description';

----Messages_InMem.Topic.RowCreateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was created',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Topic',
--   @level2type = 'Column', @level2name = 'RowCreateTime';

----Messages_InMem.Topic.RowLastUpdateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was last updated',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Topic',
--   @level2type = 'Column', @level2name = 'RowLastUpdateTime';

--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'User Id of the user that is being sent a message',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Message',
--   @level2type = 'Column', @level2name = 'SentToMessagingUserId';
   
----Messages_InMem.Message.MessagingUserId
--EXEC sp_addextendedproperty @name = 'Description',
--   @value ='User Id of the user that sent the message',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Message',
--   @level2type = 'Column', @level2name =  'MessagingUserId';

----Messages_InMem.Message.Text 
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Text of the message being sent',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Message',
--   @level2type = 'Column', @level2name = 'Text';

----Messages_InMem.Message.MessageTime 
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'The time the message is sent, at a grain of one second',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Message',
--   @level2type = 'Column', @level2name = 'MessageTime';
 
-- --Messages_InMem.Message.RowCreateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was created',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Message',
--   @level2type = 'Column', @level2name = 'RowCreateTime';

----Messages_InMem.Message.RowLastUpdateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was last updated',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'Message',
--   @level2type = 'Column', @level2name = 'RowLastUpdateTime';
   

----Messages_InMem.Message table
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Relates a message to a topic',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'MessageTopic';

----Messages_InMem.Message.MessageTopicId 
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Surrogate key representing a MessageTopic',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'MessageTopic',
--   @level2type = 'Column', @level2name = 'MessageTopicId';
   
--   --Messages_InMem.Message.MessageId 
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Surrogate key representing the message that is being associated with a topic',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'MessageTopic',
--   @level2type = 'Column', @level2name = 'MessageId';

----Messages_InMem.MessageUserDefinedTopicName 
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Allows the user to choose the “UserDefined” topic style and set their own topic ',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'MessageTopic',
--   @level2type = 'Column', @level2name = 'UserDefinedTopicName';

--   --Messages_InMem.Message.TopicId
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Surrogate key representing the topic that is being associated with a message',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'MessageTopic',
--   @level2type = 'Column', @level2name = 'TopicId';

-- --Messages_InMem.MessageTopic.RowCreateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was created',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'MessageTopic',
--   @level2type = 'Column', @level2name = 'RowCreateTime';

----Messages_InMem.MessageTopic.RowLastUpdateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was last updated',
--   @level0type = 'Schema', @level0name = 'Messages_InMem',
--   @level1type = 'Table', @level1name = 'MessageTopic',
--   @level2type = 'Column', @level2name = 'RowLastUpdateTime';
--GO

--Attendees schema 
EXEC sp_addextendedproperty @name = 'Description',
   @value = 'Attendee objects',
   @level0type = 'Schema', @level0name = 'Attendees_InMem';

----Attendees_InMem.AttendeeType table
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Domain of the different types of attendees that are supported',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'AttendeeType';

----Attendees_InMem.AttendeeType.AttendeeType
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Code representing a type of Attendee',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'AttendeeType',
--   @level2type = 'Column', @level2name = 'AttendeeType';

----Attendees_InMem.AttendeeType.AttendeeType
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Brief description explaining the Attendee Type',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'AttendeeType',
--   @level2type = 'Column', @level2name = 'Description';


----Attendees_InMem.MessagingUser table
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Represent a user of the messaging system, preloaded from another system with attendee information',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser';

----Attendees_InMem.MessagingUser.MessagingUserId
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Surrogate key representing a messaginguser',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'MessagingUserId';

----Attendees_InMem.MessagingUser.UserHandle
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'The name the user wants to be known as. Initially pre-loaded with a value based on the persons first and last name, plus a integer value, changeable by the user',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'UserHandle';

----Attendees_InMem.MessagingUser.AccessKeyValue
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'A password-like value given to the user on their badge to gain access',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'AccessKeyValue';

----Attendees_InMem.MessagingUser.AttendeeNumber
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'The number that the attendee is given to identify themselves, printed on front of badge',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'AttendeeNumber';

----Attendees_InMem.MessagingUser.FirstName
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Name of the user printed on badge for people to see',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'FirstName';

----Attendees_InMem.MessagingUser.LastName
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Name of the user printed on badge for people to see',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'LastName';

----Attendees_InMem.MessagingUser.AttendeeType
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Used to give the user special priviledges, such as access to speaker materials, vendor areas, etc.',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'AttendeeType';

----Attendees_InMem.MessagingUser.DisabledFlag
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Indicates whether or not the user'' account has been disabled',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'DisabledFlag';

----Attendees_InMem.MessagingUser.RowCreateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was created',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'RowCreateTime';

----Attendees_InMem.MessagingUser.RowLastUpdateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was last updated',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'MessagingUser',
--   @level2type = 'Column', @level2name = 'RowLastUpdateTime';
--GO

----Attendees_InMem.UserConnection table
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Represents the connection of one user to another in order to filter results to a given set of users.',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'UserConnection';

----Attendees_InMem.MessagingUser.UserConnectionId
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Surrogate key representing a messaginguser',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'UserConnection',
--   @level2type = 'Column', @level2name = 'UserConnectionId';

----Attendees_InMem.MessagingUser.UserConnectionId
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'MessagingUserId of user that is going to connect themselves to another users ',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'UserConnection',
--   @level2type = 'Column', @level2name = 'MessagingUserId';

----Attendees_InMem.MessagingUser.UserConnectionId
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'MessagingUserId of user that is being connected to',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'UserConnection',
--   @level2type = 'Column', @level2name = 'ConnectedToMessagingUserId';

----Attendees_InMem.MessagingUser.RowCreateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was created',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'UserConnection',
--   @level2type = 'Column', @level2name = 'RowCreateTime';

----Attendees_InMem.MessagingUser.RowLastUpdateTime
--EXEC sp_addextendedproperty @name = 'Description',
--   @value = 'Time when the row was last updated',
--   @level0type = 'Schema', @level0name = 'Attendees_InMem',
--   @level1type = 'Table', @level1name = 'UserConnection',
--   @level2type = 'Column', @level2name = 'RowLastUpdateTime';
--GO
SELECT SCHEMA_NAME(major_id), Value
FROM   sys.extended_properties
WHERE  class_desc = 'SCHEMA'
  AND  SCHEMA_NAME(major_id) in ('Messages_InMem','Attendees_InMem')
GO	
SELECT SCHEMA_NAME, SCHEMA_OWNER
FROM   INFORMATION_SCHEMA.SCHEMATA
WHERE  SCHEMA_NAME <> SCHEMA_OWNER
GO

SELECT table_schema + '.' + TABLE_NAME as TABLE_NAME, COLUMN_NAME, 
             --types that have a character or binary lenght
        case when DATA_TYPE IN ('varchar','char','nvarchar','nchar','varbinary')
                      then DATA_TYPE + case when character_maximum_length = -1 then '(max)'
                                            else '(' + CAST(character_maximum_length as 
                                                                    varchar(4)) + ')' end
                 --types with a datetime precision
                 when DATA_TYPE IN ('time','datetime2','datetimeoffset')
                      then DATA_TYPE + '(' + CAST(DATETIME_PRECISION as varchar(4)) + ')'
                --types with a precision/scale
                 when DATA_TYPE IN ('numeric','decimal')
                      then DATA_TYPE + '(' + CAST(NUMERIC_PRECISION as varchar(4)) + ',' + 
                                            CAST(NUMERIC_SCALE as varchar(4)) +  ')'
                 --timestamp should be reported as rowversion
                 when DATA_TYPE = 'timestamp' then 'rowversion'
                 --and the rest. Note, float is declared with a bit length, but is
                 --represented as either float or real in types 
                 else DATA_TYPE end as DECLARED_DATA_TYPE,
        COLUMN_DEFAULT
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_SCHEMA in ('Attendees_InMem','Messages_InMem')
ORDER BY TABLE_SCHEMA, TABLE_NAME,ORDINAL_POSITION;
GO
SELECT TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE  CONSTRAINT_SCHEMA in ('Attendees_InMem','Messages_InMem')
ORDER  BY  CONSTRAINT_SCHEMA, TABLE_NAME;
GO
SELECT OBJECT_SCHEMA_NAME(parent_id) + '.' + OBJECT_NAME(parent_id) AS TABLE_NAME, 
           name AS TRIGGER_NAME, 
           CASE WHEN is_instead_of_trigger = 1 then 'INSTEAD OF' else 'AFTER' End 
                        as TRIGGER_FIRE_TYPE
FROM   sys.triggers
WHERE  type_desc = 'SQL_TRIGGER' --not a clr trigger
  AND  parent_class = 1 --DML Triggers
  AND OBJECT_SCHEMA_NAME(parent_id) IN ('Attendees_InMem','Messages_InMem')
ORDER BY TABLE_NAME, TRIGGER_NAME;
GO

SELECT  TABLE_SCHEMA + '.' + TABLE_NAME AS TABLE_NAME,
        TABLE_CONSTRAINTS.CONSTRAINT_NAME, CHECK_CLAUSE
FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS
            JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS
               ON TABLE_CONSTRAINTS.CONSTRAINT_SCHEMA = 
                                CHECK_CONSTRAINTS.CONSTRAINT_SCHEMA
                  AND TABLE_CONSTRAINTS.CONSTRAINT_NAME = CHECK_CONSTRAINTS.CONSTRAINT_NAME
WHERE TABLE_SCHEMA IN ('Attendees_InMem','Messages_InMem')
GO

select *
from   sys.tables
where  object_schema_Name(object_id) IN ('Attendees_InMem','Messages_InMem');

select *
from   sys.triggers
where  object_schema_Name(parent_id) IN ('Attendees_InMem','Messages_InMem');