# 🤖 Laabrah Project Setup & AI Assistant Guide

Welcome to the **Laabrah** repository! This file is designed specifically for you (the Developer) and any **AI Coding Assistant** (like Gemini/Antigravity) to instantly configure, run, and deploy this project.

> [!IMPORTANT]
> **AI Instruction:** If you are an AI assistant tasked with modifying or running this codebase, read this file fully. It contains all paths, configurations, and quick setup commands to prevent any environment issues.

---

## 📂 Project Architecture

This is a multi-application repository containing two core web systems:
1.  **Flutter Recovery App** (Root Folder): A cross-platform mobile & web app designed for recovery from addiction.
2.  **React Chat App** (`/laabrah-chat`): A modern Vite + React + TypeScript + TailwindCSS web application for real-time community chat.

---

## ⚡ 1-Step Automatic Setup

To instantly download all packages, restore dependencies, and configure CLI tools for both applications, run the following automated script in PowerShell:

```powershell
./setup.ps1
```

### What the Setup Script Accomplishes:
1.  **Flutter Restoration:** Automatically runs `flutter pub get` in the root folder.
2.  **React Chat Restoration:** Navigates to `/laabrah-chat` and runs `npm install`.
3.  **Deployment CLI Check:** Globally installs/restores `firebase-tools` and `wrangler` for hassle-free deployments.

---

## 🛠️ Essential Development Commands

### Running the Applications Locally:
*   **Run Flutter App (Web/Chrome):**
    ```powershell
    flutter run -d chrome
    ```
*   **Run React Chat App (Local Host):**
    ```powershell
    cd laabrah-chat
    npm run dev
    ```

### Building & Deploying the Web Apps:
*   **Auto-Deploy to Both Firebase & Cloudflare:**
    We have an integrated single-command script that builds Flutter Web and pushes it to both Firebase Hosting and Cloudflare Pages:
    ```powershell
    ./deploy.ps1
    ```

---

## 📦 Key Packages & Integrations

### Flutter App (Root)
*   **Database & Auth:** Firebase Core, Firestore, Auth, and Storage.
*   **Cloudflare R2 Integration:** Powered by the `cloudflare` package (fully S3-compatible).
*   **UI/UX:** Google Fonts, Cupertino Icons, and Premium custom Vector-Gradient ShaderMask components.

### React Chat App (`/laabrah-chat`)
*   **State & Query:** React Query (`@tanstack/react-query`) & Router DOM.
*   **Styling:** TailwindCSS, Shadcn/ui elements, and Lucide React icons.

---

## 🚀 How to Upload to GitHub

If you are transferring this project to a new GitHub repository, run these quick commands in your PowerShell console:

```powershell
# 1. Initialize Git in the project root (if not done already)
git init

# 2. Add all files to staging (our .gitignore is pre-configured to ignore build/ and node_modules/)
git add .

# 3. Create initial commit
git commit -m "Initial commit: Integrated settings gradient icons, setup automation, and multi-deploy environments"

# 4. Link your new GitHub repository (replace with your actual GitHub URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# 5. Push to GitHub main branch
git branch -M main
git push -u origin main
```
