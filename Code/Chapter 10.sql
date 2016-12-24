---Indexing Overview
----Basic Index Structure
------On-Disk Indexes

-------Clustered Indexes

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   [Application].[Cities];
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   [Application].[Cities]
WHERE  CityID = 23629; --A favorite city of mine, indeed.
GO
SET SHOWPLAN_TEXT OFF

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   [Application].[Cities]
WHERE  CityID IN (23629,334);
GO
SET SHOWPLAN_TEXT OFF

SET STATISTICS IO ON;
GO
SELECT *
FROM   [Application].[Cities]
WHERE  CityID IN (23629,334);
GO
SET STATISTICS IO OFF


SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   [Application].[Cities]
WHERE  CityID > 0;
GO
SET SHOWPLAN_TEXT OFF

GO

-----Nonclustered Indexes


SELECT CONCAT(OBJECT_SCHEMA_NAME(i.object_id),'.',OBJECT_NAME(i.object_id)) AS object_name
      , CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END +
                i.TYPE_DESC AS index_type
      , i.name as index_name
      , user_seeks, user_scans, user_lookups,user_updates
FROM  sys.indexes AS i 
         LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s 
              ON i.object_id = s.object_id 
                AND i.index_id = s.index_id 
                AND database_id = DB_ID()
WHERE  OBJECTPROPERTY(i.object_id , 'IsUserTable') = 1 
ORDER  BY object_name, index_name;
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Application.Cities
WHERE  CityName = 'Nashville';
GO
SET SHOWPLAN_TEXT OFF
GO
CREATE INDEX CityName ON Application.Cities(CityName) ON USERDATA; 
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Application.Cities
WHERE  CityName = 'Nashville';
GO
SET SHOWPLAN_TEXT OFF
GO


------Determining Index Usefulness

DBCC SHOW_STATISTICS('Application.Cities', 'CityName') WITH DENSITY_VECTOR;
DBCC SHOW_STATISTICS('Application.Cities', 'CityName') WITH HISTOGRAM;
GO

--Used ISNULL as it is easier if the column can be null
--value you translate to should be impossible for the column
--ProductId is an identity with seed of 1 and increment of 1
--so this should be safe (unless a dba does something weird)
SELECT 1.0/ COUNT(DISTINCT ISNULL(CityName,'NotACity')) AS density,
            COUNT(DISTINCT ISNULL(CityName,'NotACity')) AS distinctRowCount,
            1.0/ COUNT(*) AS uniqueDensity,
            COUNT(*) AS allRowCount
FROM   Application.Cities;
GO


USE tempDB;
GO
CREATE SCHEMA demo;
GO
CREATE TABLE demo.testIndex
(
    testIndex int IDENTITY(1,1) CONSTRAINT PKtestIndex PRIMARY KEY,
    bitValue bit,
    filler char(2000) NOT NULL DEFAULT (REPLICATE('A',2000))
);
CREATE INDEX bitValue ON demo.testIndex(bitValue);
GO

SET NOCOUNT ON; --or you will get back 50100 1 row affected messages
INSERT INTO demo.testIndex(bitValue)
VALUES (0);
GO 50000 --runs current batch 50000 times in Management Studio.

INSERT INTO demo.testIndex(bitValue)
VALUES (1);
GO 100 --puts 100 rows into table with value 1

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   demo.testIndex
WHERE  bitValue = 0;
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   demo.testIndex
WHERE  bitValue = 1;
GO
SET SHOWPLAN_TEXT OFF
GO



UPDATE STATISTICS demo.testIndex;
DBCC SHOW_STATISTICS('demo.testIndex', 'bitValue')  WITH HISTOGRAM;
GO

CREATE INDEX bitValueOneOnly 
      ON testIndex(bitValue) WHERE bitValue = 1; 

DBCC SHOW_STATISTICS('demo.testIndex', 'bitValueOneOnly')  WITH HISTOGRAM;
GO

-----Indexing and Multiple Columns

USE WideWorldImporters;
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Application.Cities
WHERE  CityName = 'Nashville'
  AND  LatestRecordedPopulation = 601222; 
GO
SET SHOWPLAN_TEXT OFF
GO

