# Local Testing Guide for UTHM Dashboard

## 🚀 Quick Start

### 1. Start Local Development Server
```bash
cd web_dashboard
npm run dev
```

This will:
- Start a local server on `http://localhost:3000`
- Automatically open your browser
- Enable hot reloading for development

### 2. Access Your Dashboard
Open your browser and go to: `http://localhost:3000`

## 🧪 Testing Your Charts Locally

### Available Testing Functions

Once you're running locally, these functions will be available in your browser console:

#### Test Charts with Sample Data
```javascript
// Test both Total Users and Course charts
testChartsLocally()

// Test analytics functionality
testAnalyticsLocally()

// Show local testing status
showLocalTestStatus()

// Debug analytics system
debugAnalyticsData()

// Force analytics setup
forceAnalyticsSetup()

// Debug department data access
debugDepartmentData()

// Test PDF report generation
testPDFReportGeneration()
```

#### Manual Chart Testing
```javascript
// Navigate to Analytics section first, then:
// Test Total Users chart
const totalUserCanvas = document.getElementById('totalUserChart');
if (totalUserCanvas) {
    console.log('✅ Total User chart canvas found');
} else {
    console.log('❌ Total User chart canvas not found');
}

// Test Department chart
const courseCanvas = document.getElementById('courseChart');
if (courseCanvas) {
    console.log('✅ Department chart canvas found');
} else {
    console.log('❌ Department chart canvas not found');
}
```

## 📊 What You Should See

### 1. Total Users Chart (Doughnut)
- **Data Source**: Sample user data (5 users: 3 students, 1 lecturer, 1 admin)
- **Chart Type**: Doughnut chart
- **Colors**: Blue, Green, Orange, Red, Purple
- **Tooltips**: Shows count and percentage for each role

### 2. Department Distribution Chart (Bar)
- **Data Source**: Sample profile data (5 profiles across 3 departments)
- **Chart Type**: Bar chart
- **Colors**: Green bars
- **Tooltips**: Shows student count for each department

## 🔍 Debugging Tips

### Check Console for Errors
1. Open Browser Developer Tools (F12)
2. Go to Console tab
3. Look for any error messages
4. Use the testing functions above

### Common Issues & Solutions

#### Charts Not Rendering
```javascript
// Check if Chart.js is loaded
console.log('Chart.js available:', typeof Chart !== 'undefined');

// Check if canvas elements exist
console.log('Total User canvas:', document.getElementById('totalUserChart'));
console.log('Department canvas:', document.getElementById('courseChart'));
```

#### No Data Displayed
```javascript
// Check if sample data is loaded
console.log('Local test config:', window.LOCAL_TEST_CONFIG);

// Force chart refresh
testChartsLocally();

// Debug the entire analytics system
debugAnalyticsData();

// Force analytics setup
forceAnalyticsSetup();

// Debug department data access
debugDepartmentData();

// Test PDF report generation
testPDFReportGeneration();
```

#### Navigation Issues
```javascript
// Check if analytics section is accessible
const analyticsSection = document.getElementById('analytics');
console.log('Analytics section:', analyticsSection);

// Check navigation
const analyticsNav = document.querySelector('[data-section="analytics"]');
console.log('Analytics nav:', analyticsNav);
```

## 🎯 Testing Checklist

Before deploying to Vercel, ensure:

- [ ] Charts render correctly with sample data locally
- [ ] No JavaScript errors in console
- [ ] Navigation between sections works
- [ ] Charts are responsive (try resizing browser)
- [ ] Tooltips display correctly
- [ ] Sample data shows expected values
- [ ] PDF report generation works correctly
- [ ] Button shows "Generate PDF Report" with PDF icon

## 📄 PDF Report Generation Testing

### Test PDF Generation
```javascript
// Test PDF report generation functionality
testPDFReportGeneration()

// Generate actual PDF report (navigate to Analytics section first)
// Click the "Generate PDF Report" button
```

### What to Expect
- **Button Text**: Should show "Generate PDF Report" with PDF icon
- **PDF Content**: Should include:
  - Executive Summary with user counts
  - User Distribution by Role
  - Department Distribution
  - Event Participation
  - Performance Metrics
- **File Name**: `uthm-talent-analytics-YYYY-MM-DD.pdf`
- **Download**: PDF should download automatically

### Troubleshooting PDF Generation
```javascript
// Check if jsPDF library is loaded
console.log('jsPDF available:', typeof window.jspdf !== 'undefined');

// Check if generateReport function exists
console.log('generateReport function:', typeof window.generateReport);

// Check for any PDF generation errors in console
```

## 🚀 Ready for Deployment?

Once local testing passes:

1. **Stop local server**: `Ctrl+C` in terminal
2. **Test production build**: `npm run build`
3. **Deploy to Vercel**: `vercel --prod`

## 📝 Sample Data Reference

### Users
- 3 Students
- 1 Lecturer  
- 1 Admin

### Courses
- Computer Science (2 students)
- Information Technology (2 students)
- Software Engineering (1 student)

### Events
- Test Event 1 (Workshop)
- Test Event 2 (Seminar)
- Test Event 3 (Competition)

## 🆘 Need Help?

If you encounter issues:

1. **Check the console** for error messages
2. **Verify Chart.js is loaded** (should see Chart object in console)
3. **Ensure you're on localhost:3000** (local testing only works locally)
4. **Try the testing functions** above
5. **Check browser compatibility** (Chrome/Firefox recommended)

## 🔄 Development Workflow

1. **Make changes** to your code
2. **Test locally** using `npm run dev`
3. **Verify charts work** with sample data
4. **Fix any issues** found during local testing
5. **Deploy to Vercel** only when local testing passes

This approach saves time and ensures your dashboard works before going live!
