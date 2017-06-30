# Assign SSIS namespace to variable
$ssisNamespace = "Microsoft.SqlServer.Management.IntegrationServices"

# Load the SSIS Management Assembly
$assemblyLoad = [Reflection.Assembly]::Load($ssisNamespace + ", Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")

# Create a connection to a SQL Server instance
$connectionString = "Data Source=localhost;Initial Catalog=master;Integrated Security=SSPI;"
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

# Instantiate the SSIS object
$ssis = New-Object $ssisNamespace".IntegrationServices" $connection

# Instantiate the SSIS package
$catalog = $ssis.Catalogs["SSISDB"]
$folder = $catalog.Folders["CustomLogging"]
$project = $folder.Projects["CustomLogging"]
$package = $project.Packages[“CustomLogging.dtsx”]

# Assign environment
#$environment = 1

# Set package parameter(s)
$catalog.ServerLoggingLevel = [Microsoft.SqlServer.Management.IntegrationServices.Catalog+LoggingLevelType]::Basic
$catalog.Alter()

# Execute SSIS package
$executionId = $package.Execute()
