# CHAPTER 4: ANALYSIS AND DESIGN

## 4.1 Introduction
This chapter discusses the findings from the analysis and design process of the Student Talent Profiling App. It outlines the system modules, detailed functional and non-functional requirements, and the specific user requirements needed to support the faculty's talent management goals.

## 4.2 System Requirement Analysis
The system is divided into several core modules, each designed to handle specific functionalities ranging from student profiling to AI-driven querying. Table 4.1 summarizes these modules.

**Table 4.1: System Modules**

| No | Module | Description |
| :--- | :--- | :--- |
| 1 | **Authentication Module** | Facilitates secure user access via Supabase Auth. Supports login for Students (via Matrix ID) and Administrators/Lecturers (via Staff ID). |
| 2 | **Profile Management Module** | Enables students to create comprehensive profiles, including personal details, skills to participation history. |
| 3 | **Achievement Management Module** | Allows students to upload verified achievements (PDFs/Images). Acts as the digital repository for the student's portfolio. |
| 4 | **Event Management Module** | Allows organizers to post academic/co-curricular events. Students can view event details, register participation, and track their attendance history. |
| 5 | **AI & Analytics Module** | The core intelligence unit. Includes the **RAG Chatbot** for admin data queries using natural language. |
| 6 | **Talent Showcase Module** | A public-facing feed where students can post major accomplishments for peer and lecturer viewing. |

### 4.2.1 Functional Requirements
Table 4.2 outlines the specific functions the system must perform to meet user needs, categorized by module.

**Table 4.2: Functional Requirements**

| No | Module | Functional Requirement Description |
| :--- | :--- | :--- |
| 1 | Authentication | • The system shall allow users to register and login securely via Email/Password.<br>• The system shall manage session tokens via Supabase Auth. |
| 2 | Profile Management | • Students shall be able to update profile details manually.<br>• The system shall validate structured text fields (Skills, Bio). |
| 3 | Achievement | • Users shall be able to upload files (PDF/JPG) as proof of achievement.<br>• The system shall store file references in Supabase Storage buckets. |
| 4 | Event Management | • Organizers shall be able to create events with details (Date, Venue, Capacity).<br>• Students shall be able to browse available events and register/join them.<br>• The system shall track student event participation history. |
| 5 | AI Services | • The system shall answer admin queries (e.g., "List students with Java skills") using **Vector Search (RAG)** context. |
| 6 | Visualization | • Admins shall be able to view dashboard analytics of top student skills and event participation rates. |

### 4.2.2 Non-Functional Requirements
Table 4.3 lists the non-functional requirements, specifically how the system performs rather than what it does.

**Table 4.3: Non-functional requirements**

| No | Requirement | Description |
| :--- | :--- | :--- |
| 1 | Performance | The system should be responsive and capable of handling multiple users simultaneously without significant delay. |
| 2 | Usability | The interface must be intuitive and easy to use for all user types, especially students and lecturers. |
| 3 | Security | The system must ensure secure user authentication and protect sensitive student data from unauthorized access. |
| 4 | Compatibility | The application must be compatible across various devices and browsers, including both Android and web platforms. |

### 4.2.3 User Requirement Analysis
Table 4.4 lists the user requirements for this system. Users of this system includes student, lecturer, and administrator.

**Table 4.4: User requirements**

| No | Requirement |
| :--- | :--- |
| 1 | All users must have a registered account with valid credentials. |
| 2 | Students must be able to create and update their talent profile. |
| 3 | Students must be able to submit and manage their achievements. |
| 4 | Students must be able to post media (images, videos) to showcase their talents. |
| 5 | Lecturers must be able to view student profiles and achievements. |
| 6 | Lecturers must be able to comment or provide feedback on posted content. |
| 7 | Administrators must be able to manage all records and user accounts. |
| 8 | Administrators must be able to generate reports for planning and analysis. |
| 9 | The system must provide role-based access control. |
| 10 | Users must be able to access the system remotely at any time. |
| 11 | Data must be stored securely using cloud-based storage. |
| 12 | The app must support real-time updates and notifications. |
| 13 | The system must be accessible via both mobile and web interfaces. |
| 14 | The system must allow file uploads for achievement verification. |
| 15 | The system must allow filtering and searching of student data by lecturers and admins. |
| 17 | Administrators must be able to query the system using **Natural Language (AI)** to gain insights. |

### 4.2.4 Hardware and Software Requirements
Table 4.5 details the hardware and software used to develop and run the system.

**Table 4.5: Hardware and Software Requirements**

| Aspect | Requirement |
| :--- | :--- |
| **Hardware** | • **Laptop**: Processor Intel Core i5/AMD Ryzen 5 or higher, 8GB+ RAM, 256GB+ SSD.<br>• **Mobile Device**: Android Smartphone (Android 10+) or iPhone (iOS 14+) for testing. |
| **OS** | Windows 10/11 (64-bit) |
| **Development Tools** | Visual Studio Code, Git, Postman (API Testing) |
| **Front-End** | **Flutter** (Mobile App), **Astro** (Web Dashboard), Tailwind CSS |
| **Back-End** | **FastAPI** (Python), Uvicorn |
| **Database** | **Supabase** (PostgreSQL) with `pgvector` extension |
| **AI Services** | Google Gemini API (Generative AI), LangChain |

