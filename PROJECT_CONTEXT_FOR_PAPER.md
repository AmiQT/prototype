# Project Context Summary for Research Paper

## 1. Project Overview
**Title:** Student Talent Profiling App (UTHM)
**Purpose:** A comprehensive talent management system designed for Universiti Tun Hussein Onn Malaysia (UTHM) to profile students, track achievements, and provide AI-driven insights for talent development.
**Target Audience:** Students (Mobile App), Lecturers/Admins (Web Dashboard).

## 2. Tech Stack Details
The project utilizes a modern, cross-platform architecture:

### Mobile Application (Frontend)
- **Framework:** **Flutter** (Dart SDK >=3.0.0 <4.0.0)
- **State Management:** Provider
- **Key Dependencies:**
  - `supabase_flutter`: Backend connectivity.
  - `google_fonts`: Custom typography.
  - `speech_to_text` & `flutter_tts`: Voice interaction features.
  - `video_compress` & `image_picker`: Media handling for portfolio uploads.
  - **Cloudinary:** Cloud storage for optimization of high-res images and portfolio videos.

### Backend (API & AI)
- **Framework:** **FastAPI** (Python)
- **Database:** **Supabase** (PostgreSQL)
- **Media Storage:** **Cloudinary** (Secure hosting for certificate artifacts and user content).
- **AI/ML Layer:**
  - **LangChain & LangGraph:** Orchestration framework for Agentic AI.
  - **Google Gemini:** Core LLM for reasoning and content generation (`google-generativeai`).
  - **Vector Storage:** ChromaDB/FAISS (implied in requirements) for RAG capabilities.
  - **NLP:** Spacy & NLTK for text analysis.

### Web Dashboard (Admin)
- **Framework:** **Astro** (v5.0+)
- **Styling:** **TailwindCSS** (v4.0)
- **Visualization:** `chart.js` for analytics graphs.
- **Reporting:** `jspdf` & `jspdf-autotable` for generating PDF reports.

## 3. AI Architecture: Agentic AI with Gemini
The system implements a sophisticated **Agentic AI** model rather than a simple chatbot.

### Core Components
*   **Agent Definition:** `StudentTalentAgent` (in `backend/app/ai_assistant/langchain_agent/agent.py`) is the central intelligence. It uses **LangGraph** to define a state machine workflow that cycles between `agent` (reasoning) and `tools` (execution).
*   **Tool Calling:** The agent is equipped with a rich set of custom tools (defined in `tools.py`) that allow it to interact with the database and external services. Key tools include:
    *   `query_students`: detailed filtering of student data.
    *   `predictive_insights`: AI forecasting of student trends.
    *   `analyze_student_names`: NLP-based demographic analysis.
    *   `advanced_analytics`: complex cross-entity analysis.
*   **Conversation Memory:** A custom `ConversationMemory` system (`conversation_memory.py`) persits session history, context, and entities. This allows the AI to "remember" previous interactions and user preferences across a session.
*   **Workflow:**
    1.  User input is processed by the **LLM (Gemini)**.
    2.  The model decides if a **Tool Call** is needed (e.g., "Check student CGPA").
    3.  If yes, the system executes the specific Python function in `tools.py`.
    4.  Results are fed back to the LLM.
    5.  The LLM generates a final natural language response based on the data.

## 4. Folder Structure (Source Code)
The repository is organized into three main monorepo components:

*   **`/mobile_app`**: The Flutter codebase for the student-facing mobile application. Key directories include `lib/screens` (UI views), `lib/services` (API logic), and `lib/widgets` (reusable components).
*   **`/backend`**: The Python FastAPI server.
    *   `app/ai_assistant`: Core AI logic (agents, tools, memory).
    *   `app/routers`: API endpoints.
    *   `app/ml_analytics`: Machine learning models for specific predictions.
*   **`/web_dashboard_astro`**: The Astro-based web portal for administrators. Contains `src/pages` (routes) and `src/components` (UI elements).

## 5. Core Logic Implementation

### Automated PDF Achievement Report
*   **Location:** `web_dashboard_astro/src/pages/dashboard/analytics.astro`
*   **Process:**
    *   On the Analytics dashboard, a "Generate Report" button (`id="generate-report-btn"`) triggers the generation process.
    *   The `jspdf` library creates a document instance.
    *   `jspdf-autotable` is used to convert HTML tables (like Department Distribution) or raw data arrays directly into a formatted PDF table.
    *   The system creates charts using `Chart.js` (e.g., Skills, Risk Distribution) and embeds them as images into the PDF for a visual summary.
    *   **Logic:** The report automates the compilation of "Total Students", "Average CGPA", and "Risk Levels" into a downloadable file for administrative reviews.

### Student Profiling Logic
*   **Data Collection:** Students profile themselves via the Mobile App (`achievements_screen.dart`), uploading certificates and entering details.
*   **AI Analysis:** The backend uses the `StudentTalentAgent` to analyze this data.
    *   **Demographics:** `analyze_student_names` tool infers gender and demographics from names for rapid profiling without sensitive questions.
    *   **Risk & Talent Prediction:** The `predictive_insights` tool analyzes historical patterns (CGPA trends, participation rates) to flag "At Risk" students or identify "High Potential" talent.
    *   **Smart Querying:** The `query_profiles` tool allows admins to search for students based on semantic matches of skills and interests (e.g., "Find students good at AI" matches profiles with "Machine Learning").

