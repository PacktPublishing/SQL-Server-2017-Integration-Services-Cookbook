-- SSIS2016Cookbook_Chapter06_Configuration

USE	master;
GO

IF (NOT EXISTS (
  SELECT *
    FROM SSISDB.catalog.folders
         INNER JOIN SSISDB.catalog.environments
         ON environments.folder_id = folders.folder_id
   WHERE (folders.name = N'CustomLogging')
         and (environments.name = N'Chapter06')
 ))
 BEGIN
  EXEC SSISDB.catalog.create_environment
   @environment_name = N'Chapter06',
   @environment_description = N'',
   @folder_name = N'CustomLogging';
 END;
GO

DECLARE @var SQL_VARIANT
SET @var = N'Data Source=SSISCOOKBOOK;Initial Catalog=TestCustomLogging;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'
IF (NOT EXISTS (
  SELECT *
    FROM SSISDB.catalog.folders
         INNER JOIN SSISDB.catalog.environments
         ON environments.folder_id = folders.folder_id
         INNER JOIN SSISDB.catalog.environment_variables
         ON environment_variables.environment_id = environments.environment_id
   WHERE (folders.name = N'CustomLogging')
         AND (environments.name = N'Chapter06')
         AND (environment_variables.name = N'cmgr_TestCustomLogging_CS')
 ))
 BEGIN
  EXEC SSISDB.catalog.create_environment_variable
   @variable_name = N'cmgr_TestCustomLogging_CS',
   @sensitive = 0,
   @description = N'',
   @environment_name = N'Chapter06',
   @folder_name = N'CustomLogging',
   @value = @var,
   @data_type = N'String';
 END;
GO

DECLARE @reference_id INT
IF (NOT EXISTS (
  SELECT *
      FROM SSISDB.catalog.folders
         INNER JOIN SSISDB.catalog.projects
          ON projects.folder_id = folders.folder_id
         INNER JOIN SSISDB.catalog.environment_references
          ON environment_references.project_id = projects.project_id
   WHERE (folders.name = N'CustomLogging')
         and (projects.name = N'CustomLogging')
         and (environment_references.environment_name = N'Chapter06')
 ))
 BEGIN
  EXEC SSISDB.catalog.create_environment_reference
   @environment_name = N'Chapter06',
   @reference_id = @reference_id OUTPUT,
   @project_name = N'CustomLogging',
   @folder_name = N'CustomLogging',
   @reference_type = R;
 END;
GO

EXEC SSISDB.catalog.set_object_parameter_value
 @object_type = 30,
 @parameter_name = N'CM.cmgr_TestCustomLogging.ConnectionString',
 @object_name = N'CustomLogging.dtsx',
 @folder_name = N'CustomLogging',
 @project_name = N'CustomLogging',
 @value_type = R,
 @parameter_value = N'cmgr_TestCustomLogging_CS';
GO
