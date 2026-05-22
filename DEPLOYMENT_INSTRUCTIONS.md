# Deployment Instructions for AI (Cloudflare & Firebase)

When the user asks you to deploy the project to Cloudflare, you MUST follow these specific steps:

## 1. Check Login Information
First, always check which Cloudflare account (Gmail/email) the user is currently logged in with by running the following command:
```powershell
npx wrangler whoami
```
**Action:** Inform the user clearly which email address they are currently logged into for Cloudflare.

## 2. Deploy to Cloudflare
Once you have informed the user of their account, deploy the web build to Cloudflare Pages using the exact same method as established before. Run this command:
```powershell
npx wrangler pages deploy build/web --project-name laabrah
```
**Action:** Wait for the deployment to finish and provide the final URL to the user (`https://laabrah.pages.dev`).

## 3. General Deployment (Optional)
If the user wants a full automatic build and deployment to BOTH Firebase and Cloudflare at the same time, just run:
```powershell
./deploy.ps1
```
*(This script automatically handles generating a new version, building the Flutter web app, deploying to Firebase via the CLI, and then deploying to Cloudflare via Wrangler).*
