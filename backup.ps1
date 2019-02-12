#specify temp folder
$backup_temp = "e:\backup\temp"

#specify backup storage folder synchronized with your cloud

$backup_storage = "e:\backup\cloud\YandexDisk\!backups"

#maximal storage period in days after the backups will be deleted
$storage_days = 30

#maximal file size in MB that will be included in the backup
$maximal_file_size_mb = 100

#semicolon-separated extentions of files that must be excluded from the backup
$ignore_extensions = @("exe", "dll", "msc")

#'$true' - write log file, '$false' - this feature is disabled
$log = $true

#set encryption password or empty string to ignore encryption
$password = ""

.\pack.ps1 -target "prepare"

#TODO: add your folders to the backup here

.\pack.ps1 -target "c:\Users\user\Desktop"
.\pack.ps1 -target "c:\Users\user\Documents"
.\pack.ps1 -target "c:\Users\user\Downloads"
.\pack.ps1 -target "c:\$Recycle.Bin"

.\pack.ps1 -target "merge"