# Student Talent Profiling App

## Project Overview
A comprehensive talent management system for Universiti Tun Hussein Onn Malaysia (UTHM), Faculty of Computer Science and Information Technology (FSKTM). The system digitizes manual talent management with a mobile app for students and a web dashboard for administrators.

## Features
- **Student Features**: Registration, profile management, achievement uploads, talent showcase posts
- **Lecturer Features**: View student profiles, provide feedback on showcases
- **Admin Features**: Data management, analytics, report generation

## Tech Stack
- **Mobile App**: Flutter + Firebase (Authentication, Firestore, Cloud Storage)
- **Web Dashboard**: HTML, CSS, JavaScript + Firebase
- **Database**: Firebase Firestore with structured collections

## Project Structure
```
student-talent-profiling-app/
├── mobile_app/                 # Flutter mobile application
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── services/          # Firebase services
│   │   ├── screens/           # UI screens
│   │   ├── widgets/           # Reusable widgets
│   │   └── utils/             # Utilities and helpers
│   ├── assets/                # Images, fonts, etc.
│   └── pubspec.yaml           # Flutter dependencies
├── web_dashboard/             # Web admin dashboard
│   ├── css/                   # Stylesheets
│   ├── js/                    # JavaScript files
│   ├── pages/                 # HTML pages
│   └── assets/                # Images and resources
└── firebase_config/           # Firebase configuration files
```

## Getting Started
1. Clone the repository
2. Set up Firebase project and add configuration files
3. Install Flutter dependencies: `flutter pub get`
4. Run the mobile app: `flutter run`
5. Open web dashboard in browser

## Database Schema
- **users**: User authentication and role management
- **profiles**: Student profile information
- **achievements**: Student achievements and certificates
- **showcases**: Talent showcase posts
- **feedback**: Lecturer feedback on showcases 