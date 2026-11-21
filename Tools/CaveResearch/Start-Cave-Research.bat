@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>&1
if errorlevel 1 (
  echo Install Python 3 for Windows with the py launcher first.
  goto end
)
py -3 -c "import numpy, PIL" >nul 2>&1
if errorlevel 1 (
  echo Installing Python packages for screen reading...
  py -3 -m pip install --user numpy Pillow
  if errorlevel 1 goto end
)
where tesseract >nul 2>&1
if errorlevel 1 if not exist "%ProgramFiles%\Tesseract-OCR\tesseract.exe" (
  echo Install Tesseract OCR with English language data, then reopen this file.
  goto end
)
echo Open Roblox Upgrades and choose the cave before starting.
echo [1] Upgrade the selected skill until Max
echo [2] Cheapest eligible skill in this cave
echo [3] Exit
choice /c 123 /n
if errorlevel 3 exit /b
if errorlevel 2 (
  py -3 cave_research.py cheapest
) else (
  py -3 cave_research.py selected
)
:end
pause
