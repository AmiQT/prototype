// Clean Supabase/FastAPI integration - Firebase completely removed
import { API_ENDPOINTS, makeAuthenticatedRequest, testBackendConnection } from '../../config/backend-config.js';
import { addNotification, closeModal } from '../../ui/notifications.js';

let allUsersCache = [];
let refreshInterval = null;

function setupUserFilters() {
    const roleFilter = document.getElementById('role-filter');
    const statusFilter = document.getElementById('status-filter');
    const searchFilter = document.getElementById('user-search');

    if (roleFilter) {
        roleFilter.addEventListener('change', applyUserFiltersAndRender);
    }
    if (statusFilter) {
        statusFilter.addEventListener('change', applyUserFiltersAndRender);
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

function applyUserFiltersAndRender() {
    const roleFilter = document.getElementById('role-filter');
    const statusFilter = document.getElementById('status-filter');
    const searchFilter = document.getElementById('user-search');
    
    let filteredUsers = [...allUsersCache];
    
    // Apply role filter
    if (roleFilter && roleFilter.value) {
        filteredUsers = filteredUsers.filter(user => user.role === roleFilter.value);
    }
    
    // Apply status filter
    if (statusFilter && statusFilter.value) {
        filteredUsers = filteredUsers.filter(user => user.status === statusFilter.value);
    }
    
    // Apply search filter
    if (searchFilter && searchFilter.value.trim()) {
        const searchTerm = searchFilter.value.toLowerCase().trim();
        filteredUsers = filteredUsers.filter(user => 
            user.name?.toLowerCase().includes(searchTerm) ||
            user.email?.toLowerCase().includes(searchTerm) ||
            user.department?.toLowerCase().includes(searchTerm) ||
            user.matrix_id?.toLowerCase().includes(searchTerm)
        );
    }
    
    renderUsersTable(filteredUsers);
}

function renderUsersTable(users) {
    const tableBody = document.querySelector('#users-table-body');
    if (!tableBody) return;
    
    if (users.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="6">No users found</td></tr>';
        return;
    }
    
    tableBody.innerHTML = users.map(user => `
        <tr>
            <td>
                <button class="btn btn-sm btn-secondary" onclick="showEditUserModal('${user.id}')">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteUser('${user.id}')">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
            <td>${user.name || 'N/A'}</td>
            <td>${user.email || 'N/A'}</td>
            <td><span class="badge badge-${getRoleBadgeClass(user.role)}">${user.role || 'N/A'}</span></td>
            <td>${user.department || 'N/A'}</td>
            <td><span class="badge badge-${getStatusBadgeClass(user.status)}">${user.status || 'active'}</span></td>
        </tr>
    `).join('');
}

function getRoleBadgeClass(role) {
    switch(role) {
        case 'admin': return 'danger';
        case 'lecturer': return 'warning';
        case 'student': return 'primary';
        default: return 'secondary';
    }
}

function getStatusBadgeClass(status) {
    switch(status) {
        case 'active': return 'success';
        case 'inactive': return 'secondary';
        case 'suspended': return 'danger';
        default: return 'success';
    }
}

function showAddUserModal() {
    const modal = document.getElementById('add-user-modal');
    if (modal) {
        modal.style.display = 'block';
        
        // Reset form
        const form = document.getElementById('add-user-form');
        if (form) form.reset();
    }
}

async function showEditUserModal(userId) {
    const modal = document.getElementById('edit-user-modal');
    if (!modal) return;
    
    try {
        // Fetch user data from Supabase via backend API
        console.log('Fetching user data from Supabase for editing, ID:', userId);
        
        const response = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.get}/${userId}`,
            { method: 'GET' }
        );

        if (!response.ok) {
            throw new Error(`Failed to fetch user: ${response.status}`);
        }

        const userData = await response.json();
        
        // Populate form fields
        document.getElementById('edit-user-id').value = userData.id;
        document.getElementById('edit-user-name').value = userData.name || '';
        document.getElementById('edit-user-email').value = userData.email || '';
        document.getElementById('edit-user-role').value = userData.role || '';
        document.getElementById('edit-user-department').value = userData.department || '';
        document.getElementById('edit-user-matrix-id').value = userData.matrix_id || '';
        
        // Show/hide fields based on role
        toggleEditDepartmentField();
        
        modal.style.display = 'block';
    } catch (error) {
        console.error('Error loading user for edit:', error);
        addNotification(`Error loading user data: ${error.message}`, 'error');
    }
}

async function handleAddUser(form) {
    try {
        const formData = new FormData(form);
        const userData = {
            name: formData.get('name'),
            email: formData.get('email'),
            password: formData.get('password'),
            role: formData.get('role'),
            department: formData.get('department'),
            matrix_id: formData.get('matrixId')
        };
        
        // Validate required fields
        if (!userData.name || !userData.email || !userData.password || !userData.role) {
            throw new Error('Please fill in all required fields');
        }
        
        // Create user in Supabase via backend API
        console.log('Creating user in Supabase via backend API:', userData);
        
        const createUserPayload = {
            email: userData.email,
            name: userData.name,
            password: userData.password,
            role: userData.role,
            department: userData.department,
            matrix_id: userData.matrix_id,
            status: 'active',
            profile_completed: false,
            is_active: true
        };

        const response = await makeAuthenticatedRequest(
            API_ENDPOINTS.users.create,
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(createUserPayload)
            }
        );

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to create user: ${response.status}`);
        }

        const newUser = await response.json();
        
        // Add to local cache for immediate display
        allUsersCache.push(newUser);
        
        addNotification('User created successfully in Supabase', 'success');
        closeModal('add-user-modal');
        form.reset();
        await loadUsersTable(); // Refresh the table
        
        // Show success message with credentials
        setTimeout(() => {
            alert(`User created successfully in Supabase!\n\nEmail: ${userData.email}\nPassword: ${userData.password}\n\nPlease share these credentials with the user.`);
        }, 500);
    } catch (error) {
        console.error('Error creating user:', error);
        addNotification(error.message || 'Error creating user', 'error');
    }
}

