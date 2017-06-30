@echo off
echo Deploying the CustomLogging SSIS project . . .
ISDeploymentWizard.exe /Silent /ModelType:Project /SourcePath:""C:\SSIS2016Cookbook\Chapter06\Files\CustomLogging.ispac"" /DestinationServer:"localhost" /DestinationPath:"/SSISDB/CustomLogging/CustomLogging"
pause
