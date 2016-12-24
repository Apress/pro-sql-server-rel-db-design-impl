---Desirable Patterns
-----Uniqueness
------Selective Uniqueness

CREATE DATABASE Chapter8;
GO

USE Chapter8;
GO

CREATE SCHEMA HumanResources;
GO
CREATE TABLE HumanResources.Employee
(
    EmployeeId int IDENTITY(1,1) CONSTRAINT PKEmployee primary key,
    EmployeeNumber char(5) NOT NULL
           CONSTRAINT AKEmployee_EmployeeNummer UNIQUE,
    --skipping other columns you would likely have
    InsurancePolicyNumber char(10) NULL
);
GO

--Filtered Alternate Key (AKF)
CREATE UNIQUE INDEX AKFEmployee_InsurancePolicyNumber ON
                                    HumanResources.Employee(InsurancePolicyNumber)
WHERE InsurancePolicyNumber IS NOT NULL;
GO

INSERT INTO HumanResources.Employee (EmployeeNumber, InsurancePolicyNumber)
VALUES ('A0001','1111111111');
GO

INSERT INTO HumanResources.Employee (EmployeeNumber, InsurancePolicyNumber)
VALUES ('A0002','1111111111');
GO

INSERT INTO HumanResources.Employee (EmployeeNumber, InsurancePolicyNumber)
VALUES ('A0002','2222222222');
GO

INSERT INTO HumanResources.Employee (EmployeeNumber, InsurancePolicyNumber)
VALUES ('A0003','3333333333'),
       ('A0004',NULL),
       ('A0005',NULL);
GO

SELECT *
FROM   HumanResources.Employee;
GO


CREATE SCHEMA Account;
GO
CREATE TABLE Account.Contact
(
    ContactId   varchar(10) NOT NULL,
    AccountNumber   char(5) NOT NULL, --would be FK in full example
    PrimaryContactFlag bit NOT NULL,
    CONSTRAINT PKContact PRIMARY KEY(ContactId, AccountNumber)
);
GO

CREATE UNIQUE INDEX AKFContact_PrimaryContact
            ON Account.Contact(AccountNumber) WHERE PrimaryContactFlag = 1;
GO


INSERT INTO Account.Contact
VALUES ('bob','11111',1);
GO

INSERT INTO Account.Contact
VALUES ('fred','11111',1);
GO


BEGIN TRANSACTION;

UPDATE Account.Contact
SET primaryContactFlag = 0
WHERE  accountNumber = '11111';

INSERT Account.Contact
VALUES ('fred','11111', 1);

COMMIT TRANSACTION;
GO


-----Bulk Uniqueness

CREATE SCHEMA Lego;
GO
CREATE TABLE Lego.Build
(
        BuildId int CONSTRAINT PKBuild PRIMARY KEY,
        Name    varchar(30) NOT NULL CONSTRAINT AKBuild_Name UNIQUE,
        LegoCode varchar(5) NULL, --five character set number
        InstructionsURL varchar(255) NULL --where you can get the PDF of the instructions
);
GO

CREATE TABLE Lego.BuildInstance
(
        BuildInstanceId Int CONSTRAINT PKBuildInstance PRIMARY KEY ,
        BuildId Int CONSTRAINT FKBuildInstance$isAVersionOf$LegoBuild 
                        REFERENCES Lego.Build (BuildId),
        BuildInstanceName varchar(30) NOT NULL, --brief description of item 
        Notes varchar(1000)  NULL, --longform notes. These could describe modifications 
                                   --for the instance of the model
        CONSTRAINT AKBuildInstance UNIQUE(BuildId, BuildInstanceName)
);
GO


CREATE TABLE Lego.Piece
(
        PieceId int CONSTRAINT PKPiece PRIMARY KEY,
        Type    varchar(15) NOT NULL,
        Name    varchar(30) NOT NULL,
        Color   varchar(20) NULL,
        Width int NULL,
        Length int NULL,
        Height int NULL,
        LegoInventoryNumber int NULL,
        OwnedCount int NOT NULL,
        CONSTRAINT AKPiece_Definition UNIQUE (Type,Name,Color,Width,Length,Height),
        CONSTRAINT AKPiece_LegoInventoryNumber UNIQUE (LegoInventoryNumber)
);
GO

CREATE TABLE Lego.BuildInstancePiece
(
        BuildInstanceId int NOT NULL,
        PieceId int NOT NULL,
        AssignedCount int NOT NULL,
        CONSTRAINT PKBuildInstancePiece PRIMARY KEY (BuildInstanceId, PieceId)
);
GO


INSERT Lego.Build (BuildId, Name, LegoCode, InstructionsURL)
VALUES  (1,'Small Car','3177',
           'http://cache.lego.com/bigdownloads/buildinginstructions/4584500.pdf');
GO

INSERT Lego.BuildInstance (BuildInstanceId, BuildId, BuildInstanceName, Notes)
VALUES (1,1,'Small Car for Book',NULL);
GO

INSERT Lego.Piece (PieceId, Type, Name, Color, Width, Length, Height, 
                   LegoInventoryNumber, OwnedCount)
VALUES (1, 'Brick','Basic Brick','White',1,3,1,'362201',20),
           (2, 'Slope','Slope','White',1,1,1,'4504369',2),
           (3, 'Tile','Groved Tile','White',1,2,NULL,'306901',10),
           (4, 'Plate','Plate','White',2,2,NULL,'302201',20),
           (5, 'Plate','Plate','White',1,4,NULL,'371001',10),
           (6, 'Plate','Plate','White',2,4,NULL,'302001',1),
           (7, 'Bracket','1x2 Bracket with 2x2','White',2,1,2,'4277926',2),
           (8, 'Mudguard','Vehicle Mudguard','White',2,4,NULL,'4289272',1),
           (9, 'Door','Right Door','White',1,3,1,'4537987',1),
           (10,'Door','Left Door','White',1,3,1,'45376377',1),
           (11,'Panel','Panel','White',1,2,1,'486501',1),
           (12,'Minifig Part','Minifig Torso , Sweatshirt','White',NULL,NULL,
                NULL,'4570026',1),
           (13,'Steering Wheel','Steering Wheel','Blue',1,2,NULL,'9566',1),
           (14,'Minifig Part','Minifig Head, Male Brown Eyes','Yellow',NULL, NULL, 
                NULL,'4570043',1),
           (15,'Slope','Slope','Black',2,1,2,'4515373',2),
           (16,'Mudguard','Vehicle Mudgard','Black',2,4,NULL,'4195378',1),
           (17,'Tire','Vehicle Tire,Smooth','Black',NULL,NULL,NULL,'4508215',4),
           (18,'Vehicle Base','Vehicle Base','Black',4,7,2,'244126',1),
           (19,'Wedge','Wedge (Vehicle Roof)','Black',1,4,4,'4191191',1),
           (20,'Plate','Plate','Lime Green',1,2,NULL,'302328',4),
           (21,'Minifig Part','Minifig Legs','Lime Green',NULL,NULL,NULL,'74040',1),
           (22,'Round Plate','Round Plate','Clear',1,1,NULL,'3005740',2),
           (23,'Plate','Plate','Transparent Red',1,2,NULL,'4201019',1),
           (24,'Briefcase','Briefcase','Reddish Brown',NULL,NULL,NULL,'4211235', 1),
           (25,'Wheel','Wheel','Light Bluish Gray',NULL,NULL,NULL,'4211765',4),
           (26,'Tile','Grilled Tile','Dark Bluish Gray',1,2,NULL,'4210631', 1),
           (27,'Minifig Part','Brown Minifig Hair','Dark Brown',NULL,NULL,NULL,
               '4535553', 1),
           (28,'Windshield','Windshield','Transparent Black',3,4,1,'4496442',1),
           --and a few extra pieces to make the queries more interesting
           (29,'Baseplate','Baseplate','Green',16,24,NULL,'3334',4),
           (30,'Brick','Basic Brick','White',4,6,NULL,'2356',10);
GO

INSERT INTO Lego.BuildInstancePiece (BuildInstanceId, PieceId, AssignedCount)
VALUES (1,1,2),(1,2,2),(1,3,1),(1,4,2),(1,5,1),(1,6,1),(1,7,2),(1,8,1),(1,9,1),
       (1,10,1),(1,11,1),(1,12,1),(1,13,1),(1,14,1),(1,15,2),(1,16,1),(1,17,4),
       (1,18,1),(1,19,1),(1,20,4),(1,21,1),(1,22,2),(1,23,1),(1,24,1),(1,25,4),
       (1,26,1),(1,27,1),(1,28,1);
GO