## 4.3 System Analysis
System analysis is a process of decomposing a system into its component parts for the purpose of studying how well those component parts work and interact to accomplish their purpose. This section presents the Use Case Diagram and Use Case Specifications.

### 4.3.1 Use Case Diagram
Figure 4.1 shows the high-level Use Case Diagram for the Student Talent Profiling App, illustrating the interactions between the three main actors (Student, Lecturer, Administrator) and the system modules.

```mermaid
usecaseDiagram
    actor "Student" as S
    actor "Lecturer" as L
    actor "Administrator" as A

    package "Student Talent Profiling App" {
        usecase "Login / Authentication" as UC1
        usecase "Manage Talent Profile" as UC2
        usecase "Input Skills (Voice-to-Text)" as UC2_1
        usecase "Manage Achievements" as UC3
        usecase "Upload Achievement Proof" as UC3_1
        usecase "Browse & Register Events" as UC4
        usecase "View Event History" as UC4_1
        usecase "Post to Talent Showcase" as UC5
        usecase "View Talent Feed" as UC5_1

        usecase "Verify Achievements" as UC6
        usecase "Approve/Reject Achievement" as UC6_1
        usecase "Manage Events" as UC7
        usecase "Search Talent by Skill" as UC8

        usecase "Manage Users & Records" as UC9
        usecase "Query Data with AI" as UC10
        usecase "View System Analytics" as UC11
    }

    S --> UC1
    S --> UC2
    UC2 ..> UC2_1 : <<include>>
    S --> UC3
    UC3 ..> UC3_1 : <<include>>
    S --> UC4
    UC4 ..> UC4_1 : <<include>>
    S --> UC5
    S --> UC5_1

    L --> UC1
    L --> UC6
    UC6 ..> UC6_1 : <<extend>>
    L --> UC7
    L --> UC8

    A --> UC1
    A --> UC9
    A --> UC10
    A --> UC11
```

**Figure 4.1: Use Case Diagram of Student Talent Profiling App**

### 4.3.2 Use Case Specifications
The following tables describe the flow of events for the key use cases identified in Figure 4.1.

**Table 4.6: Login Module and Register Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Create initial use case<br>**1.0.1**: Fixed alternative flow in normal flow. Changed ID for alternative flow and exceptions.<br>**2.0.0**: Added history log. Functional requirements are added. |
| **Version** | 2.0.0 |
| **Use Case ID** | UC-01 |
| **Use Case Name** | Login Module and Register |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Student, Lecturer, Administrator |
| **Description** | Users login into the Student Talent Profiling App using valid credentials (Matrix ID/Staff ID and password). |
| **Preconditions** | Users must have a valid account in the system (Supabase Auth). |
| **Post conditions** | After successful login, the user is redirected to the main dashboard of the system. |
| **Normal Flow** | 1. The user enters their Matrix ID/Staff ID and password.<br>2. The system verifies the credentials against the Supabase database.<br>3. If the credentials are valid:<br>&nbsp;&nbsp;&nbsp;&nbsp;• The system checks if a talent profile exists in the database.<br>&nbsp;&nbsp;&nbsp;&nbsp;• If user has a talent profile, the user is redirected to their dashboard.<br>&nbsp;&nbsp;&nbsp;&nbsp;• If no profile exists, the user is prompted to create a new profile.<br>4. If credentials are invalid, the system displays an error message indicating invalid ID or password. |
| **Alternative Flow** | **A1. Register**<br>1. If the user is new to the app, they are asked to register and create a new profile.<br>2. The user will fill in required personal details.<br>3. The system displays a successful registration message and redirects user to the dashboard. |
| **Exceptions** | **E1. Invalid login**<br>1. If the credentials are invalid, the system displays an error message "Invalid username or password".<br><br>**E2. No Talent Profile**<br>1. If the user logs in successfully but has no profile, a message prompts "No profile found, please create a new one". The user is then redirected to profile creation page. |
| **Related requirement** | **FR01-01**: The system must verify credentials during login. (Basic)<br>**FR02-01**: If the user does not have a profile, the system prompts message to create a new one. (High)<br>**FR03-01**: The system should display appropriate error messages for invalid login attempts. (High) |

**Figure 4.2: Activity Diagram for Login Module and Register**

[Insert Figure 4.2: Activity Diagram for Login Module and Register here]

**Figure 4.3: Sequence Diagram for Login Module and Register**

[Insert Figure 4.3: Sequence Diagram for Login Module and Register here]

### 4.3.2.2 Use Case Specification: Manage Talent Profile
This use case details how students create and update their talent profiles.

**Table 4.7: Manage Talent Profile Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft<br>**2.0.0**: Revised flows for manual entry and photo upload. |
| **Version** | 2.0.0 |
| **Use Case ID** | UC-02 |
| **Use Case Name** | Manage Talent Profile |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Student |
| **Description** | Students create and update their talent profiles, including Bio, Skills, and Experience. |
| **Preconditions** | Student must be logged in. |
| **Post conditions** | Profile data is updated in the database. |
| **Normal Flow** | 1. User navigates to "My Profile" tab.<br>2. System displays current profile details.<br>3. User taps "Edit Profile".<br>4. User types updates in text fields (Bio, Skills).<br>5. User taps "Save".<br>6. System validates input.<br>7. System updates record in Supabase.<br>8. System displays "Profile Updated" success message. |
| **Alternative Flow** | **A1. Upload Profile Picture**<br>1. User taps "Change Photo".<br>2. System asks to select image from gallery.<br>3. User selects image.<br>4. System uploads image to Supabase Storage.<br>5. System updates profile avatar URL. |
| **Exceptions** | **E1. Save Failed**<br>1. System fails to update database (Network Error).<br>2. System displays "Update Failed, please check internet".<br>3. User prompted to retry. |
| **Related requirement** | **FR04-01**: The system must allow students to create and update their profiles. (Basic)<br>**FR04-02**: The system should allow lecturers and administrators to view profiles. (High)<br>**FR04-03**: The system must ensure all profiles are stored securely and can be retrieved when needed. (High) |

