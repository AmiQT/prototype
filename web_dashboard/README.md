# UTHM Talent Profiling - Web Dashboard

A modern, responsive web dashboard for managing the UTHM Student Talent Profiling System. This dashboard provides comprehensive tools for administrators and lecturers to manage users, verify achievements, and analyze system performance.

## Features

### 🔐 Authentication System
- Secure login with role-based access
- Session management with localStorage
- Demo credentials for testing

### 📊 Dashboard Overview
- Real-time statistics and metrics
- Interactive charts and graphs
- Recent activity feed
- System health monitoring

### 👥 User Management
- View all users (students, lecturers, admins)
- Add new users
- Edit user information
- Delete users
- Filter and search functionality

### 🏆 Achievement Verification
- View all submitted achievements
- Verify or reject achievements
- Filter by status, type, and search
- Detailed achievement information

### 📈 Analytics & Reports
- User growth trends
- Achievement distribution
- Department performance comparison
- Top performers ranking
- Comprehensive reporting tools

### 🏢 Department Management
- View department statistics
- Student and achievement counts
- Performance metrics
- Department-specific analytics

### ⚙️ System Settings
- General system configuration
- Security settings
- Notification preferences
- Maintenance mode controls

## Demo Credentials

### Admin Access
- **Email:** admin@uthm.edu.my
- **Password:** admin123

### Lecturer Access
- **Email:** lecturer@uthm.edu.my
- **Password:** lecturer123

## Getting Started

### Prerequisites
- A modern web browser (Chrome, Firefox, Safari, Edge)
- No additional software installation required

### Running the Dashboard

#### Option 1: Using Python (Recommended)
```bash
cd web_dashboard
python -m http.server 8000
```
Then open your browser and navigate to: `http://localhost:8000`

#### Option 2: Using Node.js
```bash
cd web_dashboard
npx http-server -p 8000
```

#### Option 3: Using PHP
```bash
cd web_dashboard
php -S localhost:8000
```

### Accessing the Dashboard
1. Open your web browser
2. Navigate to `http://localhost:8000`
3. You'll be redirected to the login page
4. Use the demo credentials above to log in
5. Start exploring the dashboard features!

## File Structure

```
web_dashboard/
├── index.html          # Main dashboard page
├── login.html          # Login page
├── css/
│   └── style.css       # Main stylesheet
├── js/
│   └── dashboard.js    # Dashboard functionality
└── README.md           # This file
```

## Mock Data

The dashboard uses mock data for demonstration purposes. The data includes:

### Users
- 8 sample users (students, lecturers, admin)
- Various departments and roles
- Different status states

### Achievements
- 7 sample achievements
- Different types (academic, competition, leadership, skill)
- Various verification statuses

### Departments
- 8 sample departments
- Student counts and performance metrics
- Achievement statistics

## Features in Detail

### Navigation
- **Sidebar Navigation:** Easy access to all sections
- **Responsive Design:** Works on desktop, tablet, and mobile
- **Search Functionality:** Global search across all sections

### User Management
- **User List:** View all users with detailed information
- **Add User:** Modal form to add new users
- **Edit/Delete:** Manage existing users
- **Filters:** Filter by role, department, and status
- **Search:** Find users by name or email

### Achievement Verification
- **Achievement Grid:** Visual cards showing achievement details
- **Verification Actions:** Verify or reject pending achievements
- **Status Tracking:** Track verification status
- **Filters:** Filter by status, type, and search terms

### Analytics
- **Charts:** Interactive charts using Chart.js
- **Statistics:** Real-time metrics and KPIs
- **Trends:** Historical data visualization
- **Performance:** System performance indicators

### Reports
- **User Reports:** Comprehensive user statistics
- **Achievement Reports:** Achievement analysis
- **Department Reports:** Department performance
- **System Reports:** System health and usage

## Customization

### Adding New Features
1. Edit `dashboard.js` to add new functionality
2. Update `index.html` to add new UI elements
3. Modify `style.css` for styling changes

### Modifying Mock Data
Edit the `mockData` object in `dashboard.js` to:
- Add new users
- Modify achievement data
- Update department information
- Change system statistics

### Styling Changes
The dashboard uses a modern, clean design with:
- Blue color scheme (#1e40af, #3b82f6)
- Responsive grid layouts
- Card-based UI components
- Smooth animations and transitions

## Browser Compatibility

- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+

## Security Notes

⚠️ **Important:** This is a demo system with mock data. In production:

1. Implement proper authentication with a backend server
2. Use HTTPS for all communications
3. Add proper input validation and sanitization
4. Implement role-based access control
5. Add CSRF protection
6. Use secure session management
7. Implement proper error handling

## Future Enhancements

- [ ] Real-time notifications
- [ ] Export functionality (PDF, Excel)
- [ ] Advanced filtering and sorting
- [ ] Bulk operations
- [ ] User activity logs
- [ ] Advanced analytics
- [ ] Mobile app integration
- [ ] API endpoints for mobile app

## Support

For questions or issues:
1. Check the browser console for error messages
2. Ensure you're using a supported browser
3. Verify the server is running correctly
4. Check that all files are in the correct locations

## License

This project is part of the UTHM Student Talent Profiling System Final Year Project.

---

**Note:** This dashboard is designed for demonstration purposes. For production use, implement proper backend services and security measures. 