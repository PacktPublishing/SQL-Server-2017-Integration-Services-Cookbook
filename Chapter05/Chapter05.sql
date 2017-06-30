/********************************************/
/* SSIS 2016 Cookbook Chapter 05 T-SQL Code */
/********************************************/


/**************************************/
/* Recipe 1: Profiling data with SSIS */
/**************************************/

-- Restoring the AdventureWorksDW2014 database
USE master;
RESTORE DATABASE AdventureWorksDW2014
 FROM  DISK = N'C:\SSIS2016Cookbook\AdventureWorksDW2014.bak' 
 WITH  FILE = 1,  
 MOVE N'AdventureWorksDW2014_Data'
  TO N'C:\SSIS2016Cookbook\AdventureWorksDW2014_Data.mdf',  
 MOVE N'AdventureWorksDW2014_Log'
  TO N'C:\SSIS2016Cookbook\AdventureWorksDW2014_Log.ldf',  
 STATS = 5;
GO

-- Preparing data for the Data Profiling task
USE AdventureWorksDW2014;
SELECT CustomerKey, FirstName,
 MiddleName, LastName,
 EmailAddress, MaritalStatus,
 Gender, TotalChildren, NumberChildrenAtHome,
 EnglishEducation AS Education,
 EnglishOccupation AS Occupation,
 HouseOwnerFlag, NumberCarsOwned,
 CommuteDistance, Region,
 BikeBuyer, YearlyIncome, 
 Age - 10 AS Age
INTO dbo.Chapter05Profiling
FROM dbo.vTargetMail;
GO


/*******************************************/
/* Recipe 2: Creating a DQS knowledge base */
/*******************************************/

-- Preparing data for the DQS KB
USE AdventureWorksDW2014;
SELECT DISTINCT
 City, StateProvinceName AS StateProvince,
 EnglishCountryRegionName AS CountryRegion
INTO dbo.AWCitiesStatesCountries
FROM dbo.DimGeography;
GO


/*************************************/
/* Recipe 3: Data Cleansing with DQS */
/*************************************/

-- Preparing the clean data
USE DQS_STAGING_DATA;
SELECT C.CustomerKey,
 C.FirstName + ' ' + c.LastName AS FullName,
 C.AddressLine1 AS StreetAddress,
 G.City, G.StateProvinceName AS StateProvince,
 G.EnglishCountryRegionName AS CountryRegion,
 C.EmailAddress, C.BirthDate, 
 C.EnglishOccupation AS Occupation
INTO dbo.CustomersCh05
FROM AdventureWorksDW2014.dbo.DimCustomer AS C
 INNER JOIN AdventureWorksDW2014.dbo.DimGeography AS G
  ON C.GeographyKey = G.GeographyKey
WHERE C.CustomerKey % 10 = 0;
GO

-- Adding the dirty data
USE DQS_STAGING_DATA;
SELECT CustomerKey, FullName,
 StreetAddress, City,
 StateProvince, CountryRegion,
 EmailAddress, BirthDate,
 Occupation
INTO dbo.CustomersCh05DQS
FROM dbo.CustomersCh05
UNION
SELECT -11000,
 N'Jon Yang',
 N'3761 N. 14th St',
 N'Munich',                        -- incorrect city
 N'Kingsland',                     -- incorrect state
 N'Austria',                       -- incorrect country
 N'jon24#adventure-works.com',     -- incorrect email
 '18900224',                       -- incorrect birth date
 'Profesional'                     -- incorrect occupation
UNION
SELECT -11100,
 N'Jacquelyn Suarez',
 N'7800 Corrinne Ct.',             -- incorrect term
 N'Muenchen',                      -- another incorrect city
 N'Queensland',
 N'Australia',                  
 N'jacquelyn20@adventure-works.com', 
 '19680206',                   
 'Professional';
GO

/*******************************/
/* Recipe 5: Matching with DQS */
/*******************************/

