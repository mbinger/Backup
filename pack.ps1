param (
	[string]$target = ""
)

###################################################################### Setup variables #######################################################################

$backup_temp_copy = [io.path]::combine($backup_temp, "copy")
$backup_temp_merge = [io.path]::combine($backup_temp, "merge")

$backup_format_zip = "zip"
$backup_format_7z = "7z"
$backup_extensions = @($backup_format_zip, $backup_format_7z)
$sevenZip = "7za.exe"

########################################################################### Check ############################################################################

function check {
	if ([string]::IsNullOrEmpty($target)) {
		write-host "nothing to do, exit"
		exit 1
	}
}


########################################################################### Prepare ##########################################################################

function prepare {
	write-host "prepare"

	if(!(test-path -Path $backup_temp_copy)) {
		new-item -ItemType directory -Path $backup_temp_copy
	}
	
	if(!(test-path -Path $backup_temp_merge)) {
		new-item -ItemType directory -Path $backup_temp_merge
	}
	
	if(!(test-path -Path $backup_storage)) {
		new-item -ItemType directory -Path $backup_storage
	}
	
}

######################################################################### Merge backup #######################################################################

function merge {
	write-host "merge"
	prepare
	
	#@@@ deleteIgnoredFiles $backup_temp_copy
	
	#determine last backup file
	$last_backup_file = getMostActualBackupFile $backup_storage
	$last_backup_size = 0

	if ($last_backup_file){
		$last_backup_size = $last_backup_file.Length
		write-host Last backup file is $last_backup_file.FullName with size $last_backup_size bytes
	}
	
	$new_backup_file = createArchive $backup_temp_copy $backup_temp_merge $password
	if (!$new_backup_file) {
		write-host "Unable to create backup archive"
		Exit 1
	}
	write-host $new_backup_file
}

##################################################################### Add folder to backup ###################################################################

function addFolderToBackup([String] $path) {
	write-host "pack " $path
	prepare
	
	$archiveName = removeInvalidFileNameChars $path
	
	$backup_temp_copy_archivename = [io.path]::combine($backup_temp, "copy", $archiveName)
	if(!(test-path -Path $backup_temp_copy_archivename)) {
		new-item -ItemType directory -Path $backup_temp_copy_archivename
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
				write-host skip and delete $item.FullName because its size $($item.Length / 1024 / 1024) MB greater than maximal allowed $maximal_file_size_mb MB
				remove-item $item.FullName
				continue
			}
			
			$extension = [System.IO.Path]::GetExtension($item.FullName) -replace "\."
			foreach ($i in $ignore_extensions) {
				if ($extension -eq $i) {
					write-host skip and delete $item.FullName because of ignored extension $extension
					remove-item $item.FullName
					break
				}
			}
        }
    } 
}

############################################################# Get most actual backup file ######################################################

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

#################################################################### Create archive ############################################################
function createArchive([String] $sourceFolderPath, [String] $destinationFolderPath, [String] $password) {
	
	$datestr = $(get-date).ToString("yyyy-MM-dd hhmmss")
	
	$filesToZip = $([io.path]::combine($sourceFolderPath, "*"))
	
	if ([string]::IsNullOrEmpty($password)) {
		#create ZIP archive without password
		$new_backup_filename = [io.path]::combine($destinationFolderPath, $datestr+"."+$backup_format_zip)
		Compress-Archive -path $filesToZip -destinationpath $new_backup_filename -force
		return $(Get-Item $new_backup_filename)
	} else {
		#create 7za archive with password
		
		if (-not $(Test-Path ($sevenZip))) {
			write-warning "$sevenZip not found"
			write-warning "please download console version from https://www.7-zip.org/ and place it into $PSScriptRoot to be able to create password protected backups"
			
			return createArchive $sourceFolderPath $destinationFolderPath $null
		}

		$new_backup_filename = [io.path]::combine($destinationFolderPath, $datestr+"."+$backup_format_7z)
		
		$arguments = "a ""$new_backup_filename"" ""$filesToZip"" -p$password -mhe=on"
		$windowStyle = "hidden"
	
		$p = Start-Process $sevenZip -ArgumentList $arguments -Wait -PassThru -WindowStyle $windowStyle
		
		return $(Get-Item $new_backup_filename)
	}
}

##############################################################################################################################################################
########################################################################## ENTRY POINT #######################################################################
##############################################################################################################################################################

check

if ($target -eq "merge") {
	merge
}else {
	addFolderToBackup $target
}