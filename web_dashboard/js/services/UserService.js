/**
 * User Service - OOP approach for user management
 * Extends BaseService for common functionality
 */
import { BaseService } from '../core/BaseService.js';
import { makeAuthenticatedRequest, API_ENDPOINTS } from '../config/backend-config.js';

export class UserService extends BaseService {
    constructor() {
        super(API_ENDPOINTS.users);
        this.users = [];
        this.filteredUsers = [];
        this.currentFilters = {
            role: '',
            status: '',
            search: ''
        };
    }

    // Implement makeRequest from BaseService
    async makeRequest(endpoint, options) {
        return await makeAuthenticatedRequest(endpoint, options);
    }

    // Load all users
    async loadUsers() {
        try {
            const response = await this.request(this.apiEndpoint);
            this.users = Array.isArray(response) ? response : response.users || [];
            this.applyFilters();
            this.notify({ type: 'users_loaded', data: this.filteredUsers });
            return this.users;
        } catch (error) {
            this.handleError(error);
            return [];
        }
    }

    // Create new user
    async createUser(userData) {
        try {
            const response = await this.request(this.apiEndpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(userData)
            });
            
            this.users.push(response);
            this.applyFilters();
            this.notify({ type: 'user_created', data: response });
            return response;
        } catch (error) {
            this.handleError(error);
            throw error;
        }
    }

    // Update user
    async updateUser(userId, userData) {
        try {
            const response = await this.request(`${this.apiEndpoint}/${userId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(userData)
            });
            
            const index = this.users.findIndex(u => u.id === userId);
            if (index !== -1) {
                this.users[index] = response;
                this.applyFilters();
            }
            
            this.notify({ type: 'user_updated', data: response });
            return response;
        } catch (error) {
            this.handleError(error);
            throw error;
        }
    }

    // Delete user
    async deleteUser(userId) {
        try {
            await this.request(`${this.apiEndpoint}/${userId}`, {
                method: 'DELETE'
            });
            
            this.users = this.users.filter(u => u.id !== userId);
            this.applyFilters();
            this.notify({ type: 'user_deleted', data: { id: userId } });
            return true;
        } catch (error) {
            this.handleError(error);
            throw error;
        }
    }

    // Apply filters
    applyFilters() {
        let filtered = [...this.users];
        
        // Role filter
        if (this.currentFilters.role) {
            filtered = filtered.filter(user => user.role === this.currentFilters.role);
        }
        
        // Status filter
        if (this.currentFilters.status) {
            filtered = filtered.filter(user => user.status === this.currentFilters.status);
        }
        
        // Search filter
        if (this.currentFilters.search) {
            const searchTerm = this.currentFilters.search.toLowerCase();
            filtered = filtered.filter(user => 
                user.name?.toLowerCase().includes(searchTerm) ||
                user.email?.toLowerCase().includes(searchTerm) ||
                user.department?.toLowerCase().includes(searchTerm) ||
                user.matrix_id?.toLowerCase().includes(searchTerm)
            );
        }
        
        this.filteredUsers = filtered;
        this.notify({ type: 'users_filtered', data: this.filteredUsers });
    }

    // Set filters
    setFilters(filters) {
        this.currentFilters = { ...this.currentFilters, ...filters };
        this.applyFilters();
    }

    // Get paginated users
    getPaginatedUsers(page = 1, limit = 10) {
        return this.paginate(this.filteredUsers, page, limit);
    }

    // Search users with debouncing
    searchUsers = this.debounce((searchTerm) => {
        this.setFilters({ search: searchTerm });
    }, 300);

    // Get unique departments for filter
    getDepartments() {
        return [...new Set(
            this.users
                .map(user => user.department)
                .filter(dept => dept && dept.trim() !== '')
        )].sort();
    }

    // Refresh data
    async refresh() {
        await super.refresh();
        await this.loadUsers();
    }

    // Get user by ID
    getUserById(userId) {
        return this.users.find(user => user.id === userId);
    }

    // Get users by role
    getUsersByRole(role) {
        return this.users.filter(user => user.role === role);
    }

    // Get user statistics
    getStatistics() {
        const stats = {
            total: this.users.length,
            byRole: {},
            byStatus: {},
            byDepartment: {}
        };

        this.users.forEach(user => {
            // Count by role
            stats.byRole[user.role] = (stats.byRole[user.role] || 0) + 1;
            
            // Count by status
            const status = user.status || 'active';
            stats.byStatus[status] = (stats.byStatus[status] || 0) + 1;
            
            // Count by department
            if (user.department) {
                stats.byDepartment[user.department] = (stats.byDepartment[user.department] || 0) + 1;
            }
        });

        return stats;
    }
}