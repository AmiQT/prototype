// Firebase removed - using backend API instead
import { analyticsCache } from './analytics-cache.js';
import { AnalyticsValidator } from './analytics-validator.js';
import { rateLimiter } from './rate-limiter.js';
import { securityManager } from './security-manager.js';
import { ANALYTICS_CONFIG } from '../config/analytics-config.js';

/**
 * Advanced data fetching with caching, pagination, and error handling
 */
export class AnalyticsDataFetcher {
    constructor() {
        this.requestQueue = new Map();
        this.retryAttempts = new Map();
    }
    
    /**
     * Fetch data with intelligent caching, pagination, security, and rate limiting
     */
    async fetchData(collection, options = {}) {
        const {
            query = null,
            limit = ANALYTICS_CONFIG.MAX_RECORDS_PER_QUERY,
            orderBy = null,
            startAfter = null,
            useCache = true,
            ttl = null
        } = options;

        // Security check (allow during authentication process)
        if (securityManager && securityManager.currentUser !== null && !securityManager.canAccessAnalytics()) {
            securityManager.logSecurityEvent('unauthorized_access', { collection, action: 'fetch' });
            throw new Error('Access denied: Insufficient permissions for analytics data');
        }

        // Rate limiting check (skip during authentication)
        if (rateLimiter && securityManager && securityManager.currentUser) {
            const userId = securityManager.currentUser.uid || 'anonymous';
            const rateLimitCheck = rateLimiter.checkLimit(userId, collection);
            if (!rateLimitCheck.allowed) {
                securityManager.logSecurityEvent('rate_limit_exceeded', {
                    collection,
                    reason: rateLimitCheck.reason,
                    retryAfter: rateLimitCheck.retryAfter
                });
                throw new Error(`Rate limit exceeded: ${rateLimitCheck.reason}`);
            }
        }
        
        const cacheKey = analyticsCache.generateKey(collection, query, { limit, orderBy, startAfter });
        
        // Check cache first
        if (useCache && analyticsCache.has(cacheKey)) {
            const cachedData = analyticsCache.get(cacheKey);
            if (cachedData) {
                console.debug(`[DataFetcher] Cache hit for ${collection}`);
                return {
                    data: cachedData,
                    fromCache: true,
                    hasMore: cachedData.length === limit
                };
            }
        }
        
        // Prevent duplicate requests
        if (this.requestQueue.has(cacheKey)) {
            console.debug(`[DataFetcher] Request already in progress for ${cacheKey}`);
            return await this.requestQueue.get(cacheKey);
        }
        
        // Create new request
        const requestPromise = this._executeQuery(collection, options, cacheKey, ttl);
        this.requestQueue.set(cacheKey, requestPromise);
        
        try {
            const result = await requestPromise;
            return result;
        } finally {
            this.requestQueue.delete(cacheKey);
        }
    }
    
    /**
     * Execute the actual Firestore query
     */
    async _executeQuery(collection, options, cacheKey, ttl) {
        const { query, limit, orderBy, startAfter } = options;
        const startTime = performance.now();
        
        try {
            let queryRef = db.collection(collection);
            
            // Apply query filters
            if (query) {
                if (Array.isArray(query)) {
                    query.forEach(q => {
                        queryRef = queryRef.where(q.field, q.operator, q.value);
                    });
                } else {
                    queryRef = queryRef.where(query.field, query.operator, query.value);
                }
            }
            
            // Apply ordering
            if (orderBy) {
                queryRef = queryRef.orderBy(orderBy.field, orderBy.direction || 'desc');
            }
            
            // Apply pagination
            if (startAfter) {
                queryRef = queryRef.startAfter(startAfter);
            }
            
            if (limit) {
                queryRef = queryRef.limit(limit);
            }
            
            // Execute query with timeout
            const snapshot = await Promise.race([
                queryRef.get(),
                this._createTimeout(ANALYTICS_CONFIG.ERROR_CONFIG.timeoutDuration)
            ]);
            
            const data = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            
            // Validate data (suppress warnings to reduce console noise)
            const validation = AnalyticsValidator.validateData(data, collection);
            
            const cleanData = validation.cleanedData.length > 0 ? validation.cleanedData : data;

            // Apply security sanitization
            const sanitizedData = securityManager.sanitizeData(cleanData, collection);

            // Cache the result (cache sanitized data to prevent data leaks)
            analyticsCache.set(cacheKey, sanitizedData, ttl);

            const fetchTime = performance.now() - startTime;
            // Removed debug logging to reduce console noise

            // Log successful data access
            securityManager.logSecurityEvent('data_access', {
                collection,
                recordCount: sanitizedData.length,
                fetchTime: fetchTime.toFixed(2) + 'ms'
            });

            // Reset retry attempts on success
            this.retryAttempts.delete(cacheKey);

            return {
                data: sanitizedData,
                fromCache: false,
                hasMore: sanitizedData.length === limit,
                fetchTime,
                lastDoc: snapshot.docs[snapshot.docs.length - 1] || null
            };
            
        } catch (error) {
            console.error(`[DataFetcher] Error fetching ${collection}:`, error);
            
            // Implement retry logic
            const retryCount = this.retryAttempts.get(cacheKey) || 0;
            if (retryCount < ANALYTICS_CONFIG.ERROR_CONFIG.maxRetries) {
                this.retryAttempts.set(cacheKey, retryCount + 1);
                console.debug(`[DataFetcher] Retrying ${collection} (attempt ${retryCount + 1})`);
                
                await this._delay(ANALYTICS_CONFIG.ERROR_CONFIG.retryDelay * (retryCount + 1));
                return this._executeQuery(collection, options, cacheKey, ttl);
            }
            
            throw new Error(`Failed to fetch ${collection} after ${retryCount + 1} attempts: ${error.message}`);
        }
    }
    
