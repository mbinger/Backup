$silent_vbs_filename = "task_silent_launch.vbs"
$vbs_launcher = "wscript.exe"
$task_scheduler = "schtasks.exe"
$sevenZip = "7za.exe"

$sevenZipPath = [io.path]::combine($PSScriptRoot, $sevenZip)
$silent_vbs_path = [io.path]::combine($PSScriptRoot, $silent_vbs_filename)
$task_xml_path = [io.path]::combine($PSScriptRoot,"task.xml")
$target_path = [io.path]::combine($PSScriptRoot,"backup.ps1")
$task_name = "Binger\Backup PC"
$delete_task_bat = [io.path]::combine($PSScriptRoot,"task_delete.bat")

if ([string]::IsNullOrEmpty($env:UserDomain)) {
	$user_name = $env:ComputerName + "\" + $env:UserName
} else {
	$user_name = $env:UserDomain + "\" + $env:UserName
}

write-host "Check 7zip"

if (-not $(Test-Path ($sevenZipPath))) {
		write-warning "$sevenZipPath not found
please download console version from https://www.7-zip.org/ to be able to create password protected backups"
}


write-host "Current user is ""$user_name"""

$user_sid = (New-Object System.Security.Principal.NTAccount($user_name)).Translate([System.Security.Principal.SecurityIdentifier]).value
 
write-host "Current user SID is ""$user_sid"""
                                                                    
#################################### write vbs ####################################

write-host "Write out task silent launch script ""$silent_vbs_path"""

$stream = [System.IO.StreamWriter] $silent_vbs_path
$stream.WriteLine("
Dim WinScriptHost
Set WinScriptHost = CreateObject(""WScript.Shell"")
WinScriptHost.Run ""powershell.exe $target_path"", 0
Set WinScriptHost = Nothing
")
$stream.close()

#################################### write xml ####################################

write-host "Write out task XML definition ""$task_xml_path"""

$stream = [System.IO.StreamWriter] $task_xml_path
$stream.WriteLine("<?xml version=""1.0""?>
<Task version=""1.2"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">
  <RegistrationInfo>
    <Date>$($(get-date).ToString("yyyy-MM-ddTHH:mm:ss"))</Date>
    <Author>$user_name</Author>
    <URI>\$task_name</URI>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$($(get-date).ToString("yyyy-MM-dd"))T08:00:00</StartBoundary>
      <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id=""Author"">
      <UserId>$user_sid</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context=""Author"">
    <Exec>
      <Command>$vbs_launcher</Command>
      <Arguments>$silent_vbs_filename</Arguments>
      <WorkingDirectory>$PSScriptRoot</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
")
$stream.close()

################################ write delete bat #################################

write-host "Write out task unregister script ""$delete_task_bat"""

$stream = [System.IO.StreamWriter] $delete_task_bat
$stream.WriteLine("$task_scheduler /delete /tn ""$task_name""")
$stream.close()


################################## register task ##################################

write-host "Register task ""$task_name"""

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $task_scheduler
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = "/create /tn ""$task_name"" /XML ""$task_xml_path"""
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()

$standardError = ""
if ($p.StandardError -ne $null) {
	$standardError = $p.StandardError.ReadToEnd()
}

$standardOutput = ""
if ($p.StandardOutput -ne $null) {
	$standardOutput = $p.StandardOutput.ReadToEnd()
}

if ($p.ExitCode -eq "0") {
	if ([string]::IsNullOrEmpty($standardOutput)) {
		write-host "Task ""$task_name"" successfully created"
	} else {
		write-host $standardOutput
	}
} else {
	if ([string]::IsNullOrEmpty($standardError)) {
		write-error "Unable to create task ""$task_name"". The exit code is $($p.ExitCode)"
	} else {
		write-error $standardError
	}
}


write-host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');