// UTHM Talent Profiling Admin Dashboard JS (Firestore Only, Clean Version)

// --- Global State ---
let charts = {};
let currentSection = 'overview';
let notifications = [];
let userDocIdMap = {};

// --- DOMContentLoaded ---
document.addEventListener('DOMContentLoaded', function() {
    setupNavigation();
    setupUserFilters();
    setupUserModals();
    setupDarkModeToggle();
    loadOverviewStats();
    loadUsersTable();
    setupAnalytics();
});

// --- Navigation ---
function setupNavigation() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', function() {
            const section = this.getAttribute('data-section');
            navigateToSection(section);
        });
    });
}

function navigateToSection(section) {
    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    document.querySelector(`[data-section="${section}"]`).classList.add('active');
    document.querySelectorAll('.content-section').forEach(sec => sec.classList.remove('active'));
    document.getElementById(section).classList.add('active');
    const titles = {
        'overview': 'Dashboard Overview',
        'users': 'User Management',
        'analytics': 'Analytics & Reports',
        'settings': 'System Settings'
    };
    document.getElementById('page-title').textContent = titles[section] || '';
    if (section === 'overview') loadOverviewStats();
    if (section === 'users') loadUsersTable();
    if (section === 'analytics') setupAnalytics();
}

// --- Overview Stats ---
async function loadOverviewStats() {
    const statsGrid = document.getElementById('overview-stats');
    if (!statsGrid) return;
    statsGrid.innerHTML = '<div>Loading...</div>';
    try {
        const usersSnap = await db.collection('users').get();
        const users = usersSnap.docs.map(doc => doc.data());
        const totalUsers = users.length;
        const totalStudents = users.filter(u => u.role === 'student').length;
        const totalLecturers = users.filter(u => u.role === 'lecturer').length;
        // For demo, fake achievements/departments
        const totalAchievements = 0;
        const pendingVerifications = 0;
        const totalDepartments = 0;
        statsGrid.innerHTML = `
            <div class="stat-card"><div class="stat-icon"><i class="fas fa-users"></i></div><div class="stat-content"><h3>${totalUsers}</h3><p>Total Users</p></div></div>
            <div class="stat-card"><div class="stat-icon"><i class="fas fa-user-graduate"></i></div><div class="stat-content"><h3>${totalStudents}</h3><p>Students</p></div></div>
            <div class="stat-card"><div class="stat-icon"><i class="fas fa-chalkboard-teacher"></i></div><div class="stat-content"><h3>${totalLecturers}</h3><p>Lecturers</p></div></div>
            <div class="stat-card"><div class="stat-icon"><i class="fas fa-trophy"></i></div><div class="stat-content"><h3>${totalAchievements}</h3><p>Achievements</p></div></div>
            <div class="stat-card"><div class="stat-icon"><i class="fas fa-clock"></i></div><div class="stat-content"><h3>${pendingVerifications}</h3><p>Pending Verifications</p></div></div>
            <div class="stat-card"><div class="stat-icon"><i class="fas fa-building"></i></div><div class="stat-content"><h3>${totalDepartments}</h3><p>Departments</p></div></div>
        `;
        renderOverviewCharts(users);
    } catch (e) {
        statsGrid.innerHTML = '<div>Error loading stats</div>';
    }
}

function renderOverviewCharts(users) {
    // User Growth Chart (dummy data for now)
    const ctx = document.getElementById('userGrowthChart');
    if (ctx) {
        if (charts.userGrowth) charts.userGrowth.destroy();
        charts.userGrowth = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                datasets: [{
                    label: 'Users',
                    data: [10, 20, 30, 40, 50, users.length],
                    borderColor: '#2563eb',
                    backgroundColor: 'rgba(37,99,235,0.1)',
                    tension: 0.4
                }]
            },
            options: {responsive:true, plugins:{legend:{display:false}}}
        });
    }
    // Other charts can be similarly initialized with real data if available
}

