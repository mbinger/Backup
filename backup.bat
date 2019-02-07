@echo off

rem specify temp folder
SET backup_temp=e:\backup\temp

rem specify backup storage folder synchronized with your cloud 
SET backup_storage=e:\backup\cloud\YandexDisk\!backups

rem maximal storage period in days after the backups will be deleted
SET storage_days=30

rem maximal file size in MB that will be included in the backup
SET maximal_file_size_mb=100

rem semicolon-separated extentions of files that must be excluded from the backup
SET ignore_extensions=exe;dll;msc

rem 'on' - write log file, 'off' - this feature is disabled
SET log=on

rem set encryption password or empty string to ignore encryption
set password=

@echo on

call pack prepare

rem TODO: add your folders to the backup here

call pack c:\Users\user\Desktop
call pack c:\Users\user\Documents
call pack c:\Users\user\Downloads
call pack c:\$Recycle.Bin

call pack merge
call pack cleanup