**Figure 4.4: Activity Diagram for Manage Talent Profile**

[Insert Figure 4.4: Activity Diagram for Manage Talent Profile here]

**Figure 4.5: Sequence Diagram for Manage Talent Profile**

[Insert Figure 4.5: Sequence Diagram for Manage Talent Profile here]

---

### 4.3.2.3 Use Case Specification: Manage Achievement
This use case details how students upload and manage their verified achievements.

**Table 4.8: Manage Achievement Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft |
| **Version** | 1.0.0 |
| **Use Case ID** | UC-03 |
| **Use Case Name** | Manage Achievement |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Student |
| **Description** | Students upload verified achievements (certificates, awards) as PDF or image files to build their digital portfolio. |
| **Preconditions** | Student must be logged in and have an existing profile. |
| **Post conditions** | Achievement record is created in the database with file reference stored in Supabase Storage. |
| **Normal Flow** | 1. User navigates to "Achievements" tab.<br>2. System displays list of existing achievements.<br>3. User taps "Add New Achievement".<br>4. User fills in achievement details (Title, Date, Description).<br>5. User selects file (PDF/JPG) from device.<br>6. User taps "Upload".<br>7. System uploads file to Supabase Storage.<br>8. System creates achievement record with file URL.<br>9. System displays "Achievement Added" success message. |
| **Alternative Flow** | **A1. View Achievement Details**<br>1. User taps on an existing achievement card.<br>2. System displays full details and file preview.<br>3. User can download or share the file. |
| **Exceptions** | **E1. Upload Failed**<br>1. File size exceeds limit or network error occurs.<br>2. System displays "Upload Failed, please try again".<br>3. User prompted to retry or select smaller file. |
| **Related requirement** | **FR05-01**: Users shall be able to upload files (PDF/JPG) as proof of achievement. (High)<br>**FR05-02**: The system shall store file references in Supabase Storage buckets. (High)<br>**FR05-03**: Users shall be able to view, edit, and delete their achievements. (Basic) |

**Figure 4.6: Activity Diagram for Manage Achievement**

[Insert Figure 4.6: Activity Diagram for Manage Achievement here]

**Figure 4.7: Sequence Diagram for Manage Achievement**

[Insert Figure 4.7: Sequence Diagram for Manage Achievement here]

---

### 4.3.2.4 Use Case Specification: Register Event
This use case details how students browse and register for academic or co-curricular events.

**Table 4.9: Register Event Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft |
| **Version** | 1.0.0 |
| **Use Case ID** | UC-04 |
| **Use Case Name** | Register Event |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Student, Lecturer/Organizer |
| **Description** | Students browse available events posted by organizers, view event details, and register to participate. Organizers can create and manage events. |
| **Preconditions** | Student must be logged in. Event must be published and have available slots. |
| **Post conditions** | Student registration is recorded in the database. Event participant count is updated. |
| **Normal Flow** | 1. User navigates to "Events" tab.<br>2. System displays list of available events.<br>3. User taps on an event card.<br>4. System displays event details (Title, Date, Venue, Description, Capacity).<br>5. User taps "Register".<br>6. System validates slot availability.<br>7. System creates registration record.<br>8. System displays "Registration Successful" message. |
| **Alternative Flow** | **A1. Create Event (Organizer)**<br>1. Organizer navigates to "Manage Events".<br>2. Organizer taps "Create New Event".<br>3. Organizer fills event details.<br>4. Organizer taps "Publish".<br>5. System creates event record and displays it to students. |
| **Exceptions** | **E1. Event Full**<br>1. Event capacity has been reached.<br>2. System displays "Event is full, registration closed".<br>3. User cannot register.<br><br>**E2. Already Registered**<br>1. User has already registered for this event.<br>2. System displays "You are already registered". |
| **Related requirement** | **FR06-01**: Organizers shall be able to create events with details (Date, Venue, Capacity). (High)<br>**FR06-02**: Students shall be able to browse available events and register. (High)<br>**FR06-03**: The system shall track student event participation history. (Basic) |

**Figure 4.8: Activity Diagram for Register Event**

[Insert Figure 4.8: Activity Diagram for Register Event here]

**Figure 4.9: Sequence Diagram for Register Event**

[Insert Figure 4.9: Sequence Diagram for Register Event here]

---

### 4.3.2.5 Use Case Specification: Talent Showcase
This use case details how students post and view talent showcase content on the public feed.