INSERT Lego.Build (BuildId, Name, LegoCode, InstructionsURL)
VALUES  (2,'Brick Triangle',NULL,NULL);
GO

INSERT Lego.BuildInstance (BuildInstanceId, BuildId, BuildInstanceName, Notes)
VALUES (2,2,'Brick Triangle For Book','Simple build with 3 white bricks');
GO

INSERT INTO Lego.BuildInstancePiece (BuildInstanceId, PieceId, AssignedCount)
VALUES (2,1,3);
GO

INSERT Lego.BuildInstance (BuildInstanceId, BuildId, BuildInstanceName, Notes)
VALUES (3,2,'Brick Triangle For Book2','Simple build with 3 white bricks');
GO

INSERT INTO Lego.BuildInstancePiece (BuildInstanceId, PieceId, AssignedCount)
VALUES (3,1,3);
GO

SELECT COUNT(*) AS PieceCount, SUM(OwnedCount) AS InventoryCount
FROM  Lego.Piece;
GO

SELECT Type, COUNT(*) AS TypeCount, SUM(OwnedCount) AS InventoryCount
FROM  Lego.Piece
GROUP BY Type;
GO

SELECT CASE WHEN GROUPING(Piece.Type) = 1 THEN '--Total--' ELSE Piece.Type END AS PieceType,
                Piece.Color,Piece.Height, Piece.Width, Piece.Length,
           SUM(BuildInstancePiece.AssignedCount) as AssignedCount
FROM   Lego.Build
                 JOIN Lego.BuildInstance        
                        oN Build.BuildId = BuildInstance.BuildId
                 JOIN Lego.BuildInstancePiece
                        on BuildInstance.BuildInstanceId = 
                                    BuildInstancePiece.BuildInstanceId
                 JOIN Lego.Piece
                        ON BuildInstancePiece.PieceId = Piece.PieceId
WHERE  Build.Name = 'Small Car'
       and  BuildInstanceName = 'Small Car for Book'
GROUP BY GROUPING SETS((Piece.Type,Piece.Color, Piece.Height, Piece.Width, Piece.Length),
                       ());
GO

;WITH AssignedPieceCount
AS (
SELECT PieceId, SUM(AssignedCount) as TotalAssignedCount
FROM   Lego.BuildInstancePiece
GROUP  BY PieceId )

SELECT Type, Name,  Width, Length,Height, 
       Piece.OwnedCount - Coalesce(TotalAssignedCount,0) as AvailableCount
FROM   Lego.Piece
                 LEFT OUTER JOIN AssignedPieceCount
                        on Piece.PieceId =  AssignedPieceCount.PieceId
WHERE Piece.OwnedCount - Coalesce(TotalAssignedCount,0) > 0; 
GO

-----Range Uniqueness

CREATE SCHEMA Office;
GO

CREATE TABLE Office.Doctor
(
        DoctorId        int NOT NULL CONSTRAINT PKDoctor PRIMARY KEY,
        DoctorNumber char(5) NOT NULL CONSTRAINT AKDoctor_DoctorNumber UNIQUE
);
CREATE TABLE Office.Appointment
(
        AppointmentId   int NOT NULL CONSTRAINT PKAppointment PRIMARY KEY,
        --real situation would include room, patient, etc, 
        DoctorId        int NOT NULL,
        StartTime       datetime2(0), --precision to the second
        EndTime         datetime2(0),
        CONSTRAINT AKAppointment_DoctorStartTime UNIQUE (DoctorId,StartTime),
        CONSTRAINT AKAppointment_DoctorEndTime UNIQUE (DoctorId,EndTime),
        CONSTRAINT CHKAppointment_StartBeforeEnd CHECK (StartTime <= EndTime),
        CONSTRAINT FKDoctor$IsAssignedTo$OfficeAppointment FOREIGN KEY (DoctorId)
                                            REFERENCES Office.Doctor (DoctorId)
);

INSERT INTO Office.Doctor (DoctorId, DoctorNumber)
VALUES (1,'00001'),(2,'00002');
INSERT INTO Office.Appointment
VALUES (1,1,'20160712 14:00','20160712 14:59:59'),
           (2,1,'20160712 15:00','20160712 16:59:59'),
           (3,2,'20160712 8:00','20160712 11:59:59'),
           (4,2,'20160712 13:00','20160712 17:59:59'),
           (5,2,'20160712 14:00','20160712 14:59:59'); --offensive item for demo, conflicts                
                                                       --with 4
GO

SELECT Appointment.AppointmentId,
       Acheck.AppointmentId AS ConflictingAppointmentId
FROM   Office.Appointment
          JOIN Office.Appointment AS ACheck
                ON Appointment.DoctorId = ACheck.DoctorId
        /*1*/     and Appointment.AppointmentId <> ACheck.AppointmentId
        /*2*/     and (Appointment.StartTime BETWEEN ACheck.StartTime and ACheck.EndTime  
        /*3*/           or Appointment.EndTime BETWEEN ACheck.StartTime and ACheck.EndTime
        /*4*/           or (Appointment.StartTime < ACheck.StartTime 
                            and Appointment.EndTime > ACheck.EndTime));
GO

DELETE FROM Office.Appointment WHERE AppointmentId = 5;
GO

CREATE TRIGGER Office.Appointment$insertAndUpdate
ON Office.Appointment
AFTER UPDATE, INSERT AS
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
        --if this is an update, but they don’t change times or doctor, don’t check the data
        IF UPDATE(startTime) or UPDATE(endTime) or UPDATE(doctorId)
           BEGIN
           IF EXISTS ( SELECT *
                       FROM   Office.Appointment
                                JOIN Office.Appointment AS ACheck
                                    ON Appointment.doctorId = ACheck.doctorId
                                       AND Appointment.AppointmentId <> ACheck.AppointmentId
                                       AND (Appointment.StartTime BETWEEN Acheck.StartTime 
                                                                        AND Acheck.EndTime
                                            OR Appointment.EndTime BETWEEN Acheck.StartTime 
                                                                        AND Acheck.EndTime
                                            OR (Appointment.StartTime < Acheck.StartTime 
                                                 and Appointment.EndTime > Acheck.EndTime))
                              WHERE  EXISTS (SELECT *
                                             FROM   inserted
                                             WHERE  inserted.DoctorId = Acheck.DoctorId))
                   BEGIN
                         IF @rowsAffected = 1
                                 SELECT @msg = 'Appointment for doctor ' + doctorNumber + 
                                                ' overlapped existing appointment'
                                 FROM   inserted
                                           JOIN Office.Doctor
                                                   ON inserted.DoctorId = Doctor.DoctorId;
                                  ELSE
                                    SELECT @msg = 'One of the rows caused an overlapping ' +              
                                                   'appointment time for a doctor';
                        THROW 50000,@msg,16;

                   END
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

SELECT *
FROM   Office.Appointment;
GO

INSERT INTO Office.Appointment
VALUES (5,1,'20160712 14:00','20160712 14:59:59');
GO

INSERT INTO Office.Appointment
VALUES (5,1,'20160712 14:30','20160712 14:40:59');
GO

INSERT INTO Office.Appointment
VALUES (5,1,'20160712 11:30','20160712 17:59:59');
GO

INSERT into Office.Appointment
VALUES (5,1,'20160712 11:30','20160712 15:59:59'),
       (6,2,'20160713 10:00','20160713 10:59:59');
GO

INSERT INTO Office.Appointment
VALUES (5,1,'20160712 10:00','20160712 11:59:59'),
       (6,2,'20160713 10:00','20160713 10:59:59');
GO

UPDATE Office.Appointment
SET    StartTime = '20160712 15:30',
       EndTime = '20160712 15:59:59'
WHERE  AppointmentId = 1;
GO

----Data-Driven Design

CREATE SCHEMA Customers;
GO
CREATE TABLE Customers.CustomerType
(
        CustomerType    varchar(20) NOT NULL CONSTRAINT PKCustomerType PRIMARY KEY,
        Description     varchar(1000) NOT NULL,
        ActionType      char(1) NOT NULL CONSTRAINT CHKCustomerType_ActionType_Domain
                                               CHECK (ActionType in ('A','B'))
);
----Historical/Temporal Data

---------------------------------------------------------
/* Table create not needed if you have done the earlier example on selective uniqueness

CREATE TABLE HumanResources.Employee
(
    EmployeeId int IDENTITY(1,1) CONSTRAINT PKEmployee primary key,
    EmployeeNumber char(5) NOT NULL
           CONSTRAINT AKEmployee_EmployeeNummer UNIQUE,
    InsurancePolicyNumber char(10) NULL
);
CREATE UNIQUE INDEX AKFEmployee_InsurancePolicyNumber ON
                                    HumanResources.Employee(InsurancePolicyNumber)
                                    WHERE InsurancePolicyNumber IS NOT NULL;
*/

