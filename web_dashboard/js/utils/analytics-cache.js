import { ANALYTICS_CONFIG } from '../config/analytics-config.js';

/**
 * Advanced caching system for analytics data
 */
export class AnalyticsCache {
    constructor() {
        this.cache = new Map();
        this.metadata = new Map();
        this.maxSize = ANALYTICS_CONFIG.MAX_CACHE_SIZE || 50;
        this.defaultTTL = ANALYTICS_CONFIG.CACHE_DURATION || 300000; // 5 minutes
        
        // Start cleanup interval
        this.startCleanupInterval();
    }
    
    /**
     * Generate cache key from query parameters
     */
    generateKey(collection, query = null, options = {}) {
        const keyParts = [collection];
        
        if (query) {
            keyParts.push(JSON.stringify(query));
        }
        
        if (options.limit) keyParts.push(`limit:${options.limit}`);
        if (options.orderBy) keyParts.push(`order:${JSON.stringify(options.orderBy)}`);
        if (options.startAfter) keyParts.push(`after:${options.startAfter}`);
        
        return keyParts.join('|');
    }
    
    /**
     * Set data in cache with TTL
     */
    set(key, data, ttl = null) {
        const expiresAt = Date.now() + (ttl || this.defaultTTL);
        
        // If cache is full, remove oldest entry
        if (this.cache.size >= this.maxSize) {
            this.evictOldest();
        }
        
        this.cache.set(key, data);
        this.metadata.set(key, {
            createdAt: Date.now(),
            expiresAt,
            accessCount: 0,
            lastAccessed: Date.now(),
            size: this.estimateSize(data)
        });
        
        console.debug(`[Cache] Set: ${key} (expires in ${ttl || this.defaultTTL}ms)`);
    }
    
    /**
     * Get data from cache
     */
    get(key) {
        if (!this.cache.has(key)) {
            return null;
        }
        
        const metadata = this.metadata.get(key);
        
        // Check if expired
        if (Date.now() > metadata.expiresAt) {
            this.delete(key);
            console.debug(`[Cache] Expired: ${key}`);
            return null;
        }
        
        // Update access metadata
        metadata.accessCount++;
        metadata.lastAccessed = Date.now();
        
        console.debug(`[Cache] Hit: ${key} (accessed ${metadata.accessCount} times)`);
        return this.cache.get(key);
    }
    
    /**
     * Check if key exists and is valid
     */
    has(key) {
        if (!this.cache.has(key)) {
            return false;
        }
        
        const metadata = this.metadata.get(key);
        if (Date.now() > metadata.expiresAt) {
            this.delete(key);
            return false;
        }
        
        return true;
    }
    
    /**
     * Delete specific cache entry
     */
    delete(key) {
        this.cache.delete(key);
        this.metadata.delete(key);
        console.debug(`[Cache] Deleted: ${key}`);
    }
    
    /**
     * Clear all cache
     */
    clear() {
        const size = this.cache.size;
        this.cache.clear();
        this.metadata.clear();
        console.debug(`[Cache] Cleared ${size} entries`);
    }
    
    /**
     * Invalidate cache entries by pattern
     */
    invalidatePattern(pattern) {
        const regex = new RegExp(pattern);
        const keysToDelete = [];
        
        for (const key of this.cache.keys()) {
            if (regex.test(key)) {
                keysToDelete.push(key);
            }
        }
        
        keysToDelete.forEach(key => this.delete(key));
        console.debug(`[Cache] Invalidated ${keysToDelete.length} entries matching pattern: ${pattern}`);
    }
    
    /**
     * Evict oldest entry based on LRU
     */
    evictOldest() {
        let oldestKey = null;
        let oldestTime = Date.now();
        
        for (const [key, metadata] of this.metadata.entries()) {
            if (metadata.lastAccessed < oldestTime) {
                oldestTime = metadata.lastAccessed;
                oldestKey = key;
            }
        }
        
        if (oldestKey) {
            this.delete(oldestKey);
            console.debug(`[Cache] Evicted oldest entry: ${oldestKey}`);
        }
    }
    
    /**
     * Estimate memory size of data
     */
    estimateSize(data) {
        try {
            return JSON.stringify(data).length * 2; // Rough estimate in bytes
        } catch {
            return 1000; // Default estimate
        }
    }
    
    /**
     * Get cache statistics
     */
    getStats() {
        let totalSize = 0;
        let expiredCount = 0;
        const now = Date.now();
        
        for (const metadata of this.metadata.values()) {
            totalSize += metadata.size;
            if (now > metadata.expiresAt) {
                expiredCount++;
            }
        }
        
        return {
            totalEntries: this.cache.size,
            totalSize,
            expiredCount,
            hitRate: this.calculateHitRate(),
            memoryUsage: this.getMemoryUsage()
        };
    }
    
    /**
     * Calculate cache hit rate
     */
    calculateHitRate() {
        let totalAccess = 0;
        for (const metadata of this.metadata.values()) {
            totalAccess += metadata.accessCount;
        }
        return totalAccess > 0 ? (totalAccess / this.cache.size) : 0;
    }
    
    /**
     * Get memory usage if available
     */
    getMemoryUsage() {
        if (performance.memory) {
            return {
                used: performance.memory.usedJSHeapSize,
                total: performance.memory.totalJSHeapSize,
                limit: performance.memory.jsHeapSizeLimit
            };
        }
        return null;
    }
    
    /**
     * Start automatic cleanup interval
     */
    startCleanupInterval() {
        setInterval(() => {
            this.cleanup();
        }, 60000); // Cleanup every minute
    }
    
    /**
     * Clean up expired entries
     */
    cleanup() {
        const now = Date.now();
        const expiredKeys = [];
        
        for (const [key, metadata] of this.metadata.entries()) {
            if (now > metadata.expiresAt) {
                expiredKeys.push(key);
            }
        }
        
        expiredKeys.forEach(key => this.delete(key));
        
        if (expiredKeys.length > 0) {
            console.debug(`[Cache] Cleanup removed ${expiredKeys.length} expired entries`);
        }
    }
}

// Create singleton instance
export const analyticsCache = new AnalyticsCache();