**Table 4.10: Talent Showcase Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft |
| **Version** | 1.0.0 |
| **Use Case ID** | UC-05 |
| **Use Case Name** | Talent Showcase |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Student, Lecturer, Administrator |
| **Description** | Students create posts to showcase their talents, projects, or achievements on a public feed. Other users can view, like, and interact with these posts. |
| **Preconditions** | User must be logged in. Student must have an existing profile. |
| **Post conditions** | Showcase post is created and visible on the public feed. Like/view counts are tracked. |
| **Normal Flow** | 1. User navigates to "Showcase" tab.<br>2. System displays feed of showcase posts.<br>3. User taps "Create Post".<br>4. User enters post content (Title, Description, Images).<br>5. User taps "Publish".<br>6. System uploads media to Supabase Storage.<br>7. System creates post record.<br>8. System displays "Post Published" success message. |
| **Alternative Flow** | **A1. View and Like Post**<br>1. User scrolls through the showcase feed.<br>2. User taps on a post to view details.<br>3. User taps "Like" button.<br>4. System increments like count. |
| **Exceptions** | **E1. Upload Failed**<br>1. Media file too large or network error.<br>2. System displays "Upload Failed, please try again".<br>3. User prompted to retry. |
| **Related requirement** | **FR07-01**: Students shall be able to create showcase posts with media attachments. (High)<br>**FR07-02**: Users shall be able to view and like showcase posts. (Basic)<br>**FR07-03**: The system shall display a public feed of all showcase posts. (High) |

**Figure 4.10: Activity Diagram for Talent Showcase**

[Insert Figure 4.10: Activity Diagram for Talent Showcase here]

**Figure 4.11: Sequence Diagram for Talent Showcase**

[Insert Figure 4.11: Sequence Diagram for Talent Showcase here]

---

### 4.3.2.6 Use Case Specification: View Student Profile
This use case details how lecturers and administrators view detailed student profiles.

**Table 4.11: View Student Profile Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft |
| **Version** | 1.0.0 |
| **Use Case ID** | UC-06 |
| **Use Case Name** | View Student Profile |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Lecturer, Administrator |
| **Description** | Lecturers and administrators view comprehensive student profiles including skills, achievements, event participation, and portfolio content. |
| **Preconditions** | User must be logged in as Lecturer or Administrator. |
| **Post conditions** | Student profile data is displayed to the user. |
| **Normal Flow** | 1. User navigates to "Students" section.<br>2. System displays list of students.<br>3. User taps on a student card.<br>4. System retrieves student profile data from database.<br>5. System displays student details (Bio, Skills, Achievements, Events).<br>6. User can view attached certificates and showcase posts. |
| **Alternative Flow** | **A1. Download Student Portfolio**<br>1. User taps "Export Profile".<br>2. System generates PDF summary of student profile.<br>3. System downloads file to user device. |
| **Exceptions** | **E1. Profile Not Found**<br>1. Student record does not exist or was deleted.<br>2. System displays "Profile not found" error. |
| **Related requirement** | **FR08-01**: Lecturers shall be able to view student profiles. (High)<br>**FR08-02**: Administrators shall have full access to all student data. (High)<br>**FR08-03**: The system shall display achievements and event history in profile view. (Basic) |

**Figure 4.12: Activity Diagram for View Student Profile**

[Insert Figure 4.12: Activity Diagram for View Student Profile here]

**Figure 4.13: Sequence Diagram for View Student Profile**

[Insert Figure 4.13: Sequence Diagram for View Student Profile here]

---

### 4.3.2.7 Use Case Specification: Search Students
This use case details how administrators and lecturers search for students based on skills or achievements.

**Table 4.12: Search Students Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft |
| **Version** | 1.0.0 |
| **Use Case ID** | UC-07 |
| **Use Case Name** | Search Students |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Lecturer, Administrator |
| **Description** | Lecturers and administrators search for students using filters such as skills, achievements, faculty, or event participation. |
| **Preconditions** | User must be logged in as Lecturer or Administrator. |
| **Post conditions** | Filtered list of students is displayed. |
| **Normal Flow** | 1. User navigates to "Search" section.<br>2. User enters search criteria (e.g., "Python", "Java").<br>3. User applies filters (Faculty, Year, etc.).<br>4. User clicks "Search".<br>5. System queries database with filters.<br>6. System displays matching student profiles. |
| **Alternative Flow** | **A1. No Results Found**<br>1. No students match the criteria.<br>2. System displays "No students found" message.<br>3. User modifies search criteria. |
| **Exceptions** | **E1. Search Timeout**<br>1. Query takes too long due to large dataset.<br>2. System displays "Request timed out, try narrower filters". |
| **Related requirement** | **FR09-01**: The system shall allow filtering and searching of student data. (High)<br>**FR09-02**: Search results shall display relevant student information. (Basic)<br>**FR09-03**: Filters shall include skills, faculty, and achievements. (High) |

**Figure 4.14: Activity Diagram for Search Students**

[Insert Figure 4.14: Activity Diagram for Search Students here]

**Figure 4.15: Sequence Diagram for Search Students**

[Insert Figure 4.15: Sequence Diagram for Search Students here]

---

### 4.3.2.8 Use Case Specification: Admin Dashboard
This use case details how administrators access the web dashboard for analytics and reporting.

