-- SSIS2016Cookbook_Chapter06_Preparation

USE	master;
GO

IF (NOT EXISTS (
  SELECT *
    FROM SSISDB.catalog.folders
   WHERE (folders.name = N'CustomLogging')
 ))
 BEGIN
  EXEC SSISDB.catalog.create_folder
   @folder_name = N'CustomLogging'
 END;
GO

IF (DB_ID(N'TestCustomLogging') IS NULL)
 BEGIN
  CREATE DATABASE TestCustomLogging;
 END;
GO

USE TestCustomLogging;
GO

IF (OBJECT_ID(N'CustomLogging') IS NOT NULL)
 BEGIN
  DROP TABLE CustomLogging
 END;
GO

CREATE TABLE CustomLogging
 (
 LogID INT
 );
 GO


USE AdventureWorks2014;
GO

IF (OBJECT_ID('dbo.ResolvedClient') IS NOT NULL)
 BEGIN
  DROP TABLE	dbo.ResolvedClient;
 END;

CREATE TABLE	dbo.ResolvedClient
 (
 ClientName NVARCHAR(256) NOT NULL,
 BusinessEntityID INT NULL,
 IsPerson BIT NULL,
 CONSTRAINT pk_dbo_ResolvedClient
 PRIMARY KEY CLUSTERED
  (
  ClientName
  )
 );
GO

CREATE UNIQUE NONCLUSTERED INDEX ux_dbo_ResolvedClient_BusinessEntityID
 ON dbo.ResolvedClient
  (
  BusinessEntityID
  )
 WHERE (BusinessEntityID IS NOT NULL);
 GO