SELECT CityName, LatestRecordedPopulation, COUNT(*) AS [count]
FROM   Application.Cities
GROUP BY CityName, LatestRecordedPopulation
ORDER BY CityName, LatestRecordedPopulation;
GO

SELECT COUNT(DISTINCT CityName) as CityName,
       SUM(CASE WHEN CityName IS NULL THEN 1 ELSE 0 END) as NULLCityName,
       COUNT(DISTINCT LatestRecordedPopulation) as LatestRecordedPopulation,
       SUM(CASE WHEN LatestRecordedPopulation IS NULL THEN 1 ELSE 0 END) 
                                                       AS NULLLatestRecordedPopulation
FROM   Application.Cities;
GO

CREATE INDEX CityNameAndLastRecordedPopulation
         ON Application.Cities (CityName, LatestRecordedPopulation);

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Application.Cities
WHERE  CityName = 'Nashville'
  AND  LatestRecordedPopulation = 601222; 
GO
SET SHOWPLAN_TEXT OFF
GO

-------covering indexes

SET SHOWPLAN_TEXT ON;
GO
SELECT CityName, LatestRecordedPopulation, LastEditedBy
FROM   Application.Cities;
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT CityName, LatestRecordedPopulation, LastEditedBy
FROM   Application.Cities;
GO
SET SHOWPLAN_TEXT OFF
GO


DROP INDEX CityNameAndLastRecordedPopulation
         ON Application.Cities;
GO

CREATE INDEX CityNameAndLastRecordedPopulation
         ON Application.Cities (CityName, LatestRecordedPopulation)
                 INCLUDE (LastEditedBy);
GO

SET SHOWPLAN_TEXT ON;
GO

SELECT CityName, LatestRecordedPopulation
FROM   Application.Cities; 
GO

SET SHOWPLAN_TEXT OFF;
GO

------Multiple Indexes
 
SET SHOWPLAN_TEXT ON;
GO
SELECT CityName, StateProvinceID
FROM   Application.Cities
WHERE  CityName = 'Nashville'
  AND  StateProvinceID = 44; 
GO
SET SHOWPLAN_TEXT OFF
GO

-------Sort Order of Index Keys

SET SHOWPLAN_TEXT ON;
GO
SELECT CityName, LatestRecordedPopulation
FROM   Application.Cities
ORDER BY CityName ASC, LatestRecordedPopulation DESC;
GO
SET SHOWPLAN_TEXT OFF
GO

DROP INDEX CityNameAndLastRecordedPopulation
         ON Application.Cities;

CREATE INDEX CityNameAndLastRecordedPopulation
         ON Application.Cities (CityName, LatestRecordedPopulation DESC)
                 INCLUDE (LastEditedBy); 


----Nonclustered Indexes on a Heap
SELECT *
INTO   Application.HeapCities
FROM   Application.Cities;
GO

ALTER TABLE Application.HeapCities
   ADD CONSTRAINT PKHeapCities PRIMARY KEY NONCLUSTERED (CityID);
GO

CREATE INDEX CityName ON Application.HeapCities(CityName) ON USERDATA;
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Application.HeapCities
WHERE  CityID = 23629;
GO
SET SHOWPLAN_TEXT OFF
GO




---Memory Optimized Indexes
------In-Memory OLTP Tables 
--------General Table Structure

USE WideWorldImporters
GO


SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Warehouse.VehicleTemperatures
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Warehouse.VehicleTemperatures
WHERE  VehicleTemperatureID = 2332;
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Warehouse.VehicleTemperatures
WHERE  VehicleTemperatureID <> 0;
GO
SET SHOWPLAN_TEXT OFF
GO

SET STATISTICS TIME ON;
GO
SELECT *
FROM   Warehouse.VehicleTemperatures
WHERE  VehicleTemperatureID <> 0;
GO
SET STATISTICS TIME OFF;
GO

SET STATISTICS TIME ON;
GO
SELECT *
FROM   Warehouse.VehicleTemperatures WITH (INDEX = 0)
WHERE  VehicleTemperatureID <> 0;
GO
SET STATISTICS TIME OFF;
GO

ALTER TABLE  Warehouse.VehicleTemperatures
 ADD INDEX RecordedWhen                             --33000 distinct values,
    HASH (RecordedWhen) WITH (BUCKET_COUNT = 64000) --values are in powers of 2


SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Warehouse.VehicleTemperatures
WHERE  RecordedWhen = '2016-03-10 12:50:22.0000000';
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Warehouse.VehicleTemperatures
WHERE  RecordedWhen BETWEEN '2016-03-10 12:50:22.0000000' AND '2016-03-10 12:50:22.0000000';
GO
SET SHOWPLAN_TEXT OFF
GO

-------Indexed Views

CREATE VIEW Warehouse.StockItemSalesTotals
WITH SCHEMABINDING
AS
SELECT StockItems.StockItemName,
                                 --ISNULL because expression can't be nullable
       SUM(OrderLines.Quantity * ISNULL(OrderLines.UnitPrice,0)) AS TotalSalesAmount,
       COUNT_BIG(*) AS TotalSalesCount--must use COUNT_BIG for indexed view
FROM  Warehouse.StockItems 
          JOIN Sales.OrderLines 
                 ON  OrderLines.StockItemID = StockItems.StockItemID
GROUP  BY StockItems.StockItemName;
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Warehouse.StockItemSalesTotals;
GO
SET SHOWPLAN_TEXT OFF
GO

CREATE UNIQUE CLUSTERED INDEX XPKStockItemSalesTotals on
                      Warehouse.StockItemSalesTotals(StockItemName);

SET SHOWPLAN_TEXT ON;
GO
SELECT *
FROM   Warehouse.StockItemSalesTotals;
GO
SET SHOWPLAN_TEXT OFF
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT StockItems.StockItemName,
       SUM(OrderLines.Quantity * ISNULL(OrderLines.UnitPrice,0)) / COUNT_BIG(*) AS AverageSaleAmount 
FROM  Warehouse.StockItems 
          JOIN Sales.OrderLines 
                 ON  OrderLines.StockItemID = StockItems.StockItemID
GROUP  BY StockItems.StockItemName;
GO
SET SHOWPLAN_TEXT OFF
GO

------Compression

USE Tempdb
GO
CREATE TABLE dbo.TestCompression
(
    TestCompressionId int,
    Value  int
) 
WITH (DATA_COMPRESSION = ROW) -- PAGE or NONE
    ALTER TABLE testCompression REBUILD WITH (DATA_COMPRESSION = PAGE);

CREATE CLUSTERED INDEX Value
   ON testCompression (Value) WITH ( DATA_COMPRESSION = ROW );

ALTER INDEX Value  ON testCompression REBUILD WITH ( DATA_COMPRESSION = PAGE );

--------Partitioning
USE WideWorldImporters
GO

SELECT YEAR(OrderDate), COUNT(*)
FROM Sales.Orders
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);

USE Tempdb;
GO
--Note that the PARTITON FUNCTION is not a schema owned object
CREATE PARTITION FUNCTION PartitionFunction$Dates (date)
AS RANGE LEFT FOR VALUES ('20140101','20150101');  
                  --set based on recent version of 
                  --WideWorldImporters.Sales.Orders table to show
                  --partition utilization
GO
CREATE PARTITION SCHEME PartitonScheme$dates
                AS PARTITION PartitionFunction$dates ALL to ( [PRIMARY] );
GO

CREATE TABLE dbo.Orders
(
    OrderId     int,
    CustomerId  int,
    OrderDate  date,
    CONSTRAINT PKOrder PRIMARY KEY NONCLUSTERED (OrderId) ON [Primary],
    CONSTRAINT AKOrder UNIQUE CLUSTERED (OrderId, OrderDate)
) ON PartitonScheme$dates (OrderDate);
GO

INSERT INTO dbo.Orders (OrderId, CustomerId, OrderDate)
SELECT OrderId, CustomerId, OrderDate
FROM  WideWorldImporters.Sales.Orders;
GO

SELECT *, $partition.PartitionFunction$dates(orderDate) as partiton
FROM   dbo.Orders;
GO

SELECT  partitions.partition_number, partitions.index_id, 
        partitions.rows, indexes.name, indexes.type_desc
FROM    sys.partitions as partitions
           JOIN sys.indexes as indexes
               on indexes.object_id = partitions.object_id
                   and indexes.index_id = partitions.index_id
