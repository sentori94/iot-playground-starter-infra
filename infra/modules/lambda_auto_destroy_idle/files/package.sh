#!/bin/bash
# Script pour packager la Lambda auto-destroy-idle

echo "Packaging Lambda auto-destroy-idle..."

cd "$(dirname "$0")"

rm -f check_idle_and_destroy_handler.zip
zip check_idle_and_destroy_handler.zip check_idle_and_destroy_handler.py

echo "OK check_idle_and_destroy_handler.zip created"
