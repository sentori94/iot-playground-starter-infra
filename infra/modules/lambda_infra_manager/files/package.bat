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

echo.
echo All Lambda functions packaged successfully!
#!/bin/bash
# Script pour packager les Lambda functions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="$SCRIPT_DIR"

echo "📦 Packaging Lambda functions..."

# Create Infrastructure Lambda
echo "  → Packaging create_infra..."
cd "$FILES_DIR"
if [ -f "create_infra.zip" ]; then
    rm create_infra.zip
fi
cp create_infra_handler.py handler.py
zip -q create_infra.zip handler.py
rm handler.py
echo "    ✓ create_infra.zip created"

# Check Status Lambda
echo "  → Packaging check_status..."
if [ -f "check_status.zip" ]; then
    rm check_status.zip
fi
cp check_status_handler.py handler.py
zip -q check_status.zip handler.py
rm handler.py
echo "    ✓ check_status.zip created"

# Destroy Infrastructure Lambda
echo "  → Packaging destroy_infra..."
if [ -f "destroy_infra.zip" ]; then
    rm destroy_infra.zip
fi
cp destroy_infra_handler.py handler.py
zip -q destroy_infra.zip handler.py
rm handler.py
echo "    ✓ destroy_infra.zip created"

echo "✅ All Lambda functions packaged successfully!"

