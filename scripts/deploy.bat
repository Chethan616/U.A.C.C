@echo off
REM Deploy script for UACC Firebase Functions (Windows)
REM Usage: scripts\deploy.bat [environment]

setlocal EnableDelayedExpansion

set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=development
set PROJECT_ID=uacc-uacc

echo 🚀 Deploying UACC Firebase Functions to %ENVIRONMENT%

REM Check prerequisites
where firebase >nul 2>nul
if errorlevel 1 (
    echo ❌ Firebase CLI is required but not installed. Please install it first.
    exit /b 1
)

where gcloud >nul 2>nul
if errorlevel 1 (
    echo ❌ Google Cloud CLI is required but not installed. Please install it first.
    exit /b 1
)

where node >nul 2>nul
if errorlevel 1 (
    echo ❌ Node.js is required but not installed. Please install it first.
    exit /b 1
)

REM Verify we're in the correct directory
if not exist "firebase.json" (
    echo ❌ firebase.json not found. Please run this script from the project root.
    exit /b 1
)

REM Set Firebase project
echo 📋 Using Firebase project: %PROJECT_ID%
firebase use %PROJECT_ID%

REM Install dependencies
echo 📦 Installing dependencies...
cd functions
call npm install
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    exit /b 1
)
cd ..

REM Run linting
echo 🧪 Running linting...
cd functions
call npm run lint
cd ..

REM Set up secrets if provided
if defined GEMINI_API_KEY (
    echo 🔑 Setting up Gemini API key in Secret Manager...
    
    REM Check if secret exists and create/update
    gcloud secrets describe GEMINI_API_KEY --project=%PROJECT_ID% >nul 2>nul
    if errorlevel 1 (
        echo %GEMINI_API_KEY% | gcloud secrets create GEMINI_API_KEY --data-file=- --project=%PROJECT_ID%
        echo ✅ Created new secret
    ) else (
        echo %GEMINI_API_KEY% | gcloud secrets versions add GEMINI_API_KEY --data-file=- --project=%PROJECT_ID%
        echo ✅ Updated existing secret
    )
    
    REM Grant access to Cloud Functions service account
    for /f "tokens=*" %%a in ('gcloud projects describe %PROJECT_ID% --format="value(projectNumber)"') do set PROJECT_NUMBER=%%a
    set SERVICE_ACCOUNT=!PROJECT_NUMBER!-compute@developer.gserviceaccount.com
    
    gcloud secrets add-iam-policy-binding GEMINI_API_KEY --member="serviceAccount:!SERVICE_ACCOUNT!" --role="roles/secretmanager.secretAccessor" --project=%PROJECT_ID% 2>nul
    echo ✅ Secret Manager configured
) else (
    echo ⚠️  GEMINI_API_KEY environment variable not set. Skipping secret setup.
    echo    Make sure to set this manually before deploying.
)

REM Deploy functions
echo 🚢 Deploying Firebase Functions...
firebase deploy --only functions:geminiProxy
if errorlevel 1 (
    echo ❌ Deployment failed
    exit /b 1
)

REM Test deployment
echo 🧪 Testing deployment...
set FUNCTION_URL=https://us-central1-%PROJECT_ID%.cloudfunctions.net/geminiProxy

REM Health check using curl (if available)
where curl >nul 2>nul
if not errorlevel 1 (
    for /f %%i in ('curl -s -o nul -w "%%{http_code}" -X GET "%FUNCTION_URL%"') do set HTTP_CODE=%%i
    if "!HTTP_CODE!"=="405" (
        echo ✅ Function is responding (GET returns 405 as expected^)
    ) else (
        echo ⚠️  Unexpected response code: !HTTP_CODE!
    )
) else (
    echo ⚠️  curl not available for health check
)

echo.
echo 🎉 Deployment complete!
echo.
echo 📍 Function URL: %FUNCTION_URL%
echo 📊 View logs: firebase functions:log --only geminiProxy
echo 🔍 Monitor: https://console.firebase.google.com/project/%PROJECT_ID%/functions
echo.
echo Next steps:
echo 1. Test the function with a valid Firebase ID token
echo 2. Update your Flutter app to use the deployed endpoint
echo 3. Set up monitoring and alerts for production
echo.

if "%ENVIRONMENT%"=="production" (
    echo 🔴 PRODUCTION DEPLOYMENT COMPLETE
    echo Please verify all functionality before directing traffic to this endpoint.
)

pause