ALTER TABLE HumanResources.Employee
    ADD InsurancePolicyNumberChangeTime datetime2(0)
GO

TRUNCATE TABLE HumanResources.Employee
GO

INSERT INTO HumanResources.Employee (EmployeeNumber, InsurancePolicyNumber)
VALUES ('A0001','1111111111'),
        ('A0002','2222222222'),
        ('A0003','3333333333'),
        ('A0004',NULL),
        ('A0005',NULL),
        ('A0006',NULL);
GO

---Using a Trigger to Capture History
CREATE SCHEMA HumanResourcesHistory;
GO

CREATE TABLE HumanResourcesHistory.Employee
(
    --Original columns
    EmployeeId int NOT NULL,
    EmployeeNumber char(5) NOT NULL,
    InsurancePolicyNumber char(10) NULL,

    --WHEN the row was modified    
    RowModificationTime datetime2(7) NOT NULL,
    --WHAT type of modification
    RowModificationType varchar(10) NOT NULL CONSTRAINT
               CHKEmployeeSalary_RowModificationType 
                      CHECK (RowModificationType IN ('UPDATE','DELETE')),
    --tiebreaker for seeing order of changes, if rows were modified rapidly
    RowSequencerValue bigint IDENTITY(1,1) --use to break ties in RowModificationTime
);
GO

CREATE TRIGGER HumanResources.Employee$HistoryManagementTrigger
ON HumanResources.Employee
AFTER UPDATE, DELETE AS
BEGIN
   SET NOCOUNT ON;
   SET ROWCOUNT 0; --in case the client has modified the rowcount
   --use inserted for insert or update trigger, deleted for update or delete trigger
   --count instead of @@rowcount due to merge behavior that sets @@rowcount to a number
   --that is equal to number of merged rows, not rows being checked in trigger

   DECLARE @msg varchar(2000),    --used to hold the error message
           @rowsAffected int = (SELECT COUNT(*) FROM deleted);
   IF @rowsAffected = 0 RETURN;

   DECLARE @RowModificationType char(6);
   SET @RowModificationType = CASE WHEN EXISTS (SELECT * FROM inserted) THEN 'UPDATE'
                                                          ELSE 'DELETE' END;
   BEGIN TRY
       --[validation section]
       --[modification section]
       --write deleted rows to the history table 
       INSERT  HumanResourcesHistory.Employee(EmployeeId,EmployeeNumber,InsurancePolicyNumber,
                                              RowModificationTime,RowModificationType)
       SELECT EmployeeId,EmployeeNumber,InsurancePolicyNumber, 
              SYSDATETIME(), @RowModificationType
       FROM   deleted;
   END TRY
   BEGIN CATCH
       IF @@trancount > 0
             ROLLBACK TRANSACTION;

       THROW; --will halt the batch or be caught by the caller's catch block

     END CATCH;
END;
GO

SELECT *
FROM   HumanResources.Employee;
GO

UPDATE HumanResources.Employee
SET    InsurancePolicyNumber = '4444444444'
WHERE  EmployeeId = 4;
GO

SELECT *
FROM   HumanResources.Employee
WHERE  EmployeeId = 4;
GO

SELECT *
FROM   HumanResourcesHistory.Employee
WHERE  EmployeeId = 4;
GO

UPDATE HumanResources.Employee
SET  InsurancePolicyNumber = 'IN' + RIGHT(InsurancePolicyNumber,8);

DELETE HumanResources.Employee
WHERE EmployeeId = 6;
GO

SELECT *
FROM   HumanResources.Employee
ORDER BY EmployeeId;
GO

--limiting output for formatting purposes
SELECT EmployeeId, InsurancePolicyNumber, RowModificationTime, RowModificationType
FROM   HumanResourcesHistory.Employee
ORDER BY EmployeeId,RowModificationTime,RowSequencerValue;
GO

---Using Temporal Extensions to Manage History

TRUNCATE TABLE HumanResources.Employee
GO


INSERT INTO HumanResources.Employee (EmployeeNumber, InsurancePolicyNumber)
VALUES ('A0001','1111111111'),
       ('A0002','2222222222'),
       ('A0003','3333333333'),
       ('A0004',NULL),
       ('A0005',NULL),
       ('A0006',NULL);
GO
DROP TABLE HumanResourcesHistory.Employee;
DROP TRIGGER HumanResources.Employee$HistoryManagementTrigger;
GO

ALTER TABLE HumanResources.Employee
ADD
    RowStartTime datetime2(1) GENERATED ALWAYS AS ROW START NOT NULL --HIDDEN can be specified 
                                       --so temporal columns don't show up in SELECT * queries
         --This default will start the history of all existing rows at the 
         --current time (system uses UTC time for these values)
        CONSTRAINT DFLTDelete1 DEFAULT (SYSUTCDATETIME()),
    RowEndTime datetime2(1) GENERATED ALWAYS AS ROW END NOT NULL --HIDDEN
          --data needs to be the max for the datatype
        CONSTRAINT DFLTDelete2 DEFAULT (CAST('9999-12-31 23:59:59.9' AS datetime2(1)))
  , PERIOD FOR SYSTEM_TIME (RowStartTime, RowEndTime);
GO

--DROP the constraints that are just there due to data being in the table
ALTER TABLE HumanResources.Employee
        DROP CONSTRAINT DFLTDelete1;
ALTER TABLE HumanResources.Employee
         DROP CONSTRAINT DFLTDelete2;
GO

ALTER TABLE HumanResources.Employee
         SET (SYSTEM_VERSIONING = ON);
GO

SELECT  tables.object_id AS baseTableObject, 
        CONCAT(historySchema.name,'.',historyTable.name) AS historyTable
FROM    sys.tables
          JOIN sys.schemas
              ON schemas.schema_id = tables.schema_id
          LEFT OUTER JOIN sys.tables AS historyTable
                 JOIN sys.schemas AS historySchema
                       ON historySchema.schema_id = historyTable.schema_id
            ON TABLES.history_table_id = historyTable.object_id
WHERE   schemas.name = 'HumanResources'
  AND   tables.name = 'Employee';
GO

ALTER TABLE HumanResources.Employee
         SET (SYSTEM_VERSIONING = OFF);
DROP TABLE HumanResources.MSSQL_TemporalHistoryFor_1330103779;
GO


ALTER TABLE HumanResources.Employee
                                     --must be in the same database
         SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = HumanResourcesHistory.Employee));
GO

SELECT *
FROM   HumanResources.Employee;
GO

SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME AS OF '2016-05-04';
GO

SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME AS OF '2016-05-11';
GO

UPDATE HumanResources.Employee
SET    InsurancePolicyNumber = '4444444444'
WHERE  EmployeeId = 4;
GO

SELECT * 
FROM   HumanResources.Employee
WHERE  EmployeeId = 4;
GO

SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME AS OF '2016-05-10 02:46:58'
WHERE  EmployeeId = 4;
GO

SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME ALL
ORDER  BY EmployeeId, RowStartTime;
GO

DELETE HumanResources.Employee
WHERE  EmployeeId = 6;
GO


SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME ALL
WHERE  EmployeeId = 6
ORDER  BY EmployeeId, RowStartTime;

UPDATE HumanResources.Employee
SET    EmployeeNumber = EmployeeNumber
WHERE  EmployeeId = 4;
GO

SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME ALL
WHERE  EmployeeId = 4
ORDER  BY EmployeeId, RowStartTime;

UPDATE HumanResources.Employee
SET    EmployeeNumber = EmployeeNumber
WHERE  EmployeeId = 4;
GO 5

SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME ALL
WHERE  EmployeeId = 4
ORDER  BY EmployeeId, RowStartTime;
GO

SELECT *
FROM   HumanResourcesHistory.Employee
WHERE  EmployeeId = 4
  AND  RowStartTime = RowEndTime;

BEGIN TRANSACTION

UPDATE HumanResources.Employee
SET    InsurancePolicyNumber = CONCAT('IN',RIGHT(InsurancePolicyNumber,8))
WHERE  EmployeeId = 1;

WAITFOR DELAY '00:00:01';

UPDATE HumanResources.Employee
SET    InsurancePolicyNumber = CONCAT('IN',RIGHT(InsurancePolicyNumber,8))
WHERE  EmployeeId = 2;

WAITFOR DELAY '00:00:01';

UPDATE HumanResources.Employee
SET    InsurancePolicyNumber = CONCAT('IN',RIGHT(InsurancePolicyNumber,8))
WHERE  EmployeeId = 3;

