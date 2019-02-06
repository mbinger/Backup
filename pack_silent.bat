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
rem ************************************************************ MODE prepare ************************************************************
rem **************************************************************************************************************************************

if "%folder%"=="prepare" (

rem clean-up temp
if exist "%backup_temp%\copy" rd /s /q "%backup_temp%\copy"
if exist "%backup_temp%\merge" rd /s /q "%backup_temp%\merge"
goto :eof
)

rem **************************************************************************************************************************************
rem ************************************************************* MODE merge *************************************************************
rem **************************************************************************************************************************************

if "%folder%"=="merge" (

@echo merge

rem call procedure delete_ignored_files_proc to delete ignored files, fill variable %maximal_file_size_bytes% and return to label :continue_merge_1
:continue_merge_1
if "%maximal_file_size_bytes%"=="" goto delete_ignored_files_proc

rem call procedure date_time_proc to format current date and time, save result into variable %datestr% and return to label :continue_merge_2
:continue_merge_2
if "%datestr%"=="" goto date_time_proc

rem determine the most recently created (newest) .zip file in the storage
for /f "delims=;" %%i in ('dir "%backup_storage%\*.zip" /b/a-d/od/t:c') do set last_backup_file=%backup_storage%\%%i
echo Last backup file is %last_backup_file%

rem determine size in bytes of the most recently created backup file in the storage
for %%I in ("%last_backup_file%") do set last_backup_size=%%~zI

@echo last backup file "%last_backup_file%" has size "%last_backup_size%" bytes

rem create folder temp\merge
if not exist "%backup_temp%\merge" mkdir "%backup_temp%\merge"

rem merge created archives from temp folder into storage folder

set actual_backup_file=%backup_temp%\merge\%datestr%.zip
@echo pack files into %actual_backup_file% 
7za.exe a -tzip "%actual_backup_file%" "%backup_temp%\copy\*"

rem determine size in bytes of the newly merged backup
for %%I in ("%actual_backup_file%") do set actual_backup_size=%%~zI

@echo actual backup file "%actual_backup_file%" has size "%actual_backup_size%" bytes

rem check if the size of newly created backup differs from the size of most recently backup

if "%last_backup_size%" NEQ "%actual_backup_size%" (
  @echo move actual backup file "%actual_backup_file%" to storage folder %backup_storage%
  move "%actual_backup_file%" "%backup_storage%"
) else (
  @echo actual backup file "%actual_backup_file%" seems to have same content to last backup file "%last_backup_file%", skip
)

rem clean-up temp
if exist "%backup_temp%\copy" rd /s /q "%backup_temp%\copy"
if exist "%backup_temp%\merge" rd /s /q "%backup_temp%\merge"
goto :eof
)

rem **************************************************************************************************************************************
rem **************************************************** MODE clean-up storage folder ****************************************************
rem **************************************************************************************************************************************

if "%folder%"=="cleanup" (
@echo clean-up storage

@echo delete backups older than %storage_days% days
@echo on
FORFILES /P %backup_storage% /D -%storage_days% /M *.zip /C "cmd /c del @path /f /q"
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

if not exist "%backup_temp%\copy" mkdir "%backup_temp%\copy"
if not exist "%backup_temp%\copy\%archivename%" mkdir "%backup_temp%\copy\%archivename%"

rem recursively copy sorce folder into temp\copy

@echo copy "%folder%" into "%backup_temp%\copy\%archivename%"
xcopy "%folder%" "%backup_temp%\copy\%archivename%" /s /e /q /h /r /c 

goto :eof

rem **************************************************************************************************************************************
rem ************************************ PROCEDURE delete files with ignored extensions and huge size ************************************
rem **************************************************************************************************************************************

:delete_ignored_files_proc

@echo delete files larger than %maximal_file_size_mb% MB or with extensions %ignore_extensions%

set /a maximal_file_size_bytes=maximal_file_size_mb*1024*1024

rem enumerate all files and folders in temp\copy
for /f "delims=;" %%i in ('dir /s/b "%backup_temp%\copy\*.*"') do (
	rem check the path is a file
	if not exist "%%i\*" (
		
		if %%~zi gtr %maximal_file_size_bytes% ( 
			@echo delete "%%i" because its size "%%~zi" is too large
			del "%%i" /f /q
		)

		rem enumerate all ignored extensions
		for %%e in (%ignore_extensions%) do (
			if "%%~xi"==".%%e" (
				@echo delete "%%i" because its extension is ignored
				del "%%i" /f /q
			)
		)
	)
)

goto continue_merge_1

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

goto continue_merge_2