    /**
     * Fetch paginated data in chunks
     */
    async fetchPaginated(collection, options = {}) {
        const { pageSize = 100, maxPages = 10 } = options;
        const allData = [];
        let lastDoc = null;
        let pageCount = 0;
        
        while (pageCount < maxPages) {
            const pageOptions = {
                ...options,
                limit: pageSize,
                startAfter: lastDoc
            };
            
            const result = await this.fetchData(collection, pageOptions);
            allData.push(...result.data);
            
            if (!result.hasMore || result.data.length < pageSize) {
                break;
            }
            
            lastDoc = result.lastDoc;
            pageCount++;
        }
        
        return {
            data: allData,
            totalPages: pageCount + 1,
            totalRecords: allData.length
        };
    }
    
    /**
     * Fetch aggregated data
     */
    async fetchAggregated(collection, aggregations = []) {
        const cacheKey = `aggregated_${collection}_${JSON.stringify(aggregations)}`;
        
        if (analyticsCache.has(cacheKey)) {
            return analyticsCache.get(cacheKey);
        }
        
        try {
            // For now, we'll simulate aggregation on client side
            // In production, consider using Firebase Functions for server-side aggregation
            const { data } = await this.fetchData(collection, { useCache: true });
            
            const aggregatedData = this._performAggregations(data, aggregations);
            analyticsCache.set(cacheKey, aggregatedData, 300000); // 5 minutes cache
            
            return aggregatedData;
        } catch (error) {
            console.error(`[DataFetcher] Error in aggregation for ${collection}:`, error);
            throw error;
        }
    }
    
    /**
     * Perform client-side aggregations
     */
    _performAggregations(data, aggregations) {
        const results = {};
        
        aggregations.forEach(agg => {
            switch (agg.type) {
                case 'count':
                    results[agg.name] = data.length;
                    break;
                case 'sum':
                    results[agg.name] = data.reduce((sum, item) => sum + (item[agg.field] || 0), 0);
                    break;
                case 'avg':
                    const total = data.reduce((sum, item) => sum + (item[agg.field] || 0), 0);
                    results[agg.name] = data.length > 0 ? total / data.length : 0;
                    break;
                case 'groupBy':
                    results[agg.name] = this._groupBy(data, agg.field);
                    break;
            }
        });
        
        return results;
    }
    
    /**
     * Group data by field
     */
    _groupBy(data, field) {
        return data.reduce((groups, item) => {
            const key = item[field] || 'unknown';
            groups[key] = (groups[key] || 0) + 1;
            return groups;
        }, {});
    }
    
    /**
     * Create timeout promise
     */
    _createTimeout(ms) {
        return new Promise((_, reject) => {
            setTimeout(() => reject(new Error('Request timeout')), ms);
        });
    }
    
    /**
     * Delay utility
     */
    _delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    
    /**
     * Invalidate cache for collection
     */
    invalidateCache(collection) {
        analyticsCache.invalidatePattern(`^${collection}`);
    }
    
    /**
     * Get fetcher statistics
     */
    getStats() {
        return {
            activeRequests: this.requestQueue.size,
            retryAttempts: Array.from(this.retryAttempts.values()).reduce((sum, count) => sum + count, 0),
            cacheStats: analyticsCache.getStats()
        };
    }
}

// Create singleton instance
export const dataFetcher = new AnalyticsDataFetcher();
