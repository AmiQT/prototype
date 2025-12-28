# CHAPTER 5: SYSTEM IMPLEMENTATION AND TESTING

## 5.1 Web Dashboard Implementation

This section documents the implementation of the administrative web dashboard built using Astro framework with TailwindCSS for styling, connected to Supabase backend for database and authentication services.

---

### 5.1.1 Login Page

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.1.1: Admin Login Page**

Figure 5.1.1 shows the admin login page of the web dashboard. This page provides secure authentication for administrators and managers to access the talent profiling system. The interface features an animated gradient background with floating elements, and a split-panel design displaying branding information alongside the login form.

**Code Snippet:**

```typescript
// Form Submission Handler
loginForm?.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    // UI Loading State
    loginBtn.disabled = true;
    btnContent.style.opacity = '0';
    loading?.classList.remove('hidden');

    const email = (document.getElementById('email') as HTMLInputElement).value;
    const password = (document.getElementById('password') as HTMLInputElement).value;

    try {
        // CHECK FOR DEMO LOGIN FIRST
        if (email === DEMO_CREDENTIALS.email && password === DEMO_CREDENTIALS.password) {
            setDemoMode(true);
            window.location.href = '/dashboard';
            return;
        }

        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
        });

        if (error) throw error;

        // Check user role
        const { data: profileData } = await supabase
            .from('users')
            .select('role')
            .eq('email', email)
            .single();

        const role = profileData?.role ?? data?.user?.user_metadata?.role;
        if (role && !['admin', 'manager'].includes(role)) {
            await supabase.auth.signOut();
            throw new Error('Access restricted to admin users only');
        }

        window.location.href = '/dashboard';
    } catch (error: any) {
        alert(error.message || 'Login failed');
    }
});
```

This code handles user authentication using Supabase Auth. It validates credentials, checks user roles to ensure only administrators can access the dashboard, and redirects to the main dashboard upon successful login. The system also supports a demo mode for testing purposes.

---

### 5.1.2 Dashboard Overview

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.1.2: Dashboard Overview Page**

Figure 5.1.2 displays the main dashboard overview page which provides administrators with a quick summary of key system metrics. The page features three primary statistics cards showing Total Users, Active Events, and Student Profiles, along with interactive charts for User Growth and Department Distribution.

**Code Snippet:**

```typescript
async function loadStats() {
    try {
        // Get total counts in parallel
        const [
            { count: userCount },
            { count: eventCount },
            { count: profileCount }
        ] = await Promise.all([
            supabase.from("users").select("*", { count: "exact", head: true }),
            supabase.from("events").select("*", { count: "exact", head: true }),
            supabase.from("profiles").select("*", { count: "exact", head: true })
        ]);

        const userEl = document.getElementById("total-users");
        if (userEl && userCount !== null) userEl.textContent = userCount.toString();

        const eventEl = document.getElementById("total-events");
        if (eventEl && eventCount !== null) eventEl.textContent = eventCount.toString();

        const profileEl = document.getElementById("total-profiles");
        if (profileEl && profileCount !== null) profileEl.textContent = profileCount.toString();
    } catch (error) {
        console.error("Error loading stats:", error);
    }
}
```

This code fetches statistical data from the Supabase database using parallel queries for optimal performance. The `Promise.all()` method ensures all three counts (users, events, profiles) are retrieved simultaneously, reducing load time and improving user experience.

---

### 5.1.3 Analytics Page

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.1.3: Analytics Dashboard Page**

Figure 5.1.3 shows the comprehensive analytics dashboard that provides in-depth insights into student data. The page includes quick statistics cards (Total Students, Average CGPA, Kokurikulum Score, Active Events), multiple chart visualizations, PAK (Academic Advisor) statistics, tabbed analytics sections (Skills, Program, Engagement, Risk), and AI-powered student risk analysis.

**Code Snippet:**

```typescript
// Generate PDF Report
document.getElementById("generate-report-btn")?.addEventListener("click", async () => {
    const doc = new jsPDF();
    
    // Add header
    doc.setFontSize(18);
    doc.text("UTHM Talent Profiling Analytics Report", 14, 22);
    doc.setFontSize(11);
    doc.text(`Generated on: ${new Date().toLocaleDateString()}`, 14, 30);
    
    // Quick Stats Summary
    doc.setFontSize(14);
    doc.text("Summary Statistics", 14, 45);
    
    const statsData = [
        ["Total Students", document.getElementById("total-students")?.textContent || "0"],
        ["Average CGPA", document.getElementById("avg-cgpa")?.textContent || "0"],
        ["Average Kokurikulum", document.getElementById("avg-koku")?.textContent || "0%"],
        ["Active Events", document.getElementById("active-events")?.textContent || "0"]
    ];
    
    autoTable(doc, {
        startY: 50,
        head: [["Metric", "Value"]],
        body: statsData,
        theme: "striped"
    });
    
    doc.save("analytics_report.pdf");
});
```

