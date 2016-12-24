SET NOCOUNT ON;
USE ConferenceMessaging;
GO
DELETE FROM Messages.MessageTopic ;
DELETE FROM Messages.Message;
DELETE FROM Messages.Topic WHERE TopicId <> 0; --Leave the User Defined Topic
DELETE FROM Attendees.UserConnection;
DELETE FROM Attendees.MessagingUser;

GO

INSERT INTO [Attendees].[MessagingUser]
           ([UserHandle],[AccessKeyValue],[AttendeeNumber]
           ,[FirstName],[LastName],[AttendeeType]
           ,[DisabledFlag])
VALUES ('FredF','0000000000','00000000','Fred','Flintstone','Regular',0)

IF @@ROWCOUNT <> 1 THROW 50000,'Attendees.MessagingUser Single Row  Failed',16
GO

BEGIN TRY --Check UserHandle Check Constraint
	INSERT INTO [Attendees].[MessagingUser]
			   ([UserHandle],[AccessKeyValue],[AttendeeNumber]
			   ,[FirstName],[LastName],[AttendeeType]
			   ,[DisabledFlag])
	VALUES ('Wil','0000000000','00000001','Wilma','Flintstone','Regular',0);
	THROW 50000,'No error raised',16;
END TRY
BEGIN CATCH
	if ERROR_MESSAGE() not like 
                              '%CHKMessagingUser_UserHandle_LengthAndStart%'
		THROW 50000,'Check Messages.Topic.Name didn''t work',16;
END CATCH
GO

BEGIN TRY --Check UserHandle Check Constraint
	INSERT INTO [Attendees].[MessagingUser]
			   ([UserHandle],[AccessKeyValue],[AttendeeNumber]
			   ,[FirstName],[LastName],[AttendeeType]
			   ,[DisabledFlag])
	VALUES ('Wilma@','0000000000','00000001','Wilma','Flintstone','Regular',0);
	THROW 50000,'No error raised',16;
End TRY
BEGIN CATCH
	if ERROR_MESSAGE() not like  
                         '%CHKMessagingUser_UserHandle_LengthAndStart%'
		THROW 50000,'Check Messages.Topic.Name didn''t work',16;
END CATCH
GO



BEGIN TRY --Check UserHandle Check Constraint
	INSERT INTO [Attendees].[MessagingUser]
			   ([UserHandle],[AccessKeyValue],[AttendeeNumber]
			   ,[FirstName],[LastName],[AttendeeType]
			   ,[DisabledFlag])
	VALUES ('Wil','0000000000','00000001','Wilma','Flintstone','Regular',0);
	THROW 50000,'No error raised',16;
End TRY
BEGIN CATCH
	if ERROR_MESSAGE() not like '%CHKMessagingUser_UserHandle_LengthAndStart%'
		THROW 50000,'Check Messages.Topic.Name didn''t work',16
END CATCH
GO
BEGIN TRY --Check UserHandle Check Constraint
	INSERT INTO [Attendees].[MessagingUser]
			   ([UserHandle],[AccessKeyValue],[AttendeeNumber]
			   ,[FirstName],[LastName],[AttendeeType]
			   ,[DisabledFlag])
	VALUES ('Wilma@','0000000000','00000001','Wilma','Flintstone','Regular',0);
	THROW 50000,'No error raised',16;
End TRY
BEGIN CATCH
	if ERROR_MESSAGE() not like '%CHKMessagingUser_UserHandle_LengthAndStart%'
		THROW 50000,'Check Messages.Topic.Name didn''t work',16;
END CATCH
GO

INSERT INTO [Attendees].[MessagingUser]
           ([UserHandle],[AccessKeyValue],[AttendeeNumber]
           ,[FirstName],[LastName],[AttendeeType]
           ,[DisabledFlag])
VALUES ('WilmaF','0000000000','00000001','Wilma','Flintstone','Regular',0),
       ('BarneyR','0000000000','00000002','Barney','Rubble','Regular',0),
	   ('BettyR22','0000000000','00000003','Betty','Rubble','Speaker',0),
	   ('SSlate','000000000','00000004','Sam','Slate','Regular',0),
	   ('JimRocky','000000000','00000005','Jim','Rock','Administrator',0);

if @@ROWCOUNT <> 5 THROW 50000,'Attendees.MessagingUser Multi Row Failed',16;

waitfor delay '00:00:03' --to make sure the update time is different 

UPDATE Attendees.MessagingUser
SET    AttendeeType = case when UserHandle = 'BettyR22' then 'Regular'
						   when UserHandle = 'SSlate' then 'Speaker'
					  end
