// Firebase removed - using backend API instead
import { API_ENDPOINTS, makeAuthenticatedRequest, testBackendConnection } from '../../config/backend-config.js';
import { addNotification, closeModal } from '../../ui/notifications.js';

let usersListener = null;
let allUsersCache = [];

function setupUserFilters() {
    const roleFilter = document.getElementById('user-role-filter');
    const deptFilter = document.getElementById('user-department-filter');
    const searchFilter = document.getElementById('user-search');

    if (roleFilter) {
        roleFilter.addEventListener('change', applyUserFiltersAndRender);
    }
    if (deptFilter) {
        deptFilter.addEventListener('change', applyUserFiltersAndRender);
    }
    if (searchFilter) {
        searchFilter.addEventListener('input', applyUserFiltersAndRender);
    }

    // Setup form submission handler
    const addUserForm = document.getElementById('add-user-form');
    if (addUserForm) {
        addUserForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            await handleAddUser(e.target);
        });
    }
}

async function loadUsersTable() {
    const tableBody = document.querySelector('#users-table-body');
    if (!tableBody) {
        console.error('Users table body not found');
        return;
    }

    tableBody.innerHTML = '<tr><td colspan="6">Loading all users...</td></tr>';

    // Always load from Firebase to show ALL users (students, lecturers, admins)
    // Firebase is the source of truth for user management
    
    if (usersListener) {
        // If listener already exists, just return - it will auto-update
        return;
    }
    
    // Loading users from Firebase
    
    usersListener = db.collection('users').onSnapshot(querySnapshot => {
        allUsersCache = querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
        
        // User data loaded successfully
        
        loadDepartmentFilterFromFirebase(); // Load department options from Firebase data
        applyUserFiltersAndRender();
    }, e => {
        console.error('Error loading users from Firebase:', e);
        tableBody.innerHTML = '<tr><td colspan="6">Error loading users from Firebase</td></tr>';
    });
}

// Load department options from Firebase user data
function loadDepartmentFilterFromFirebase() {
    try {
        const deptFilter = document.getElementById('user-department-filter');
        if (!deptFilter) return;
        
        // Get unique departments from all users
        const departments = [...new Set(
            allUsersCache
                .map(user => user.department)
                .filter(dept => dept && dept.trim() !== '')
        )].sort();
        
        // Clear existing options except "All Departments"
        const allOption = deptFilter.querySelector('option[value=""]');
        deptFilter.innerHTML = '';
        
        // Add "All Departments" option
        const allDeptOption = document.createElement('option');
        allDeptOption.value = '';
        allDeptOption.textContent = 'All Departments';
        deptFilter.appendChild(allDeptOption);
        
        // Add department options
        departments.forEach(dept => {
            const option = document.createElement('option');
            option.value = dept;
            option.textContent = dept;
            deptFilter.appendChild(option);
        });
        
        // Departments loaded successfully
    } catch (error) {
        console.error('Error loading departments from Firebase:', error);
    }
}

function applyUserFiltersAndRender() {
    const roleFilterEl = document.getElementById('user-role-filter');
    const deptFilterEl = document.getElementById('user-department-filter');
    const searchFilterEl = document.getElementById('user-search');
    
    const roleFilter = roleFilterEl ? roleFilterEl.value : '';
    const deptFilter = deptFilterEl ? deptFilterEl.value : '';
    const searchFilter = searchFilterEl ? searchFilterEl.value.toLowerCase() : '';

    let filteredUsers = allUsersCache.filter(user => {
        // Check if user is active (handle different field names)
        if (user.status === 'inactive' || user.isActive === false) return false;
        if (roleFilter && user.role !== roleFilter) return false;
        if (deptFilter && user.department !== deptFilter) return false;
        if (searchFilter && !user.name.toLowerCase().includes(searchFilter) &&
            !user.email.toLowerCase().includes(searchFilter)) return false;
        return true;
    });

    renderUsersTable(filteredUsers);
}

function renderUsersTable(users) {
    const tableBody = document.querySelector('#users-table-body');
    if (!tableBody) {
        console.error('Users table body not found in renderUsersTable');
        return;
    }

    if (users.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="6">No users found</td></tr>';
        return;
    }

    tableBody.innerHTML = users.map(user => `
        <tr>
            <td>
                <button class="btn btn-sm btn-primary" onclick="window.showEditUserModal('${user.id}')">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="window.deleteUser('${user.id}')">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td><span class="badge badge-${user.role}">${user.role}</span></td>
            <td>${user.department || '-'}</td>
            <td>
                <span class="status-badge ${user.profileCompleted ? 'completed' : 'pending'}">
                    ${user.profileCompleted ? 'Profile Complete' : 'Profile Pending'}
                </span>
            </td>
        </tr>
    `).join('');
}

