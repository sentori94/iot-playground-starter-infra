@echo off
REM Script pour packager la Lambda auto-destroy-idle

echo Packaging Lambda auto-destroy-idle...

cd /d "%~dp0"

if exist check_idle_and_destroy_handler.zip del check_idle_and_destroy_handler.zip
powershell -Command "Compress-Archive -Path check_idle_and_destroy_handler.py -DestinationPath check_idle_and_destroy_handler.zip -Force"

echo OK check_idle_and_destroy_handler.zip created
pause