## 6. Functional Requirements (Modules)

### Module 1: Student Talent Profiling
This module serves as the core data collection engine for student skills, achievements, and academic background.
*   **Requirement 1.1:** The system must allow students to input academic details (CGPA, Faculty, Department).
*   **Requirement 1.2:** The system must allow students to upload achievement artifacts (certificates in PDF/Image format) and tag them with relevant skills.
*   **Requirement 1.3:** The system must utilize AI to parse uploaded certificates and auto-suggest achievement titles and descriptions.

### Module 2: AI Analytics & Reporting
This module empowers administrators with data-driven insights.
*   **Requirement 2.1:** The system must generate an automated PDF Achievement Report containing statistical summaries (CGPA trends, risk distribution) and visual charts.
*   **Requirement 2.2:** The system must provide a 'Risk Analysis' feature that flags students with low engagement or academic performance using predictive modeling.

### Module 3: Event Management
*   **Requirement 3.1:** The system must allow authorized users (organizers) to create, edit, and publish campus events.
*   **Requirement 3.2:** The system must track student precipitation in events to calculate 'Kokurikulum Score'.

### Module 4: Communication & Collaboration
*   **Requirement 4.1:** The system must support real-time Direct Messaging (Chat) between students and advisors/lecturers.

## 7. Non-Functional Requirements
*   **NFR 1 (Performance):** The system ensures AI response latency is under 2 seconds for text queries and under 5 seconds for complex data analysis.
*   **NFR 2 (Scalability):** The database design supports horizontal scaling to accommodate the entire UTHM student population (estimated 15,000+ users).
*   **NFR 3 (Security):** All user data, especially academic records and personal chats, must be encrypted at rest and in transit using SSL/TLS.
*   **NFR 4 (Usability):** The mobile application must follow Material Design guidelines to ensure an intuitive and accessible user experience for students.

## 8. User Requirements
### Student Role
*   "As a student, I want to easily upload my competition certificates so that my talent profile is always up-to-date."
*   "As a student, I need to see my 'Academic vs. Co-curricular' balance chart to know if I need to participate in more events."

### Lecturer/Advisor Role
*   "As an advisor, I want to filter my supervisees by risk level so I can intervene with struggling students early."
*   "As a lecturer, I need to generate a monthly performance report of my department in PDF format for meetings."

### Admin Role
*   "As an admin, I require a dashboard that gives me a high-level overview of the entire campus talent distribution."

## 9. System Design (Database Schema)

### Table: Users
| Attributes | Data Type | Size | Key | Descriptions |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique identifier for each user (matches Supabase Auth) |
| email | VARCHAR | 255 | UQ | User’s email address |
| role | VARCHAR | 50 | | User’s role (student, lecturer, admin) |
| created_at | TIMESTAMP | N/A | | Timestamp of account creation |

### Table: Profiles
| Attributes | Data Type | Size | Key | Descriptions |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK, FK | Foreign Key linking to `users.id` |
| full_name | VARCHAR | 255 | | User’s full display name |
| cgpa | VARCHAR | 10 | | Cumulative Grade Point Average |
| kokurikulum_score | FLOAT | N/A | | Calculated score for extracurricular involvement |
| skills | ARRAY | N/A | | List of technical and soft skills |

### Table: Achievements
*(Note: Pending migration in live DB, definition based on application logic)*
| Attributes | Data Type | Size | Key | Descriptions |
| :--- | :--- | :--- | :--- | :--- |
| id | VARCHAR | 128 | PK | Unique identifier for achievement |
| user_id | UUID | N/A | FK | Link to the student who owns this achievement |
| title | VARCHAR | 255 | | Title of the verified achievement |
| image_urls | JSON | N/A | | URLs to stored proof images/certificates |
| is_verified | BOOLEAN | 1 | | Status flag (True = Verified by Admin) |

### Table: Events
| Attributes | Data Type | Size | Key | Descriptions |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique identifier for event |
| title | VARCHAR | 255 | | Name of the event |
| event_date | TIMESTAMP | N/A | | Scheduled date and time of event |
| check_in_code | VARCHAR | 6 | | Code for attendance tracking |
| venue | VARCHAR | 255 | | Physical location or meeting link |
| max_participants | INT | 11 | | Capacity limit for the event |
| organizer_id | UUID | N/A | FK | Link to User who created the event |

### Table: Showcase Posts
| Attributes | Data Type | Size | Key | Descriptions |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique ID for portfolio showcase posts |
| user_id | UUID | N/A | FK | Link to student author |
| content | TEXT | N/A | | Main textual content of the post |
| likes | ARRAY | N/A | | Array of User IDs who liked the post |
| reactions | JSONB | N/A | | Rich reactions data (e.g. love, celebrate) |

### Table: Conversations
| Attributes | Data Type | Size | Key | Descriptions |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique ID for a chat thread |

### Table: Messages
| Attributes | Data Type | Size | Key | Descriptions |
| :--- | :--- | :--- | :--- | :--- |
| id | UUID | N/A | PK | Unique ID for specific message |
| conversation_id | UUID | N/A | FK | Link to parent conversation |
| sender_id | UUID | N/A | FK | Link to user who sent the message |
| content | TEXT | N/A | | The text payload of the message |