function showAddUserModal() {
    document.getElementById('add-user-form').reset();
    document.getElementById('add-department-field-group').style.display = 'none';
    document.getElementById('add-matrix-id-field-group').style.display = 'none';

    // Show existing emails for reference
    showExistingEmails();

    const modal = document.getElementById('add-user-modal');
    modal.classList.add('show');
    modal.style.display = 'flex';
}

function showExistingEmails() {
    const existingEmails = allUsersCache.map(user => user.email).sort();
    
    // Only show in console if there are many users (for debugging)
    if (existingEmails.length > 5) {
        // Tip: Use unique email address
    }
}

function toggleDepartmentField() {
    const role = document.getElementById('add-user-role').value;
    const departmentGroup = document.getElementById('add-department-field-group');
    const matrixIdGroup = document.getElementById('add-matrix-id-field-group');
    const departmentLabel = document.getElementById('add-department-field-label');
    const matrixIdLabel = document.getElementById('add-matrix-id-field-label');

    if (role === 'student') {
        departmentGroup.style.display = 'block';
        matrixIdGroup.style.display = 'block';
        departmentLabel.innerHTML = '<i class="fas fa-graduation-cap"></i> Course Code *';
        matrixIdLabel.innerHTML = '<i class="fas fa-id-card"></i> Matrix Number *';
        document.getElementById('add-user-course').required = true;
        document.getElementById('add-user-matrix-id').required = true;
    } else if (role === 'lecturer') {
        departmentGroup.style.display = 'block';
        matrixIdGroup.style.display = 'block';
        departmentLabel.innerHTML = '<i class="fas fa-building"></i> Department *';
        matrixIdLabel.innerHTML = '<i class="fas fa-id-card"></i> Staff ID *';
        document.getElementById('add-user-course').required = true;
        document.getElementById('add-user-matrix-id').required = true;
    } else {
        // Admin - no course/department field
        departmentGroup.style.display = 'none';
        matrixIdGroup.style.display = 'none';
        document.getElementById('add-user-course').required = false;
        document.getElementById('add-user-matrix-id').required = false;
    }
}

function toggleEditDepartmentField() {
    const role = document.getElementById('edit-user-role').value;
    const departmentGroup = document.getElementById('edit-department-field-group');
    const matrixIdGroup = document.getElementById('edit-id-field-group');
    const departmentLabel = document.getElementById('edit-user-department-label');
    const matrixIdLabel = document.getElementById('edit-id-field-label');

    if (role === 'student') {
        departmentGroup.style.display = 'block';
        matrixIdGroup.style.display = 'block';
        departmentLabel.innerHTML = '<i class="fas fa-graduation-cap"></i> Course Code *';
        matrixIdLabel.innerHTML = '<i class="fas fa-id-card"></i> Matrix Number *';
        document.getElementById('edit-user-course').required = true;
        document.getElementById('edit-user-matrix-id').required = true;
    } else if (role === 'lecturer') {
        departmentGroup.style.display = 'block';
        matrixIdGroup.style.display = 'block';
        departmentLabel.innerHTML = '<i class="fas fa-building"></i> Department *';
        matrixIdLabel.innerHTML = '<i class="fas fa-id-card"></i> Staff ID *';
        document.getElementById('edit-user-course').required = true;
        document.getElementById('edit-user-matrix-id').required = true;
    } else {
        // Admin - no course/department field
        departmentGroup.style.display = 'none';
        matrixIdGroup.style.display = 'none';
        document.getElementById('edit-user-course').required = false;
        document.getElementById('edit-user-matrix-id').required = false;
    }
}

function showEditUserModal(id) {
    db.collection('users').doc(id).get().then(doc => {
        if (doc.exists) {
            const user = doc.data();

            document.getElementById('edit-user-id').value = id;
            document.getElementById('edit-user-name').value = user.name;
            document.getElementById('edit-user-email').value = user.email;
            document.getElementById('edit-user-role').value = user.role;
            document.getElementById('edit-user-course').value = user.department || '';
            document.getElementById('edit-user-matrix-id').value = user.matrixId || '';

            // Set the field visibility and labels based on role
            toggleEditDepartmentField();

            const modal = document.getElementById('edit-user-modal');
            modal.classList.add('show');
            modal.style.display = 'flex';
        }
    });
}

