:setvar OnPremRebuilddB Yes
use master

if '$(OnPremRebuildDb)' = 'Yes' 
	--drop db if you are recreating it, dropping all connections to existing database.
	if exists (select * from sys.databases where name = 'ConferenceMessaging')
		exec ('
	alter database  ConferenceMessaging
		set single_user with rollback immediate;

	drop database ConferenceMessaging;')
go
if not exists (select * from sys.databases where name = 'ConferenceMessaging')
	CREATE DATABASE ConferenceMessaging 
		-- ON  
		-- PRIMARY ( NAME = N'ConferenceMessaging', FILENAME = N'C:\SQL\DATA\ConferenceMessaging.mdf' ,
		--	    SIZE = 1024MB , MAXSIZE = 1024MB)
		--LOG ON 
		--	 ( NAME = N'ConferenceMessaging_log', FILENAME = N'C:\SQL\LOG\ConferenceMessaging_log.ldf' ,
		--	   SIZE = 100MB , MAXSIZE = 2048GB , FILEGROWTH = 100MB);
GO
use ConferenceMessaging

select *
from   sys.master_files
where  database_id = db_id()

ALTER AUTHORIZATION ON Database::ConferenceMessaging to SA;