**Table 4.13: Admin Dashboard Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft |
| **Version** | 1.0.0 |
| **Use Case ID** | UC-08 |
| **Use Case Name** | Admin Dashboard |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Administrator |
| **Description** | Administrators access the web-based dashboard to view system analytics, student statistics, and generate reports. |
| **Preconditions** | User must be logged in as Administrator via web dashboard. |
| **Post conditions** | Analytics data is displayed on the dashboard. |
| **Normal Flow** | 1. Admin opens web dashboard URL.<br>2. Admin logs in with credentials.<br>3. System displays dashboard home with summary cards.<br>4. Admin views charts (Total Students, Achievements, Events).<br>5. Admin can navigate to detailed sections. |
| **Alternative Flow** | **A1. Export Report**<br>1. Admin clicks "Generate Report".<br>2. System compiles data into PDF/Excel.<br>3. System downloads report file. |
| **Exceptions** | **E1. Data Load Failed**<br>1. Database connection error.<br>2. System displays "Unable to load data, please refresh". |
| **Related requirement** | **FR10-01**: Administrators shall access a web dashboard for analytics. (High)<br>**FR10-02**: Dashboard shall display student and event statistics. (High)<br>**FR10-03**: Administrators shall be able to export reports. (Basic) |

**Figure 4.16: Activity Diagram for Admin Dashboard**

[Insert Figure 4.16: Activity Diagram for Admin Dashboard here]

**Figure 4.17: Sequence Diagram for Admin Dashboard**

[Insert Figure 4.17: Sequence Diagram for Admin Dashboard here]

---

### 4.3.2.9 Use Case Specification: AI Query
This use case details how administrators use natural language to query the system via RAG Chatbot.

**Table 4.14: AI Query Use Case Specification**

| Aspect | Detail |
| :--- | :--- |
| **History Log** | **1.0.0**: Initial Draft |
| **Version** | 1.0.0 |
| **Use Case ID** | UC-09 |
| **Use Case Name** | AI Query |
| **Created By** | Muhammad Noor Azami |
| **Updated By** | Muhammad Noor Azami |
| **Date Created** | 27/12/2025 |
| **Last Revision Date** | 27/12/2025 |
| **Actors** | Administrator |
| **Description** | Administrators use the RAG (Retrieval-Augmented Generation) Chatbot to query student data using natural language (e.g., "List students with Python skills"). |
| **Preconditions** | User must be logged in as Administrator. RAG service must be running. |
| **Post conditions** | AI-generated response is displayed based on the query. |
| **Normal Flow** | 1. Admin navigates to "AI Assistant" section.<br>2. Admin types query in natural language.<br>3. System sends query to RAG backend.<br>4. Backend performs vector search on student data.<br>5. Backend generates response using LLM (Gemini).<br>6. System displays AI response with relevant student data. |
| **Alternative Flow** | **A1. Follow-up Question**<br>1. Admin asks a follow-up question.<br>2. System maintains conversation context.<br>3. System generates contextual response. |
| **Exceptions** | **E1. AI Service Unavailable**<br>1. RAG backend is down or unresponsive.<br>2. System displays "AI service temporarily unavailable".<br><br>**E2. No Matching Data**<br>1. Query returns no results from vector search.<br>2. AI responds with "No matching students found for your query". |
| **Related requirement** | **FR11-01**: Administrators must be able to query the system using natural language. (High)<br>**FR11-02**: The system shall use RAG (Vector Search) for context retrieval. (High)<br>**FR11-03**: AI responses shall be generated using Google Gemini LLM. (High) |

**Figure 4.18: Activity Diagram for AI Query**

[Insert Figure 4.18: Activity Diagram for AI Query here]

**Figure 4.19: Sequence Diagram for AI Query**

[Insert Figure 4.19: Sequence Diagram for AI Query here]

---

## 4.3.4 Class Diagram

A class diagram is a type of UML diagram that visually represents the structure of a system by showing its classes, their attributes, methods, and relationships. It's used in object-oriented software design to model the static structure of a system.

Figure 4.20 shows UML diagram for overall Student Talent Profiling App with labelled data type to use for better workflow when developing the system app.

**Table 4.15: Class Diagram - Classes and Attributes**

| Class Name | Attributes | Data Type | Description |
| :--- | :--- | :--- | :--- |
| **User** | id | UUID | Primary key identifier |
| | email | String | User email address |
| | name | String | User display name |
| | role | String | "student", "lecturer", "admin" |
| | department | String | Faculty/Department |
| | student_id | String | Matrix ID (students) |
| | staff_id | String | Staff ID (lecturers/admin) |
| | is_active | Boolean | Account status |
| | profile_completed | Boolean | Profile completion flag |
| | created_at | DateTime | Registration timestamp |
| **Profile** | id | String | Primary key |
| | user_id | String | FK to User |
| | full_name | String | Student full name |
| | bio | Text | Biography |
| | skills | Array[String] | List of skills |
| | interests | Array[String] | List of interests |
| | experiences | JSON | Work/project experience |
| | cgpa | String | Academic grade |
| | linkedin_url | String | Social link |
| | github_url | String | Social link |
| **Achievement** | id | String | Primary key |
| | user_id | String | FK to User |
| | title | String | Achievement title |
| | description | Text | Details |
| | category | String | "academic", "technical", etc. |
| | image_urls | JSON | Array of image URLs |
| | document_urls | JSON | Array of document URLs |
| | is_verified | Boolean | Verification status |
| | date_achieved | DateTime | Achievement date |
| **Event** | id | UUID | Primary key |
| | title | String | Event title |
| | description | Text | Event details |
| | category | String | Event category |
| | event_date | DateTime | Event date/time |
| | location | String | Venue |
| | max_participants | Integer | Capacity limit |
| | organizer_id | UUID | FK to User (organizer) |
| | is_active | Boolean | Event status |
| **EventParticipation** | id | UUID | Primary key |
| | event_id | UUID | FK to Event |
| | user_id | UUID | FK to User |
| | attendance_status | String | "registered", "attended", "no_show" |
| | registration_date | DateTime | Registration timestamp |
| **ShowcasePost** | id | UUID | Primary key |
| | user_id | UUID | FK to User |
| | title | String | Post title |
| | content | Text | Post content |
| | category | String | Post category |
| | media_urls | JSON | Array of media URLs |
| | tags | JSON | Array of tags |
| | likes_count | Integer | Number of likes |
| | comments_count | Integer | Number of comments |
| | is_public | Boolean | Visibility flag |
| | created_at | DateTime | Post timestamp |