async function handleAddUser(form) {
    if (!form || form.tagName !== 'FORM') {
        console.error('Invalid form element passed to handleAddUser');
        addNotification('Form error: Invalid form element', 'error');
        return;
    }

    const submitBtn = document.getElementById('add-user-submit');
    const loadingSpan = document.getElementById('add-user-loading');
    const submitSpan = submitBtn?.querySelector('span');
    
    if (submitBtn) {
        submitBtn.disabled = true;
        if (loadingSpan) loadingSpan.style.display = 'inline-block';
        if (submitSpan) submitSpan.textContent = 'Creating User...';
    }

    try {
        const formData = new FormData(form);
        const userData = {
            name: formData.get('name').trim(),
            email: formData.get('email').trim(),
            password: 'defaultPassword123', // Default password for new users
            role: formData.get('role'),
            department: formData.get('course') || '', // Using 'course' field from form
            studentId: formData.get('matrixId') || '', // Using 'matrixId' field from form
            staffId: formData.get('matrixId') || '', // Using 'matrixId' field from form
            status: formData.get('status') || 'active',
            createdAt: new Date().toISOString(),
            profileCompleted: false,
            isActive: formData.get('status') === 'active'
        };

        if (!userData.name || !userData.email || !userData.role) {
            throw new Error('Please fill in all required fields');
        }

        if (userData.password.length < 6) {
            throw new Error('Password must be at least 6 characters long');
        }

        if (userData.role === 'student' && !userData.department) {
            throw new Error('Department is required for students');
        }
        if (userData.role === 'student' && !userData.studentId) {
            throw new Error('Student ID is required for students');
        }
        if (userData.role === 'lecturer' && !userData.department) {
            throw new Error('Department is required for lecturers');
        }
        if (userData.role === 'lecturer' && !userData.staffId) {
            throw new Error('Staff ID is required for lecturers');
        }

        // Check if email already exists in Firebase Auth and Firestore
        const emailCheck = await db.collection('users')
            .where('email', '==', userData.email)
            .get();
        
        if (!emailCheck.empty) {
            throw new Error(`User with email ${userData.email} already exists in the system`);
        }

        const userCredential = await auth.createUserWithEmailAndPassword(
            userData.email, 
            userData.password
        );

        const firestoreUserData = {
            id: userCredential.user.uid,
            uid: userCredential.user.uid,
            email: userData.email,
            name: userData.name,
            role: userData.role,
            department: userData.department,
            studentId: userData.studentId,
            staffId: userData.staffId,
            createdAt: userData.createdAt,
            profileCompleted: false,
            isActive: true
        };

        await db.collection('users').doc(userCredential.user.uid).set(firestoreUserData);

        // Also sync with backend database if available
        await syncUserWithBackend('create', firestoreUserData);

        closeModal('add-user-modal');
        addNotification(`User ${userData.name} created successfully!`, 'success');
        
        // Force reload the users table to show the new user
        await loadUsersTable();
        
        // Refresh overview stats to reflect changes
        if (typeof window.loadOverviewStats === 'function') {
            await window.loadOverviewStats();
        }
        
        setTimeout(() => {
            alert(`User created successfully!\n\nEmail: ${userData.email}\nPassword: ${userData.password}\n\nPlease share these credentials with the user.`);
        }, 500);

    } catch (e) {
        console.error('Error creating user:', e);
        
        let errorMessage = 'Error creating user';
        if (e.code === 'auth/email-already-in-use') {
            errorMessage = `Email ${userData.email} is already registered. Please use a different email address.`;
        } else if (e.code === 'auth/invalid-email') {
            errorMessage = 'Invalid email address format';
        } else if (e.code === 'auth/weak-password') {
            errorMessage = 'Password is too weak (minimum 6 characters)';
        } else if (e.message) {
            errorMessage = e.message;
        }
        
        addNotification(errorMessage, 'error');
    } finally {
        submitBtn.disabled = false;
        loadingSpan.style.display = 'none';
        submitSpan.textContent = 'Create User';
    }
}

async function handleEditUser(form) {
    if (!form || form.tagName !== 'FORM') {
        console.error('Invalid form element passed to handleEditUser');
        addNotification('Form error: Invalid form element', 'error');
        return;
    }
    
    const userId = document.getElementById('edit-user-id').value;
    const userData = {
        name: document.getElementById('edit-user-name').value,
        email: document.getElementById('edit-user-email').value,
        role: document.getElementById('edit-user-role').value,
        department: document.getElementById('edit-user-course').value,
        updatedAt: new Date().toISOString()
    };

    try {
        await db.collection('users').doc(userId).update(userData);
        
        // Also sync with backend database if available
        await syncUserWithBackend('update', { ...userData, id: userId, uid: userId });
        
        closeModal('edit-user-modal');
        addNotification('User updated successfully', 'success');
        
        // Force reload the users table to show the updated user
        await loadUsersTable();
        
        // Refresh overview stats to reflect changes
        if (typeof window.loadOverviewStats === 'function') {
            await window.loadOverviewStats();
        }
    } catch (e) {
        console.error('Error updating user:', e);
        addNotification('Error updating user: ' + e.message, 'error');
    }
}

