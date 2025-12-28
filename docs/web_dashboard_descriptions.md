# Web Dashboard Interface Design Descriptions
## For Section 4.4.3.2 of Chapter 4

---

## Figure 4.36: Web Dashboard - Admin Login

The web dashboard authentication interface serves as the secure entry point for administrators and lecturers to access the Student Talent Profiling system. The login page features a professional design with two primary input fields: an email field for institutional email addresses and a password field with masked character display. Client-side validation ensures proper email formatting before form submission, while a prominently styled login button initiates the authentication process with visual loading feedback.

When credentials are submitted, the system performs secure authentication through the Supabase Auth service via HTTPS connection. Upon successful verification, the system validates the user's assigned role and generates a session token stored in browser cookies for seamless navigation. The authentication module implements security best practices including bcrypt password hashing, SSL/TLS encryption, session timeout after inactivity, and rate limiting to prevent brute-force attacks.

---

## Figure 4.37: Web Dashboard - Analytics Overview

The analytics dashboard provides administrators with a centralized view of the institution's talent ecosystem through an intuitive Admin Portal interface. The left sidebar navigation provides quick access to key modules including Overview, User Management, Event Management, Analytics, and Settings. The top section displays four color-coded Key Performance Indicator (KPI) cards: Jumlah Pelajar (Total Students) showing registered student count, Purata CGPA displaying the average academic performance across all students, Purata Kokurikulum indicating the co-curricular participation percentage, and Event Aktif showing the number of currently active events available for registration.

The middle section features two primary data visualizations. The User Growth Trend chart displays a line graph tracking student registration growth over time from September through December, enabling administrators to monitor platform adoption rates. The Keseimbangan Akademik vs Kokurikulum doughnut chart provides a visual breakdown of student balance between academic focus and co-curricular activities, categorized as Seimbang (Balanced), Fokus Akademik (Academic Focus), and Data Tak Lengkap (Incomplete Data). At the bottom, the Statistik PAK (Penasihat Akademik) section displays advisor-related metrics including Jumlah PAK (total advisors), Pelajar Seliaan (supervised students), and Purata per PAK (average students per advisor), with a dropdown filter to view statistics for specific advisors.

---

## Figure 4.38: Web Dashboard - Student List

The User Management interface provides a comprehensive table view of all registered users within the system. The main table displays essential information in organized columns including NAME with profile avatar and email address, ROLE indicating whether the user is a Lecturer or Student, DEPARTMENT showing faculty affiliation such as FSKTM, FKEE, FKAAB, or FTK, PROFILE completion status marked with a green checkmark for complete profiles, STATUS toggle showing Active or Inactive state, and ACTIONS buttons for edit, view, and delete operations.

Above the table, a search toolbar enables real-time filtering with a "Search users..." input field and an "All Roles" dropdown filter for role-based filtering. A prominent blue "Add User" button allows administrators to create new user accounts. The table displays user entries with circular avatar initials, full names, and institutional email addresses in the @uthm.edu.my domain format. Status indicators use green toggle switches to show account activation state, providing administrators with quick visibility into user account status across the platform.

---

## Figure 4.39: Web Dashboard - Edit User Data

The Edit User interface presents a modal dialog overlay that appears when administrators select the edit action for a specific user record. This streamlined design allows quick modifications to user information without navigating away from the User Management list view, maintaining workflow efficiency for administrators managing multiple user accounts.

The modal form contains four essential fields for user data modification: Name field displaying the user's full name, Email field showing the institutional email address, Role dropdown selector allowing administrators to change the user's role between Student and Lecturer designations, and Department field for specifying faculty affiliation such as FSKTM. The modal includes Cancel and Save Changes buttons at the bottom, enabling administrators to either discard modifications or commit updates to the database. Upon successful save, the changes are immediately reflected in the user management table without requiring page refresh.

---

## Figure 4.40: Web Dashboard - Event Management

The Event Management interface enables administrators and lecturers to oversee all academic and co-curricular events within the system. The main listing displays events in a structured table format with columns for TITLE showing event name and venue location, DATE indicating the scheduled event date, CATEGORY displaying color-coded event types such as Seminar, Competition, Academic, Workshop, and general categories, STATUS showing publication state with green "Published" badges, PARTICIPANTS displaying current registration count, and ACTIONS buttons for participant management, edit, and delete operations.

The interface includes events such as "UTHM Hackathon & Innovation Challenge 2024", "UTHM Career Fair & Industry Networking Day", "Student Innovation & Project Showcase", and "AI & Machine Learning Workshop 2025" with their respective venues and dates. Above the table, a search field and "All Categories" dropdown enable filtering, while a blue "Add Event" button allows creation of new events. Pagination controls at the bottom display "Showing 1 to 10 of 6 entries" with Previous and Next navigation buttons for managing larger event lists.

---

## Figure 4.41: Web Dashboard - AI Assistant Chat

The AI Assistant interface presents a floating chat widget accessible from any page within the Admin Portal. The widget displays a compact chat window with a purple gradient header showing "AI Assistant" title with an online status indicator, providing administrators with instant access to AI-powered query capabilities without leaving their current workflow context.

The chat interface follows a conversational design pattern with the AI's welcome message displayed on the left stating "Hi! Saya AI assistant kampus. Boleh saya bantu anda manage dashboard hari ini?" (Hello! I am the campus AI assistant. Can I help you manage the dashboard today?), while user messages appear on the right side in blue bubbles. A loading state indicator shows "Sedang berfikir..." (Thinking...) when the AI is processing queries using the RAG (Retrieval-Augmented Generation) system powered by Google Gemini. The input field at the bottom allows users to type messages with a send button for submission. A floating action button in the corner enables quick access to open the chat widget from anywhere in the dashboard.

---

## Figure 4.42: Web Dashboard - Report Generation

The report generation module enables administrators to create PDF documents containing student analytics and system statistics for academic planning, talent identification, and stakeholder presentations. The configuration interface offers predefined templates including Student Overview Report for campus-wide statistics, Faculty Report for department-specific analysis, Individual Student Report for complete portfolio compilation, and Event Summary Report for participation metrics documentation.

Parameter controls allow administrators to define report scope through date range filters, faculty selection, and specific student identifiers. The generation engine compiles data using the jsPDF library, producing formatted tables with student information, statistical chart images embedded from the dashboard visualizations, and narrative summary sections. A preview interface enables document review before downloading, with the final PDF available for distribution, printing, or archival storage. The Export CSV button visible in the Analytics dashboard header provides an alternative export option for raw data analysis in spreadsheet applications.
