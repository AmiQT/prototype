/**
 * Rate limiting utility for API calls and analytics operations
 */
export class RateLimiter {
    constructor() {
        this.requests = new Map(); // Track requests by key
        this.globalRequests = []; // Track all requests for global limits
        this.config = {
            // Per-endpoint limits (requests per minute)
            endpoints: {
                'users': 30,
                'achievements': 30,
                'events': 30,
                'profiles': 20,
                'badgeClaims': 25,
                'analytics': 15,
                'export': 5
            },
            // Global limits
            global: {
                perMinute: 100,
                perHour: 1000,
                burstLimit: 10 // Max requests in 1 second
            },
            // Cleanup interval
            cleanupInterval: 60000 // 1 minute
        };
        
        this.startCleanup();
    }
    
    /**
     * Check if request is allowed
     * @param {string} key - Request identifier (endpoint, user, etc.)
     * @param {string} type - Request type for specific limits
     * @returns {Object} - { allowed: boolean, retryAfter?: number, reason?: string }
     */
    checkLimit(key, type = 'default') {
        const now = Date.now();
        
        // Check burst limit (global)
        const burstCheck = this.checkBurstLimit(now);
        if (!burstCheck.allowed) {
            return burstCheck;
        }
        
        // Check global per-minute limit
        const globalCheck = this.checkGlobalLimit(now);
        if (!globalCheck.allowed) {
            return globalCheck;
        }
        
        // Check endpoint-specific limit
        const endpointCheck = this.checkEndpointLimit(key, type, now);
        if (!endpointCheck.allowed) {
            return endpointCheck;
        }
        
        // Record the request
        this.recordRequest(key, type, now);
        
        return { allowed: true };
    }
    
    /**
     * Check burst limit (max requests per second)
     */
    checkBurstLimit(now) {
        const oneSecondAgo = now - 1000;
        const recentRequests = this.globalRequests.filter(time => time > oneSecondAgo);
        
        if (recentRequests.length >= this.config.global.burstLimit) {
            return {
                allowed: false,
                retryAfter: 1000,
                reason: 'Burst limit exceeded'
            };
        }
        
        return { allowed: true };
    }
    
    /**
     * Check global rate limit
     */
    checkGlobalLimit(now) {
        const oneMinuteAgo = now - 60000;
        const recentRequests = this.globalRequests.filter(time => time > oneMinuteAgo);
        
        if (recentRequests.length >= this.config.global.perMinute) {
            return {
                allowed: false,
                retryAfter: 60000,
                reason: 'Global rate limit exceeded'
            };
        }
        
        return { allowed: true };
    }
    
    /**
     * Check endpoint-specific rate limit
     */
    checkEndpointLimit(key, type, now) {
        const limit = this.config.endpoints[type] || 20; // Default limit
        const oneMinuteAgo = now - 60000;
        
        if (!this.requests.has(key)) {
            this.requests.set(key, []);
        }
        
        const keyRequests = this.requests.get(key);
        const recentRequests = keyRequests.filter(time => time > oneMinuteAgo);
        
        if (recentRequests.length >= limit) {
            return {
                allowed: false,
                retryAfter: 60000,
                reason: `Endpoint rate limit exceeded for ${type}`
            };
        }
        
        return { allowed: true };
    }
    
    /**
     * Record a request
     */
    recordRequest(key, type, now) {
        // Record in global requests
        this.globalRequests.push(now);
        
        // Record in key-specific requests
        if (!this.requests.has(key)) {
            this.requests.set(key, []);
        }
        this.requests.get(key).push(now);
    }
    
    /**
     * Get current usage statistics
     */
    getUsageStats() {
        const now = Date.now();
        const oneMinuteAgo = now - 60000;
        const oneHourAgo = now - 3600000;
        
        const recentGlobal = this.globalRequests.filter(time => time > oneMinuteAgo);
        const hourlyGlobal = this.globalRequests.filter(time => time > oneHourAgo);
        
        const endpointStats = {};
        for (const [key, requests] of this.requests.entries()) {
            const recent = requests.filter(time => time > oneMinuteAgo);
            endpointStats[key] = {
                lastMinute: recent.length,
                total: requests.length
            };
        }
        
        return {
            global: {
                lastMinute: recentGlobal.length,
                lastHour: hourlyGlobal.length,
                limits: {
                    perMinute: this.config.global.perMinute,
                    perHour: this.config.global.perHour,
                    burst: this.config.global.burstLimit
                }
            },
            endpoints: endpointStats,
            totalTrackedKeys: this.requests.size
        };
    }
    
    /**
     * Reset limits for a specific key
     */
    resetKey(key) {
        this.requests.delete(key);
    }
    
    /**
     * Reset all limits
     */
    resetAll() {
        this.requests.clear();
        this.globalRequests.length = 0;
    }
    
    /**
     * Update rate limit configuration
     */
    updateConfig(newConfig) {
        this.config = {
            ...this.config,
            ...newConfig,
            endpoints: {
                ...this.config.endpoints,
                ...newConfig.endpoints
            },
            global: {
                ...this.config.global,
                ...newConfig.global
            }
        };
    }
    
    /**
     * Start cleanup process
     */
    startCleanup() {
        setInterval(() => {
            this.cleanup();
        }, this.config.cleanupInterval);
    }
    
    /**
     * Clean up old request records
     */
    cleanup() {
        const now = Date.now();
        const oneHourAgo = now - 3600000;
        
        // Clean global requests (keep last hour)
        this.globalRequests = this.globalRequests.filter(time => time > oneHourAgo);
        
        // Clean endpoint requests
        for (const [key, requests] of this.requests.entries()) {
            const filtered = requests.filter(time => time > oneHourAgo);
            if (filtered.length === 0) {
                this.requests.delete(key);
            } else {
                this.requests.set(key, filtered);
            }
        }
    }
    
    /**
     * Create a rate-limited wrapper for functions
     */
    createLimitedFunction(fn, key, type = 'default') {
        return async (...args) => {
            const limitCheck = this.checkLimit(key, type);
            
            if (!limitCheck.allowed) {
                const error = new Error(`Rate limit exceeded: ${limitCheck.reason}`);
                error.retryAfter = limitCheck.retryAfter;
                error.rateLimited = true;
                throw error;
            }
            
            return await fn(...args);
        };
    }
    
    /**
     * Wait for rate limit to reset
     */
    async waitForReset(key, type = 'default') {
        const limitCheck = this.checkLimit(key, type);
        if (limitCheck.allowed) {
            return;
        }
        
        const waitTime = limitCheck.retryAfter || 60000;
        console.log(`Rate limited. Waiting ${waitTime}ms before retry...`);
        
        return new Promise(resolve => {
            setTimeout(resolve, waitTime);
        });
    }
}

// Create singleton instance
export const rateLimiter = new RateLimiter();