-- Preparing the clean data table
USE DQS_STAGING_DATA;
CREATE TABLE dbo.CustomersClean
(
 CustomerKey   INT           NOT NULL PRIMARY KEY,
 FullName      NVARCHAR(200) NULL,
 StreetAddress NVARCHAR(200) NULL
);
GO
-- Populating the clean data table
INSERT INTO dbo.CustomersClean
 (CustomerKey, FullName, StreetAddress)
SELECT CustomerKey,
 FirstName + ' ' + LastName AS FullName,
 AddressLine1 AS StreetAddress
FROM AdventureWorksDW2014.dbo.DimCustomer
WHERE CustomerKey % 10 = 0;
GO        

-- Creating and populating the table for dirty data
CREATE TABLE dbo.CustomersDirty
(
 CustomerKey      INT           NOT NULL PRIMARY KEY,
 FullName         NVARCHAR(200) NULL,
 StreetAddress    NVARCHAR(200) NULL,
 Updated          INT           NULL,
 CleanCustomerKey INT           NULL
);
GO
INSERT INTO dbo.CustomersDirty
 (CustomerKey, FullName, StreetAddress, Updated)
SELECT CustomerKey * (-1) AS CustomerKey,
 FirstName + ' ' + LastName AS FullName,
 AddressLine1 AS StreetAddress,
 0 AS Updated
FROM AdventureWorksDW2014.dbo.DimCustomer
WHERE CustomerKey % 10 = 0;
GO   

-- Making random changes in the dirty table
DECLARE @i AS INT = 0, @j AS INT = 0;
WHILE (@i < 3)      -- loop more times for more changes
BEGIN
 SET @i += 1;
 SET @j = @i - 2;   -- control here in which step you want to update
                    -- only already updated rows
 WITH RandomNumbersCTE AS
 (
  SELECT  CustomerKey
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber1
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber2  
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber3                      
         ,FullName
         ,StreetAddress
         ,Updated
    FROM dbo.CustomersDirty 
 )    
 UPDATE RandomNumbersCTE SET
         FullName =
         STUFF(FullName,
               CAST(CEILING(RandomNumber1 * LEN(FullName)) AS INT),
               1,
               CHAR(CEILING(RandomNumber2 * 26) + 96))
        ,StreetAddress = 
         STUFF(StreetAddress,
               CAST(CEILING(RandomNumber1 * LEN(StreetAddress)) AS INT),
               2, '')                              
        ,Updated = Updated + 1
  WHERE RAND(CHECKSUM(NEWID()) % 1000000000 - CustomerKey) < 0.17
        AND Updated > @j;
 WITH RandomNumbersCTE AS
 (
  SELECT  CustomerKey
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber1
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber2 
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber3                   
         ,FullName
         ,StreetAddress
		 ,Updated
    FROM dbo.CustomersDirty 
 )    
 UPDATE RandomNumbersCTE SET
         FullName =
         STUFF(FullName, CAST(CEILING(RandomNumber1 * LEN(FullName)) AS INT),
               0,
               CHAR(CEILING(RandomNumber2 * 26) + 96))
        ,StreetAddress = 
         STUFF(StreetAddress,
               CAST(CEILING(RandomNumber1 * LEN(StreetAddress)) AS INT),
               2,
               CHAR(CEILING(RandomNumber2 * 26) + 96) + 
               CHAR(CEILING(RandomNumber3 * 26) + 96))  
        ,Updated = Updated + 1                                                               
  WHERE RAND(CHECKSUM(NEWID()) % 1000000000 - CustomerKey) < 0.17
        AND Updated > @j;
 WITH RandomNumbersCTE AS
 (
  SELECT  CustomerKey
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber1
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber2 
         ,RAND(CHECKSUM(NEWID()) % 1000000000 + CustomerKey) AS RandomNumber3                   
         ,FullName
         ,StreetAddress
         ,Updated
    FROM dbo.CustomersDirty
 )    
 UPDATE RandomNumbersCTE SET
         FullName =
         STUFF(FullName,
               CAST(CEILING(RandomNumber1 * LEN(FullName)) AS INT),
               1, '')
        ,StreetAddress = 
         STUFF(StreetAddress,
               CAST(CEILING(RandomNumber1 * LEN(StreetAddress)) AS INT),
               0,
               CHAR(CEILING(RandomNumber2 * 26) + 96) + 
               CHAR(CEILING(RandomNumber3 * 26) + 96))                           
        ,Updated = Updated + 1               
  WHERE RAND(CHECKSUM(NEWID()) % 1000000000 - CustomerKey) < 0.16
        AND Updated > @j;
