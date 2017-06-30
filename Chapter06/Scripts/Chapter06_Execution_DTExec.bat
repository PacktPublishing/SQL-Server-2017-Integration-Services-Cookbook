@echo off
echo Executing CustomLogging.dtsx with environment_reference_id = 1 . . .
DTExec /Server localhost /ISServer "\SSISDB\CustomLogging\CustomLogging\CustomLogging.dtsx" /Env 1 /Par $ServerOption::LOGGING_LEVEL(Int32);1
pause