**Table 4.16: Class Relationships**

| Relationship | Class A | Class B | Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| 1 | User | Profile | 1:1 | One user has one profile |
| 2 | User | Achievement | 1:N | One user has many achievements |
| 3 | User | Event | 1:N | One user (organizer) creates many events |
| 4 | User | EventParticipation | 1:N | One user joins many events |
| 5 | Event | EventParticipation | 1:N | One event has many participants |
| 6 | User | ShowcasePost | 1:N | One user creates many posts |
| 7 | ShowcasePost | ShowcaseLike | 1:N | One post has many likes |
| 8 | ShowcasePost | ShowcaseComment | 1:N | One post has many comments |

**Figure 4.20: Class Diagram for Student Talent Profiling App**

[Insert Figure 4.20: Class Diagram here]

---

## 4.3.5 Entity Relationship Diagram (ERD)

An Entity Relationship Diagram (ERD) illustrates the logical structure of databases by showing the entities (tables), their attributes, and the relationships between them. The ERD is essential for understanding how data is organized and connected within the Student Talent Profiling App.

The system uses **Supabase (PostgreSQL)** as the database backend. Figure 4.21 shows the complete ERD for the application.

**Figure 4.21: Entity Relationship Diagram (ERD)**

[Insert Figure 4.21: ERD Diagram here]

---

## 4.3.6 Flowchart

A flowchart is a graphical representation of a process or algorithm, showing the steps as boxes and their order by connecting them with arrows. It helps visualize the system flow and decision-making processes within the application.

Figure 4.22 illustrates the overall system flowchart for the Student Talent Profiling App, showing how users navigate through the application from login to accessing various modules.

**Figure 4.22: System Flowchart for Student Talent Profiling App**

[Insert Figure 4.22: System Flowchart here]

---

# 4.4 Design

This section presents the design aspects of the Student Talent Profiling App, including system architecture, database design, and interface design.

## 4.4.1 System Architecture

The system architecture diagram illustrates the overall structure and components of the Student Talent Profiling App. It shows how different layers and services interact with each other.

The application follows a **three-tier architecture**:

1. **Presentation Layer (Frontend)**
   - **Mobile App**: Built with Flutter (Dart) for cross-platform iOS/Android support
   - **Web Dashboard**: Built with Astro framework for admin/lecturer access

2. **Application Layer (Backend)**
   - **FastAPI**: Python-based REST API server handling business logic
   - **AI Services**: 
     - Google Gemini LLM for natural language processing
     - LangChain for RAG (Retrieval-Augmented Generation)
     - Vector Search for semantic queries

3. **Data Layer**
   - **Supabase**: PostgreSQL database for structured data storage
   - **Supabase Storage**: Cloud storage for media files (PDFs, images)
   - **Supabase Auth**: Authentication and session management

**Table 4.17: System Architecture Components**

| Layer | Component | Technology | Description |
| :--- | :--- | :--- | :--- |
| Frontend | Mobile App | Flutter (Dart) | Cross-platform mobile application for students |
| Frontend | Web Dashboard | Astro | Web-based admin dashboard for lecturers/admins |
| Backend | API Server | FastAPI (Python) | REST API handling all business logic |
| Backend | AI Assistant | LangChain + Gemini | RAG-powered chatbot for natural language queries |
| Database | Primary DB | Supabase (PostgreSQL) | Stores users, profiles, achievements, events |
| Database | File Storage | Supabase Storage | Stores uploaded certificates and media |
| Auth | Authentication | Supabase Auth | Handles login, registration, session tokens |

**Figure 4.23: System Architecture Diagram**

[Insert Figure 4.23: System Architecture Diagram here]

---

## 4.4.2 Database Design

The database design outlines the schema structure used to store and manage data within the Student Talent Profiling App. The system uses **Supabase (PostgreSQL)** as the primary database.

### 4.4.2.1 Users Table

Stores core authentication and user identity data.

**Table 4.18: Users Table Schema**

| Attribute | Data Type | Size | Key | Description |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Primary key identifier |
| email | VARCHAR | 255 | Unique | User email address |
| name | VARCHAR | 255 | | Full name for display |
| role | VARCHAR | 50 | | student, lecturer, or admin (Default: 'student') |
| department | VARCHAR | 100 | | Faculty or department name |
| student_id | VARCHAR | 20 | | Matrix ID for students |
| staff_id | VARCHAR | 20 | | Staff ID for lecturers/admin |
| is_active | BOOLEAN | 1 | | Account status (Default: true) |
| profile_completed | BOOLEAN | 1 | | Flag for onboarding completion (Default: false) |
| created_at | TIMESTAMPTZ | N/A | | Registration timestamp |

