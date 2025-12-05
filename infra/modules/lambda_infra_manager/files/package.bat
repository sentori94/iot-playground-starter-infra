@echo off
REM Script pour packager les Lambda functions sur Windows

setlocal enabledelayedexpansion

echo Packaging Lambda functions...

cd /d "%~dp0"

REM Create Infrastructure Lambda
echo   -^> Packaging create_infra...
if exist create_infra.zip del create_infra.zip
copy create_infra_handler.py handler.py >nul
powershell -Command "Compress-Archive -Path handler.py -DestinationPath create_infra.zip -Force"
del handler.py
echo     OK create_infra.zip created

REM Check Status Lambda
echo   -^> Packaging check_status...
if exist check_status.zip del check_status.zip
copy check_status_handler.py handler.py >nul
powershell -Command "Compress-Archive -Path handler.py -DestinationPath check_status.zip -Force"
del handler.py
echo     OK check_status.zip created

REM Destroy Infrastructure Lambda
echo   -^> Packaging destroy_infra...
if exist destroy_infra.zip del destroy_infra.zip
copy destroy_infra_handler.py handler.py >nul
powershell -Command "Compress-Archive -Path handler.py -DestinationPath destroy_infra.zip -Force"
del handler.py
echo     OK destroy_infra.zip created

REM Get Latest Deployment Lambda
echo   -^> Packaging get_latest_deployment...
if exist get_latest_deployment.zip del get_latest_deployment.zip
powershell -Command "Compress-Archive -Path get_latest_deployment_handler.py -DestinationPath get_latest_deployment.zip -Force"
echo     OK get_latest_deployment.zip created

REM List Deployments Lambda
echo   -^> Packaging list_deployments...
if exist list_deployments.zip del list_deployments.zip
powershell -Command "Compress-Archive -Path list_deployments_handler.py -DestinationPath list_deployments.zip -Force"
echo     OK list_deployments.zip created

REM Cancel Deployment Lambda
echo   -^> Packaging cancel_deployment...
if exist cancel_deployment.zip del cancel_deployment.zip
powershell -Command "Compress-Archive -Path cancel_deployment_handler.py -DestinationPath cancel_deployment.zip -Force"
echo     OK cancel_deployment.zip created

REM Periodic Status Updater Lambda
echo   -^> Packaging periodic_status_updater...
if exist periodic_status_updater.zip del periodic_status_updater.zip
powershell -Command "Compress-Archive -Path periodic_status_updater_handler.py -DestinationPath periodic_status_updater.zip -Force"
echo     OK periodic_status_updater.zip created

echo.
echo All Lambda functions packaged successfully!
pause
