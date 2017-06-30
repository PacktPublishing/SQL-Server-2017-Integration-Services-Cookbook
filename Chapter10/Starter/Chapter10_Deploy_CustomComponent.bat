@echo off
copy "C:\SSIS2016Cookbook\Chapter10\Starter\SSISCustomization\SSISCustomComponents\bin\Release\SSISCustomComponents.dll" "C:\Program Files\Microsoft SQL Server\130\DTS\PipelineComponents\" /y
copy "C:\SSIS2016Cookbook\Chapter10\Starter\SSISCustomization\SSISCustomComponents\bin\Release\SSISCustomComponents.dll" "C:\Program Files (x86)\Microsoft SQL Server\130\DTS\PipelineComponents\" /y

"C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\gacutil.exe" /if "C:\Program Files (x86)\Microsoft SQL Server\130\DTS\PipelineComponents\SSISCustomComponents.dll"

pause
