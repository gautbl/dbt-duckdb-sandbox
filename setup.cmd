@echo off
rem Wrapper so setup also runs from cmd.exe or Git Bash without touching
rem the execution policy:  setup.cmd
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*