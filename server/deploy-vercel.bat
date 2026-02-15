@echo off
echo.
echo ========================================
echo   LPG Dealer API - Vercel Deployment
echo ========================================
echo.

REM Check if vercel CLI is installed
where vercel >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Installing Vercel CLI...
    call npm install -g vercel
)

echo Vercel CLI is ready
echo.

echo Logging in to Vercel...
call vercel login

echo.
echo Deploying to production...
call vercel --prod

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Copy your deployment URL
echo 2. Open the Flutter app
echo 3. Double-tap the gas station icon
echo 4. Enter your Vercel URL
echo 5. Click 'Test' to verify connection
echo 6. Click 'Save'
echo.
echo Done!
echo.
pause