WHERE UserHandle in ('BettyR22','SSlate')

if @@ROWCOUNT <> 2 THROW 50000,'Attendees.MessagingUser Multi Row Update Failed',16

insert into Attendees.UserConnection (MessagingUserId,ConnectedToMessagingUserId)
select MessagingUser.MessagingUserId, ConnectedTo.MessagingUserId
from   Attendees.MessagingUser
		 cross join Attendees.MessagingUser as ConnectedTo
where  MessagingUser.UserHandle = 'FredF'
 and   ConnectedTo.UserHandle = 'WilmaF';

  if @@ROWCOUNT <> 1 THROW 50000,'Attendees.UserConnection Single Row Update Failed',16;

insert into Attendees.UserConnection (MessagingUserId,ConnectedToMessagingUserId)
select MessagingUser.MessagingUserId, ConnectedTo.MessagingUserId
from   Attendees.MessagingUser
		 cross join Attendees.MessagingUser as ConnectedTo
where  MessagingUser.UserHandle = 'WilmaF'
 and   MessagingUser.MessagingUserId <> ConnectedTo.MessagingUserId;

 if @@ROWCOUNT <> 5 THROW 50000,'Attendees.UserConnection Multi Row Update Failed',16;

 Insert into Messages.Topic(Name, Description)
Values ('General','General Messages')

if @@ROWCOUNT <> 1 THROW 50000,'Messages.Topic Single Row Update  Failed',16

BEGIN TRY --Check Messages.Topic.Name Check Constraint
	Insert into Messages.Topic(Name, Description)
	Values (' ','General Messages');
	THROW 50000,'No error raised',16;
End TRY
BEGIN CATCH
	if ERROR_MESSAGE() not like '%CHKTopic_Name_NotEmpty%'
		THROW 50000,'Check Messages.Topic.Name didn''t work',16
END CATCH
GO


INSERT INTO Messages.Topic(Name, Description)
VALUES ('Misc','Miscelaneous'),
	   ('Special','Special Topic');

if @@ROWCOUNT <> 2 THROW 50000, 'Messages.Topic MultiRow Update Failed',16;

GO


INSERT INTO [Messages].[Message]
           ([MessagingUserId]
		   ,[SentToMessagingUserId]
           ,[Text]
           ,[MessageTime])
     VALUES
        ((select MessagingUserId from Attendees.MessagingUser where UserHandle = 'FredF')
        ,(select MessagingUserId from Attendees.MessagingUser where UserHandle = 'WilmaF')
        ,'It looks like I will be late tonight'
         ,GETDATE());

IF @@ROWCOUNT <> 1 THROW 50000,'Messages.Messages Single Insert Failed',16;
GO

GO

BEGIN TRY --Unique Message Error...
	INSERT INTO [Messages].[Message]
			   ([MessagingUserId]
			   ,[SentToMessagingUserId]
			   ,[Text]
			   ,[MessageTime])
		 VALUES
			   ((SELECT MessagingUserId FROM Attendees.MessagingUser 
                             WHERE UserHandle = 'FredF')
			   ,(SELECT MessagingUserId FROM Attendees.MessagingUser 
                             WHERE UserHandle = 'WilmaF')
			   ,'It looks like I will be late tonight'
			   ,GETDATE());
	THROW 50000,'No error raised',16;
END TRY
BEGIN CATCH
	if ERROR_MESSAGE() NOT LIKE '%AKMessage_TimeUserAndText%'
		 THROW 50000,'Unique Message Error didn''t work (check times)',16;
END CATCH
GO

INSERT INTO [Messages].[Message]
		([MessagingUserId]
		,[SentToMessagingUserId]
		,[Text]
		,[MessageTime])
	VALUES
		((select MessagingUserId from Attendees.MessagingUser where UserHandle = 'WilmaF')
		,(select MessagingUserId from Attendees.MessagingUser where UserHandle = 'FredF')
		,'I will kill you :)'
		,GETDATE()),
		((select MessagingUserId from Attendees.MessagingUser where UserHandle = 'BarneyR')
		,(select MessagingUserId from Attendees.MessagingUser where UserHandle = 'BettyR22')
		,'Fred and Wilma Are Nuts!'
		,GETDATE());

if @@ROWCOUNT <> 2 THROW 50000,'Messages.Messages MultiRow Update Failed',16
GO

declare @messagingUserId int, @text nvarchar(200), 
		@messageTime datetime2, @RoundedMessageTime smalldatetime
select @messagingUserId = (select MessagingUserId from Attendees.MessagingUser where UserHandle = 'FredF'),
       @text = 'Going bowling, don''t tell my wife!', @messageTime = GETDATE()
