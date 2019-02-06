@echo off

if "%log%"=="on" (

	if "%1"=="prepare" (
		@echo %date% %time%>"%backup_temp%\log.txt"
	)

call pack_silent %1>>"%backup_temp%\log.txt"

if "%1"=="cleanup" move "%backup_temp%\log.txt" "%backup_storage%"

)else (
call pack_silent %1
)