WHERE   partitions.object_id = object_id('dbo.Orders');
GO


-----Index Dynamic Management View Queries
---Missing Indexes

SELECT ddmid.statement AS object_name, ddmid.equality_columns, ddmid.inequality_columns, 
       ddmid.included_columns,  ddmigs.user_seeks, ddmigs.user_scans, 
       ddmigs.last_user_seek, ddmigs.last_user_scan, ddmigs.avg_total_user_cost,
       ddmigs.avg_user_impact, ddmigs.unique_compiles 
FROM   sys.dm_db_missing_index_groups AS ddmig
         JOIN sys.dm_db_missing_index_group_stats AS ddmigs
                ON ddmig.index_group_handle = ddmigs.group_handle
         JOIN sys.dm_db_missing_index_details AS ddmid
                ON ddmid.index_handle = ddmig.index_handle
ORDER BY ((user_seeks + user_scans) * avg_total_user_cost * (avg_user_impact * 0.01)) DESC;
GO

----On-Disk Index Utilization Statistics
SELECT OBJECT_SCHEMA_NAME(indexes.object_id) + '.' +
       OBJECT_NAME(indexes.object_id) as objectName,
       indexes.name, 
       case when is_unique = 1 then 'UNIQUE ' 
              else '' end + indexes.type_desc as index_type, 
       ddius.user_seeks, ddius.user_scans, ddius.user_lookups, 
       ddius.user_updates, last_user_lookup, last_user_scan, last_user_seek,last_user_update
FROM   sys.indexes
          LEFT OUTER JOIN sys.dm_db_index_usage_stats ddius
               ON indexes.object_id = ddius.object_id
                   AND indexes.index_id = ddius.index_id
                   AND ddius.database_id = DB_ID()
ORDER  BY ddius.user_seeks + ddius.user_scans + ddius.user_lookups DESC;
GO

----Fragmentation
SELECT  s.[name] AS SchemaName,
        o.[name] AS TableName,
        i.[name] AS IndexName,
        f.[avg_fragmentation_in_percent] AS FragPercent,
        f.fragment_count ,
        f.forwarded_record_count --heap only
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, DEFAULT) f
        JOIN sys.indexes i 
             ON f.[object_id] = i.[object_id] AND f.[index_id] = i.[index_id]
        JOIN sys.objects o 
             ON i.[object_id] = o.[object_id]
        JOIN sys.schemas s 
             ON o.[schema_id] = s.[schema_id]
WHERE o.[is_ms_shipped] = 0
  AND i.[is_disabled] = 0; -- skip disabled indexes
GO

-----In-Memory OLTP Index Stats
SELECT OBJECT_SCHEMA_NAME(object_id) + '.' +
       OBJECT_NAME(object_id) AS objectName,
           memory_allocated_for_table_kb,memory_used_by_table_kb,
           memory_allocated_for_indexes_kb,memory_used_by_indexes_kb
FROM sys.dm_db_xtp_table_memory_stats;
SELECT OBJECT_SCHEMA_NAME(ddxis.object_id) + '.' +
       OBJECT_NAME(ddxis.object_id) AS objectName,
           ISNULL(indexes.name,'BaseTable') AS indexName, 
           scans_started, rows_returned, rows_touched, 
           rows_expiring, rows_expired,
           rows_expired_removed, phantom_scans_started --and several other phantom columns
FROM   sys.dm_db_xtp_index_stats AS ddxis
                 JOIN sys.indexes
                        ON indexes.index_id = ddxis.index_id
                          AND indexes.object_id = ddxis.object_id
GO
SELECT OBJECT_SCHEMA_NAME(ddxhis.object_id) + '.' +
       OBJECT_NAME(ddxhis.object_id) AS objectName,
           ISNULL(indexes.name,'BaseTable') AS indexName, 
           ddxhis.total_bucket_count, ddxhis.empty_bucket_count,
           ddxhis.avg_chain_length, ddxhis.max_chain_length
FROM   sys.dm_db_xtp_hash_index_stats ddxhis
                 JOIN sys.indexes
                        ON indexes.index_id = ddxhis.index_id
                          AND indexes.object_id = ddxhis.object_id
GO