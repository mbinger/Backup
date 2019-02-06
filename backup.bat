@echo off
SET backup_temp=e:\backup\temp
SET backup_storage=e:\backup\cloud\YandexDisk\!backups
SET storage_days=30
SET maximal_file_size_mb=100
SET ignore_extensions=exe;dll;msc
SET log=on
@echo on

call pack prepare

call pack c:\Users\user\Desktop
call pack c:\Users\user\Documents
call pack c:\Users\user\Downloads
call pack c:\$Recycle.Bin

call pack merge
call pack cleanup