@echo off

rem **************************************************************************************************************************************
rem ********************************************************** MODE check ****************************************************************
rem **************************************************************************************************************************************

if "%backup_temp%"=="" (
@echo on
@echo nothing to do, exit
exit
)

set folder=%1

rem **************************************************************************************************************************************
rem ************************************************************* MODE merge *************************************************************
rem **************************************************************************************************************************************

if "%folder%"=="merge" (

rem call procedure date_time_proc to format current date and time, save result into variable %datestr% and return to label :continue_merge
:continue_merge
if "%datestr%"=="" goto date_time_proc

rem determine the most recently created (newest) .zip file in the storage
for /f "delims=;" %%i in ('dir "%backup_storage%\*.zip" /b/a-d/od/t:c') do set last_backup_file=%%i
echo The most recently created backup file is %last_backup_file%

rem determine size in bytes of the most recently created backup file in the storage
for %%I in ("%backup_storage%\%last_backup_file%") do set last_backup_size=%%~zI

rem merge created archives from temp folder into storage folder
7za.exe a -tzip -mx0 "%backup_storage%\%datestr%.zip" "%backup_temp%\*.*"

rem determine size in bytes of the newly merged backup
for %%I in ("%backup_storage%\%datestr%.zip") do set actual_backup_size=%%~zI

@echo last backup file "%backup_storage%\%last_backup_file%" has size "%last_backup_size%" bytes
@echo actual backup file "%backup_storage%\%datestr%.zip" has size "%actual_backup_size%" bytes

rem check if the size of newly created backup not differs from the size of most recently backup OR this is the same file (first backup ever)
if "%last_backup_size%"=="%actual_backup_size%" if "%backup_storage%\%last_backup_file%" NEQ "%backup_storage%\%datestr%.zip"  (
  @echo actual backup file "%backup_storage%\%datestr%.zip" seems to have same content to last backup file "%backup_storage%\%last_backup_file%", delete
  del "%backup_storage%\%datestr%.zip"
)

rem clean-up temp
del "%backup_temp%\*.zip"

goto :eof
)

rem **************************************************************************************************************************************
rem **************************************************** MODE clean-up storage folder ****************************************************
rem **************************************************************************************************************************************

if "%folder%"=="cleanup" (
@echo clean-up storage

rem delete backups older than %storage_days%
@echo on
FORFILES /P %backup_storage% /D -%storage_days% /M *.zip /C "cmd /c echo delete @path"
FORFILES /P %backup_storage% /D -%storage_days% /M *.zip /C "cmd /c del @path"
@echo off

goto :eof
)

rem **************************************************************************************************************************************
rem ***************************************************** MAIN MODE do folder backup *****************************************************
rem **************************************************************************************************************************************

rem normalize folder name and make archive name
set archivename=%folder:\=_%
set archivename=%archivename:.=_%
set archivename=%archivename:$=_%
set archivename=%archivename::=_%

rem pack folder into temp folder
@echo on
@echo pack

7za.exe a -tzip -mx0 "%backup_temp%\%archivename%.zip" "%folder%"

@echo off
goto :eof

rem **************************************************************************************************************************************
rem ********************************* PROCEDURE format current date time with pattern "yyyy_mm_dd hh_mm" *********************************
rem **************************************************************************************************************************************
         
:date_time_proc

for /f "tokens=1-3 delims=. " %%i in ("%date%") do (
set day=%%i
set month=%%j
set year=%%k
)
for /f "tokens=1-2 delims=: " %%i in ("%time%") do (
     set hour=%%i
     set minute=%%j
)
set datestr=%year%_%month%_%day% %hour%_%minute%

goto continue_merge


