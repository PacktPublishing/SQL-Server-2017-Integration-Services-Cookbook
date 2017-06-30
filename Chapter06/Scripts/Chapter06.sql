-- SSIS2016Cookbook_Chapter06

-- Change the context
USE SSISDB;
GO

/******************************************/
/* Using T-SQL to Execute an SSIS Package */
/******************************************/

-- Determine the environment reference id
DECLARE @reference_id INT

SET @reference_id = (
  SELECT environment_references.reference_id
      FROM catalog.folders
         INNER JOIN catalog.projects
          ON projects.folder_id = folders.folder_id
         INNER JOIN catalog.environment_references
          ON environment_references.project_id = projects.project_id
   WHERE (folders.name = N'CustomLogging')
         and (projects.name = N'CustomLogging')
         and (environment_references.environment_name = N'Chapter06')
 );

 -- Create the execution
DECLARE @execution_id BIGINT
EXEC catalog.create_execution
 @package_name = N'CustomLogging.dtsx',
 @execution_id = @execution_id OUTPUT,
 @folder_name = N'CustomLogging',
 @project_name = N'CustomLogging',
 @use32bitruntime = False,
 @reference_id = @reference_id;
PRINT @execution_id;

-- Set the logging level
DECLARE @logging_level SMALLINT;
SET @logging_level = 1;
EXEC catalog.set_execution_parameter_value
 @execution_id = @execution_id,
 @object_type = 50,
 @parameter_name = N'LOGGING_LEVEL',
 @parameter_value = @logging_level;

-- To execute the package synchronously, uncomment the following procedure call:
---- Set mode of operation
--DECLARE @is_synchronized BIT
--SET @is_synchronized = 1
--EXEC catalog.set_execution_parameter_value
-- @execution_id = @execution_id,
-- @object_type = 50,
-- @parameter_name = N'SYNCHRONIZED',
-- @parameter_value = @is_synchronized;

-- Start the execution
EXEC catalog.start_execution
 @execution_id = @execution_id;
GO



/**************************************/
/* Using the Cascading Lookup Pattern */
/**************************************/

USE AdventureWorks2014;
GO

-- Truncate Resolved Client
TRUNCATE TABLE	dbo.ResolvedClient;
GO

-- Person Lookup
SELECT CAST(Person.LastName + COALESCE(N' ' + Person.MiddleName, N'') + N', ' + Person.FirstName AS NVARCHAR(256)) as ClientName
       ,Person.BusinessEntityID AS BusinessEntityID
	   ,CAST(1 AS BIT) AS IsPerson
  FROM Person.Person;

-- Company Lookup
SELECT CAST(Vendor.Name AS NVARCHAR(256)) AS ClientName
       ,Vendor.BusinessEntityID AS BusinessEntityID
	   ,CAST(0 AS BIT) AS IsPerson
  FROM Purchasing.Vendor;

-- Check the results
SELECT ResolvedClient.IsPerson AS IsPerson
       ,COUNT(*) AS ClientCount
  FROM dbo.ResolvedClient
GROUP BY ResolvedClient.IsPerson
ORDER BY ClientCount DESC;


/**/

/* Lower Boundary expression
@[User::lowerBoundary]:= SUBSTRING( @[User::currentFileName] , FINDSTRING( @[User::currentFileName] , "_", 1) + 1 , 1 )
*/

/* Upper Boundary expression
@[User::upperBoundary] := SUBSTRING(@[User::currentFileName], FINDSTRING(@[User::currentFileName], "-", 1) + 1 , 1 ) + REPLICATE("Z", 255)
*/

/* Person Lookup Query Expression
@[User::personLookupQuery]:="SELECT *
 FROM
  (
  SELECT CAST(Person.LastName + COALESCE(N' ' + Person.MiddleName, N'') + N', ' + Person.FirstName AS NVARCHAR(256)) as ClientName
         ,Person.BusinessEntityID AS BusinessEntityID
         ,CAST(1 AS BIT) AS IsPerson
    FROM Person.Person
  ) RefTable
WHERE (RefTable.ClientName BETWEEN '" + @[User::lowerBoundary]  + "' AND '" + @[User::upperBoundary]  + "');"
*/
