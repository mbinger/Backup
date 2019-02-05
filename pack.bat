@echo off
if "%backup_temp%"=="" (
@echo on
@echo nothing to do, exit
exit
)

set folder=%1

rem merge
if "%folder%"=="merge" (

:continue_merge
if "%datestr%"=="" goto date_time_proc

@echo determine the oldest file in the storage
for /f "delims=;" %%i in ('dir "%backup_storage%\*.zip" /b/a-d/od/t:c') do set last_backup_file=%%i
echo The most recently created backup file is %last_backup_file%

@echo determine the size of the oldest backup file in the storage
for %%I in ("%backup_storage%\%last_backup_file%") do set last_backup_size=%%~zI

@echo merge
7za.exe a -tzip -mx0 "%backup_storage%\%datestr%.zip" "%backup_temp%\*.*"

for %%I in ("%backup_storage%\%datestr%.zip") do set actual_backup_size=%%~zI

@echo last backup file "%backup_storage%\%last_backup_file%" has size "%last_backup_size%" bytes
@echo actual backup file "%backup_storage%\%datestr%.zip" has size "%actual_backup_size%" bytes

if "%last_backup_size%"=="%actual_backup_size%" if "%backup_storage%\%last_backup_file%" NEQ "%backup_storage%\%datestr%.zip"  (
  @echo actual backup file "%backup_storage%\%datestr%.zip" seems to have same content to last backup file "%backup_storage%\%last_backup_file%", delete
  del "%backup_storage%\%datestr%.zip"
)

@echo clean-up temp
del "%backup_temp%\*.zip"

goto :eof
)

rem clean-up storage
if "%folder%"=="cleanup" (
@echo clean-up storage

@echo on
FORFILES /P %backup_storage% /D -%storage_days% /M *.zip /C "cmd /c echo delete @path"
FORFILES /P %backup_storage% /D -%storage_days% /M *.zip /C "cmd /c del @path"
@echo off

goto :eof
)

rem normalize folder name and make archive name
set archivename=%folder:\=_%
set archivename=%archivename:.=_%
set archivename=%archivename:$=_%
set archivename=%archivename::=_%

@echo on
@echo pack

7za.exe a -tzip -mx0 "%backup_temp%\%archivename%.zip" "%folder%"

@echo off
goto :eof
         
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

echo %datestr%
goto continue_merge