// --- User Management (CRUD) ---
function setupUserFilters() {
    const roleFilter = document.getElementById('user-role-filter');
    const deptFilter = document.getElementById('user-department-filter');
    const searchInput = document.getElementById('user-search');
    if (roleFilter) roleFilter.addEventListener('change', loadUsersTable);
    if (deptFilter) deptFilter.addEventListener('change', loadUsersTable);
    if (searchInput) searchInput.addEventListener('input', loadUsersTable);
}

async function loadUsersTable() {
    const tbody = document.getElementById('users-table-body');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="7">Loading...</td></tr>';
    try {
        let query = db.collection('users');
        const role = document.getElementById('user-role-filter').value;
        const dept = document.getElementById('user-department-filter').value;
        if (role) query = query.where('role', '==', role);
        if (dept) query = query.where('department', '==', dept);
        const snap = await query.get();
        let users = snap.docs.map(doc => ({...doc.data(), _id: doc.id}));
        userDocIdMap = {};
        users.forEach(u => userDocIdMap[u._id] = u);
        const search = document.getElementById('user-search').value.toLowerCase();
        if (search) users = users.filter(u => (u.name+u.email+u.role+u.department+u.matrixId).toLowerCase().includes(search));
        tbody.innerHTML = users.length ? users.map(u => `
            <tr>
                <td>${u._id}</td>
                <td>${u.name}</td>
                <td>${u.email}</td>
                <td>${u.role}</td>
                <td>${u.department||''}</td>
                <td>${u.matrixId||''}</td>
                <td>
                    <button class="btn btn-secondary" onclick="showEditUserModal('${u._id}')"><i class="fas fa-edit"></i></button>
                    <button class="btn btn-danger" onclick="deleteUser('${u._id}')"><i class="fas fa-trash"></i></button>
                </td>
            </tr>
        `).join('') : '<tr><td colspan="7">No users found.</td></tr>';
    } catch (e) {
        tbody.innerHTML = '<tr><td colspan="7">Error loading users</td></tr>';
    }
}

function setupUserModals() {
    // Add User Modal
    document.getElementById('add-user-form').onsubmit = function(e) {
        e.preventDefault();
        handleAddUser(this);
    };
    // Edit User Modal
    document.getElementById('edit-user-form').onsubmit = function(e) {
        e.preventDefault();
        handleEditUser(this);
    };
}

function showAddUserModal() {
    document.getElementById('add-user-form').reset();
    document.getElementById('add-user-modal').style.display = 'block';
}

function showEditUserModal(id) {
    const user = userDocIdMap[id];
    if (!user) return;
    document.getElementById('edit-user-id').value = id;
    document.getElementById('edit-user-name').value = user.name;
    document.getElementById('edit-user-email').value = user.email;
    document.getElementById('edit-user-role').value = user.role;
    document.getElementById('edit-user-department').value = user.department||'';
    document.getElementById('edit-user-matrix-id').value = user.matrixId||'';
    document.getElementById('edit-user-modal').style.display = 'block';
}

function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}

async function handleAddUser(form) {
    const name = form['add-user-name'].value.trim();
    const email = form['add-user-email'].value.trim();
    const role = form['add-user-role'].value;
    const department = form['add-user-department'].value;
    const matrixId = form['add-user-id'].value.trim();
    if (!name || !email || !role || !matrixId) {
        addNotification('Please fill in all required fields.', 'error');
        return;
    }
    try {
        await db.collection('users').add({ name, email, role, department, matrixId });
        addNotification('User added successfully!', 'success');
        closeModal('add-user-modal');
        loadUsersTable();
        loadOverviewStats();
    } catch (e) {
        addNotification('Failed to add user.', 'error');
    }
}

async function handleEditUser(form) {
    const id = form['edit-user-id'].value;
    const name = form['edit-user-name'].value.trim();
    const email = form['edit-user-email'].value.trim();
    const role = form['edit-user-role'].value;
    const department = form['edit-user-department'].value;
    const matrixId = form['edit-user-matrix-id'].value.trim();
    if (!id || !name || !email || !role || !matrixId) {
        addNotification('Please fill in all required fields.', 'error');
        return;
    }
    try {
        await db.collection('users').doc(id).update({ name, email, role, department, matrixId });
        addNotification('User updated successfully!', 'success');
        closeModal('edit-user-modal');
        loadUsersTable();
        loadOverviewStats();
    } catch (e) {
        addNotification('Failed to update user.', 'error');
    }
}

