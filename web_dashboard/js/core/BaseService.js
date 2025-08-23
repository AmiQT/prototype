/**
 * Base Service Class - Foundation for all services
 * Implements common patterns: caching, error handling, cleanup
 */
export class BaseService {
    constructor(apiEndpoint) {
        this.apiEndpoint = apiEndpoint;
        this.cache = new Map();
        this.refreshInterval = null;
        this.isLoading = false;
        this.subscribers = new Set();
    }

    // Subscribe to data changes
    subscribe(callback) {
        this.subscribers.add(callback);
        return () => this.subscribers.delete(callback);
    }

    // Notify all subscribers
    notify(data) {
        this.subscribers.forEach(callback => callback(data));
    }

    // Generic API request with caching
    async request(endpoint, options = {}) {
        const cacheKey = `${endpoint}_${JSON.stringify(options)}`;
        
        // Return cached data if available and fresh
        if (this.cache.has(cacheKey)) {
            const cached = this.cache.get(cacheKey);
            if (Date.now() - cached.timestamp < 30000) { // 30 seconds cache
                return cached.data;
            }
        }

        try {
            this.isLoading = true;
            const response = await this.makeRequest(endpoint, options);
            
            // Cache the response
            this.cache.set(cacheKey, {
                data: response,
                timestamp: Date.now()
            });
            
            return response;
        } catch (error) {
            this.handleError(error);
            throw error;
        } finally {
            this.isLoading = false;
        }
    }

    // Override in child classes
    async makeRequest(endpoint, options) {
        throw new Error('makeRequest must be implemented by child class');
    }

    // Error handling
    handleError(error) {
        console.error(`${this.constructor.name} Error:`, error);
        this.notify({ type: 'error', message: error.message });
    }

    // Setup auto-refresh
    startAutoRefresh(interval = 30000) {
        this.stopAutoRefresh();
        this.refreshInterval = setInterval(() => {
            this.refresh();
        }, interval);
    }

    // Stop auto-refresh
    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    }

    // Refresh data (override in child classes)
    async refresh() {
        this.cache.clear();
    }

    // Cleanup resources
    cleanup() {
        this.stopAutoRefresh();
        this.cache.clear();
        this.subscribers.clear();
    }

    // Pagination helper
    paginate(data, page = 1, limit = 10) {
        const offset = (page - 1) * limit;
        return {
            data: data.slice(offset, offset + limit),
            pagination: {
                page,
                limit,
                total: data.length,
                totalPages: Math.ceil(data.length / limit),
                hasNext: offset + limit < data.length,
                hasPrev: page > 1
            }
        };
    }

    // Search helper with debouncing
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
}