### 4.4.2.2 Profiles Table

Stores extended student profile data, including RAG-ready fields for AI analysis.

**Table 4.19: Profiles Table Schema**

| Attribute | Data Type | Size | Key | Description |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Primary key (match user_id) |
| user_id | UUID | N/A | FK | Link to user account (users.id) |
| full_name | VARCHAR | 255 | | Complete name |
| bio | TEXT | N/A | | Personal biography |
| headline | VARCHAR | 255 | | Professional summary headline |
| academic_info | JSONB | N/A | | Complex academic data (CGPA, semester) |
| skills | ARRAY (TEXT) | N/A | | List of student skills |
| experiences | JSONB | N/A | | Past work or volunteer history |
| projects | JSONB | N/A | | List of projects completed |
| kokurikulum_score | NUMERIC | N/A | | Score for co-curricular activities |
| talent_quiz_results | JSONB | N/A | | Results from personality/talent quizzes |
| created_at | TIMESTAMPTZ | N/A | | Profile creation date |

### 4.4.2.3 Showcase Posts Table

Stores portfolio content shared by students to demonstrate their talents.

**Table 4.20: Showcase Posts Table Schema**

| Attribute | Data Type | Size | Key | Description |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique post identifier |
| user_id | UUID | N/A | FK | Author of the post (users.id) |
| title | VARCHAR | 255 | | Post title |
| content | TEXT | N/A | | Post text description |
| media_urls | ARRAY (TEXT) | N/A | | URLs to images or videos in storage |
| tags | ARRAY (TEXT) | N/A | | Categorization tags |
| view_count | INTEGER | N/A | | Performance metric |
| is_public | BOOLEAN | 1 | | Visibility toggle |
| is_approved | BOOLEAN | 1 | | Moderation status |

### 4.4.2.4 Events Table

Manages event listings and participation tracking.

**Table 4.21: Events Table Schema**

| Attribute | Data Type | Size | Key | Description |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Event ID |
| title | VARCHAR | 255 | | Name of the event |
| description | TEXT | N/A | | Full event details |
| event_date | TIMESTAMPTZ | N/A | | Scheduled date |
| location | VARCHAR | 255 | | Physical or virtual venue |
| current_participants| INTEGER | N/A | | Real-time count |
| max_participants | INTEGER | N/A | | Maximum capacity |
| category | VARCHAR | 50 | | Event type (Academic, Tech, etc.) |

### 4.4.2.5 Messaging Tables

Handles real-time communication between users (Students and PAK).

**Table 4.22: Conversations Table Schema**

| Attribute | Data Type | Size | Key | Description |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique chat thread ID |
| type | VARCHAR | 50 | | Conversation type (direct/group) |

**Table 4.23: Messages Table Schema**

| Attribute | Data Type | Size | Key | Description |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique message ID |
| conversation_id | UUID | N/A | FK | Reference to conversation |
| sender_id | UUID | N/A | FK | Reference to sender (users) |
| content | TEXT | N/A | | Message body |

---

## 4.4.3 Interface Design

This section presents the user interface design for the Student Talent Profiling App. The system consists of two main interfaces: a **Mobile Application** for students and a **Web Dashboard** for lecturers and administrators. The design focuses on user experience (UX) and usability, ensuring that the application is intuitive for all user types.

---

### 4.4.3.1 Mobile Application (Student Interface)

The mobile application is built using **Flutter** framework and serves as the primary interface for students to manage their talent profiles, achievements, and participate in campus activities.

#### 4.4.3.1.1 Authentication Screens

The login screen allows users to access the system securely. New students can register for an account using their university email.

**Figure 4.24: Mobile App - Login Screen**

[Insert Screenshot of Mobile Login Screen here]

**Figure 4.25: Mobile App - Registration Screen**

[Insert Screenshot of Mobile Registration Screen here]

#### 4.4.3.1.2 Student Dashboard

The dashboard serves as the central hub, providing quick access to profile stats, recent achievements, upcoming events, and navigation to other modules.

**Figure 4.26: Mobile App - Student Dashboard**

[Insert Screenshot of Student Dashboard here]

#### 4.4.3.1.3 Profile Management

The profile screen displays the student's personal information, skills, academic summary, and social links. Users can edit their details from this screen.

**Figure 4.27: Mobile App - View Profile Screen**

[Insert Screenshot of View Profile Screen here]

**Figure 4.28: Mobile App - Edit Profile Screen**

[Insert Screenshot of Edit Profile Screen here]

#### 4.4.3.1.4 Achievement Repository

This module allows students to view their verified achievements and upload new certificates for verification.

**Figure 4.29: Mobile App - Achievement List**

[Insert Screenshot of Achievement List here]

**Figure 4.30: Mobile App - Upload Achievement Form**

[Insert Screenshot of Upload Achievement Form here]

#### 4.4.3.1.5 Event Management

Students can browse available events, view details, and register for participation.

**Figure 4.31: Mobile App - Event Listing**

[Insert Screenshot of Event List here]

**Figure 4.32: Mobile App - Event Detail & Registration**

[Insert Screenshot of Event Detail/Registration here]

#### 4.4.3.1.6 Talent Showcase

The showcase feed allows students to post their work and interact with peers through likes and comments.

