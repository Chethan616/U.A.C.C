# Google Workspace API Setup Guide

## Overview
This guide will help you set up Google Workspace integration for UACC's automation features, including Calendar and Tasks APIs.

## Step-by-Step Setup

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "New Project" or select the project dropdown
3. Create a new project called "UACC-Automation" (or any name you prefer)
4. Wait for the project to be created and select it

### Step 2: Enable Required APIs

1. In the Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for and enable the following APIs:
   - **Google Calendar API**
   - **Google Tasks API** 
   - **Google People API** (optional, for contact integration)

### Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type (unless you have a Google Workspace account)
3. Fill in the required information:
   - **App name**: UACC - Universal AI Call Companion
   - **User support email**: Your email
   - **Developer contact information**: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/calendar`
   - `https://www.googleapis.com/auth/tasks`
5. Add your email as a test user
6. Save and continue

### Step 4: Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client IDs"
3. Choose "Android" as application type
4. Fill in:
   - **Name**: UACC Android Client
   - **Package name**: `com.example.uacc` (or your app's package name)
   - **SHA-1 certificate fingerprint**: `70:EF:49:70:E7:01:3B:AC:4D:DB:4F:71:1D:AF:37:CE:F8:BF:E4:BD`
5. Click "Create"
6. Copy the **Client ID** - you'll need this in the app

### Step 5: Create Service Account (Optional but Recommended)

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "Service Account"
3. Fill in:
   - **Service account name**: uacc-automation-service
   - **Description**: Service account for UACC automation features
4. Click "Create and Continue"
5. Grant the service account the "Project > Editor" role
6. Click "Continue" then "Done"
7. Click on the created service account
8. Go to the "Keys" tab
9. Click "Add Key" > "Create new key"
10. Choose JSON format and download the key file
11. **Important**: Keep this JSON file secure - it contains credentials

### Step 6: Configure App Credentials

Open the UACC app and go to Settings > API & Permissions Setup:

1. **Gemini API Key**: Already configured with your key: `AIzaSyAWH1WyfGJE-JdtZRbS2leFRK2yX4TWJu0`

2. **Google OAuth Client ID**: Enter the Client ID from Step 4

3. **Service Account JSON**: Copy and paste the entire contents of the JSON file from Step 5

### Step 7: Test Google Integration

1. Open the Automation Dashboard in the app
2. Try enabling "Google Workspace Integration"
3. You should be prompted to sign in with your Google account
4. Grant the requested permissions

## Features Enabled

Once configured, UACC will be able to:

- **Automatically schedule meetings** from call analysis
- **Create tasks** in Google Tasks based on action items from calls
- **Check calendar conflicts** before scheduling
- **Sync with your existing calendar** events
- **Find optimal meeting times** based on your availability

## Security Notes

- Never share your service account JSON file
- The OAuth Client ID is safe to include in your app
- All credentials are stored securely in the app using Flutter Secure Storage
- You can revoke access anytime from your Google Account settings

## Troubleshooting

### "Access Denied" Error
- Make sure all required APIs are enabled
- Check that your email is added as a test user in OAuth consent screen
- Verify the package name matches your app

### "Invalid Client" Error
- Double-check the Client ID is entered correctly
- Make sure the SHA-1 fingerprint is correct for your debug keystore

### Calendar Not Syncing
- Ensure Calendar API is enabled
- Check that the service account has the necessary permissions
- Verify the JSON credentials are valid

## Support

If you encounter any issues:
1. Check the app logs in the Automation Dashboard
2. Verify all APIs are enabled in Google Cloud Console
3. Make sure OAuth consent screen is properly configured
4. Ensure all credentials are entered correctly in the app

---

**Note**: This setup enables powerful automation features. Make sure to review what permissions you're granting and only use credentials from trusted sources.