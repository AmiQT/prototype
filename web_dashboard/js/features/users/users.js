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

// Generate a random secure password
function generatePassword() {
    const length = 12;
    const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*";
    let password = "";
    for (let i = 0; i < length; i++) {
        password += charset.charAt(Math.floor(Math.random() * charset.length));
    }
    const passwordInput = document.getElementById('add-user-password');
    if (passwordInput) {
        passwordInput.value = password;
        addNotification('Password generated successfully', 'success');
    }
}

// Make generatePassword available globally
window.generatePassword = generatePassword;

async function loadUsersTable() {
    const tableBody = document.querySelector('#users-table-body');
    if (!tableBody) {
        console.error('Users table body not found');
        return;
    }

    tableBody.innerHTML = '<tr><td colspan="6">Loading users from Supabase...</td></tr>';

    try {
        // SUPABASE DIRECT CALLS: Load real users from Supabase
        console.log('📊 Loading real user data from Supabase...');
        
        const { supabase } = await import('../../config/supabase-config.js');
        
        // Get users first, then profiles separately to avoid complex join issues
        const { data: users, error: usersError } = await supabase
            .from('users')
            .select('*')
            .order('created_at', { ascending: false });
        
        if (usersError) {
            throw usersError;
        }
        
        // Get profiles separately (handle potential missing columns gracefully)
        const { data: profiles, error: profilesError } = await supabase
            .from('profiles')
            .select('*');
        
        if (profilesError) {
            console.warn('❌ Error loading profiles:', profilesError);
        }
        
        // Create a map of profiles by user_id for easy lookup
        const profilesMap = {};
        profiles?.forEach(profile => {
            profilesMap[profile.user_id] = profile;
        });
        
        // Format users data for table display, merging with profiles
        allUsersCache = users?.map(user => {
            const userProfile = profilesMap[user.id] || {};
            
            return {
                id: user.id,
                uid: user.uid || user.id,
                name: user.name || userProfile.full_name || 'N/A',
                email: user.email || 'N/A',
                role: user.role || 'student',
                department: user.department || userProfile.academic_info?.department || userProfile.department || 'N/A',
                faculty: userProfile.academic_info?.faculty || userProfile.faculty || 'N/A',
                student_id: user.student_id || userProfile.academic_info?.studentId || userProfile.student_id || 'N/A',
                phone: userProfile.phone_number || userProfile.phone || 'N/A',
                bio: userProfile.bio || 'N/A',
                is_active: user.is_active !== false,
                status: user.is_active !== false ? 'active' : 'inactive',
                created_at: user.created_at,
                profile_completed: user.profile_completed || false
            };
        }) || [];
        
        console.log(`✅ Loaded ${allUsersCache.length} users from Supabase`);
        
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
    if (!tableBody) {
        console.error('❌ Users table body element not found!');
        return;
    }
    
    console.log(`📋 Rendering ${users.length} users to table`);
    
    if (users.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="6">No users found</td></tr>';
        return;
    }

    const tableHTML = users.map(user => `
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
    
    tableBody.innerHTML = tableHTML;
    console.log('✅ Users table rendered successfully');
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
        // Show modal with proper class and styling (same as edit modal)
        modal.classList.add('show');
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        modal.style.zIndex = '1000';
        
        // Reset form
        const form = document.getElementById('add-user-form');
        if (form) form.reset();
        
        // Show/hide fields based on default role
        toggleDepartmentField();
        
        console.log('✅ Add user modal opened');
    }
}

async function showEditUserModal(userId) {
    const modal = document.getElementById('edit-user-modal');
    if (!modal) return;
    
    try {
        // SUPABASE DIRECT: Fetch user data from cache first
        console.log('Loading user data for editing, ID:', userId);
        
        // Find user in cache
        let userData = allUsersCache.find(user => user.id === userId || user.uid === userId);
        
        if (!userData) {
            // If not in cache, fetch from Supabase directly
            const { supabase } = await import('../../config/supabase-config.js');
            
            const { data: user, error: userError } = await supabase
                .from('users')
                .select('*')
                .eq('id', userId)
                .single();
                
            if (userError) throw userError;
            
            const { data: profile, error: profileError } = await supabase
                .from('profiles')
                .select('*')
                .eq('user_id', userId)
                .single();
                
            // Merge user and profile data
            userData = {
                id: user.id,
                uid: user.uid || user.id,
                name: user.name || profile?.full_name || '',
                email: user.email || '',
                role: user.role || 'student',
                department: user.department || profile?.academic_info?.department || profile?.department || '',
                student_id: user.student_id || profile?.academic_info?.studentId || profile?.student_id || '',
                status: user.is_active !== false ? 'active' : 'inactive'
            };
        }
        
        // Populate form fields with correct IDs
        document.getElementById('edit-user-id').value = userData.id;
        document.getElementById('edit-user-name').value = userData.name || '';
        document.getElementById('edit-user-email').value = userData.email || '';
        document.getElementById('edit-user-role').value = userData.role || '';
        document.getElementById('edit-user-status').value = userData.status || 'active';
        
        // Handle department field
        const courseField = document.getElementById('edit-user-course');
        if (courseField) {
            courseField.value = userData.department || '';
        }
        
        // Handle matrix/staff ID field
        const matrixField = document.getElementById('edit-user-matrix-id');
        if (matrixField) {
            matrixField.value = userData.student_id || '';
        }
        
        // Show/hide fields based on role
        toggleEditDepartmentField();
        
        // Show modal with proper class and debugging
        modal.classList.add('show');
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        modal.style.zIndex = '1000';
        
        // Debug modal state
        console.log('🔍 Modal element:', modal);
        console.log('🔍 Modal classes:', modal.className);
        console.log('🔍 Modal display:', modal.style.display);
        console.log('🔍 Modal visibility:', modal.style.visibility);
        
        // Force focus on modal
        setTimeout(() => {
            modal.focus();
        }, 100);
        
        console.log('✅ User data loaded for editing:', userData);
        console.log('✅ Modal should be visible now!');
        
    } catch (error) {
        console.error('❌ Error loading user for edit:', error);
        alert(`Error loading user data: ${error.message}`);
    }
}

async function handleAddUser(form) {
    // Define userData outside try block so it's accessible in catch
    let userData = null;
    
    try {
        const formData = new FormData(form);
        userData = {
            name: formData.get('name'),
            email: formData.get('email'),
            password: formData.get('password'),
            role: formData.get('role'),
            department: formData.get('course') || formData.get('department'), // Support both field names
            matrix_id: formData.get('matrixId')
        };
        
        // Validate required fields
        if (!userData.name || !userData.email || !userData.password || !userData.role) {
            throw new Error('Please fill in all required fields');
        }
        
        // ✅ FIX: Use Backend API to create user with auth
        console.log('✅ Creating user via backend API:', userData);
        
        // Call backend API to create user (backend has service role access)
        const result = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.create}/admin/create`,
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    email: userData.email,
                    password: userData.password,
                    name: userData.name,
                    role: userData.role,
                    department: userData.department,
                    student_id: userData.matrix_id,
                    is_active: true
                })
            }
        );
        
        console.log('✅ User created successfully:', result);
        
        // Refresh the table to show new user
        await loadUsersTable();
        
        addNotification('User created successfully!', 'success');
        closeModal('add-user-modal');
        form.reset();
        
        // Show credentials notification
        setTimeout(() => {
            addNotification(`New user created! Email: ${userData.email} | Password: ${userData.password}`, 'success', 8000);
        }, 500);
        
    } catch (error) {
        console.error('Error creating user:', error);
        
        // Extract user-friendly error message
        let errorMessage = 'Error creating user';
        if (error.message) {
            // Check for specific error patterns
            const userEmail = userData?.email || 'this email';
            if (error.message.includes('already exists')) {
                errorMessage = `User ${userEmail} already exists. Please use a different email.`;
            } else if (error.message.includes('already been registered')) {
                errorMessage = `Email ${userEmail} is already registered. Please use a different email.`;
            } else {
                errorMessage = error.message;
            }
        }
        
        addNotification(errorMessage, 'error', 5000);
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
            status: formData.get('status'),
            department: formData.get('course'),
            matrixId: formData.get('matrixId')
        };
        
        // Validate required fields
        if (!userData.name || !userData.email || !userData.role) {
            throw new Error('Please fill in all required fields');
        }
        
        // SUPABASE DIRECT: Update user in Supabase
        console.log('✅ Updating user in Supabase:', userData);
        
        const { supabase } = await import('../../config/supabase-config.js');
        
        // Update users table
        const { data: updatedUser, error: userError } = await supabase
            .from('users')
            .update({
                name: userData.name,
                email: userData.email,
                role: userData.role,
                is_active: userData.status === 'active',
                department: userData.department,
                student_id: userData.matrixId,
                updated_at: new Date().toISOString()
            })
            .eq('id', userId)
            .select()
            .single();
            
        if (userError) throw userError;
        
        // Update profiles table if exists
        const { error: profileError } = await supabase
            .from('profiles')
            .upsert({
                user_id: userId,
                full_name: userData.name,
                department: userData.department,
                student_id: userData.matrixId,
                updated_at: new Date().toISOString()
            });
            
        if (profileError) {
            console.warn('Profile update warning:', profileError);
        }
        
        // Update local cache
        const index = allUsersCache.findIndex(user => user.id === userId || user.uid === userId);
        if (index !== -1) {
            allUsersCache[index] = {
                ...allUsersCache[index],
                name: userData.name,
                email: userData.email,
                role: userData.role,
                department: userData.department,
                student_id: userData.matrixId,
                status: userData.status,
                is_active: userData.status === 'active'
            };
        }
        
        alert('✅ User updated successfully!');
        closeModal('edit-user-modal');
        await loadUsersTable(); // Refresh the table
        
    } catch (error) {
        console.error('❌ Error updating user:', error);
        alert(`Error updating user: ${error.message}`);
    }
}