async function handleEditUser(form) {
    try {
        const formData = new FormData(form);
        const userId = formData.get('id');
        const userData = {
            name: formData.get('name'),
            email: formData.get('email'),
            role: formData.get('role'),
            department: formData.get('department'),
            matrix_id: formData.get('matrixId')
        };
        
        // Update user in Supabase via backend API
        console.log('Updating user in Supabase via backend API:', userData);
        
        const updatePayload = {
            name: userData.name,
            email: userData.email,
            role: userData.role,
            department: userData.department,
            matrix_id: userData.matrix_id,
            updated_at: new Date().toISOString()
        };

        const response = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.update}/${userId}`,
            {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(updatePayload)
            }
        );

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to update user: ${response.status}`);
        }

        const updatedUser = await response.json();
        
        // Update local cache
        const index = allUsersCache.findIndex(user => user.id === userId);
        if (index !== -1) {
            allUsersCache[index] = { ...allUsersCache[index], ...updatedUser };
        }
        
        addNotification('User updated successfully in Supabase', 'success');
        closeModal('edit-user-modal');
        await loadUsersTable(); // Refresh the table
    } catch (error) {
        console.error('Error updating user:', error);
        addNotification(error.message || 'Error updating user', 'error');
    }
}

async function deleteUser(userId) {
    if (!confirm('Are you sure you want to disable this user? Their access will be revoked.')) {
        return;
    }
    
    try {
        // Delete/disable user in Supabase via backend API
        console.log('Deleting user from Supabase via backend API for ID:', userId);
        
        const response = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.delete}/${userId}`,
            { method: 'DELETE' }
        );

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to delete user: ${response.status}`);
        }

        // Remove from local cache
        allUsersCache = allUsersCache.filter(user => user.id !== userId);
        
        addNotification('User has been disabled successfully in Supabase', 'success');
        await loadUsersTable(); // Refresh the table
    } catch (error) {
        console.error('Error deleting user:', error);
        addNotification(error.message || 'Error deleting user', 'error');
    }
}

function toggleDepartmentField() {
    const roleSelect = document.getElementById('add-user-role');
    const deptField = document.getElementById('add-user-department');
    const deptLabel = document.querySelector('label[for="add-user-department"]');
    
    if (roleSelect && deptField && deptLabel) {
        if (roleSelect.value === 'student') {
            deptLabel.textContent = 'Course';
            deptField.placeholder = 'e.g., Computer Science, Engineering';
        } else if (roleSelect.value === 'lecturer') {
            deptLabel.textContent = 'Department';
            deptField.placeholder = 'e.g., Faculty of Computer Science';
        } else {
            deptLabel.textContent = 'Department';
            deptField.placeholder = 'Department';
        }
    }
}

function toggleEditDepartmentField() {
    const roleSelect = document.getElementById('edit-user-role');
    const deptField = document.getElementById('edit-user-department');
    const deptLabel = document.querySelector('label[for="edit-user-department"]');
    
    if (roleSelect && deptField && deptLabel) {
        if (roleSelect.value === 'student') {
            deptLabel.textContent = 'Course';
            deptField.placeholder = 'e.g., Computer Science, Engineering';
        } else if (roleSelect.value === 'lecturer') {
            deptLabel.textContent = 'Department';
            deptField.placeholder = 'e.g., Faculty of Computer Science';
        } else {
            deptLabel.textContent = 'Department';
            deptField.placeholder = 'Department';
        }
    }
}

function cleanup() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
        refreshInterval = null;
    }
    allUsersCache = [];
}

// Export functions
export {
    setupUserFilters,
    loadUsersTable,
    showAddUserModal,
    showEditUserModal,
    handleAddUser,
    handleEditUser,
    deleteUser,
    toggleDepartmentField,
    toggleEditDepartmentField,
    cleanup
};