**Figure 4.33: Mobile App - Showcase Feed**

[Insert Screenshot of Showcase Feed here]

**Figure 4.34: Mobile App - Create Showcase Post**

[Insert Screenshot of Create Post Screen here]

#### 4.4.3.1.7 Messaging & Chat

Students can communicate with their Academic Advisors (PAK) through the built-in messaging system.

**Figure 4.35: Mobile App - Chat Interface**

[Insert Screenshot of Chat/Messaging Screen here]

---

### 4.4.3.2 Web Dashboard (Admin/Lecturer Interface)

The web dashboard is built using **Astro** framework and provides administrators and lecturers with tools to manage students, view analytics, and query data using AI.

#### 4.4.3.2.1 Admin Authentication

The web dashboard authentication interface serves as the secure entry point for administrators and lecturers to access the Student Talent Profiling system. This module implements role-based access control (RBAC) to ensure that only authorized personnel can view and manage student data.

**User Interface Components:**

The login page features a clean, professional design consistent with the institutional branding. The interface includes the following key elements:

1. **Email Input Field** - A text input field where users enter their registered staff email address. The field includes client-side validation to ensure proper email format before form submission.

2. **Password Input Field** - A secure password field with masked character display for privacy protection. Users can toggle password visibility using an eye icon button.

3. **Login Button** - A prominently styled button that initiates the authentication process. The button displays a loading indicator during the authentication request to provide user feedback.

4. **Error Display Area** - A dedicated section that displays error messages when authentication fails, such as "Invalid email or password" or "Account not found".

**Authentication Flow:**

When users submit their credentials, the system performs the following operations:
- Validates input format on the client side
- Sends credentials to Supabase Auth service via secure HTTPS connection
- Verifies user role (admin/lecturer) against the database
- Creates a session token stored in browser cookies for subsequent requests
- Redirects authenticated users to the main dashboard

**Security Measures:**

The authentication system implements industry-standard security practices including password hashing using bcrypt algorithm, SSL/TLS encryption for all data transmission, session timeout after 24 hours of inactivity, and protection against brute-force attacks through rate limiting.

**Figure 4.36: Web Dashboard - Admin Login**

[Insert Screenshot of Web Login Page here]

#### 4.4.3.2.2 Dashboard Analytics

The analytics dashboard serves as the central command center for administrators to monitor and analyze the talent ecosystem within the institution. This interface provides real-time insights into student performance, engagement metrics, and system activity through intuitive data visualizations.

**Key Performance Indicator (KPI) Cards:**

The top section of the dashboard displays summary cards that provide at-a-glance statistics:

1. **Total Students** - Displays the count of all registered students in the system with comparison to previous period growth. This metric helps administrators track user adoption and system reach.

2. **Total Achievements** - Shows the cumulative number of achievements uploaded by students, including verified and pending submissions. This indicates the level of student engagement with the portfolio feature.

3. **Active Events** - Presents the number of currently active events that students can register for, along with the total number of registered participants across all events.

4. **Average CGPA** - Calculates and displays the mean CGPA across all student profiles, providing insight into the overall academic performance of the student body.

5. **At-Risk Students** - Highlights students flagged by the AI predictive model as potentially needing academic intervention based on CGPA trends and engagement patterns.

**Data Visualization Charts:**

The dashboard incorporates interactive charts powered by Chart.js library:

1. **Faculty Distribution Chart** - A pie or doughnut chart showing the breakdown of students by faculty/department, enabling administrators to see which faculties are most active on the platform.

2. **Skills Distribution Chart** - A horizontal bar chart displaying the most common skills among students, helping identify talent trends and skill gaps within the institution.

3. **Event Participation Trend** - A line chart showing event registration trends over time, useful for planning future events and measuring engagement initiatives.

4. **Achievement Categories Chart** - A bar chart categorizing achievements by type (academic, technical, leadership, creative), providing insight into the diverse talents of students.

**Interactive Features:**

Administrators can interact with the dashboard through filtering options that allow data segmentation by faculty, date range, and student cohort. Clicking on chart elements reveals detailed breakdowns, and hovering over data points displays additional context information.

**Figure 4.37: Web Dashboard - Analytics Overview**

[Insert Screenshot of Dashboard Analytics here]

#### 4.4.3.2.3 Student Management

Administrators can view the list of all registered students, search by skills or achievements, and access individual student profiles.

**Figure 4.38: Web Dashboard - Student List**

[Insert Screenshot of Student List/Table here]

**Figure 4.39: Web Dashboard - Edit Student Data**

[Insert Screenshot of Edit Student Data Form here]

#### 4.4.3.2.4 Event Management

Lecturers and administrators can create, edit, and manage campus events. They can also view participation statistics.

**Figure 4.40: Web Dashboard - Event Management**

[Insert Screenshot of Event Management Page here]

#### 4.4.3.2.5 AI Assistant (RAG Chatbot)

The AI Assistant allows administrators to query student data using natural language. The system uses RAG (Retrieval-Augmented Generation) to provide accurate responses.

**Figure 4.41: Web Dashboard - AI Assistant Chat**

[Insert Screenshot of AI Chat Interface here]

#### 4.4.3.2.6 Report Generation

Administrators can generate PDF reports containing student statistics, achievement summaries, and analytics data.

**Figure 4.42: Web Dashboard - Report Generation**

[Insert Screenshot of Report Generation Page here]
