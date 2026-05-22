# 📚 La Abrah - Native PDF & Download Architecture

This file contains the core architectural context of the new **In-App Native PDF Library System** integrated into the "La Abrah" project. It serves as a persistent memory reference for future edits to this workflow.

## 🛠 Features Implemented
1. **MediaFire Link Parsing**: Automatically bypasses MediaFire ads and retrieves the direct `.pdf` file.
2. **Background Downloading**: Downloads `.pdf` files sequentially/simultaneously using `dio` and saves them in local private app storage.
3. **Smart UI Tracking**: Download/Read buttons dynamically toggle per book based on its presence physically in the storage.
4. **Offline PDF Reader Native Engine**: Employs `flutter_pdfview` instead of web views, supporting night mode, pinch zoom, and localization counters natively.

## 🗂 Key Files & How to Modify Them

### 1. `lib/services/download_service.dart`
**Purpose**: Handles network communication, link extraction, and file management.
- **How to edit MediaFire extraction logic**: If MediaFire changes their HTML structure, open this file and modify the `html.Document` parsing section in `getDirectMediafireLink()`. Currently, it looks for an HTML element with `id="downloadButton"`.
- **How to view where files are saved**: They are saved via `path_provider` inside `getApplicationSupportDirectory()`. This prevents users from moving the files, keeping them exclusive to the app's internal sandbox.

### 2. `lib/screens/components/book_card_item.dart`
**Purpose**: Controls the UI representation of each Book in the `LibraryScreen`.
- **How to edit the visual appearance**: Any changes to the spacing, font sizes, download percentage overlay (`LinearProgressIndicator`), card margins, or colors, must be made here. This component was modularized out of `libraryScreen`.

### 3. `lib/screens/pdf_reader_screen.dart`
**Purpose**: The actual document viewer where the local PDF is rendered.
- **How to edit Reader settings**: Settings like `enableSwipe`, `pageSnap`, `nightMode` and its UI toggle button inside the top `AppBar` are explicitly declared here. The tracking pill at the bottom (`Page X of Y`) is also customized localized conditionally.

## ⚙️ Core Build Configurations (Important)
- **AGP**: The project operates on **Android Gradle Plugin 8.6.0** combined with **Kotlin 1.9.22** and **Gradle 8.7**. Do not downgrade unless completely necessary.
- **Desugaring**: The `app/build.gradle` enforces `coreLibraryDesugaringEnabled true` utilizing `desugar_jdk_libs:2.1.4` due to dependencies from local notification/pdf modules relying on Java 8 API features natively.

## 🚀 Quick Commands
To perform a clean release build natively:
```bash
flutter clean && flutter pub get
flutter build appbundle --release
flutter build apk --release
```