select @RoundedMessageTime = (dateadd(hour,datepart(hour,@MessageTime),CONVERT(smalldatetime,CONVERT(date,@MessageTime))))

INSERT INTO [Messages].[Message]
           ([MessagingUserId]
		   ,[SentToMessagingUserId]
           ,[Text]
           ,[MessageTime])
     VALUES
           (@messagingUserId,NULL,@text, @messageTime);

if @@ROWCOUNT <> 1 THROW 50000,'Messages.Messages Single Insert Failed',16;

insert into Messages.MessageTopic(MessageId, TopicId)
VALUES(
(SELECT MessageId
 FROM   Messages.Message
 WHERE  MessagingUserId = @messagingUserId
  and   Text = @text
  and  RoundedMessageTime = @RoundedMessageTime), (SELECT TopicId 
	 											   FROM   Messages.Topic 
												   WHERE  Name = 'General'));

if @@ROWCOUNT <> 1 THROW 50000,'Messages.MessageTopic Single Insert Failed',16;
GO

--Do this in a more natural way. Usually the client would pass in these values
DECLARE @messagingUserId int, @text nvarchar(200), 
	@messageTime datetime2, @RoundedMessageTime smalldatetime

SELECT @messagingUserId = (SELECT MessagingUserId FROM Attendees.MessagingUser 
                           WHERE UserHandle = 'FredF'),
       @text = 'Oops Why Did I say That?', @messageTime = GETDATE()

--uses the same algorithm as the check constraint to calculate part of the key
SELECT @RoundedMessageTime = (
DATEADD(HOUR,DATEPART(HOUR,@MessageTime),CONVERT(datetime2(0),CONVERT(date,@MessageTime))))

BEGIN TRY
   BEGIN TRANSACTION
                --first create a new message
		INSERT INTO [Messages].[Message]
					([MessagingUserId],[SentToMessagingUserId]
					,[Text]	,[MessageTime])
		VALUES
			(@messagingUserId,NULL,@text, @messageTime)

		--then insert the topic,but this will fail because General topic is not
                --compatible with a UserDefinedTopicName value
		INSERT INTO Messages.MessageTopic(MessageId, TopicId, UserDefinedTopicName)
		VALUES(
		(SELECT MessageId
		 FROM   Messages.Message
		 WHERE  MessagingUserId = @messagingUserId
		  AND   Text = @text
		  AND   RoundedMessageTime = @RoundedMessageTime),
					(SELECT TopicId
					 FROM Messages.Topic 
					 WHERE Name = 'General'),'Stupid Stuff')

  COMMIT TRANSACTION
END TRY
BEGIN CATCH
	if @@TRANCOUNT <> 0 ROLLBACK;
	if ERROR_MESSAGE() not like '%CHKMessageTopic_UserDefinedTopicName_NullUnlessUserDefined%'
	  BEGIN 
		THROW 50000,'UserDefined Message Check Failed',16;
	  END
END CATCH
GO

declare @messagingUserId int, @text nvarchar(200), 
		@messageTime datetime2, @RoundedMessageTime smalldatetime
select @messagingUserId = (select MessagingUserId from Attendees.MessagingUser where UserHandle = 'FredF'),
       @text = 'Oops Why Did I say That?', @messageTime = GETDATE()
select @RoundedMessageTime = (dateadd(hour,datepart(hour,@MessageTime),CONVERT(smalldatetime,CONVERT(date,@MessageTime))))

INSERT INTO [Messages].[Message]
           ([MessagingUserId]
		   ,[SentToMessagingUserId]
           ,[Text]
           ,[MessageTime])
     VALUES
           (@messagingUserId,NULL,@text, @messageTime)

if @@ROWCOUNT <> 1 THROW 50000,'Messages.Messages Single Insert Failed',16;

INSERT into Messages.MessageTopic(MessageId, TopicId, UserDefinedTopicName)
VALUES(
(SELECT MessageId
 FROM   Messages.Message
 WHERE  MessagingUserId = @messagingUserId
  and   Text = @text
  and  RoundedMessageTime = @RoundedMessageTime), (SELECT TopicId 
	 											   FROM   Messages.Topic 
												   WHERE  Name = 'User Defined'),'Stupid Stuff');

if @@ROWCOUNT <> 1 THROW 50000,'Messages.MessageTopic Single Insert Failed',16;
GO

select *
from   Attendees.AttendeeType

select *
from   Attendees.MessagingUser

select *
from   Attendees.UserConnection

select *
from   Messages.Topic

SELECT *
from   Messages.Message

SELECT *
from   Messages.MessageTopic