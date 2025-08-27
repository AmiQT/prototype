/**
 * User Controller - MVC Pattern Implementation
 * Handles UI interactions and coordinates between Service and View
 */
import { UserService } from '../services/UserService.js';
import { addNotification, closeModal } from '../ui/notifications.js';

export class UserController {
    constructor() {
        this.userService = new UserService();
        this.currentPage = 1;
        this.pageLimit = 10;
        this.isInitialized = false;
        
        // Bind methods to preserve 'this' context
        this.handleAddUser = this.handleAddUser.bind(this);
        this.handleEditUser = this.handleEditUser.bind(this);
        this.handleDeleteUser = this.handleDeleteUser.bind(this);
        this.handleSearch = this.handleSearch.bind(this);
        this.handleFilterChange = this.handleFilterChange.bind(this);
    }

    // Initialize controller
    async initialize() {
        if (this.isInitialized) return;
        
        try {
            // Subscribe to service events
            this.userService.subscribe(this.handleServiceEvent.bind(this));
            
            // Setup UI event listeners
            this.setupEventListeners();
            
            // Load initial data
            await this.userService.loadUsers();
            
            // Start auto-refresh
            this.userService.startAutoRefresh();
            
            this.isInitialized = true;
            console.log('UserController initialized successfully');
        } catch (error) {
            console.error('Failed to initialize UserController:', error);
            addNotification('Failed to initialize user management', 'error');
        }
    }

