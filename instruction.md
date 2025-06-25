// You are an expert AI developer assistant. Please help me code this project.

Project Name: Student Talent Profiling App

Overview:
This is a Final Year Project developed for Universiti Tun Hussein Onn Malaysia (UTHM), specifically for the Faculty of Computer Science and Information Technology (FSKTM). The goal is to digitize the manual talent management system using a mobile app for students and a web dashboard for admin.

User Roles:
- Student: Register, login, create/update profile, upload achievements, post talent showcase (text, image, video).
- Lecturer: View student profiles, comment/feedback on showcase.
- Administrator: Access the web dashboard (reporting and analytics only), manage data, generate reports, analyze student profiles via web dashboard.

Features:
- Login/Register module using SMAP credentials
- Profile Management (CRUD)
- Achievement Management (with file upload)
- Talent Showcase (media post + feedback)
- Reporting and Analytics (filter + graph + export report) (**Web dashboard only; mobile app does not require reporting/analytics**)

Tech Stack:
- Mobile App: Flutter + Firebase (auth, Firestore, cloud storage)
- Web Dashboard: HTML, CSS, JavaScript + Firebase (admin access, reporting & analytics only)
- Database design and schema already created (user, profile, achievement, feedback tables)
- Object-Oriented Approach must be applied
- Use modular, reusable classes for each user role and feature

Instructions:
Please generate:
1. Folder/file structure for the full project (both Flutter app and web dashboard)
2. Dummy data and Firebase structure suggestions
3. Example code for login, profile creation, and one module (e.g., achievement)
4. Use clean, readable, and scalable code (modular and object-oriented)

//New Changes UI Design.
Generate the Flutter UI for a mobile application with the following design:

1. **Login Page**:
   - Title: "Talent Hub" centered at the top.
   - Welcome message: "Showcase your skills and connect with opportunities. Sign in or register to get started."
   - Two buttons at the bottom: "Sign In" (blue) and "Register" (grey), with rounded corners.
   - Make the design clean, modern, and mobile-friendly with proper spacing and padding.
   - Add a simple background color with a white container for buttons.

2. **Talent Profile Page**:
   - App bar with "Talent Profile" as the title, and a back button to navigate back.
   - User profile picture at the top, followed by the name ("Ethan Carter") and details (e.g., Major, University, Graduation Year).
   - A horizontal tab bar with 4 tabs: Profile (selected), Achievements, Talent Showcase, and Admin Dashboard.
   - Below the tabs, show "Personal Details" and "Skills" in expandable containers or cards.
   - Display skills as tags (e.g., Python, Java, Data Analysis, etc.) in a row with padding between each tag.
   - Display achievements in a list format with clickable/expandable items showing the achievement's year and description.

3. **Achievements Page**:
   - Use a ListView to display all achievements in a card-like design.
   - Each card will contain an icon (e.g., trophy for awards) and the name of the achievement (e.g., "Dean's List").
   - Add a floating action button ("+") at the bottom right for adding new achievements.
   - Each achievement should be tappable to expand for further details.

4. **Talent Showcase and Recent Activity**:
   - Display recent activity and posts in a scrollable list.
   - Each post will have a user profile picture on the left side, followed by the comment text.
   - Allow the user to like, comment, and share posts, which should be represented by icons (heart, comment bubble, share arrow).
   - Display posts in card-like widgets with rounded edges and shadows for depth.
   - Below each post, add a comment section with profile pictures next to each comment.

5. **Navigation**:
   - Bottom navigation bar with 4 tabs: "Profile", "Search", "Notifications", and "Home".
   - Use `BottomNavigationBar` to switch between the main sections of the app.
   - Ensure the tab bar is always visible and responsive.

6. **General Design Guidelines**:
   - Use a minimalist design with a white background for the majority of the app.
   - Use light blue accents for buttons and highlights (consistent with the design).
   - Ensure smooth transitions between pages with proper navigation management using `Navigator` or `MaterialPageRoute`.
   - The app should be responsive, adapting well to different screen sizes (phones, tablets).

Please create the Flutter code with appropriate widgets like `Container`, `Column`, `Row`, `ListView`, `TabBar`, `Scaffold`, `FloatingActionButton`, and so on. Ensure proper padding, margins, and alignment for each element to match the clean, modern look of the design.