WAITFOR DELAY '00:00:01';

UPDATE HumanResources.Employee
SET    InsurancePolicyNumber = CONCAT('IN',RIGHT(InsurancePolicyNumber,8))
WHERE  EmployeeId = 4;

COMMIT TRANSACTION
GO


SELECT *
FROM   HumanResources.Employee 
WHERE  InsurancePolicyNumber IS NOT NULL
ORDER BY EmployeeId;
GO

SELECT MIN(RowStartTime)
FROM   HumanResources.Employee FOR SYSTEM_TIME ALL;
GO

ALTER TABLE HumanResources.Employee
         SET (SYSTEM_VERSIONING = OFF);
GO

--Rows that have been modified
UPDATE HumanResourcesHistory.Employee
SET    RowStartTime = '2016-01-01 00:00:00.0'
WHERE  RowStartTime = '2016-05-10 02:35:49.1'; --value from previous select if you are 
                                               --following along in the home game
GO

INSERT INTO HumanResourcesHistory.Employee (EmployeeId, EmployeeNumber, 
                                            InsurancePolicyNumber, RowStartTime, RowEndTime)
SELECT EmployeeId, EmployeeNumber, InsurancePolicyNumber, 
       '2016-01-01 00:00:00.0',
        RowStartTime --use the rowStartTime in the row for the endTime of the history
FROM   HumanResources.Employee
WHERE  NOT EXISTS (SELECT *
                   FROM   HumanResourcesHistory.Employee AS HistEmployee
                   WHERE  HistEmployee.EmployeeId = Employee.EmployeeId);
GO

SELECT *
FROM   HumanResourcesHistory.Employee
WHERE  RowStartTime = '2016-01-01 00:00:00.0'
ORDER BY EmployeeId;
GO

ALTER TABLE HumanResources.Employee
	SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = HumanResourcesHistory.Employee));

SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME AS OF '2016-01-01 00:00:00.0'
ORDER BY EmployeeId;


/*
Continuing from the text, with different time period data, but in the same condition (make one mistake and you have to redo the entire example due to the temporal
aspects of the data
*/
SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME ALL
ORDER BY EmployeeId, RowStartTime;

/*
EmployeeId  EmployeeNumber InsurancePolicyNumber RowStartTime                RowEndTime
----------- -------------- --------------------- --------------------------- ---------------------------
1           A0001          1111111111            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
1           A0001          IN11111111            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
2           A0002          2222222222            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
2           A0002          IN22222222            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
3           A0003          3333333333            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
3           A0003          IN33333333            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
4           A0004          NULL                  2016-01-01 00:00:00.0       2016-05-10 03:51:44.7
4           A0004          4444444444            2016-05-10 03:51:44.7       2016-05-10 03:51:53.5
4           A0004          4444444444            2016-05-10 03:51:53.5       2016-05-10 03:51:57.5
4           A0004          4444444444            2016-05-10 03:51:57.5       2016-05-10 03:51:57.6
4           A0004          4444444444            2016-05-10 03:51:57.6       2016-05-10 03:52:00.4
4           A0004          IN44444444            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
5           A0005          NULL                  2016-01-01 00:00:00.0       2016-05-10 03:51:22.9
5           A0005          NULL                  2016-05-10 03:51:22.9       9999-12-31 23:59:59.9
6           A0006          NULL                  2016-01-01 00:00:00.0       2016-05-10 03:51:53.5

Next we want to deal with fixing EmployeeId = 5's history. We find the row that was in force during March 1st (which is shown in the previous result set.  
Then we are going to inject the new history row, and update this row.  The new row should start at the point in time you want the version to exist from, 
and end at the previous RowEndTime that was he version row for the same time period. So grab the start and end times that are currently set for this time period:

*/
--must have your final row looking like you expect before the versioning... 
UPDATE HumanResources.Employee
SET   InsurancePolicyNumber = 'IN55555555'
WHERE EmployeeId = 5;


ALTER TABLE HumanResources.Employee
	SET (SYSTEM_VERSIONING = OFF);
GO

--this code assumes you are changing history, not dealing with any data in the employee table
SELECT RowStartTime, RowEndTime
FROM   HumanResourcesHistory.Employee
WHERE  '2016-03-01 00:00:00.0000000' BETWEEN RowStartTime AND RowEndTime
  AND  EmployeeId = 5

--RowStartTime is the time you are splitting on, RowEndTime is the RowEndTime from the previous query
INSERT HumanResourcesHistory.Employee (EmployeeId, EmployeeNumber, InsurancePolicyNumber, RowStartTime, RowEndTime)
VALUES  (5, 'A0005', '5555555555', '2016-03-01 00:00:00.0',' 2016-05-10 03:51:22.9');

--RowEndTime is the time you are splitting on, and rowStartTime is the start time of the previous query
UPDATE HumanResourcesHistory.Employee
SET    RowEndTime = '2016-03-01 00:00:00.0'
WHERE EmployeeId = 5
 AND  RowStartTime = '2016-01-01 00:00:00.0';
/* 
Check the history:
*/
SELECT 'History',*
FROM   HumanResourcesHistory.Employee
WHERE  EmployeeId = 5
UNION ALL
SELECT 'Base',*
FROM   HumanResources.Employee
WHERE  EmployeeId = 5
ORDER BY RowStartTime;
/*
You can see the progression exists that is contiguous. So we have updated the data back in history:

        EmployeeId  EmployeeNumber InsurancePolicyNumber RowStartTime                RowEndTime
------- ----------- -------------- --------------------- --------------------------- ---------------------------
History 5           A0005          NULL                  2016-01-01 00:00:00.0       2016-03-01 00:00:00.0
History 5           A0005          5555555555            2016-03-01 00:00:00.0       2016-05-10 03:51:22.9
History 5           A0005          NULL                  2016-05-10 03:51:22.9       2016-05-10 03:53:36.3
Base    5           A0005          IN55555555            2016-05-10 03:53:36.3       9999-12-31 23:59:59.9
*/
UPDATE HumanResourcesHistory.Employee
SET  InsurancePolicyNumber = '5555555555'
WHERE  EmployeeId = 5
  AND  RowStartTime = '2016-05-10 03:51:22.9';
SELECT 'History',*
FROM   HumanResourcesHistory.Employee
WHERE  EmployeeId = 5
UNION ALL
SELECT 'Base',*
FROM   HumanResources.Employee
WHERE  EmployeeId = 5
ORDER BY RowStartTime;

/*
        EmployeeId  EmployeeNumber InsurancePolicyNumber RowStartTime                RowEndTime
------- ----------- -------------- --------------------- --------------------------- ---------------------------
History 5           A0005          NULL                  2016-01-01 00:00:00.0       2016-03-01 00:00:00.0
History 5           A0005          5555555555            2016-03-01 00:00:00.0       2016-05-10 03:51:22.9
History 5           A0005          5555555555            2016-05-10 03:51:22.9       2016-05-10 03:53:36.3
Base    5           A0005          IN55555555            2016-05-10 03:53:36.3       9999-12-31 23:59:59.9

Next, since we actually have updated the way insurance numbers are formatted, we need to make this change match the other rows. 
Find out when the row was modified for EmployeeId = 4
*/

SELECT 'History',*
FROM   HumanResourcesHistory.Employee
WHERE  EmployeeId = 4
AND    InsurancePolicyNumber LIKE 'IN%'
UNION ALL
SELECT 'Base',*
FROM   HumanResources.Employee
WHERE  EmployeeId = 4
AND    InsurancePolicyNumber LIKE 'IN%'
ORDER BY RowStartTime;
/*
This returns:
*/
        EmployeeId  EmployeeNumber InsurancePolicyNumber RowStartTime                RowEndTime
------- ----------- -------------- --------------------- --------------------------- ---------------------------
Base    4           A0004          IN44444444            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9

/*
So we can see the row changed at '2016-05-10 03:52:00.4'. So we basically just do the same thing to the history rows as we did previously, using this time as our split time:
*/

SELECT RowStartTime, RowEndTime
FROM   HumanResourcesHistory.Employee
WHERE  '2016-05-10 03:52:00.4' BETWEEN RowStartTime AND RowEndTime
  AND  EmployeeId = 5;
/*
If you get back two rows, then the data already changes at this point in time. 

RowStartTime                RowEndTime
--------------------------- ---------------------------
2016-05-10 03:51:22.9       2016-05-10 03:53:36.3
*/

 --RowStartTime is the time you are splitting on (when we saw 4 changed), RowEndTime is the RowEndTime from the previous query
