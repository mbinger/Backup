param (
	[string]$target = ""
)

if ($log -eq $true) {
	$log_file = [io.path]::combine($backup_temp, "log.txt")
	
	if ($global:outputStream -eq $null) {
		$global:outputStream = [System.IO.StreamWriter] $log_file
		$datestr = $(get-date).ToString("dd.MM.yyyy HH:mm:ss")
		$global:outputStream.WriteLine($dateStr)
	}
}	

.\pack_silent.ps1 -target $target $global:outputStream


if ($log -eq $true) {
	if ($target -eq "merge") {
		$global:outputStream.close()
		$global:outputStream = $null
		$log_file_storage = [io.path]::combine($backup_storage, "log.txt")
		move-item -Path $log_file -Destination $log_file_storage -Force
	}
}	
