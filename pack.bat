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
for /f "delims=;" %%i in ('dir "%backup_storage%\*.zip" /b/a-d/od/t:c') do set last_backup_file=%backup_storage%\%%i
echo The most recently created backup file is %last_backup_file%

rem determine size in bytes of the most recently created backup file in the storage
for %%I in ("%last_backup_file%") do set last_backup_size=%%~zI

rem create folder temp\merge
if not exist "%backup_temp%\merge" mkdir "%backup_temp%\merge"

rem merge created archives from temp folder into storage folder
set actual_backup_file=%backup_temp%\merge\%datestr%.zip
7za.exe a -tzip -mx0 "%actual_backup_file%" "%backup_temp%\pack\*.zip"

rem determine size in bytes of the newly merged backup
for %%I in ("%actual_backup_file%") do set actual_backup_size=%%~zI

@echo last backup file "%last_backup_file%" has size "%last_backup_size%" bytes
@echo actual backup file "%actual_backup_file%" has size "%actual_backup_size%" bytes

rem check if the size of newly created backup differs from the size of most recently backup

if "%last_backup_size%" NEQ "%actual_backup_size%" (
  @echo move actual backup file "%actual_backup_file%" to storage folder %backup_storage%
  move "%actual_backup_file%" "%backup_storage%"
) else (
  @echo actual backup file "%actual_backup_file%" seems to have same content to last backup file "%last_backup_file%", skip
)

rem clean-up temp
rd /s /q "%backup_temp%\pack"
rd /s /q "%backup_temp%\merge"

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

rem create folder temp\pack
if not exist "%backup_temp%\pack" mkdir "%backup_temp%\pack"

@echo on
@echo pack

7za.exe a -tzip -mx0 "%backup_temp%\pack\%archivename%.zip" "%folder%"

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


