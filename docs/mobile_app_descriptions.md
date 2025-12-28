# Mobile App Interface Design Descriptions
## For Section 4.4.3.1 of Chapter 4

---

## Figure 4.24: Mobile App - Login Screen

The mobile application login screen serves as the primary entry point for users accessing the Student Talent Profiling system, branded as "Talent Hub". The interface presents the official UTHM logo at the top followed by the application name and tagline "Showcase your skills and connect with opportunities. Sign in to get started." This welcoming message establishes the application's purpose while encouraging user engagement.

The login form features two input fields: an Email field for institutional email addresses and a Password field with visibility toggle icon for secure credential entry. A prominently styled blue "Sign In" button initiates the authentication process through Supabase Auth service. The clean, minimal design with generous white space ensures the interface remains focused and accessible on various mobile screen sizes.

---

## Figure 4.25: Mobile App - Home Dashboard

The home dashboard serves as the central hub of the mobile application, greeting users with a personalized message "Hello, Student! 👋" and the tagline "Discover opportunities & showcase your talent." The interface combines quick action shortcuts with a social showcase feed, providing immediate access to core features while keeping users engaged with peer content.

The quick action section displays three circular buttons for New Post, Trending, and Events, enabling one-tap navigation to common tasks. Below this, horizontal category filter tabs (All, Academic, Creative, Technical) allow users to filter the showcase feed by content type. The feed displays student posts in card format showing author information, post content with media, category tags like "PROJECT", and engagement metrics including likes and comments. A bottom navigation bar provides persistent access to Home, Discover, AI Chat, Events, and Profile sections throughout the application.

---

## Figure 4.26: Mobile App - Discover Screen

The Discover screen provides a powerful search interface for finding lecturers, students, and skills across the institution's talent database. The search bar at the top accepts natural language queries such as "data science", enabling users to find relevant profiles based on skills, interests, or expertise areas. Horizontal filter tabs (Lecturers, Students, Skills, More) allow users to narrow results by user type.

Search results display in a list format showing profile cards with avatar, name, title or headline, and relevant skill tags. The "Top Match" badge highlights profiles most relevant to the search query based on skill matching algorithms. Each profile card displays competency tags such as "Data Science", "Machine Learning", and "Big Data" for quick skill identification. Tapping on a profile card navigates to the full profile view, while the "Tap to view details" prompt encourages exploration of matched profiles.

---

## Figure 4.27: Mobile App - Profile View (Own)

The student's own profile view displays their complete talent portfolio organized into logical sections. The header shows the "Profile" title with settings, edit, and share icons for quick access to profile management functions. The Talent DNA section highlights the student's top talent area (e.g., "sports") identified through the system's talent assessment features, displayed with a trophy icon indicating achievement status.

The profile is organized into card-based sections: Skills showing competency tags like "Circuit Design", "MATLAB", and "Leadership"; Academic & Kokurikulum displaying CGPA score (3.70) versus Kokurikulum score (92) with a "Seimbang" (Balanced) indicator and semester information; Experience section for work and volunteer history; Projects section for portfolio items; and Badges & Achievements section showcasing verified accomplishments. This comprehensive layout provides a complete picture of the student's academic and extracurricular profile.

---

## Figure 4.28: Mobile App - Profile View (Others)

The profile view for viewing other users displays comprehensive information about lecturers or fellow students. The header shows the user's name (e.g., "Dr. Mohd Razali") with a blue gradient banner and circular avatar displaying initials. Below the avatar, the user's role is indicated with a badge (e.g., "Lecturer") and their headline describes their position and expertise areas.

A profile strength indicator shows completion percentage (e.g., "80% Complete") encouraging profile optimization. Quick info chips display email access, department affiliation (e.g., "FSKTM"), and skill count (e.g., "3 Skills"). The Academic Information section presents structured data including Program, Department, Semester, and Staff/Student ID. This detailed view enables students to discover potential mentors, collaborators, or peers with complementary skills.

---

## Figure 4.29: Mobile App - Edit Profile

The edit profile screen provides a comprehensive form for students to update their talent profile information. The interface features a tabbed navigation system with four sections: Basic, Academic, Skills & Inter (Interests), and Experience, allowing organized editing of different profile aspects. The currently active tab is highlighted with blue underline for clear navigation feedback.