INSERT HumanResourcesHistory.Employee (EmployeeId, EmployeeNumber, InsurancePolicyNumber, RowStartTime, RowEndTime)
VALUES  (5, 'A0005', 'IN55555555', '2016-05-10 03:52:00.4','2016-05-10 03:53:36.3');

--RowEndTime is the time you are splitting on, and rowStartTime is the start time of the previous query
UPDATE HumanResourcesHistory.Employee
SET    RowEndTime = '2016-05-10 03:52:00.4'
WHERE EmployeeId = 5
 AND  RowStartTime = '2016-05-10 03:51:22.9';

 
 Finally, inspect the history:
 
SELECT 'History',*
FROM   HumanResourcesHistory.Employee
WHERE  EmployeeId = 5
UNION ALL
SELECT 'Base',*
FROM   HumanResources.Employee
WHERE  EmployeeId = 5
ORDER BY RowStartTime;
/*
And if you have done everything just right (which to be honest, may not happen the first time you try this), when you turn back on versioning everything will work as desired:
*/

ALTER TABLE HumanResources.Employee
	SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = HumanResourcesHistory.Employee));
/*
Then test various points in time. The first is the time when the IN update occurred:
*/
SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME AS OF '2016-05-10 03:52:00.4'
ORDER BY EmployeeId;
/*
Looks as expected:

EmployeeId  EmployeeNumber InsurancePolicyNumber RowStartTime                RowEndTime
----------- -------------- --------------------- --------------------------- ---------------------------
1           A0001          IN11111111            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
2           A0002          IN22222222            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
3           A0003          IN33333333            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
4           A0004          IN44444444            2016-05-10 03:52:00.4       9999-12-31 23:59:59.9
5           A0005          IN55555555            2016-05-10 03:52:00.4       2016-05-10 03:53:36.3

Now the moment just before this update:
*/
SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME AS OF '2016-05-10 03:52:00'
ORDER BY EmployeeId;
/*
EmployeeId = 5 is set as having insurance, and all data is still in old format:

EmployeeId  EmployeeNumber InsurancePolicyNumber RowStartTime                RowEndTime
----------- -------------- --------------------- --------------------------- ---------------------------
1           A0001          1111111111            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
2           A0002          2222222222            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
3           A0003          3333333333            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
4           A0004          4444444444            2016-05-10 03:51:57.6       2016-05-10 03:52:00.4
5           A0005          5555555555            2016-05-10 03:51:22.9       2016-05-10 03:52:00.4

Finally (for the text, in any case), check the start of time as we care about it:
*/
SELECT *
FROM   HumanResources.Employee FOR SYSTEM_TIME AS OF '2016-01-01'
ORDER BY EmployeeId;
/*
This looks as it did when we started:

EmployeeId  EmployeeNumber InsurancePolicyNumber RowStartTime                RowEndTime
----------- -------------- --------------------- --------------------------- ---------------------------
1           A0001          1111111111            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
2           A0002          2222222222            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
3           A0003          3333333333            2016-01-01 00:00:00.0       2016-05-10 03:52:00.4
4           A0004          NULL                  2016-01-01 00:00:00.0       2016-05-10 03:51:44.7
5           A0005          NULL                  2016-01-01 00:00:00.0       2016-03-01 00:00:00.0
6           A0006          NULL                  2016-01-01 00:00:00.0       2016-05-10 03:51:53.5
*/




----Hierarchies
---Self Referencing/Recursive Relationship/Adjacency List 

CREATE SCHEMA Corporate;
GO
CREATE TABLE Corporate.Company
(
    CompanyId   int NOT NULL CONSTRAINT PKCompany PRIMARY KEY,
    Name        varchar(20) NOT NULL CONSTRAINT AKCompany_Name UNIQUE,
    ParentCompanyId int NULL
      CONSTRAINT Company$isParentOf$Company REFERENCES Corporate.Company(companyId)
);  
GO

INSERT INTO Corporate.Company (CompanyId, Name, ParentCompanyId)
VALUES (1, 'Company HQ', NULL),
       (2, 'Maine HQ',1),              (3, 'Tennessee HQ',1),
       (4, 'Nashville Branch',3),      (5, 'Knoxville Branch',3),
       (6, 'Memphis Branch',3),        (7, 'Portland Branch',2),
       (8, 'Camden Branch',2);
GO

SELECT *
FROM    Corporate.Company;
GO


--getting the children of a row (or ancestors with slight mod to query)
DECLARE @CompanyId int = <set me>;

