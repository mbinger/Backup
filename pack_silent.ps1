param (
	[string]$target = "",
	[System.IO.StreamWriter]$outputstream = $null
)

###################################################################### Setup variables #######################################################################

$backup_temp_copy = [io.path]::combine($backup_temp, "copy")
$backup_temp_merge = [io.path]::combine($backup_temp, "merge")

$backup_format_zip = "zip"
$backup_format_7z = "7z"
$backup_extensions = @($backup_format_zip, $backup_format_7z)
$sevenZip = "7za.exe"

########################################################################### Check ############################################################################
function writeln ([String] $message) {
	
	if ($outputstream -ne $null) {
		$outputstream.WriteLine($message)
	}
	
	write-host $message
}

function check {
	if ([string]::IsNullOrEmpty($target)) {
		writeln "ERROR: Run backup.ps1 to start the backup"
		exit 1
	}
}

########################################################################### Prepare ##########################################################################

function prepare {
	writeln "Prepare"

	if(!(test-path -Path $backup_temp_copy)) {
		new-item -ItemType directory -Path $backup_temp_copy  | Out-Null
	}
	
	if(!(test-path -Path $backup_temp_merge)) {
		new-item -ItemType directory -Path $backup_temp_merge  | Out-Null
	}
	
	if(!(test-path -Path $backup_storage)) {
		new-item -ItemType directory -Path $backup_storage  | Out-Null
	}
	
}

######################################################################### Merge backup #######################################################################

function merge {
	writeln "Merge"
	
	deleteIgnoredFiles $backup_temp_copy
	
	#determine last backup file
	$last_backup_file = getMostActualBackupFile $backup_storage
	$last_backup_size = 0

	if ($last_backup_file){
		$last_backup_size = $last_backup_file.Length
		writeln "Last backup file is ""$last_backup_file"" with size $last_backup_size bytes"
	}

	$new_backup_file = createArchive $backup_temp_copy $backup_temp_merge $password
	
	if (!$new_backup_file) {
		writeln "ERROR: The backup archive is not created"
		exit 1
	}
	
	$new_backup_size = $new_backup_file.Length
	writeln "New backup file is ""$new_backup_file"" with size $new_backup_size bytes"

	if ($new_backup_size -eq $last_backup_size) {
		writeln "New backup file ""$new_backup_file"" seems to have same content to last backup file ""$last_backup_file"", skip and delete"
		remove-item $new_backup_file.FullName -Force
	}else {
		writeln "Move new backup file ""$new_backup_file"" to backup storage ""$backup_storage"""
		move-item -Path $new_backup_file.FullName -Destination $backup_storage -Force
	}
}

####################################################################### Clean-up temp ########################################################################

function cleanupTemp {
	writeln "Clean-up temp $backup_temp_copy" 
	remove-item -Path $backup_temp_copy -Recurse -Force
	
	writeln "Clean-up temp $backup_temp_merge" 
	remove-item -Path $backup_temp_merge -Recurse -Force
}

##################################################################### Add folder to backup ###################################################################

function addFolderToBackup([String] $path) {
	writeln "Add ""$path"" to backup"
	
	$archiveName = removeInvalidFileNameChars $path
	
	$backup_temp_copy_archivename = [io.path]::combine($backup_temp, "copy", $archiveName)
	if(!(test-path -Path $backup_temp_copy_archivename)) {
		new-item -ItemType directory -Path $backup_temp_copy_archivename  | Out-Null
	}	
	
	copy-item -Force -Recurse $([io.path]::combine($path,"*")) -Destination $backup_temp_copy_archivename -ErrorAction SilentlyContinue
}

####################################################### Remove invalid file name chars and replace it by '_' #################################################

function removeInvalidFileNameChars([String] $name) {
  $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
  $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
  return ($name -replace $re,"_")
}

############################################################# Delete ignored files from path recoursive ######################################################
function deleteIgnoredFiles([String] $path) {

	$maximal_file_size_bytes = $maximal_file_size_mb *1024*1024
	
	
    foreach ($item in Get-ChildItem $path)
    {
        if (Test-Path $item.FullName -PathType Container) 
        {
            deleteIgnoredFiles $item.FullName
        } 
        else 
        { 
			if ($item.Length -ge $maximal_file_size_bytes) {
				writeln "Skip and delete ""$item"" because its size $($item.Length / 1024 / 1024) MB greater than maximal allowed $maximal_file_size_mb MB"
				remove-item $item.FullName -Force
				continue
			}
			
			$extension = [System.IO.Path]::GetExtension($item.FullName) -replace "\."
			foreach ($i in $ignore_extensions) {
				if ($extension -eq $i) {
					writeln "Skip and delete ""$item"" because of ignored extension ""$extension"""
					remove-item $item.FullName -Force
					break
				}
			}
        }
    } 
}

