// Clean Supabase/FastAPI integration
import { API_ENDPOINTS, makeAuthenticatedRequest, testBackendConnection } from '../config/backend-config.js';
import { addNotification, closeModal } from '../ui/notifications.js';

let allUsersCache = [];
let refreshInterval = null;

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

    tableBody.innerHTML = '<tr><td colspan="6">Loading users from Supabase...</td></tr>';

    try {
        // Check if backend is available
        const isBackendConnected = await testBackendConnection();
        if (!isBackendConnected) {
            throw new Error('Backend connection failed');
        }

        // Fetch real users from Supabase via backend API
        console.log('📊 Loading real user data from Supabase...');
        
        const response = await makeAuthenticatedRequest(
            API_ENDPOINTS.users.list,
            { method: 'GET' }
        );

        if (!response.ok) {
            throw new Error(`Failed to fetch users: ${response.status} ${response.statusText}`);
        }

        const usersData = await response.json();
        allUsersCache = usersData.users || usersData || [];
        
        console.log(`Loaded ${allUsersCache.length} users from Supabase`);
        
        // Load department filter options
        loadDepartmentFilterOptions();
        applyUserFiltersAndRender();
        
        // Setup auto-refresh every 30 seconds
        if (refreshInterval) clearInterval(refreshInterval);
        refreshInterval = setInterval(() => {
            loadUsersTable();
        }, 30000);
    } catch (error) {
        console.error('Error loading users from Supabase:', error);
        
        // Fallback to empty state with retry option
        tableBody.innerHTML = `
            <tr>
                <td colspan="6">
                    <div class="text-center">
                        <p class="text-muted mb-2">Error loading users from Supabase</p>
                        <button class="btn btn-sm btn-primary" onclick="loadUsersTable()">
                            <i class="fas fa-redo"></i> Retry
                        </button>
                    </div>
                </td>
            </tr>
        `;
        
        // Clear cache on error
        allUsersCache = [];
    }
}

// Load department options from user data
function loadDepartmentFilterOptions() {
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
        console.error('Error loading departments:', error);
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

async function showEditUserModal(id) {
    try {
        // Fetch user data from Supabase via backend API
        console.log('Fetching user data from Supabase for editing, ID:', id);
        
        const response = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.get}/${id}`,
            { method: 'GET' }
        );

        if (!response.ok) {
            throw new Error(`Failed to fetch user: ${response.status}`);
        }

        const userData = await response.json();
        
        // Populate the edit form with user data
        document.getElementById('edit-user-id').value = userData.id;
        document.getElementById('edit-user-name').value = userData.name || '';
        document.getElementById('edit-user-email').value = userData.email || '';
        document.getElementById('edit-user-role').value = userData.role || '';
        document.getElementById('edit-user-course').value = userData.department || '';
        
        // Show/hide fields based on role
        toggleEditDepartmentField();
        
        // Show the modal
        const modal = document.getElementById('edit-user-modal');
        modal.classList.add('show');
        modal.style.display = 'flex';
        
    } catch (error) {
        console.error('Error fetching user data for editing:', error);
        addNotification(`Error loading user data: ${error.message}`, 'error');
    }
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

        // Check if email already exists in Supabase Auth and database
        // This logic needs to be adapted for backend
        const emailCheck = allUsersCache.find(user => user.email === userData.email);
        
        if (emailCheck) {
            throw new Error(`User with email ${userData.email} already exists in the system`);
        }

        // Create user in Supabase via backend API
        console.log('Creating user in Supabase via backend API:', userData);
        
        const createUserPayload = {
            email: userData.email,
            name: userData.name,
            password: userData.password,
            role: userData.role,
            department: userData.department,
            student_id: userData.studentId,
            staff_id: userData.staffId,
            status: userData.status,
            profile_completed: false,
            is_active: true
        };

        const createResponse = await makeAuthenticatedRequest(
            API_ENDPOINTS.users.create,
            {
                method: 'POST',
                body: JSON.stringify(createUserPayload)
            }
        );

        if (!createResponse.ok) {
            const errorData = await createResponse.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to create user: ${createResponse.status}`);
        }

        const newUser = await createResponse.json();
        
        // Add to local cache for immediate display
        allUsersCache.push(newUser);

        closeModal('add-user-modal');
        addNotification(`User ${userData.name} created successfully in Supabase!`, 'success');
        
        // Force reload the users table to show the new user
        await loadUsersTable();
        
        // Refresh overview stats to reflect changes
        if (typeof window.loadOverviewStats === 'function') {
            await window.loadOverviewStats();
        }
        
        setTimeout(() => {
            alert(`User created successfully in Supabase!\n\nEmail: ${userData.email}\nPassword: ${userData.password}\n\nPlease share these credentials with the user.`);
        }, 500);

    } catch (e) {
        console.error('Error creating user:', e);
        
        let errorMessage = 'Error creating user';
        if (e.message.includes('already exists')) {
            errorMessage = `Email ${userData.email} is already registered. Please use a different email address.`;
        } else if (e.message.includes('Password must be at least 6 characters long')) {
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
        // Update user in Supabase via backend API
        console.log('Updating user in Supabase via backend API:', userData);
        
        const updatePayload = {
            name: userData.name,
            email: userData.email,
            role: userData.role,
            department: userData.department,
            updated_at: userData.updatedAt
        };

        const updateResponse = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.update}/${userId}`,
            {
                method: 'PUT',
                body: JSON.stringify(updatePayload)
            }
        );

        if (!updateResponse.ok) {
            const errorData = await updateResponse.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to update user: ${updateResponse.status}`);
        }

        const updatedUser = await updateResponse.json();
        
        // Update local cache
        const index = allUsersCache.findIndex(user => user.id === userId);
        if (index !== -1) {
            allUsersCache[index] = { ...allUsersCache[index], ...updatedUser };
        }
        
        closeModal('edit-user-modal');
        addNotification('User updated successfully in Supabase', 'success');
        
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
        // Delete/disable user in Supabase via backend API
        console.log('Deleting user from Supabase via backend API for ID:', id);
        
        const deleteResponse = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.delete}/${id}`,
            { method: 'DELETE' }
        );

        if (!deleteResponse.ok) {
            const errorData = await deleteResponse.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to delete user: ${deleteResponse.status}`);
        }

        // Remove from local cache
        allUsersCache = allUsersCache.filter(user => user.id !== id);
        
        addNotification('User has been disabled successfully in Supabase.', 'success');
        
        // Force reload the users table to reflect the change
        await loadUsersTable();
        
        // Refresh overview stats to reflect changes
        if (typeof window.loadOverviewStats === 'function') {
            await window.loadOverviewStats();
        }
    } catch (e) {
        console.error('Error disabling user:', e);
        if (e.message.includes('not-found')) {
             addNotification('Error: User not found. The user list may be out of date.', 'error');
        } else {
             addNotification('Error disabling user: ' + e.message, 'error');
        }
    }
}

function unsubscribeUsers() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
        refreshInterval = null;
    }
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
    loadDepartmentFilterOptions
};