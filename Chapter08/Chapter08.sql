/********************************************/
/* SSIS 2016 Cookbook Chapter 08 T-SQL Code */
/********************************************/


/********************************************/
/* Recipe 5: Creating a R data mining model */
/********************************************/

-- Add Ruser
USE master;
GO
CREATE LOGIN RUser WITH PASSWORD=N'Pa$$w0rd';
GO
USE AdventureworksDW2014;
GO
CREATE USER RUser FOR LOGIN RUser;
GO
ALTER ROLE db_datareader ADD MEMBER RUser;
GO


/***************************************************/
/* Recipe 6: Using the R data mining model in SSIS */
/***************************************************/

-- Allow external scripts
USE master;
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE
EXEC sp_configure 'external scripts enabled', 1; 
RECONFIGURE;
GO


-- Install package e1071
-- Run as administrator R.exe R command prompt from the
-- C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\R_SERVICES\bin
-- folder and execute the following command:
-- install.packages("e1071");
-- q();


-- Use SQL Server data and analyze it in R
USE AdventureWorksDW2014;
EXECUTE sys.sp_execute_external_script
  @language = N'R'
 ,@script = N'
   # Education and Occupation are ordered
   TM$Education =
     factor(TM$Education, order=TRUE, 
            levels=c("Partial High School", 
                     "High School","Partial College",
                     "Bachelors", "Graduate Degree"));
   TM$Occupation =
     factor(TM$Occupation, order=TRUE,
            levels=c("Manual", "Skilled Manual",
                     "Professional", "Clerical",
                     "Management"));
   # Split the data to the training and test set
   TMTrain <- TM[TM$TrainTest==1,];
   TMTest <- TM[TM$TrainTest==2,];
   # Package e1071 (Naive Bayes)
   library(e1071);
   # Build the Naive Bayes model
   TMNB <- naiveBayes(TMTrain[,2:11], TMTrain[,13]);
   # Data frame with predictions for all rows
   TM_PR <- as.data.frame(predict(TMNB, TMTest, type = "raw"));
   # Combine original data with predictions
   df_TM_PR <- cbind(TMTest[,-(2:12)], TM_PR);'
 ,@input_data_1 = N'
   SELECT CustomerKey, MaritalStatus, Gender,
    TotalChildren, NumberChildrenAtHome,
    EnglishEducation AS Education,
    EnglishOccupation AS Occupation,
    HouseOwnerFlag, NumberCarsOwned, CommuteDistance,
    Region, TrainTest, BikeBuyer    
   FROM dbo.TMTrainingSet
   UNION
   SELECT CustomerKey, MaritalStatus, Gender,
    TotalChildren, NumberChildrenAtHome,
    EnglishEducation AS Education,
    EnglishOccupation AS Occupation,
    HouseOwnerFlag, NumberCarsOwned, CommuteDistance,
    Region, TrainTest, BikeBuyer
   FROM dbo.TMTestSet;'
 ,@input_data_1_name =  N'TM'
 ,@output_data_1_name = N'df_TM_PR'
WITH RESULT SETS 
(
 ("CustomerKey"             INT   NOT NULL,
  "BikeBuyer"               INT   NOT NULL,
  "Predicted_0_Probability" FLOAT NOT NULL, 
  "Predicted_1_Probability" FLOAT NOT NULL)
);
GO


/******************************************************************************/
/* Recipe 7: Text mining with Term Extraction and Term Lookup transformations */
/******************************************************************************/

-- Checking the results of the TermExtactionLookup package
USE AdventureWorksDW2014
GO
SELECT *
FROM dbo.Blogs;
SELECT *
FROM dbo.Terms;
SELECT * 
FROM dbo.TermsInBlogs;
GO


-- Clean up
USE AdventureWorksDW2014;
DROP TABLE IF EXISTS dbo.Blogs;
DROP TABLE IF EXISTS dbo.Terms;
DROP TABLE IF EXISTS dbo.TermsInBlogs;
DROP TABLE IF EXISTS dbo.TMTrainingSet;
DROP TABLE IF EXISTS dbo.TMTestSet;
DROP USER RUser;
USE master;
DROP LOGIN RUser;
GO