#################################################################### Get most actual backup file #############################################################
function getMostActualBackupFile([String] $path) {
	$result = $null
	$fileDate = [DateTime]::MinValue
	
	foreach ($item in Get-ChildItem $path)
    {
		if ($item.PSIsContainer) {
		    $file = getMostActualBackupFile $item.FullName
		
			if ($file -and $file.LastWriteTime -gt $fileDate) {
				$result = $file
				$fileDate = $file.LastWriteTime
			}
		}
		else {
			$extension = [System.IO.Path]::GetExtension($item.FullName) -replace "\."
			foreach ($i in $backup_extensions) {
				if ($extension -eq $i -and $item.LastWriteTime -gt $fileDate) {

					$result = $item
					$fileDate = $item.LastWriteTime
				
					break
				}
			}
        } 
    } 
	
	return $result
}

########################################################################### Create archive ###################################################################
function createArchive([String] $sourceFolderPath, [String] $destinationFolderPath, [String] $password) {
	
	$filesToZip = $([io.path]::combine($sourceFolderPath, "*"))
	
	if(!(test-path -Path $filesToZip)) {
		writeln "ERROR: Folder ""$filesToZip"" is empty
Add some folders to backup in backup.ps like
.\pack.ps1 -target ""c:\Users\user\Desktop""
Before call merge"
		exit 1
	}
		
	$datestr = $(get-date).ToString("yyyy-MM-dd HHmmss")
		
	if ([string]::IsNullOrEmpty($password)) {
		#create ZIP archive without password
		$new_backup_filename = [io.path]::combine($destinationFolderPath, $datestr+"."+$backup_format_zip)
		
		writeln "Pack ""$filesToZip"" into ""$new_backup_filename"" using internal archive tool"
		
		Compress-Archive -force -path $filesToZip -destinationpath "$new_backup_filename"
		return $(Get-Item $new_backup_filename)
	} else {
		#create 7za archive with password
		
		if (-not $(Test-Path ($sevenZip))) {
			writeln "WARNING: $sevenZip not found
please download console version from https://www.7-zip.org/ and place it into $PSScriptRoot to be able to create password protected backups"
			
			return createArchive $sourceFolderPath $destinationFolderPath $null
		}

		$new_backup_filename = [io.path]::combine($destinationFolderPath, $datestr+"."+$backup_format_7z)
		
		$arguments = "a ""$new_backup_filename"" ""$filesToZip"" -p$password -mhe=on"
		$windowStyle = "hidden"
	
		writeln "Pack ""$filesToZip"" into ""$new_backup_filename"" using $sevenZip"
		$p = Start-Process $sevenZip -ArgumentList $arguments -Wait -PassThru -WindowStyle $windowStyle
		
		return $(Get-Item $new_backup_filename)
	}
}

######################################################################## Clean-up storage ####################################################################
function cleanUpStorage {
	writeln "Clean-up storage"
	
	$now = $(get-date)

	foreach ($item in Get-ChildItem $backup_storage)
    {
		if (!($item.PSIsContainer)) {
			$extension = [System.IO.Path]::GetExtension($item.FullName) -replace "\."
			foreach ($i in $backup_extensions) {
				if ($extension -eq $i) {

					$difference = new-timespan -start $item.LastWriteTime -end $now
					$differenceDays = $difference.TotalDays
					
					if ($differenceDays -ge $storage_days) {
					
						writeln "Backup ""$item"" created $differenceDays days before will be deleted as expired"
						remove-item $item.FullName -Force
					}
			
					break
				}
			}
		
		}
    } 	
	
}

##############################################################################################################################################################
########################################################################## ENTRY POINT #######################################################################
##############################################################################################################################################################

check

if ($target -eq "prepare") {
	prepare
} else {
	if ($target -eq "merge") {
		merge
		cleanupTemp
		cleanUpStorage
		writeln "Done"
	}else {
		addFolderToBackup $target
	}
}