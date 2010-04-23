@echo off

REM this is a windows batch file helper script: drop a MindMap file onto it and a CSV file will drop out

set OUTPUT_FILENAME="%CD%\SprintTasks.csv"


IF EXIST %OUTPUT_FILENAME% GOTO FileExists


:DoIt
cd /D %~dp0
type %1 | ccperl.exe "%~dp0MM2CSV.pl" > %OUTPUT_FILENAME%

IF ERRORLEVEL 1 GOTO End

echo Tasks written to %OUTPUT_FILENAME%

GOTO End


:FileExists
echo Warning: %OUTPUT_FILENAME% already exists
set /P OVERRIDE_OUTPUT_FILE=Enter "y" to override:

IF %OVERRIDE_OUTPUT_FILE%==y GOTO DoIt

echo You chose not to override file.

GOTO End


:End
pause
