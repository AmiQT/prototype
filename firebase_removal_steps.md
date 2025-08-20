# Firebase Removal Steps

## Step 1: Update Dependencies
1. Replace your `pubspec.yaml` with the content from `remove_firebase_dependencies.yaml`
2. Run `flutter pub get` to update dependencies

## Step 2: Remove Firebase Configuration Files
Delete these files:
- `mobile_app/firebase.json`
- `mobile_app/firestore.rules`
- `mobile_app/firestore.indexes.json`
- `mobile_app/firestore.dev.rules`
- `mobile_app/lib/firebase_options.dart`
- `mobile_app/android/app/google-services.json`
- `firebase.json` (root level)
- `firestore.indexes.json` (root level)
- `.firebaserc` (root level)

## Step 3: Remove Firebase Imports
I'll update all files that import Firebase packages.

## Step 4: Update Main App Initialization
Remove Firebase initialization from main.dart

## Step 5: Clean Generated Files
Remove Firebase-generated plugin registrations

Let me start with Step 3 - removing Firebase imports from all files.