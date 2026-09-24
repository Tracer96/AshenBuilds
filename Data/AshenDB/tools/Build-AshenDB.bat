@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel%==0 (
  py -m pip install --user brotli
  py build_ashendb.py
) else (
  python -m pip install --user brotli
  python build_ashendb.py
)
pause