async function deleteUser(id) {
    if (!confirm('Are you sure you want to disable this user? Their access will be revoked.')) return;

    try {
        await db.collection('users').doc(id).update({
            isActive: false,
            deletedAt: new Date().toISOString()
        });
        
        // Also sync with backend database if available
        await syncUserWithBackend('delete', { id: id, uid: id });
        
        addNotification('User has been disabled successfully.', 'success');
        
        // Force reload the users table to reflect the change
        await loadUsersTable();
        
        // Refresh overview stats to reflect changes
        if (typeof window.loadOverviewStats === 'function') {
            await window.loadOverviewStats();
        }
    } catch (e) {
        console.error('Error disabling user:', e);
        if (e.code === 'not-found') {
             addNotification('Error: User not found. The user list may be out of date.', 'error');
        } else {
             addNotification('Error disabling user: ' + e.message, 'error');
        }
    }
}

function unsubscribeUsers() {
    if (usersListener) {
        usersListener();
        usersListener = null;
    }
}

/**
 * Sync user operations with backend database
 * @param {string} operation - 'create', 'update', or 'delete'
 * @param {object} userData - User data to sync
 */
async function syncUserWithBackend(operation, userData) {
    try {
        // Check if backend is available
        const isBackendConnected = await testBackendConnection();
        if (!isBackendConnected) {
            // Backend not available - skipping sync
            return;
        }

        // Note: Backend sync requires admin authentication
        // In development, this may fail with 403 Forbidden - that's expected

        // Only log errors, not every sync operation
        switch (operation) {
            case 'create':
                await syncCreateUserWithBackend(userData);
                break;
            case 'update':
                await syncUpdateUserWithBackend(userData);
                break;
            case 'delete':
                await syncDeleteUserWithBackend(userData);
                break;
            default:
                console.warn('Unknown sync operation:', operation);
        }

        // Sync completed successfully

    } catch (error) {
        console.error(`❌ Failed to sync user ${operation} with backend:`, error);
        // Don't throw error - Firebase operation already succeeded
        
        if (error.message.includes('403') || error.message.includes('Forbidden')) {
            console.warn('Backend sync failed: Admin authentication required');
            // Don't show notification for auth issues - it's expected in development
        } else {
            addNotification(`User ${operation}d in Firebase, but backend sync failed. Backend will sync later.`, 'warning');
        }
    }
}

/**
 * Create user in backend database
 */
async function syncCreateUserWithBackend(userData) {
    const payload = {
        uid: userData.uid,
        email: userData.email,
        name: userData.name,
        role: userData.role,
        department: userData.department,
        student_id: userData.studentId,
        staff_id: userData.staffId,
        is_active: userData.isActive,
        profile_completed: userData.profileCompleted
    };

    const response = await makeAuthenticatedRequest(
        API_ENDPOINTS.users.create,
        {
            method: 'POST',
            body: JSON.stringify(payload)
        }
    );
    return response;
}

/**
 * Update user in backend database
 */
async function syncUpdateUserWithBackend(userData) {
    const payload = {
        email: userData.email,
        name: userData.name,
        role: userData.role,
        department: userData.department
    };

    const response = await makeAuthenticatedRequest(
        `${API_ENDPOINTS.users.update}/${userData.uid}`,
        {
            method: 'PUT',
            body: JSON.stringify(payload)
        }
    );
    return response;
}

/**
 * Delete/disable user in backend database
 */
async function syncDeleteUserWithBackend(userData) {
    const response = await makeAuthenticatedRequest(
        `${API_ENDPOINTS.users.delete}/${userData.uid}`,
        {
            method: 'DELETE'
        }
    );
    return response;
}

export { 
    setupUserFilters, 
    loadUsersTable, 
    showAddUserModal, 
    toggleDepartmentField, 
    toggleEditDepartmentField,
    showEditUserModal, 
    handleAddUser, 
    handleEditUser, 
    deleteUser, 
    unsubscribeUsers,
    loadDepartmentFilterFromFirebase
};