This code implements the automated PDF report generation feature using jsPDF library. When administrators click the "Generate Report" button, the system compiles current dashboard statistics into a formatted PDF document with header information, summary statistics table, and visual charts embedded as images.

---

### 5.1.4 Event Management Page

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.1.4: Event Management Page**

Figure 5.1.4 displays the event management interface where administrators can create, edit, view participants, and manage campus events. The page features a searchable and filterable table of events with columns for Title, Date, Category, Status, Participants, and Actions. Administrators can add new events through a modal form that supports image uploads and paid event configuration.

**Code Snippet:**

```typescript
async function uploadToCloudinary(file: File) {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error("Not authenticated");

    const formData = new FormData();
    formData.append("file", file);

    const response = await fetch(`${BACKEND_URL}/api/media/upload/image`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${session.access_token}`,
        },
        body: formData,
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || "Upload failed");
    }

    const data = await response.json();
    return data.media.url;
}

// Create Event
addForm?.addEventListener("submit", async (e) => {
    e.preventDefault();

    const { error } = await supabase.from("events").insert([{
        title,
        event_date: new Date(date).toISOString(),
        category,
        location,
        status,
        image_url: imageUrl,
        max_participants: maxParticipants ? parseInt(maxParticipants) : null,
        is_paid: isPaid,
        price: isPaid && price ? parseFloat(price) : null,
        is_active: true,
    }]);

    if (error) throw error;
    alert("Event added successfully");
});
```

This code demonstrates the event creation workflow with Cloudinary image upload integration. The `uploadToCloudinary()` function handles secure file uploads through the backend API with JWT authentication. Event data including title, date, category, location, and pricing information is then inserted into the Supabase database.

---

### 5.1.5 User Management Page

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.1.5: User Management Page**

Figure 5.1.5 shows the user management interface that allows administrators to manage system users including students, lecturers, and other admins. The page provides comprehensive user listing with role-based color coding, profile completion status indicators, active/inactive toggle switches, and bulk action capabilities. Administrators can add new users, edit existing ones, reset passwords, and delete accounts.

**Code Snippet:**

```typescript
// Add New User via Backend Admin API
addForm?.addEventListener("submit", async (e) => {
    e.preventDefault();

    const { data: { session } } = await supabase.auth.getSession();
    const token = session?.access_token;

    if (!token) {
        throw new Error("No authentication token found. Please login again.");
    }

    // Call Backend Admin API (bypasses email verification)
    const response = await fetch(`${BACKEND_URL}/api/users/admin/create`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
            email: email,
            password: password,
            name: name,
            role: role,
            department: department,
            is_active: true,
        }),
    });

    const result = await response.json();
    if (!response.ok) throw new Error(result.detail || "Failed to create user");

    alert("User added successfully! They can login immediately.");
});
```

This code handles user creation through a secure backend admin API endpoint. Unlike standard registration, this approach bypasses email verification requirements, allowing administrators to create accounts that are immediately active. The function validates authentication tokens and sends user data including name, email, password, role, and department to the FastAPI backend.

---

### 5.1.6 Settings Page

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.1.6: Dashboard Settings Page**

Figure 5.1.6 displays the settings page which provides system configuration options for administrators. The page is organized into sections including Appearance settings (theme selection), Security settings (two-factor authentication toggle, password change), and System Information displaying application name, version, and database connection status.

**Code Snippet:**

```html
<!-- Settings Page Structure -->
<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
    <!-- Appearance Settings -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
        <div class="flex items-center gap-3 mb-6">
            <div class="p-2 bg-purple-50 rounded-lg">
                <i class="fas fa-palette text-purple-600"></i>
            </div>
            <h3 class="text-lg font-bold text-gray-800">Appearance</h3>
        </div>
        <select class="w-full px-4 py-2 border border-gray-200 rounded-xl">
            <option value="light">Light Mode</option>
            <option value="dark">Dark Mode</option>
            <option value="system">System Default</option>
        </select>
    </div>

    <!-- Security Settings -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
        <div class="flex items-center justify-between">
            <div>
                <h4 class="text-sm font-medium text-gray-900">Two-Factor Authentication</h4>
                <p class="text-xs text-gray-500">Add extra security to your account</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" class="sr-only peer">
                <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-[#667eea]"></div>
            </label>
        </div>
    </div>
</div>
```

This code shows the settings page layout using a responsive CSS grid system. The interface organizes configuration options into distinct cards with consistent styling. Each setting section features an icon header, descriptive labels, and appropriate input controls such as dropdowns for theme selection and toggle switches for boolean settings like two-factor authentication.

---

## 5.1.7 Sidebar Navigation Component

**[INSERT SCREENSHOT HERE]**

**FIGURE 5.1.7: Dashboard Sidebar Navigation**

Figure 5.1.7 shows the sidebar navigation component that provides consistent navigation across all dashboard pages. The sidebar displays the UTHM logo, application title, and a menu of navigation items (Overview, User Management, Event Management, Analytics, Settings) with visual active state indicators.

**Code Snippet:**

```typescript
const menuItems = [
    { id: "overview", label: "Overview", icon: "fas fa-tachometer-alt", href: "/dashboard" },
    { id: "users", label: "User Management", icon: "fas fa-users", href: "/dashboard/users" },
    { id: "events", label: "Event Management", icon: "fas fa-calendar-alt", href: "/dashboard/events" },
    { id: "analytics", label: "Analytics", icon: "fas fa-chart-bar", href: "/dashboard/analytics" },
    { id: "settings", label: "Settings", icon: "fas fa-cog", href: "/dashboard/settings" },
];

// Dynamic active state rendering
menuItems.map((item) => (
    <a href={item.href}
       class={`flex items-center gap-3 px-6 py-3 text-sm font-medium transition-colors ${
           activeSection === item.id 
               ? "text-[#667eea] bg-[#667eea]/10 border-r-4 border-[#667eea]" 
               : "text-gray-600 hover:text-[#667eea] hover:bg-gray-50"
       }`}>
        <i class={`${item.icon} w-5 text-center`} />
        <span>{item.label}</span>
    </a>
));
```

This code implements a reusable navigation sidebar component using Astro's component architecture. The menu items are defined as a data array for maintainability. The component dynamically applies active state styling based on the current page, providing visual feedback to users about their current location within the dashboard.

---

### 5.1.8 AI & Analytics Services

**Purpose:** This section details the core service modules that power the intelligent features of the dashboard, including Gemini AI integration for generating intervention plans and the ML Analytics service for fetching student risk predictions.

**Code Snippet:**

```typescript
// Gemini AI Service - Action Plan Generation
async generateActionPlan(studentData: any): Promise<ActionPlanResult> {
    // Construct prompt with student risk metrics
    const prompt = `
        Analisis data pelajar dan beri pelan tindakan ringkas.
        Data: ID=${studentData.student_id}, Risiko=${studentData.risk_level}, 
        Skor=${(studentData.risk_score * 100).toFixed(1)}%, 
        Faktor=${studentData.risk_factors.join(", ")}
        
        Arahan: Beri 2-3 cadangan praktikal dalam JSON format.
    `;

    try {
        const result = await this.model.generateContent(prompt);
        const response = await result.response;
        // Parse JSON response for structured action plan
        return { success: true, plan: JSON.parse(response.text()) };
    } catch (error) {
        return { success: false, error: "Failed to generate AI plan" };
    }
}
```

The AI integration service encapsulates the logic for interacting with Google's Gemini Pro model. It constructs a context-rich prompt using the student's academic and co-curricular data (risk score, strengths, factors) and requests a structured JSON response containing tailored intervention strategies.

```typescript
// ML Analytics Service - Batch Prediction Integrator
async batchPredict(studentIds: string[]): Promise<RiskPredictionResult> {
    const response = await fetch(`${this.baseUrl}/api/ml/batch/predict`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ student_ids: studentIds }),
    });

    const data = await response.json();
    
    // Transform backend response to frontend model
    return {
        success: true,
        data: {
            results: data.results.map((r: any) => ({
                student_id: r.student_id,
                risk_level: r.risk_level,
                risk_score: r.risk_score,
                confidence: r.confidence,
                // ... map other fields
            }))
        }
    };
}
```

The predictive analytics service acts as the bridge between the frontend dashboard and the Python FastAPI backend. It handles batch processing of student risk predictions, providing a simplified interface for the UI components to consume complex ML inference results. It also includes health check capabilities to monitor the status of the ML inference engine.

---

*End of Section 5.1 - Web Dashboard Implementation*