END;
GO

-- Checking the data after changes
SELECT  C.FullName
       ,D.FullName
       ,C.StreetAddress
       ,D.StreetAddress
       ,D.Updated
  FROM dbo.CustomersClean AS C
       INNER JOIN dbo.CustomersDirty AS D
        ON C.CustomerKey = D.CustomerKey * (-1)
 WHERE C.FullName <> D.FullName
       OR C.StreetAddress <> D.StreetAddress
ORDER BY D.Updated DESC;
GO       

-- Table for exact matches of the Lookup transformation
CREATE TABLE dbo.CustomersDirtyMatch
(
 CustomerKey              INT            NOT NULL PRIMARY KEY,
 FullName                 NVARCHAR(200)  NULL,
 StreetAddress            NVARCHAR(200)  NULL,
 Updated                  INT            NULL,
 CleanCustomerKey         INT            NULL
);
GO

-- Table for no matches of the Lookup transformation
CREATE TABLE dbo.CustomersDirtyNoMatch
(
 CustomerKey              INT            NOT NULL PRIMARY KEY,
 FullName                 NVARCHAR(200)  NULL,
 StreetAddress            NVARCHAR(200)  NULL,
 Updated                  INT            NULL,
 CleanCustomerKey         INT            NULL
);
GO

-- Creating a table for DQS matching
USE DQS_STAGING_DATA;
GO
SELECT CustomerKey, FullName, StreetAddress
INTO dbo.CustomersDQSMatch
FROM dbo.CustomersClean
UNION
SELECT CustomerKey, FullName, StreetAddress 
FROM dbo.CustomersDirtyNoMatch;
GO


/*****************************************/
/* Recipe 6: Using SSIS fuzzy components */
/*****************************************/

-- Preparing the table for fuzzy matches
CREATE TABLE dbo.FuzzyMatchingResults 
(
 CustomerKey              INT NOT NULL PRIMARY KEY,
 FullName                 NVARCHAR(200)  NULL,
 StreetAddress            NVARCHAR(200)  NULL,
 Updated                  INT            NULL,
 CleanCustomerKey         INT            NULL
);
GO

-- Truncate the destination tables
TRUNCATE TABLE dbo.CustomersDirtyMatch;
TRUNCATE TABLE dbo.CustomersDirtyNoMatch;
TRUNCATE TABLE dbo.FuzzyMatchingResults;
GO

-- Check the Fuzy Lookup results
-- Not matched
SELECT * FROM FuzzyMatchingResults
WHERE CleanCustomerKey IS NULL;
-- Incorrect matches
SELECT * FROM FuzzyMatchingResults
WHERE CleanCustomerKey <> CustomerKey * (-1);
GO


-- Clean up
USE AdventureWorksDW2014;
DROP TABLE IF EXISTS dbo.Chapter05Profiling;
DROP TABLE IF EXISTS dbo.AWCitiesStatesCountries;
USE DQS_STAGING_DATA;
DROP TABLE IF EXISTS dbo.CustomersCh05;
DROP TABLE IF EXISTS dbo.CustomersCh05DQS;
DROP TABLE IF EXISTS dbo.CustomersClean;
DROP TABLE IF EXISTS dbo.CustomersDirty;
DROP TABLE IF EXISTS dbo.CustomersDirtyMatch;
DROP TABLE IF EXISTS dbo.CustomersDirtyNoMatch;
DROP TABLE IF EXISTS dbo.CustomersDQSMatch;
DROP TABLE IF EXISTS dbo.DQSMatchingResults;
DROP TABLE IF EXISTS dbo.DQSSurvivorshipResults;
DROP TABLE IF EXISTS dbo.FuzzyMatchingResults;
GO