async function deleteUser(userId) {
    if (!confirm('Are you sure you want to delete this user permanently? This action cannot be undone.')) {
        return;
    }
    
    try {
        // Delete user via backend API (deletes from both Supabase Auth and database)
        console.log('Deleting user from Supabase via backend API for ID:', userId);
        
        const result = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.users.delete}/${userId}`,
            { method: 'DELETE' }
        );

        console.log('✅ User deleted successfully:', result);

        // Remove from local cache
        allUsersCache = allUsersCache.filter(user => user.id !== userId);
        
        addNotification('User deleted successfully', 'success');
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
            deptLabel.textContent = 'Department';
            deptField.placeholder = 'e.g., Computer Science, Information Technology';
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
    const deptFieldGroup = document.getElementById('edit-department-field-group');
    const idFieldGroup = document.getElementById('edit-id-field-group');
    const deptLabel = document.getElementById('edit-user-department-label');
    const idLabel = document.getElementById('edit-id-field-label');
    
    if (roleSelect && deptFieldGroup && idFieldGroup) {
        const selectedRole = roleSelect.value;
        
        if (selectedRole === 'student' || selectedRole === 'lecturer') {
            // Show both fields for students and lecturers
            deptFieldGroup.style.display = 'block';
            idFieldGroup.style.display = 'block';
            
            if (selectedRole === 'student') {
                if (deptLabel) {
                    deptLabel.innerHTML = '<i class="fas fa-building"></i> Department *';
                }
                if (idLabel) {
                    idLabel.innerHTML = '<i class="fas fa-id-card"></i> Matrix Number *';
                }
                const courseField = document.getElementById('edit-user-course');
                const matrixField = document.getElementById('edit-user-matrix-id');
                if (courseField) courseField.placeholder = 'e.g., Computer Science, Information Technology';
                if (matrixField) matrixField.placeholder = 'e.g., CD21110123';
            } else if (selectedRole === 'lecturer') {
                if (deptLabel) {
                    deptLabel.innerHTML = '<i class="fas fa-building"></i> Department *';
                }
                if (idLabel) {
                    idLabel.innerHTML = '<i class="fas fa-id-badge"></i> Staff ID *';
                }
                const courseField = document.getElementById('edit-user-course');
                const matrixField = document.getElementById('edit-user-matrix-id');
                if (courseField) courseField.placeholder = 'e.g., Faculty of Computer Science';
                if (matrixField) matrixField.placeholder = 'e.g., STAFF001';
            }
        } else {
            // Hide fields for admin and other roles
            deptFieldGroup.style.display = 'none';
            idFieldGroup.style.display = 'none';
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