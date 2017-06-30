#****************************************
#* SSIS 2016 Cookbook Chapter 08 R Code *
#****************************************
  
  
#********************************************
#* Recipe 5: Creating a R data mining model *
#********************************************


# Install RODBC library
install.packages("RODBC");
# Load RODBC library
library(RODBC);


# Connect to AWDW
# AWDW system DSN created in advance
con <- odbcConnect("AWDW", uid="RUser", pwd="Pa$$w0rd");

# Read data
TM <- as.data.frame(sqlQuery(con, 
"SELECT CustomerKey, MaritalStatus, Gender,
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
 FROM dbo.TMTestSet;"),
 stringsAsFactors = TRUE);

# Close the connection
close(con);

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

# A quick plot of Education
plot(TM$Education, main = 'TM$Education',
     xlab='TM$Education', ylab ='Number of Cases',
     col="purple");

# Split the data to the training and test set
TMTrain <- TM[TM$TrainTest==1,];
TMTest <- TM[TM$TrainTest==2,];

# Naive Bayes
# Package e1071 (Naive Bayes)
install.packages("e1071", dependencies = TRUE);
library(e1071);

# Build the Naive Bayes model
TMNB <- naiveBayes(TMTrain[,2:11], TMTrain[,13]);

# Data frame with predictions for all rows
TM_PR <- as.data.frame(predict(
  TMNB, TMTest, type = "raw"));

# Combine original data with predictions
df_TM_PR <- cbind(TMTest[,-(2:12)], TM_PR);
# View the original data with the predictions
View(df_TM_PR);