;WITH companyHierarchy(CompanyId, ParentCompanyId, treelevel, hierarchy)
AS
(
     --gets the top level in hierarchy we want. The hierarchy column
     --will show the row's place in the hierarchy from this query only
     --not in the overall reality of the row's place in the table
     SELECT CompanyId, ParentCompanyId,
            1 as treelevel, CAST(CompanyId AS varchar(max)) as hierarchy
     FROM   Corporate.Company
     WHERE CompanyId=@CompanyId

     UNION ALL

     --joins back to the CTE to recursively retrieve the rows 
     --note that treelevel is incremented on each iteration
     SELECT Company.CompanyID, Company.ParentCompanyId,
            treelevel + 1 as treelevel,
            CONCAT(hierarchy,'\',Company.CompanyId) AS hierarchy
     FROM   Corporate.Company
              INNER JOIN companyHierarchy
                --use to get children
                ON Company.ParentCompanyId= companyHierarchy.CompanyId
                --use to get parents
                --ON Company.CompanyId= companyHierarchy.ParentcompanyId
)
--return results from the CTE, joining to the company data to get the 
--company name
SELECT  Company.CompanyID,Company.Name,
        companyHierarchy.treelevel, companyHierarchy.hierarchy
FROM     Corporate.Company
         INNER JOIN companyHierarchy
              ON Company.CompanyId = companyHierarchy.companyId
ORDER BY hierarchy;
GO


                
CREATE SCHEMA Parts;
GO
CREATE TABLE Parts.Part
(
        PartId   int    NOT NULL CONSTRAINT PKPart PRIMARY KEY,
        PartNumber char(5) NOT NULL CONSTRAINT AKPart UNIQUE,
        Name    varchar(20) NULL
);
GO

INSERT INTO Parts.Part (PartId, PartNumber,Name)
VALUES (1,'00001','Screw Package'),(2,'00002','Piece of Wood'),
       (3,'00003','Tape Package'),(4,'00004','Screw and Tape'),
       (5,'00005','Wood with Tape') ,(6,'00006','Screw'),(7,'00007','Tape');
GO


CREATE TABLE Parts.Assembly
(
       PartId   int
            CONSTRAINT FKAssembly$contains$PartsPart
                              REFERENCES Parts.Part(PartId),
       ContainsPartId   int
            CONSTRAINT FKAssembly$isContainedBy$PartsPart
                              REFERENCES Parts.Part(PartId),
            CONSTRAINT PKAssembly PRIMARY KEY (PartId, ContainsPartId),
);
GO

INSERT INTO PARTS.Assembly(PartId,ContainsPartId)
VALUES (1,6),(3,7);
GO

INSERT INTO PARTS.Assembly(PartId,ContainsPartId)
VALUES (4,1),(4,3);
GO

INSERT INTO Parts.Assembly(PartId,ContainsPartId)
VALUES (5,2),(5,3);
GO

--getting the children of a row (or ancestors with slight mod to query)
DECLARE @PartId int = 4;

;WITH partsHierarchy(PartId, ContainsPartId, treelevel, hierarchy,nameHierarchy)
AS
(
     --gets the top level in hierarchy we want. The hierarchy column
     --will show the row's place in the hierarchy from this query only
     --not in the overall reality of the row's place in the table
     SELECT NULL  AS PartId, PartId AS ContainsPartId,
            1 AS treelevel, 
            CAST(PartId AS varchar(max)) as hierarchy,
            --added more textual hierarchy for this example
            CAST(Name AS varchar(max)) AS nameHierarchy
     FROM   Parts.Part
     WHERE PartId=@PartId

     UNION ALL

     --joins back to the CTE to recursively retrieve the rows 
     --note that treelevel is incremented on each iteration
     SELECT Assembly.PartId, Assembly.ContainsPartId,
            treelevel + 1 as treelevel,
            CONCAT(hierarchy,'\',Assembly.ContainsPartId) AS hierarchy,
            CONCAT(nameHierarchy,'\',Part.Name) AS nameHierarchy
     FROM   Parts.Assembly
                          INNER JOIN Parts.Part
                                ON Assembly.ContainsPartId = Part.PartId
              INNER JOIN partsHierarchy
                ON Assembly.PartId= partsHierarchy.ContainsPartId
)
SELECT PartId, nameHierarchy, hierarchy 
FROM partsHierarchy;

-------Implementing the Hierarchy using the hierarchyId Type

CREATE TABLE Corporate.CompanyAlternate
(
    CompanyOrgNode hierarchyId not null 
                 CONSTRAINT AKCompanyAlternate UNIQUE,
    CompanyId   int CONSTRAINT PKCompanyAlternate PRIMARY KEY NONCLUSTERED,
    Name        varchar(20) CONSTRAINT AKCompanyAlternate_name UNIQUE,
    OrganizationLevel as CompanyOrgNode.GetLevel() PERSISTED
);   
GO

CREATE CLUSTERED INDEX Org_Breadth_First 
         ON Corporate.CompanyAlternate(OrganizationLevel,CompanyOrgNode);
GO

INSERT Corporate.CompanyAlternate (CompanyOrgNode, CompanyId, Name)
VALUES (hierarchyid::GetRoot(), 1, 'Company HQ');
GO

CREATE PROCEDURE Corporate. CompanyAlternate$Insert(@CompanyId int, @ParentCompanyId int, 
                                           @Name varchar(20)) 
AS 
BEGIN
   SET NOCOUNT ON
   --the last child will be used when generating the next node, 
   --and the parent is used to set the parent in the insert
   DECLARE  @lastChildofParentOrgNode hierarchyid,
            @parentCompanyOrgNode hierarchyid; 
   IF @ParentCompanyId IS NOT NULL
     BEGIN
        SET @ParentCompanyOrgNode = 
                            (  SELECT CompanyOrgNode 
                               FROM   Corporate. CompanyAlternate
                               WHERE  CompanyID = @ParentCompanyId)
         IF  @parentCompanyOrgNode IS NULL
           BEGIN
                THROW 50000, 'Invalid parentCompanyId passed in',1;
                RETURN -100;
            END
    END
   
   BEGIN TRANSACTION;

      --get the last child of the parent you passed in if one exists
      SELECT @lastChildofParentOrgNode = MAX(CompanyOrgNode) 
      FROM Corporate.CompanyAlternate (UPDLOCK) --compatibile with shared, but blocks
                                       --other connections trying to get an UPDLOCK 
      WHERE CompanyOrgNode.GetAncestor(1) = @parentCompanyOrgNode ;

      --getDecendant will give you the next node that is greater than 
      --the one passed in.  Since the value was the max in the table, the 
      --getDescendant Method returns the next one
      INSERT Corporate.CompanyAlternate  (CompanyOrgNode, CompanyId, Name)
             --the coalesce puts the row as a NULL this will be a root node
             --invalid ParentCompanyId values were tossed out earlier
      SELECT COALESCE(@parentCompanyOrgNode.GetDescendant(
                   @lastChildofParentOrgNode, NULL),hierarchyid::GetRoot())
                  ,@CompanyId, @Name;
   COMMIT;
END; 
GO

--exec Corporate.CompanyAlternate$insert @CompanyId = 1, @parentCompanyId = NULL,
--                               @Name = 'Company HQ'; --already created
exec Corporate.CompanyAlternate$insert @CompanyId = 2, @ParentCompanyId = 1,
                                 @Name = 'Maine HQ';
exec Corporate.CompanyAlternate$insert @CompanyId = 3, @ParentCompanyId = 1, 
                                 @Name = 'Tennessee HQ';
exec Corporate.CompanyAlternate$insert @CompanyId = 4, @ParentCompanyId = 3, 
                                 @Name = 'Knoxville Branch';
exec Corporate.CompanyAlternate$insert @CompanyId = 5, @ParentCompanyId = 3, 
                                 @Name = 'Memphis Branch';
exec Corporate.CompanyAlternate$insert @CompanyId = 6, @ParentCompanyId = 2, 
                                 @Name = 'Portland Branch';
exec Corporate.CompanyAlternate$insert @CompanyId = 7, @ParentCompanyId = 2, 
                                 @Name = 'Camden Branch';
GO

SELECT CompanyOrgNode, CompanyId, Name
FROM   Corporate.CompanyAlternate
ORDER  BY CompanyId;
GO


SELECT CompanyId, OrganizationLevel,
       Name, CompanyOrgNode.ToString() as Hierarchy 
FROM   Corporate.CompanyAlternate
ORDER  BY Hierarchy;
GO

DECLARE @CompanyId int = 3;
SELECT Target.CompanyId, Target.Name, Target.CompanyOrgNode.ToString() AS Hierarchy
FROM   Corporate.CompanyAlternate AS Target
               JOIN Corporate.CompanyAlternate AS SearchFor
                       ON SearchFor.CompanyId = @CompanyId
                          and Target.CompanyOrgNode.IsDescendantOf
                                                 (SearchFor.CompanyOrgNode) = 1;
GO

DECLARE @CompanyId int = 3;
SELECT Target.CompanyId, Target.Name, Target.CompanyOrgNode.ToString() AS Hierarchy
FROM   Corporate.CompanyAlternate AS Target
               JOIN Corporate.CompanyAlternate AS SearchFor
                       ON SearchFor.CompanyId = @CompanyId
                          and SearchFor.CompanyOrgNode.IsDescendantOf
                                                 (Target.CompanyOrgNode) = 1;
GO

----Images, Documents, and Other Files, Oh My

EXEC sp_configure filestream_access_level 2;
GO
RECONFIGURE;
GO

CREATE DATABASE FileStorageDemo; --uses basic defaults from model databases
GO
USE FileStorageDemo;
GO
--will cover filegroups more in the chapter 10 on structures
ALTER DATABASE FileStorageDemo ADD
        FILEGROUP FilestreamData CONTAINS FILESTREAM;
GO

ALTER DATABASE FileStorageDemo ADD FILE (
       NAME = FilestreamDataFile1,
       FILENAME = 'c:\sql\filestream') --directory cannot yet exist and SQL account must have 
                                      --access to drive.
TO FILEGROUP FilestreamData;
GO



CREATE SCHEMA Demo;
GO
CREATE TABLE Demo.TestSimpleFileStream
(
        TestSimpleFilestreamId INT NOT NULL 
                      CONSTRAINT PKTestSimpleFileStream PRIMARY KEY,
        FileStreamColumn VARBINARY(MAX) FILESTREAM NULL,
        RowGuid uniqueidentifier NOT NULL ROWGUIDCOL DEFAULT (NEWID()) 
                      CONSTRAINT AKTestSimpleFileStream_RowGuid UNIQUE
)       FILESTREAM_ON FilestreamData; 
GO

INSERT INTO Demo.TestSimpleFileStream(TestSimpleFilestreamId,FileStreamColumn)
SELECT 1, CAST('This is an exciting example' AS varbinary(max));
GO

SELECT TestSimpleFilestreamId,FileStreamColumn,
       CAST(FileStreamColumn AS varchar(40)) AS FileStreamText
FROM   Demo.TestSimpleFilestream;
GO

ALTER DATABASE FileStorageDemo
        SET FILESTREAM (NON_TRANSACTED_ACCESS = FULL, 
                         DIRECTORY_NAME = N'ProSQLServerDBDesign');
GO


CREATE TABLE Demo.FileTableTest AS FILETABLE
  WITH (
        FILETABLE_DIRECTORY = 'FileTableTest',
        FILETABLE_COLLATE_FILENAME = database_default
        );
    GO

INSERT INTO Demo.FiletableTest(name, is_directory) 
VALUES ( 'Project 1', 1);
GO

SELECT stream_id, file_stream, name
FROM   Demo.FileTableTest
WHERE  name = 'Project 1';
GO

INSERT INTO Demo.FiletableTest(name, is_directory, file_stream) 
VALUES ( 'Test.Txt', 0, CAST('This is some text' AS varbinary(max)));
GO

UPDATE Demo.FiletableTest
SET    path_locator = path_locator.GetReparentedValue( path_locator.GetAncestor(1),
       (SELECT path_locator FROM Demo.FiletableTest 
            WHERE name = 'Project 1' 
                  AND parent_path_locator IS NULL
                  AND is_directory = 1))
WHERE name = 'Test.Txt';
GO


SELECT  CONCAT(FileTableRootPath(),
                            file_stream.GetFileNamespacePath()) AS FilePath
FROM    Demo.FileTableTest
WHERE   name = 'Project 1' 
  AND   parent_path_locator is NULL
  AND   is_directory = 1;
GO

----Generalization

CREATE SCHEMA Inventory;
GO
CREATE TABLE Inventory.Item
(
        ItemId  int NOT NULL IDENTITY CONSTRAINT PKItem PRIMARY KEY,
        Name    varchar(30) NOT NULL CONSTRAINT AKItemName UNIQUE,
        Type    varchar(15) NOT NULL,
        Color   varchar(15) NOT NULL,
        Description varchar(100) NOT NULL,
        ApproximateValue  numeric(12,2) NULL,
        ReceiptImage   varbinary(max) NULL,
        PhotographicImage varbinary(max) NULL
);
GO

INSERT INTO Inventory.Item
VALUES ('Den Couch','Furniture','Blue','Blue plaid couch, seats 4',450.00,0x001,0x001),
       ('Den Ottoman','Furniture','Blue','Blue plaid ottoman that goes with couch',  
         150.00,0x001,0x001),
       ('40 Inch Sorny TV','Electronics','Black',
        '40 Inch Sorny TV, Model R2D12, Serial Number XD49292',
         800,0x001,0x001),
        ('29 Inch JQC TV','Electronics','Black','29 Inch JQC CRTVX29 TV',800,0x001,0x001),
        ('Mom''s Pearl Necklace','Jewelery','White',
         'Appraised for $1300 in June of 2003. 30 inch necklace, was Mom''s',
         1300,0x001,0x001);
GO

SELECT Name, Type, Description
FROM   Inventory.Item;
GO


CREATE TABLE Inventory.JeweleryItem
(
        ItemId  int     CONSTRAINT PKJewleryItem PRIMARY KEY
                    CONSTRAINT FKJewleryItem$Extends$InventoryItem
                                           REFERENCES Inventory.Item(ItemId),
        QualityLevel   varchar(10) NOT NULL,
        AppraiserName  varchar(100) NULL,
        AppraisalValue numeric(12,2) NULL,
        AppraisalYear  char(4) NULL

);
GO

CREATE TABLE Inventory.ElectronicItem
(
        ItemId        int        CONSTRAINT PKElectronicItem PRIMARY KEY
                    CONSTRAINT FKElectronicItem$Extends$InventoryItem
                                           REFERENCES Inventory.Item(ItemId),
        BrandName  varchar(20) NOT NULL,
        ModelNumber varchar(20) NOT NULL,
        SerialNumber varchar(20) NULL
);
GO

UPDATE Inventory.Item
SET    Description = '40 Inch TV' 
WHERE  Name = '40 Inch Sorny TV';
GO

INSERT INTO Inventory.ElectronicItem (ItemId, BrandName, ModelNumber, SerialNumber)
SELECT ItemId, 'Sorny','R2D12','XD49393'
FROM   Inventory.Item
WHERE  Name = '40 Inch Sorny TV';
GO

UPDATE Inventory.Item
SET    Description = '29 Inch TV' 
WHERE  Name = '29 Inch JQC TV';
GO

INSERT INTO Inventory.ElectronicItem(ItemId, BrandName, ModelNumber, SerialNumber)
SELECT ItemId, 'JVC','CRTVX29',NULL
FROM   Inventory.Item
WHERE  Name = '29 Inch JQC TV';
GO


UPDATE Inventory.Item
SET    Description = '30 Inch Pearl Neclace' 
WHERE  Name = 'Mom''s Pearl Necklace';
GO

INSERT INTO Inventory.JeweleryItem (ItemId, QualityLevel, AppraiserName, AppraisalValue,AppraisalYear )
SELECT ItemId, 'Fine','Joey Appraiser',1300,'2003'
FROM   Inventory.Item
WHERE  Name = 'Mom''s Pearl Necklace';
GO

SELECT Name, Type, Description
FROM   Inventory.Item;
GO

SELECT Item.Name, ElectronicItem.BrandName, ElectronicItem.ModelNumber, ElectronicItem.SerialNumber
FROM   Inventory.ElectronicItem
         JOIN Inventory.Item
                ON Item.ItemId = ElectronicItem.ItemId;
GO

SELECT Name, Description, 
       CASE Type
          WHEN 'Electronics'
            THEN CONCAT('Brand:', COALESCE(BrandName,'_______'),
                 ' Model:',COALESCE(ModelNumber,'________'), 
                 ' SerialNumber:', COALESCE(SerialNumber,'_______'))
          WHEN 'Jewelery'
            THEN CONCAT('QualityLevel:', QualityLevel,
                 ' Appraiser:', COALESCE(AppraiserName,'_______'),
                 ' AppraisalValue:', COALESCE(Cast(AppraisalValue as varchar(20)),'_______'),   
                 ' AppraisalYear:', COALESCE(AppraisalYear,'____'))
            ELSE '' END as ExtendedDescription
FROM   Inventory.Item --simple outer joins because every not item will have extensions
                      --but they will only have one if any extension
           LEFT OUTER JOIN Inventory.ElectronicItem
                ON Item.ItemId = ElectronicItem.ItemId
           LEFT OUTER JOIN Inventory.JeweleryItem
                ON Item.ItemId = JeweleryItem.ItemId;
GO


---Storing User-Specified Data

CREATE SCHEMA Hardware;
GO
CREATE TABLE Hardware.Equipment
(
    EquipmentId int NOT NULL
          CONSTRAINT PKEquipment PRIMARY KEY,
    EquipmentTag varchar(10) NOT NULL
          CONSTRAINT AKEquipment UNIQUE,
    EquipmentType varchar(10)
);
GO

INSERT INTO Hardware.Equipment
VALUES (1,'CLAWHAMMER','Hammer'),
       (2,'HANDSAW','Saw'),	
       (3,'POWERDRILL','PowerTool');
GO


---Entity-Attribute-Value (EAV)
CREATE TABLE Hardware.EquipmentPropertyType
(
    EquipmentPropertyTypeId int NOT NULL
        CONSTRAINT PKEquipmentPropertyType PRIMARY KEY,
    Name varchar(15)
        CONSTRAINT AKEquipmentPropertyType UNIQUE,
    TreatAsDatatype sysname NOT NULL
);
GO


INSERT INTO Hardware.EquipmentPropertyType
VALUES(1,'Width','numeric(10,2)'),
      (2,'Length','numeric(10,2)'),
      (3,'HammerHeadStyle','varchar(30)');
GO


CREATE TABLE Hardware.EquipmentProperty
(
    EquipmentId int NOT NULL
      CONSTRAINT FKEquipment$hasExtendedPropertiesIn$HardwareEquipmentProperty
           REFERENCES Hardware.Equipment(EquipmentId),
    EquipmentPropertyTypeId int
      CONSTRAINT FKEquipmentPropertyTypeId$definesTypesFor$HardwareEquipmentProperty
           REFERENCES Hardware.EquipmentPropertyType(EquipmentPropertyTypeId),
    Value sql_variant,
    CONSTRAINT PKEquipmentProperty PRIMARY KEY
                     (EquipmentId, EquipmentPropertyTypeId)
);
GO


CREATE PROCEDURE Hardware.EquipmentProperty$Insert
(
    @EquipmentId int,
    @EquipmentPropertyName varchar(15),
    @Value sql_variant
)
AS
    SET NOCOUNT ON;
    DECLARE @entryTrancount int = @@trancount;

    BEGIN TRY
        DECLARE @EquipmentPropertyTypeId int,
                @TreatASDatatype sysname;

        SELECT @TreatASDatatype = TreatAsDatatype,
               @EquipmentPropertyTypeId = EquipmentPropertyTypeId
        FROM   Hardware.EquipmentPropertyType
        WHERE  EquipmentPropertyType.Name = @EquipmentPropertyName;

      BEGIN TRANSACTION;
        --insert the value
        INSERT INTO Hardware.EquipmentProperty(EquipmentId, EquipmentPropertyTypeId,
                    Value)
        VALUES (@EquipmentId, @EquipmentPropertyTypeId, @Value);


        --Then get that value from the table and cast it in a dynamic SQL
        -- call.  This will raise a trappable error if the type is incompatible
        DECLARE @validationQuery  varchar(max) =
           CONCAT(' DECLARE @value sql_variant
                   SELECT  @value = CAST(VALUE AS ', @TreatASDatatype, ')
                   FROM    Hardware.EquipmentProperty
                   WHERE   EquipmentId = ', @EquipmentId, '
                     and   EquipmentPropertyTypeId = ' ,
                          @EquipmentPropertyTypeId);

        EXECUTE (@validationQuery);
      COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
         IF @@TRANCOUNT > 0
             ROLLBACK TRANSACTION;

         DECLARE @ERRORmessage nvarchar(4000)
         SET @ERRORmessage = CONCAT('Error occurred in procedure ''',
                  OBJECT_NAME(@@procid), ''', Original Message: ''',
                  ERROR_MESSAGE(),''' Property:''',@EquipmentPropertyName,
                 ''' Value:''',cast(@Value as nvarchar(1000)),'''');
      THROW 50000,@ERRORMessage,16;
      RETURN -100;

     END CATCH;
GO


EXEC Hardware.EquipmentProperty$Insert 1,'Width','Claw'; --width is numeric(10,2)
GO

EXEC Hardware.EquipmentProperty$Insert @EquipmentId =1 ,
        @EquipmentPropertyName = 'Width', @Value = 2;
EXEC Hardware.EquipmentProperty$Insert @EquipmentId =1 ,
        @EquipmentPropertyName = 'Length',@Value = 8.4;
EXEC Hardware.EquipmentProperty$Insert @EquipmentId =1 ,
        @EquipmentPropertyName = 'HammerHeadStyle',@Value = 'Claw';
EXEC Hardware.EquipmentProperty$Insert @EquipmentId =2 ,
        @EquipmentPropertyName = 'Width',@Value = 1;
EXEC Hardware.EquipmentProperty$Insert @EquipmentId =2 ,
        @EquipmentPropertyName = 'Length',@Value = 7;
EXEC Hardware.EquipmentProperty$Insert @EquipmentId =3 ,
        @EquipmentPropertyName = 'Width',@Value = 6;
EXEC Hardware.EquipmentProperty$Insert @EquipmentId =3 ,
        @EquipmentPropertyName = 'Length',@Value = 12.1;
GO


SELECT Equipment.EquipmentTag,Equipment.EquipmentType,
       EquipmentPropertyType.name, EquipmentProperty.Value
FROM   Hardware.EquipmentProperty
         JOIN Hardware.Equipment
            on Equipment.EquipmentId = EquipmentProperty.EquipmentId
         JOIN Hardware.EquipmentPropertyType
            on EquipmentPropertyType.EquipmentPropertyTypeId =
                                   EquipmentProperty.EquipmentPropertyTypeId;
GO


SET ANSI_WARNINGS OFF; --eliminates the NULL warning on aggregates.
SELECT  Equipment.EquipmentTag,Equipment.EquipmentType,
   MAX(CASE WHEN EquipmentPropertyType.name = 'HammerHeadStyle' THEN Value END)
                                                            AS 'HammerHeadStyle',
   MAX(CASE WHEN EquipmentPropertyType.name = 'Length'THEN Value END) AS Length,
   MAX(CASE WHEN EquipmentPropertyType.name = 'Width' THEN Value END) AS Width
FROM   Hardware.EquipmentProperty
         JOIN Hardware.Equipment
            on Equipment.EquipmentId = EquipmentProperty.EquipmentId
         JOIN Hardware.EquipmentPropertyType
            on EquipmentPropertyType.EquipmentPropertyTypeId =
                                     EquipmentProperty.EquipmentPropertyTypeId
GROUP BY Equipment.EquipmentTag,Equipment.EquipmentType;
SET ANSI_WARNINGS OFF; --eliminates the NULL warning on aggregates.
GO

SET ANSI_WARNINGS OFF;
DECLARE @query varchar(8000);
SELECT  @query = 'SELECT Equipment.EquipmentTag,Equipment.EquipmentType ' + (
                SELECT DISTINCT
                    ',MAX(CASE WHEN EquipmentPropertyType.name = ''' +
                       EquipmentPropertyType.name + ''' THEN cast(Value as ' +
                       EquipmentPropertyType.TreatAsDatatype + ') END) AS [' +
                       EquipmentPropertyType.name + ']' AS [text()]
                FROM
                    Hardware.EquipmentPropertyType
                FOR XML PATH('') ) + '
                FROM  Hardware.EquipmentProperty
                             JOIN Hardware.Equipment
                                ON Equipment.EquipmentId =
                                     EquipmentProperty.EquipmentId
                             JOIN Hardware.EquipmentPropertyType
                                ON EquipmentPropertyType.EquipmentPropertyTypeId
                                   = EquipmentProperty.EquipmentPropertyTypeId
          GROUP BY Equipment.EquipmentTag,Equipment.EquipmentType  '
EXEC (@query);

---Adding Columns to a Table

ALTER TABLE Hardware.Equipment
    ADD Length numeric(10,2) SPARSE NULL;
GO\

CREATE PROCEDURE Hardware.Equipment$addProperty
(
    @propertyName   sysname, --the column to add
    @datatype       sysname, --the datatype as it appears in a column creation
    @sparselyPopulatedFlag bit = 1 --Add column as sparse or not
)
WITH EXECUTE AS OWNER
AS
  --note: I did not include full error handling for clarity
  DECLARE @query nvarchar(max);

 --check for column existance
 IF NOT EXISTS (SELECT *
               FROM   sys.columns
               WHERE  name = @propertyName
                 AND  OBJECT_NAME(object_id) = 'Equipment'
                 AND  OBJECT_SCHEMA_NAME(object_id) = 'Hardware')
  BEGIN
    --build the ALTER statement, then execute it
     SET @query = 'ALTER TABLE Hardware.Equipment ADD ' + quotename(@propertyName) + ' '
                + @datatype
                + case when @sparselyPopulatedFlag = 1 then ' SPARSE ' end
                + ' NULL ';
     EXEC (@query);
  END
 ELSE
     THROW 50000, 'The property you are adding already exists',1;
GO


--EXEC Hardware.Equipment$addProperty 'Length','numeric(10,2)',1; -- added manually
EXEC Hardware.Equipment$addProperty 'Width','numeric(10,2)',1;
EXEC Hardware.Equipment$addProperty 'HammerHeadStyle','varchar(30)',1;
GO

SELECT EquipmentTag, EquipmentType, HammerHeadStyle,Length,Width
FROM   Hardware.Equipment;
GO

UPDATE Hardware.Equipment
SET    Length = 7.00,
       Width =  1.00
WHERE  EquipmentTag = 'HANDSAW';
GO

ALTER TABLE Hardware.Equipment
 ADD CONSTRAINT CHKEquipment$HammerHeadStyle CHECK
        ((HammerHeadStyle is NULL AND EquipmentType <> 'Hammer')
        OR EquipmentType = 'Hammer');
GO


UPDATE Hardware.Equipment
SET    Length = 12.10,
       Width =  6.00,
       HammerHeadStyle = 'Wrong!'
WHERE  EquipmentTag = 'HANDSAW';
GO

UPDATE Hardware.Equipment
SET    Length = 12.10,
       Width =  6.00
WHERE  EquipmentTag = 'POWERDRILL';
GO

UPDATE Hardware.Equipment
SET    Length = 8.40,
       Width =  2.00,
       HammerHeadStyle = 'Claw'
WHERE  EquipmentTag = 'CLAWHAMMER';
GO
SELECT EquipmentTag, EquipmentType, HammerHeadStyle ,Length,Width
FROM   Hardware.Equipment;
GO

SELECT name, is_sparse
FROM   sys.columns
WHERE  OBJECT_NAME(object_id) = 'Equipment'
GO

ALTER TABLE Hardware.Equipment
    DROP CONSTRAINT CHKEquipment$HammerHeadStyle;
ALTER TABLE Hardware.Equipment
    DROP COLUMN HammerHeadStyle, Length, Width;
GO

ALTER TABLE Hardware.Equipment
  ADD SparseColumns XML COLUMN_SET FOR ALL_SPARSE_COLUMNS;
GO

EXEC Hardware.Equipment$addProperty 'Length','numeric(10,2)',1;
EXEC Hardware.Equipment$addProperty 'Width','numeric(10,2)',1;
EXEC Hardware.Equipment$addProperty 'HammerHeadStyle','varchar(30)',1;
GO
ALTER TABLE Hardware.Equipment
 ADD CONSTRAINT CHKEquipment$HammerHeadStyle CHECK
        ((HammerHeadStyle is NULL AND EquipmentType <> 'Hammer')
        OR EquipmentType = 'Hammer');
GO

UPDATE Hardware.Equipment
SET    Length = 7,
       Width =  1
WHERE  EquipmentTag = 'HANDSAW';
GO

SELECT *
FROM   Hardware.Equipment;
GO
UPDATE Hardware.Equipment
SET    SparseColumns = '<Length>12.10</Length><Width>6.00</Width>'
WHERE  EquipmentTag = 'POWERDRILL';
GO
UPDATE Hardware.Equipment
SET    SparseColumns = '<Length>8.40</Length><Width>2.00</Width>
                        <HammerHeadStyle>Claw</HammerHeadStyle>'
WHERE  EquipmentTag = 'CLAWHAMMER';
GO

SELECT EquipmentTag, EquipmentType, HammerHeadStyle ,Length,Width
FROM   Hardware.Equipment;
GO

SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

