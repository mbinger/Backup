@echo off

set silent_vbs_filename=task_silent_launch.vbs
set vbs_launcher=wscript.exe
set task_scheduler=schtasks.exe
set sevenZip=7za.exe
set mypath=%~dp0
set target=backup.bat

rem normalize path
if {%mypath:~-1,1%} neq {\} set mypath=%mypath%\

set sevenZipPath=%mypath%%sevenZip%
set silent_vbs_path=%mypath%%silent_vbs_filename%
set task_xml_path=%mypath%task.xml
set target_path=%mypath%%target%
set task_name=Binger\Backup PC
set delete_task_bat=%mypath%task_delete.bat
set create_task_bat=%mypath%task_create.bat

rem get date time

for /f "tokens=1-3 delims=. " %%i in ("%date%") do (
set day=%%i
set month=%%j
set year=%%k
)
for /f "tokens=1-2 delims=: " %%i in ("%time%") do (
     set hour=%%i
     set minute=%%j
)
echo Today is %day%.%month%.%year% %hour%:%minute%

rem check 7zip

if not exist "%sevenZipPath%" (
	echo %sevenZipPath% not found
	echo please download console version from https://www.7-zip.org/ to be able to create password protected backups
)

rem get current user

if "%USERDOMAIN%"=="" (
	set user_name=%COMPUTERNAME%\%USERNAME%
) else (
	set user_name=%USERDOMAIN%\%USERNAME%
)

echo Current user name is "%user_name%"

for /f tokens^=3^ delims^=^" %%a in (
    'whoami /user /FO CSV /NH') do set user_sid=%%a

echo Current user SID is "%user_sid%"

rem #################################### write vbs ####################################
echo Write out task silent launch script "%silent_vbs_path%"

>%silent_vbs_path% echo Dim WinScriptHost
>>%silent_vbs_path% echo Set WinScriptHost = CreateObject("WScript.Shell")
>>%silent_vbs_path% echo WinScriptHost.Run Chr(34) ^& "%target%" ^& Chr(34), 0
>>%silent_vbs_path% echo Set WinScriptHost = Nothing

rem #################################### write xml ####################################
echo Write out task XML definition "%task_xml_path%"

>%task_xml_path% echo ^<?xml version="1.0"?^>
>>%task_xml_path% echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
>>%task_xml_path% echo   ^<RegistrationInfo^>
>>%task_xml_path% echo     ^<Date^>%year%-%month%-%day%T%hour%:%minute%:00^</Date^>
>>%task_xml_path% echo     ^<Author^>%user_name%^</Author^>
>>%task_xml_path% echo     ^<URI^>\%task_name%^</URI^>
>>%task_xml_path% echo   ^</RegistrationInfo^>
>>%task_xml_path% echo   ^<Triggers^>
>>%task_xml_path% echo     ^<CalendarTrigger^>
>>%task_xml_path% echo       ^<StartBoundary^>%year%-%month%-%day%T08:00:00^</StartBoundary^>
>>%task_xml_path% echo       ^<ExecutionTimeLimit^>PT2H^</ExecutionTimeLimit^>
>>%task_xml_path% echo       ^<Enabled^>true^</Enabled^>
>>%task_xml_path% echo       ^<ScheduleByDay^>
>>%task_xml_path% echo         ^<DaysInterval^>1^</DaysInterval^>
>>%task_xml_path% echo       ^</ScheduleByDay^>
>>%task_xml_path% echo     ^</CalendarTrigger^>
>>%task_xml_path% echo   ^</Triggers^>
>>%task_xml_path% echo   ^<Principals^>
>>%task_xml_path% echo     ^<Principal id="Author"^>
>>%task_xml_path% echo       ^<UserId^>%user_sid%^</UserId^>
>>%task_xml_path% echo       ^<LogonType^>InteractiveToken^</LogonType^>
>>%task_xml_path% echo       ^<RunLevel^>LeastPrivilege^</RunLevel^>
>>%task_xml_path% echo     ^</Principal^>
>>%task_xml_path% echo   ^</Principals^>
>>%task_xml_path% echo   ^<Settings^>
>>%task_xml_path% echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
>>%task_xml_path% echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
>>%task_xml_path% echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
>>%task_xml_path% echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^>
>>%task_xml_path% echo     ^<StartWhenAvailable^>true^</StartWhenAvailable^>
>>%task_xml_path% echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
>>%task_xml_path% echo     ^<IdleSettings^>
>>%task_xml_path% echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
>>%task_xml_path% echo       ^<RestartOnIdle^>false^</RestartOnIdle^>
>>%task_xml_path% echo     ^</IdleSettings^>
>>%task_xml_path% echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^>
>>%task_xml_path% echo     ^<Enabled^>true^</Enabled^>
>>%task_xml_path% echo     ^<Hidden^>false^</Hidden^>
>>%task_xml_path% echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^>
>>%task_xml_path% echo     ^<WakeToRun^>false^</WakeToRun^>
>>%task_xml_path% echo     ^<ExecutionTimeLimit^>PT2H^</ExecutionTimeLimit^>
>>%task_xml_path% echo     ^<Priority^>7^</Priority^>
>>%task_xml_path% echo   ^</Settings^>
>>%task_xml_path% echo   ^<Actions Context="Author"^>
>>%task_xml_path% echo     ^<Exec^>
>>%task_xml_path% echo       ^<Command^>%vbs_launcher%^</Command^>
>>%task_xml_path% echo       ^<Arguments^>%silent_vbs_filename%^</Arguments^>
>>%task_xml_path% echo       ^<WorkingDirectory^>%mypath%^</WorkingDirectory^>
>>%task_xml_path% echo     ^</Exec^>
>>%task_xml_path% echo   ^</Actions^>
>>%task_xml_path% echo ^</Task^>

rem ################################ write delete bat #################################
echo Write out task unregister script "%delete_task_bat%"

>%delete_task_bat% echo %task_scheduler% /delete /tn "%task_name%"

rem ################################ write create bat #################################
echo Write out task register script "%create_task_bat%"

>%create_task_bat% echo %task_scheduler% /create /tn "%task_name%" /XML "%task_xml_path%"

rem ################################### create task ###################################
echo Create Task "%task_name%"
call %create_task_bat%

echo Done