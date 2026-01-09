@echo off
echo Generating Android Release Keystore...
echo.

REM Find keytool
set KEYTOOL=keytool
where keytool >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Searching for Java keytool...
    if exist "C:\Program Files\Java\jdk*\bin\keytool.exe" (
        for /f "delims=" %%i in ('dir /b /s "C:\Program Files\Java\jdk*\bin\keytool.exe" 2^>nul') do set KEYTOOL=%%i
    )
    if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" (
        set KEYTOOL=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
    )
)

echo Using keytool: %KEYTOOL%
echo.

cd /d "%~dp0"

"%KEYTOOL%" -genkey -v -keystore alkhatm-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias alkhatm-key -storepass alkhatm2025secure -keypass alkhatm2025secure -dname "CN=AL KHATM, OU=Mobile, O=AL KHATM GROUP, L=Dubai, ST=Dubai, C=AE"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Keystore generated successfully!
    echo File: alkhatm-release-key.jks
    echo ========================================
    echo.
    echo IMPORTANT: Keep these credentials safe!
    echo Store Password: alkhatm2025secure
    echo Key Password: alkhatm2025secure
    echo Key Alias: alkhatm-key
    echo ========================================
) else (
    echo.
    echo ERROR: Failed to generate keystore!
    echo Please install Java JDK and try again.
)

pause