async function deleteUser(id) {
    if (!confirm('Are you sure you want to delete this user?')) return;
    try {
        await db.collection('users').doc(id).delete();
        addNotification('User deleted.', 'success');
        loadUsersTable();
        loadOverviewStats();
    } catch (e) {
        addNotification('Failed to delete user.', 'error');
    }
}

function toggleDepartmentField(mode) {
    // Show/hide department field based on role
    let role, deptGroup;
    if (mode === 'edit') {
        role = document.getElementById('edit-user-role').value;
        deptGroup = document.getElementById('edit-department-field-group');
    } else {
        role = document.getElementById('add-user-role').value;
        deptGroup = document.getElementById('department-field-group');
    }
    if (role === 'student' || role === 'lecturer') {
        deptGroup.style.display = '';
    } else {
        deptGroup.style.display = 'none';
    }
}

// --- Notifications ---
function addNotification(message, type = 'info') {
    notifications.push({ message, type, time: new Date() });
    renderNotifications();
}

function renderNotifications() {
    // You can implement a notification UI if desired
    // For now, use alert for errors
    const last = notifications[notifications.length-1];
    if (last) {
        if (last.type === 'error') alert('Error: ' + last.message);
        else if (last.type === 'success') alert(last.message);
    }
}

// --- Analytics ---
function setupAnalytics() {
    // Example: render dummy charts for analytics
    const engagementCtx = document.getElementById('engagementChart');
    if (engagementCtx) {
        if (charts.engagement) charts.engagement.destroy();
        charts.engagement = new Chart(engagementCtx, {
            type: 'bar',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                datasets: [{
                    label: 'Engagement',
                    data: [5, 10, 8, 12, 7, 15],
                    backgroundColor: '#2563eb'
                }]
            },
            options: {responsive:true, plugins:{legend:{display:false}}}
        });
    }
    const trendsCtx = document.getElementById('trendsChart');
    if (trendsCtx) {
        if (charts.trends) charts.trends.destroy();
        charts.trends = new Chart(trendsCtx, {
            type: 'line',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                datasets: [{
                    label: 'Achievements',
                    data: [2, 4, 6, 8, 10, 12],
                    borderColor: '#059669',
                    backgroundColor: 'rgba(5,150,105,0.1)',
                    tension: 0.4
                }]
            },
            options: {responsive:true, plugins:{legend:{display:false}}}
        });
    }
    const comparisonCtx = document.getElementById('comparisonChart');
    if (comparisonCtx) {
        if (charts.comparison) charts.comparison.destroy();
        charts.comparison = new Chart(comparisonCtx, {
            type: 'pie',
            data: {
                labels: ['FSKTM', 'FKAAS', 'FKE', 'FKM'],
                datasets: [{
                    label: 'Departments',
                    data: [10, 8, 6, 12],
                    backgroundColor: ['#2563eb','#059669','#f59e42','#e11d48']
                }]
            },
            options: {responsive:true, plugins:{legend:{display:true}}}
        });
    }
}

// --- Settings ---
function setupDarkModeToggle() {
    const toggle = document.getElementById('dark-mode-toggle');
    if (!toggle) return;
    toggle.addEventListener('change', function() {
        if (toggle.checked) {
            document.body.classList.add('dark-mode');
            localStorage.setItem('darkMode', '1');
        } else {
            document.body.classList.remove('dark-mode');
            localStorage.setItem('darkMode', '0');
        }
    });
    // On load
    if (localStorage.getItem('darkMode') === '1') {
        toggle.checked = true;
        document.body.classList.add('dark-mode');
    }
}

// --- Logout ---
function logout() {
    // Optionally clear session/localStorage
    window.location.href = 'login.html';
}