The Basic Information section displays the profile avatar with camera icon overlay for photo updates, followed by input fields for Full Name, Headline (e.g., "Electrical Engineering Student | Renewable"), Phone Number, Address, and Bio. Each field includes appropriate icons and placeholder text for guidance. A persistent "Save Profile" button at the bottom commits changes to the database, with validation ensuring required fields are completed before submission.

---

## Figure 4.30: Mobile App - Events Listing

The Events screen provides students with a discovery interface for academic and co-curricular activities. The header displays a personalized greeting (e.g., "Good Evening, Siti!") with "Discover Events" subtitle, creating an engaging browsing experience. A search bar enables keyword-based event filtering, while Filter Events and Favorites buttons provide quick access to filtering options and saved events.

Events display in an attractive card format featuring banner images, category badges (Workshop, Academic), and price indicators for paid events (e.g., "RM 1.00"). Each card shows event title, description, interested count, and posting time. A "View Details" button navigates to the full event page, while heart icons enable saving events to favorites. The card-based layout with visual imagery makes event browsing engaging and informative.

---

## Figure 4.31: Mobile App - Favorite Events

The Favorite Events screen displays events that the student has bookmarked for quick access. The interface presents a clean list of saved events using the same card format as the main events listing, maintaining visual consistency throughout the application. Each card shows the event banner image, category badge, title, description, and engagement metrics.

The favorites feature enables students to curate a personalized list of events they are interested in attending. The heart icon on each card indicates favorited status, and tapping it removes the event from favorites. This screen serves as a quick reference for students to track events they plan to register for or are considering attending, improving event management and participation planning.

---

## Figure 4.32: Mobile App - Event Detail

The event detail screen provides comprehensive information about a specific event and enables registration. The top section displays the event banner image in full width with a share icon and heart icon for favoriting. Below the image, category badge (e.g., "WORKSHOP"), price indicator (e.g., "RM 1.00"), and interested count provide quick event classification.

The "About This Event" section presents the event description, while "Event Details" shows metadata including creation date and last update timestamp. For paid events, a prominent "Pay RM 1.00 & Join" button initiates the payment flow through ToyyibPay integration, enabling secure transaction processing. A "Share Event" button allows students to share event details with peers. This comprehensive detail view provides all information needed for informed registration decisions.

---

## Figure 4.33: Mobile App - Post Detail

The post detail screen displays the full content of a showcase post with interaction capabilities. The header shows "Post" title with share and menu icons. The post content section displays author information including avatar, name, headline, and posting timestamp. The post body shows the full content text, description sections, key features, and technologies used with hashtags (e.g., #flutter #firebase #dart).

Below the content, a category tag (e.g., "Project") classifies the post type. Interaction buttons for Comment and Share enable engagement with the content. A comment input field at the bottom with the user's avatar allows direct commenting on the post. This detailed view enables meaningful interaction with peer content beyond the feed's preview cards.

---

## Figure 4.34: Mobile App - Create Post

The create post screen enables students to share their projects, achievements, and talents with the campus community. The header provides Save Draft and Post buttons for content management, with the student's profile information displayed below. A large text input area accepts the post content with character count indicator (e.g., "137/2000") and media attachment options for images, videos, and camera capture.

The form includes Category dropdown (e.g., "Project"), Visibility selector (e.g., "Public"), and Tags section displaying applied hashtags (#project, #coding, #development) with option to add more. An "Add location" field enables geotagging posts. The "Save Draft" button preserves work-in-progress posts, while the "Post" button publishes content to the showcase feed. This comprehensive creation interface supports rich content sharing with proper categorization.

---

## Figure 4.35: Mobile App - AI Chat (STAP Advisor)

The STAP UTHM Advisor screen provides students with an AI-powered conversational interface for academic and career guidance. The header displays "STAP UTHM Advisor" with online status indicator and quick action icons for history and information access. The chat interface follows a familiar messaging pattern with user messages on the right (blue bubbles) and AI responses on the left.

The AI advisor introduces itself in Bahasa Melayu: "Hai juga! Saya STAP UTHM Advisor anda dari FSKTM. Saya sedia membantu anda dengan sebarang pertanyaan berkaitan pengajian akademik, pembangunan kerjaya, kehidupan universiti di UTHM, atau maklumat spesifik FSKTM." The interface includes copy, text-to-speech, and more options for each message. The input area features camera, gallery, and attachment icons for media sharing, voice input button, and a text field with placeholder "Ask me anything about your studies..." This comprehensive AI assistant supports students with academic and career-related queries.
