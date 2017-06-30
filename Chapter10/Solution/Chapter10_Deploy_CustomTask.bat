@echo off
copy "C:\SSIS2016Cookbook\Chapter10\Solution\SSISCustomization\SSISCustomTasks\bin\Release\SSISCustomTasks.dll" "C:\Program Files\Microsoft SQL Server\130\DTS\Tasks\" /y
copy "C:\SSIS2016Cookbook\Chapter10\Solution\SSISCustomization\SSISCustomTasks\bin\Release\SSISCustomTasks.dll" "C:\Program Files (x86)\Microsoft SQL Server\130\DTS\Tasks\" /y

"C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\gacutil.exe" /if "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
"C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\gacutil.exe" /if "C:\Program Files (x86)\Microsoft SQL Server\130\DTS\Tasks\SSISCustomTasks.dll"

pause