    // Setup UI event listeners
    setupEventListeners() {
        // Search input
        const searchInput = document.getElementById('user-search');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.handleSearch(e.target.value);
            });
        }

        // Role filter
        const roleFilter = document.getElementById('role-filter');
        if (roleFilter) {
            roleFilter.addEventListener('change', (e) => {
                this.handleFilterChange({ role: e.target.value });
            });
        }

        // Status filter
        const statusFilter = document.getElementById('status-filter');
        if (statusFilter) {
            statusFilter.addEventListener('change', (e) => {
                this.handleFilterChange({ status: e.target.value });
            });
        }

        // Add user form
        const addUserForm = document.getElementById('add-user-form');
        if (addUserForm) {
            addUserForm.addEventListener('submit', this.handleAddUser);
        }

        // Edit user form
        const editUserForm = document.getElementById('edit-user-form');
        if (editUserForm) {
            editUserForm.addEventListener('submit', this.handleEditUser);
        }

        // Pagination controls
        this.setupPaginationListeners();
    }

    // Setup pagination event listeners
    setupPaginationListeners() {
        // Previous page button
        const prevBtn = document.getElementById('users-prev-page');
        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                if (this.currentPage > 1) {
                    this.currentPage--;
                    this.renderUsers();
                }
            });
        }

        // Next page button
        const nextBtn = document.getElementById('users-next-page');
        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                const paginatedData = this.userService.getPaginatedUsers(this.currentPage + 1, this.pageLimit);
                if (paginatedData.pagination.hasNext) {
                    this.currentPage++;
                    this.renderUsers();
                }
            });
        }
    }

    // Handle service events
    handleServiceEvent(event) {
        switch (event.type) {
            case 'users_loaded':
            case 'users_filtered':
                this.renderUsers();
                break;
            case 'user_created':
                addNotification('User created successfully', 'success');
                this.renderUsers();
                break;
            case 'user_updated':
                addNotification('User updated successfully', 'success');
                this.renderUsers();
                break;
            case 'user_deleted':
                addNotification('User deleted successfully', 'success');
                this.renderUsers();
                break;
            case 'error':
                addNotification(event.message, 'error');
                break;
        }
    }

    // Handle search input
    handleSearch(searchTerm) {
        this.currentPage = 1; // Reset to first page
        this.userService.searchUsers(searchTerm);
    }

    // Handle filter changes
    handleFilterChange(filters) {
        this.currentPage = 1; // Reset to first page
        this.userService.setFilters(filters);
    }

    // Handle add user form submission
    async handleAddUser(event) {
        event.preventDefault();
        
        try {
            const formData = new FormData(event.target);
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

            await this.userService.createUser(userData);
            closeModal('add-user-modal');
            event.target.reset();
        } catch (error) {
            addNotification(error.message, 'error');
        }
    }

    // Handle edit user form submission
    async handleEditUser(event) {
        event.preventDefault();
        
        try {
            const formData = new FormData(event.target);
            const userId = formData.get('id');
            const userData = {
                name: formData.get('name'),
                email: formData.get('email'),
                role: formData.get('role'),
                department: formData.get('department'),
                matrix_id: formData.get('matrixId')
            };

            await this.userService.updateUser(userId, userData);
            closeModal('edit-user-modal');
        } catch (error) {
            addNotification(error.message, 'error');
        }
    }

    // Handle delete user
    async handleDeleteUser(userId) {
        if (!confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
            return;
        }

        try {
            await this.userService.deleteUser(userId);
        } catch (error) {
            addNotification(error.message, 'error');
        }
    }

    // Show add user modal
    showAddUserModal() {
        const modal = document.getElementById('add-user-modal');
        if (modal) {
            modal.style.display = 'block';
            
            // Reset form
            const form = document.getElementById('add-user-form');
            if (form) form.reset();
        }
    }

    // Show edit user modal
    showEditUserModal(userId) {
        const modal = document.getElementById('edit-user-modal');
        if (!modal) return;
        
        try {
            const user = this.userService.getUserById(userId);
            if (!user) {
                throw new Error('User not found');
            }
            
            // Populate form fields
            document.getElementById('edit-user-id').value = user.id;
            document.getElementById('edit-user-name').value = user.name || '';
            document.getElementById('edit-user-email').value = user.email || '';
            document.getElementById('edit-user-role').value = user.role || '';
            document.getElementById('edit-user-department').value = user.department || '';
            document.getElementById('edit-user-matrix-id').value = user.matrix_id || '';
            
            modal.style.display = 'block';
        } catch (error) {
            addNotification('Error loading user data', 'error');
        }
    }

    // Render users table
    renderUsers() {
        const tableBody = document.querySelector('#users-table-body');
        if (!tableBody) return;
        
        const paginatedData = this.userService.getPaginatedUsers(this.currentPage, this.pageLimit);
        const users = paginatedData.data;
        
        if (users.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="6">No users found</td></tr>';
            this.updatePaginationControls(paginatedData.pagination);
            return;
        }
        
        tableBody.innerHTML = users.map(user => `
            <tr>
                <td>
                    <button class="btn btn-sm btn-secondary" onclick="userController.showEditUserModal('${user.id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="userController.handleDeleteUser('${user.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
                <td>${user.name || 'N/A'}</td>
                <td>${user.email || 'N/A'}</td>
                <td><span class="badge badge-${this.getRoleBadgeClass(user.role)}">${user.role || 'N/A'}</span></td>
                <td>${user.department || 'N/A'}</td>
                <td><span class="badge badge-${this.getStatusBadgeClass(user.status)}">${user.status || 'active'}</span></td>
            </tr>
        `).join('');
        
        this.updatePaginationControls(paginatedData.pagination);
        this.updateUserStats();
    }

    // Update pagination controls
    updatePaginationControls(pagination) {
        const prevBtn = document.getElementById('users-prev-page');
        const nextBtn = document.getElementById('users-next-page');
        const pageInfo = document.getElementById('users-page-info');
        
        if (prevBtn) prevBtn.disabled = !pagination.hasPrev;
        if (nextBtn) nextBtn.disabled = !pagination.hasNext;
        if (pageInfo) {
            pageInfo.textContent = `Page ${pagination.page} of ${pagination.totalPages} (${pagination.total} total)`;
        }
    }

    // Update user statistics
    updateUserStats() {
        const stats = this.userService.getStatistics();
        
        // Update total users count
        const totalUsersElement = document.getElementById('total-users');
        if (totalUsersElement) {
            totalUsersElement.textContent = stats.total;
        }
        
        // Update role breakdown if element exists
        const roleStatsElement = document.getElementById('user-role-stats');
        if (roleStatsElement) {
            roleStatsElement.innerHTML = Object.entries(stats.byRole)
                .map(([role, count]) => `<span class="stat-item">${role}: ${count}</span>`)
                .join(' | ');
        }
    }

    // Helper methods for badge classes
    getRoleBadgeClass(role) {
        switch(role) {
            case 'admin': return 'danger';
            case 'lecturer': return 'warning';
            case 'student': return 'primary';
            default: return 'secondary';
        }
    }

    getStatusBadgeClass(status) {
        switch(status) {
            case 'active': return 'success';
            case 'inactive': return 'secondary';
            case 'suspended': return 'danger';
            default: return 'success';
        }
    }

    // Toggle department field based on role
    toggleDepartmentField(isEdit = false) {
        const prefix = isEdit ? 'edit-' : 'add-';
        const roleSelect = document.getElementById(`${prefix}user-role`);
        const deptField = document.getElementById(`${prefix}user-department`);
        const deptLabel = document.querySelector(`label[for="${prefix}user-department"]`);
        
        if (roleSelect && deptField && deptLabel) {
            if (roleSelect.value === 'student') {
                deptLabel.textContent = 'Department';
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

    // Cleanup resources
    cleanup() {
        this.userService.cleanup();
        this.isInitialized = false;
    }

    // Refresh data
    async refresh() {
        await this.userService.refresh();
    }
}