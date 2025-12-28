## 5.4 System Case Testing

This section presents the comprehensive testing performed on the system to ensure functional correctness and reliability. The testing process covers six main modules: User Authentication, Web Dashboard, Mobile Application, AI & Analytics Services, Student Profiling & Gamification, and Backend Security.

### 5.4.1 User Authentication Module

Table 5.1 presents the test cases for the User Authentication module, covering login, registration, and role-based access control.

**Table 5.1: User Authentication Module Test Cases**

| ID | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| TC-AUTH-01 | Admin login with valid credentials | System validates credentials and redirects to Dashboard Overview. | Pass |
| TC-AUTH-02 | Admin login with invalid password | System rejects access and displays "Invalid credentials" error message. | Pass |
| TC-AUTH-03 | Student login via Mobile App | System authenticates student and loads Student Dashboard. | Pass |
| TC-AUTH-04 | Accessing protected route without session | System redirects user back to Login page. | Pass |
| TC-AUTH-05 | Role-based redirection (Admin vs Student) | Admin triggers Web Dashboard load; Student triggers Mobile Home load. | Pass |
| TC-AUTH-06 | Logout functionality | Session is terminated, cookies cleared, and user redirected to Login. | Pass |

### 5.4.2 Web Dashboard Module

Table 5.2 benchmarks the functional testing of the Administrative Web Dashboard key features.

**Table 5.2: Web Dashboard Module Test Cases**

| ID | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| TC-WEB-01 | View Dashboard Statistics | Total Users, Active Events, and Profile stats load correctly from database. | Pass |
| TC-WEB-02 | Generate Analytics PDF Report | System compiles charts/data and downloads a formatted PDF file. | Pass |
| TC-WEB-03 | Create New Event (with Image) | Event details saved to DB, image uploaded to Cloudinary, success message shown. | Pass |
| TC-WEB-04 | Filter User List by Department | User table updates to show only students from selected department. | Pass |
| TC-WEB-05 | Bulk Delete Users | Selected users are marked inactive/deleted in database. | Pass |
| TC-WEB-06 | Update System Settings | Theme preference (Dark/Light) is saved and applied immediately. | Pass |

### 5.4.3 Mobile Application Module

Table 5.3 outlines the testing scenarios for the Student Mobile Application features.

**Table 5.3: Mobile Application Module Test Cases**

| ID | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| TC-MOB-01 | View Student Profile | Profile data including CGPA and skills is fetched and displayed. | Pass |
| TC-MOB-02 | Submit Showcase Post | Post with text/image appears in the community feed in real-time. | Pass |
| TC-MOB-03 | Search for Peers (Filter) | Search results return students matching the selected specific skills. | Pass |
| TC-MOB-04 | Join Event (Payment Gateway) | User redirected to ToyyibPay, payment processes, status updates to 'Paid'. | Pass |
| TC-MOB-05 | Upload Achievement Certificate | File uploads successfully, achievement marked as 'Pending Verification'. | Pass |
| TC-MOB-06 | Receive Push Notification | Notification banner appears when a new event is posted. | Pass |

### 5.4.4 AI & Analytics Module

Table 5.4 focuses on the intelligent features driven by Machine Learning and Generative AI.

**Table 5.4: AI & Analytics Services Test Cases**

| ID | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| TC-AI-01 | Predict Student Risk (Low Risk) | ML Engine returns 'Low Risk' score for student with high CGPA/Koku. | Pass |
| TC-AI-02 | Predict Student Risk (High Risk) | ML Engine identifies 'High Risk' based on failing grades/low engagement. | Pass |
| TC-AI-03 | Generate Intervention Plan | Gemini API returns a structured JSON plan 2-3 actionable steps. | Pass |
| TC-AI-04 | AI Chatbot RAG Query | Chatbot answers university-specific question using context from knowledge base. | Pass |
| TC-AI-05 | AI Chatbot General Query | Chatbot declines or redirects questions unrelated to academic context. | Pass |
| TC-AI-06 | Batch Prediction Benchmark | System processes 50+ student records and returns risk scores < 5 seconds. | Pass |

### 5.4.5 Student Profiling & Talent Management

Table 5.5 details the testing for the soft skills, talent quizzes, and student profiling elements.

**Table 5.5: Profiling & Talent Management Test Cases**

| ID | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| TC-TM-01 | Update Soft Skills | Selected skills are saved to profile without duplicate categories. | Pass |
| TC-TM-02 | Submit Talent Quiz | Quiz answers are processed, and top 3 talents are calculated/saved. | Pass |
| TC-TM-03 | Recommendation Engine | System suggests clubs/events based on the user's new quiz results. | Pass |
| TC-TM-04 | Skill Compatibility Match | System finds other students with overlapping hobby interests (Similarity > 50%). | Pass |
| TC-TM-05 | Activity Milestones | User achieves "Active Member" status after joining 5 events. | Pass |
| TC-TM-06 | Profile Completion Meter | Progress bar updates from 50% to 80% after filling bio and LinkedIn URL. | Pass |

### 5.4.6 Backend Security & Performance

Table 5.6 validates the non-functional requirements including security and API performance.

**Table 5.6: Security & Performance Test Cases**

| ID | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| TC-SEC-01 | API Rate Limiting | Repeated rapid requests trigger 429 "Too Many Requests" response. | Pass |
| TC-SEC-02 | SQL Injection Protection | Input fields with SQL payloads are sanitized; query executes safely. | Pass |
| TC-SEC-03 | Invalid Media Type Upload | System rejects .exe/.sh files and only accepts .jpg/.png/.pdf. | Pass |
| TC-SEC-04 | Cross-Origin (CORS) Check | Requests from unauthorized domains are blocked by the browser/API. | Pass |
| TC-SEC-05 | Database Connection Pooling | System handles 10 concurrent DB connections without timeout errors. | Pass |
| TC-SEC-06 | JWT Token Expiry | Expired session token is rejected, forcing a new login. | Pass |

---

*End of Section 5.4 - System Testing*
