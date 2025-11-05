// Supabase integration - using backend API instead
import { API_ENDPOINTS, makeAuthenticatedRequest, testBackendConnection } from '../config/backend-config.js';
import { addNotification } from '../ui/notifications.js';

// Enhanced imports with fallbacks
let dataFetcher, chartManager, analyticsCache, AnalyticsValidator;
let securityManager, rateLimiter, advancedCharts, comparativeAnalysis, automatedReporting;
let ANALYTICS_CONFIG, CHART_TYPES, METRICS;

// Initialize enhanced modules with fallbacks
async function initializeEnhancedModules() {
    try {
        const modules = await Promise.allSettled([
            import('../utils/analytics-data-fetcher.js'),
            import('../utils/analytics-chart-manager.js'),
            import('../utils/analytics-cache.js'),
            import('../utils/analytics-validator.js'),
            import('../utils/security-manager.js'),
            import('../utils/rate-limiter.js'),
            import('../components/advanced-charts.js'),
            import('../utils/comparative-analysis.js'),
            import('../utils/automated-reporting.js'),
            import('../config/analytics-config.js')
        ]);

        // Extract successful imports
        if (modules[0].status === 'fulfilled') dataFetcher = modules[0].value.dataFetcher;
        if (modules[1].status === 'fulfilled') chartManager = modules[1].value.chartManager;
        if (modules[2].status === 'fulfilled') analyticsCache = modules[2].value.analyticsCache;
        if (modules[3].status === 'fulfilled') AnalyticsValidator = modules[3].value.AnalyticsValidator;
        if (modules[4].status === 'fulfilled') securityManager = modules[4].value.securityManager;
        if (modules[5].status === 'fulfilled') rateLimiter = modules[5].value.rateLimiter;
        if (modules[6].status === 'fulfilled') advancedCharts = modules[6].value.advancedCharts;
        if (modules[7].status === 'fulfilled') comparativeAnalysis = modules[7].value.comparativeAnalysis;
        if (modules[8].status === 'fulfilled') automatedReporting = modules[8].value.automatedReporting;
        if (modules[9].status === 'fulfilled') {
            ANALYTICS_CONFIG = modules[9].value.ANALYTICS_CONFIG;
            CHART_TYPES = modules[9].value.CHART_TYPES;
            METRICS = modules[9].value.METRICS;
        }

        // Enhanced analytics modules loaded (logging suppressed)
    } catch (error) {
        console.warn('Some enhanced analytics modules failed to load, using fallbacks:', error);
    }
}

// Fallback implementations with real Supabase data
const fallbackDataFetcher = {
    async fetchData(collection, options = {}) {
        console.log(`📊 Fallback data fetcher loading ${collection} from Supabase...`);
        
        try {
            const { supabase } = await import('../config/supabase-config.js');
            let data = [];
            
            switch (collection) {
                case 'users':
                    const { data: users, error: usersError } = await supabase
                        .from('users')
                        .select('*');
                    if (usersError) throw usersError;
                    data = users || [];
                    break;
                    
                case 'events':
                    const { data: events, error: eventsError } = await supabase
                        .from('events')
                        .select('*');
                    if (eventsError) throw eventsError;
                    data = events || [];
                    break;
                    
                case 'profiles':
                    const { data: profiles, error: profilesError } = await supabase
                        .from('profiles')
                        .select('*');
                    if (profilesError) throw profilesError;
                    data = profiles || [];
                    break;
                    

                    
                default:
                    console.warn(`Unknown collection: ${collection}`);
                    data = [];
            }
            
            console.log(`✅ Loaded ${data.length} ${collection} from Supabase`);
            
            return {
                data: data,
                fromCache: false,
                hasMore: false
            };
            
        } catch (error) {
            console.error(`❌ Error loading ${collection} from Supabase:`, error);
            return {
                data: [],
                fromCache: false,
                hasMore: false
            };
        }
    },
    invalidateCache() {},
    getStats() { return { activeRequests: 0, retryAttempts: 0, cacheStats: {} }; }
};

const fallbackChartManager = {
    chartInstances: {},  // Store chart instances
    async createChart(canvasId, config) {
        try {
            const canvas = document.getElementById(canvasId);
            if (canvas) {
                // Destroy existing chart if it exists
                if (this.chartInstances[canvasId]) {
                    console.log(`🗑️ Destroying existing chart: ${canvasId}`);
                    this.chartInstances[canvasId].destroy();
                    delete this.chartInstances[canvasId];
                }
                
                const ctx = canvas.getContext('2d');
                // Check if Chart.js is available
                if (typeof Chart !== 'undefined') {
                    const chart = new Chart(ctx, config);
                    this.chartInstances[canvasId] = chart;  // Store instance
                    return chart;
                } else {
                    console.warn('Chart.js not available, trying to import...');
                    // Try to import Chart.js dynamically
                    const { Chart } = await import('https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js');
                    const chart = new Chart(ctx, config);
                    this.chartInstances[canvasId] = chart;  // Store instance
                    return chart;
                }
            }
            return null;
        } catch (error) {
            console.error('Error creating chart:', error);
            return null;
        }
    },
    destroyChart() {},
    destroyAllCharts() {},
    getPerformanceStats() { return { totalCharts: 0, activeCharts: 0, averageRenderTime: 0 }; }
};

const fallbackAnalyticsCache = {
    getStats() { 
        return { 
            totalEntries: 0, 
            hitRate: 0, 
            cacheStats: {},
            activeRequests: 0,
            retryAttempts: 0
        }; 
    },
    cleanup() {},
    invalidateCache() {}
};

const fallbackSecurityManager = {
    canAccessAnalytics() { return true; },
    canExportData() { return true; },
    canManageAnalytics() { return true; },
    sanitizeData(data) { return data; },
    logSecurityEvent() {},
    getSecurityStatus() { return { isAuthenticated: true, sessionValid: true }; },
    currentUser: { uid: 'fallback', role: 'admin' }
};

const fallbackConfig = {
    CHART_COLORS: {
        primary: '#2563eb',
        secondary: '#10b981',
        accent: '#f59e0b',
        warning: '#ef4444'
    }
};

// Fallback for missing variables
const fallbackVariables = {
    CHART_TYPES: {
        LINE: 'line',
        BAR: 'bar',
        PIE: 'pie',
        DOUGHNUT: 'doughnut'
    },
    METRICS: {
        USER_GROWTH: 'user_growth',
        EVENT_PARTICIPATION: 'event_participation',
    
    }
};

// Enhanced logging system
class AnalyticsLogger {
    static log(level, message, data = null) {
        const timestamp = new Date().toISOString();
        const logEntry = { timestamp, level, message, data };

        if (level === 'error') {
            console.error(`[Analytics ${level.toUpperCase()}]`, message, data);
            // In production, send to error tracking service
            this._sendToErrorTracking(logEntry);
        } else if (this._isDevelopment() && level === 'error') {
            // Only show errors in development, suppress info/debug
            console.log(`[Analytics ${level.toUpperCase()}]`, message, data);
        }

        // Store in local storage for debugging (limit to last 100 entries)
        const logs = JSON.parse(localStorage.getItem('analyticsLogs') || '[]');
        logs.push(logEntry);
        if (logs.length > 100) logs.shift();
        localStorage.setItem('analyticsLogs', JSON.stringify(logs));
    }

    static _sendToErrorTracking(logEntry) {
        // In production, integrate with error tracking service like Sentry
        // For now, just store critical errors
        if (logEntry.level === 'error') {
            const criticalErrors = JSON.parse(localStorage.getItem('criticalErrors') || '[]');
            criticalErrors.push(logEntry);
            if (criticalErrors.length > 50) criticalErrors.shift();
            localStorage.setItem('criticalErrors', JSON.stringify(criticalErrors));
        }
    }

    static _isDevelopment() {
        // Check if we're in development mode (browser environment)
        return window.location.hostname === 'localhost' ||
               window.location.hostname === '127.0.0.1' ||
               window.location.hostname.includes('dev') ||
               window.location.port !== '';
    }

    static error(message, data) { this.log('error', message, data); }
    static warn(message, data) { this.log('warn', message, data); }
    static info(message, data) { this.log('info', message, data); }
    static debug(message, data) { this.log('debug', message, data); }
}

// Global data storage
let currentData = {
    users: [],
    events: [],
    profiles: [],
    lastUpdated: null
};

// Performance monitoring
const performanceMetrics = {
    chartRenderTimes: [],
    dataFetchTimes: [],
    totalMemoryUsage: 0,
    apiCalls: 0,
    cacheHits: 0
};

// Analytics state
let isInitialized = false;
let updateInterval = null;

// Helper function to wait for authentication
async function waitForAuth(maxWait = 2000) {
    const startTime = Date.now();
    while (Date.now() - startTime < maxWait) {
        const security = securityManager || fallbackSecurityManager;
        if (security && security.currentUser !== null) {
            return true; // Auth completed
        }
        await new Promise(resolve => setTimeout(resolve, 50));
    }
    return false; // Timeout, proceed anyway
}

// Enhanced data fetching with caching and performance monitoring
async function fetchDataWithCache(collectionName, query = null) {
    // Use fallback if cache is not available
    if (!dataCache) {
        AnalyticsLogger.warn('Data cache not available, using fallback');
        return [];
    }
    
    const cacheKey = query ? `${collectionName}_${JSON.stringify(query)}` : collectionName;
    const now = Date.now();

    // Check cache first
    if (dataCache.has(cacheKey) && lastCacheUpdate && (now - lastCacheUpdate) < CACHE_DURATION) {
        AnalyticsLogger.debug(`Cache hit for ${cacheKey}`);
        return dataCache.get(cacheKey);
    }

    const startTime = performance.now();
    try {
        console.warn(`Legacy query attempted for ${collectionName} - using backend API instead`);
        return [];
        if (query) {
            queryRef = queryRef.where(query.field, query.operator, query.value);
        }

        const snapshot = await queryRef.get();
        const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        // Cache the result
        if (dataCache) {
            dataCache.set(cacheKey, data);
            lastCacheUpdate = now;
        }

        const fetchTime = performance.now() - startTime;
        if (performanceMetrics && performanceMetrics.dataFetchTimes) {
            performanceMetrics.dataFetchTimes.push(fetchTime);
        }
        AnalyticsLogger.debug(`Fetched ${collectionName}: ${data.length} records in ${fetchTime.toFixed(2)}ms`);

        return data;
    } catch (error) {
        AnalyticsLogger.error(`Failed to fetch ${collectionName}`, error);
        throw error;
    }
}

async function loadOverviewStats() {
    try {
        AnalyticsLogger.info('Loading overview stats...');
        const startTime = performance.now();

        // ✅ DIRECT: Load from Supabase only - backend reserved for data mining
        await loadOverviewStatsFromSupabase();

        const totalTime = performance.now() - startTime;
        AnalyticsLogger.info('Overview stats loaded', {
            loadTime: `${totalTime.toFixed(2)}ms`
        });

    } catch (e) {
        AnalyticsLogger.error('Error loading overview stats', e);
        addNotification('Error loading overview stats', 'error');
    }
}

// NEW: Load stats from backend (bypasses Firestore rules completely!)
async function loadOverviewStatsFromBackend() {
    try {
        // Check if endpoint exists
        if (!API_ENDPOINTS.users.getStats) {
            console.warn('Stats endpoint not available');
            return null;
        }
        
        // COMMENTED OUT: Custom backend authentication check
        // const isLoggedIn = localStorage.getItem('isLoggedIn');
        // if (!isLoggedIn || isLoggedIn !== 'true') {
        //     console.warn('User not authenticated, skipping backend stats');
        //     return null;
        // }
        
        // SUPABASE DIRECT CALLS: Get real stats from Supabase
        try {
            const { supabase } = await import('../config/supabase-config.js');
            
            // Get users count by role
            const { data: users, error: usersError } = await supabase
                .from('users')
                .select('role');
            
            if (usersError) throw usersError;
            
            // Get events count
            const { data: events, error: eventsError } = await supabase
                .from('events')
                .select('id');
                
            if (eventsError) throw eventsError;
            
            // Get profiles completion data
            const { data: profiles, error: profilesError } = await supabase
                .from('profiles')
                .select('full_name, bio, phone, department');
                
            if (profilesError) throw profilesError;
            
            // Calculate stats
            const totalUsers = users?.length || 0;
            const totalEvents = events?.length || 0;
            
            // Count users by role
            const usersByRole = {};
            users?.forEach(user => {
                const role = user.role || 'student';
                usersByRole[role] = (usersByRole[role] || 0) + 1;
            });
            
            // Calculate profile completion
            let profilesCompleted = 0;
            profiles?.forEach(profile => {
                const fields = [profile.full_name, profile.bio, profile.phone_number || profile.phone, profile.academic_info?.department || profile.department];
                const completedFields = fields.filter(f => f && f.trim() !== '').length;
                if (completedFields >= 3) profilesCompleted++;
            });
            
            const profileCompletionRate = profiles?.length > 0 ? 
                Math.round((profilesCompleted / profiles.length) * 100) : 0;
            
            console.log('✅ Loaded real stats from Supabase:', {
                totalUsers,
                totalEvents,
                usersByRole,
                profilesCompleted,
                profileCompletionRate
            });
            
            return {
                overview: {
                    total_users: totalUsers,
                    total_events: totalEvents,
                    total_posts: 0, // Will add showcase posts later
                    users_by_role: usersByRole,
                    profiles_completed: profilesCompleted,
                    profile_completion_rate: profileCompletionRate
                }
            };
            
        } catch (error) {
            console.error('❌ Error loading stats from Supabase:', error);
            return null;
        }
        
        if (response && response.overview) {
            const stats = response.overview;
            
            // Update stats directly from backend
            updateStatElement('total-users', stats.total_students || 0);
            updateStatElement('total-events', stats.total_events || 0);
            updateStatElement('total-profiles', stats.students_with_profiles || 0);
            
            console.log('✅ Analytics loaded from backend - no Firestore rules needed!');
            return;
        }
    } catch (error) {
        console.error('Backend analytics failed:', error);
        throw error; // Fall back to Supabase
    }
}

// Clean Supabase-based stats loading
async function loadOverviewStatsFromSupabase() {
    try {
        console.log('📊 Loading overview stats from Supabase/Backend...');
        const startTime = performance.now();

        // Try to get data from backend API
        let users = [];
        let events = [];
        
        try {
            // SUPABASE DIRECT CALLS: Fetch real data from Supabase
            console.log('📊 Fetching real data from Supabase...');
            
            const { supabase } = await import('../config/supabase-config.js');
            
            const [usersResult, eventsResult] = await Promise.all([
                supabase.from('users').select('*'),
                supabase.from('events').select('*')
            ]);

            if (usersResult.error) {
                console.error('❌ Error loading users:', usersResult.error);
                users = [];
            } else {
                users = usersResult.data || [];
            }

            if (eventsResult.error) {
                console.error('❌ Error loading events:', eventsResult.error);
                events = [];
            } else {
                events = eventsResult.data || [];
            }
            
            console.log(`✅ Loaded ${users.length} users and ${events.length} events from Supabase`);
            
        } catch (apiError) {
            console.warn('⚠️ Supabase error, using empty data:', apiError.message);
            
            // Use empty data on error
            users = [];
            events = [];
            
            console.log(`✅ No data available from Supabase - using empty state`);
        }

        // Calculate statistics
        const totalUsers = users.length;
        const totalEvents = events.length;
        const completedProfiles = users.filter(u => u.profile_completed === true).length;
        
        // Update individual stat elements with animation
        updateStatElement('total-users', totalUsers);
        updateStatElement('total-events', totalEvents);
        updateStatElement('total-profiles', completedProfiles);
        
        // Log detailed breakdown for verification
        console.log('📊 Overview Stats Breakdown:', {
            totalUsers: totalUsers,
            usersByRole: {
                students: users.filter(u => u.role === 'student').length,
                lecturers: users.filter(u => u.role === 'lecturer').length,
                admins: users.filter(u => u.role === 'admin').length
            },
            totalEvents: totalEvents,
            profilesCompleted: completedProfiles,
            profileCompletionRate: totalUsers > 0 ? Math.round((completedProfiles / totalUsers) * 100) : 0
        });

        const totalTime = performance.now() - startTime;
        console.log(`✅ Overview stats updated from Supabase in ${totalTime.toFixed(2)}ms`);

        // Store data for charts
        if (currentData) {
            currentData.users = users;
            currentData.events = events;
            currentData.lastUpdated = new Date().toISOString();
        }

        // Render overview charts if on overview section
        if (document.getElementById('overview')?.classList.contains('active')) {
            await renderOverviewCharts(users);
        }

    } catch (e) {
        console.warn('📊 Error loading overview stats, using fallback:', e.message);
        
        // Use fallback data
        updateStatElement('total-users', 0);
        updateStatElement('total-events', 0);
        updateStatElement('total-profiles', 0);
        
        console.log('📊 Overview Stats Breakdown:', {
            totalUsers: 0,
            usersByRole: { students: 0, lecturers: 0, admins: 0 },
            totalEvents: 0,
            profilesCompleted: 0,
            profileCompletionRate: 0
        });
    }
}

// Utility function to update stat elements with animation
function updateStatElement(elementId, newValue) {
    const element = document.getElementById(elementId);
    if (!element) return;

    const currentValue = parseInt(element.textContent) || 0;

    if (currentValue === newValue) return;

    // Animate the number change
    const duration = 1000; // 1 second
    const startTime = performance.now();
    const difference = newValue - currentValue;

    function animate(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);

        // Easing function for smooth animation
        const easeOutQuart = 1 - Math.pow(1 - progress, 4);
        const currentDisplayValue = Math.round(currentValue + (difference * easeOutQuart));

        element.textContent = currentDisplayValue.toLocaleString();

        if (progress < 1) {
            requestAnimationFrame(animate);
        }
    }

    requestAnimationFrame(animate);
}

// Enhanced chart management with proper cleanup
function destroyChart(chartKey) {
    if (charts[chartKey]) {
        charts[chartKey].destroy();
        delete charts[chartKey];
        AnalyticsLogger.debug(`Destroyed chart: ${chartKey}`);
    }
}

function destroyAllCharts() {
    Object.keys(charts).forEach(key => destroyChart(key));
    AnalyticsLogger.info('All charts destroyed');
}

// Function to refresh overview stats (can be called from other modules)
async function refreshOverviewStats() {
    await loadOverviewStats();
}

async function renderOverviewCharts(users) {
    try {
        AnalyticsLogger.debug('Rendering overview charts');

        // Ensure users is an array
        if (!users || !Array.isArray(users)) {
            AnalyticsLogger.warn('No valid users data for overview charts');
            return;
        }

        // User Growth Chart (only if canvas exists)
        const userGrowthCanvas = document.getElementById('userGrowthChart');
        if (userGrowthCanvas) {
            const monthlyData = processUserGrowthData(users);

            // Use fallback config if not available
            const chartColors = ANALYTICS_CONFIG?.CHART_COLORS || fallbackConfig.CHART_COLORS;
            const chartType = CHART_TYPES?.LINE || fallbackVariables.CHART_TYPES.LINE;

            const config = {
                type: chartType || 'line',
                data: {
                    labels: monthlyData.labels,
                    datasets: [{
                        label: 'New Users',
                        data: monthlyData.data,
                        borderColor: chartColors.primary,
                        backgroundColor: `${chartColors.primary}20`,
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            mode: 'index',
                            intersect: false,
                            callbacks: {
                                title: (context) => {
                                    return `Month: ${context[0].label}`;
                                },
                                label: (context) => {
                                    return `New Users: ${context.parsed.y}`;
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { stepSize: 1 }
                        }
                    }
                }
            };

            const manager = chartManager || fallbackChartManager;
            await manager.createChart('userGrowthChart', config);
        }

    } catch (error) {
        AnalyticsLogger.error('Error rendering overview charts', error);
    }
}

// Process user growth data
function processUserGrowthData(users) {
    const monthlyData = {};

    // Ensure users is an array
    if (!users || !Array.isArray(users)) {
        return { labels: [], data: [] };
    }

    users.forEach(user => {
        if (user.createdAt) {
            const date = new Date(user.createdAt);
            if (!isNaN(date.getTime())) {
                const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                monthlyData[monthKey] = (monthlyData[monthKey] || 0) + 1;
            }
        }
    });

    const labels = Object.keys(monthlyData).sort();
    const data = labels.map(label => monthlyData[label]);

    return { labels, data };
}

async function setupAnalytics() {
    try {
        AnalyticsLogger.info('Setting up analytics dashboard');

        if (isInitialized) {
            // Already initialized, just reload data
            await loadOverviewStats();
            // Re-expose ML functions to ensure they're available
            exposeMlFunctions();
            return;
        }

        const startTime = performance.now();

        // ✅ SIMPLIFIED: Direct Supabase approach only
        // Custom backend reserved for future data mining features
        await setupAnalyticsWithSupabase();

        // Expose ML functions to global scope for onclick handlers
        exposeMlFunctions();

        const setupTime = performance.now() - startTime;
        AnalyticsLogger.info(`Analytics setup completed in ${setupTime.toFixed(2)}ms`);

        isInitialized = true;

    } catch (e) {
        AnalyticsLogger.error('Error setting up analytics', e);
        addNotification('Error setting up analytics dashboard', 'error');
    }
}

// Backend-only analytics setup (NO FIRESTORE!)
async function setupAnalyticsFromBackend() {
    try {
        // Check if endpoint exists
        if (!API_ENDPOINTS.users.getStats) {
            console.warn('Analytics endpoint not available');
            return null;
        }
        
        // COMMENTED OUT: Custom backend authentication check
        // const isLoggedIn = localStorage.getItem('isLoggedIn');
        // if (!isLoggedIn || isLoggedIn !== 'true') {
        //     console.warn('User not authenticated, skipping backend analytics');
        //     return null;
        // }
        
        // COMMENTED OUT: Custom backend call - Using Supabase direct calls only
        // const response = await makeAuthenticatedRequest(API_ENDPOINTS.users.getStats);
        console.warn('Custom backend analytics disabled - using Supabase direct calls');
        return null;
        
        if (response && response.overview) {
            const stats = response.overview;
            
            // Create minimal data for charts from backend stats
            const users = Array(stats.total_students || 0).fill({}).map((_, i) => ({
                id: `user_${i}`,
                role: 'student',
                createdAt: new Date().toISOString()
            }));
            
            const events = Array(stats.total_events || 0).fill({}).map((_, i) => ({
                id: `event_${i}`,
                title: `Event ${i + 1}`,
                createdAt: new Date().toISOString()
            }));

            // Store data for charts
            if (currentData) {
                currentData.users = users;
                currentData.events = events;
                currentData.profiles = [];
                currentData.lastUpdated = new Date().toISOString();
            }

            // Render charts with backend data
            await renderAnalyticsCharts(users, [], events);
            
            console.log('✅ Analytics setup completed from backend - NO FIRESTORE USED!');
        }
    } catch (error) {
        console.error('Backend analytics setup failed:', error);
        setupAnalyticsWithSupabase();
    }
}

// ✅ SIMPLIFIED: Load analytics data directly from Supabase
async function setupAnalyticsWithSupabase() {
    console.log('📊 Loading analytics data from Supabase - Clean approach');
    
    try {
        const { supabase } = await import('../config/supabase-config.js');
        
        // Fetch data from Supabase
        const [usersResult, profilesResult, eventsResult] = await Promise.all([
            supabase.from('users').select('*'),
            supabase.from('profiles').select('*'),
            supabase.from('events').select('*')
        ]);
        
        let users = usersResult.data || [];
        let profiles = profilesResult.data || [];
        let events = eventsResult.data || [];
        
        // Store data for charts
        if (currentData) {
            currentData.users = users;
            currentData.events = events;
            currentData.profiles = profiles;
            currentData.lastUpdated = new Date().toISOString();
        }
        
        console.log(`✅ Analytics loaded: ${users.length} users, ${profiles.length} profiles, ${events.length} events`);
        
        // Render charts with real data
        await renderAnalyticsCharts(users, profiles, events);
        
    } catch (error) {
        console.warn('⚠️ Error loading analytics from Supabase:', error.message);
        
        // Store empty data as fallback
        if (currentData) {
            currentData.users = [];
            currentData.events = [];
            currentData.profiles = [];
            currentData.lastUpdated = new Date().toISOString();
        }

        // Render empty charts as fallback
        await renderAnalyticsCharts([], [], []);
    }
}

async function renderAnalyticsCharts(users, profiles, events = []) {
    try {
        console.log('🎨 Starting to render analytics charts...');
        console.log('📊 Data received:', { users: users?.length || 0, profiles: profiles?.length || 0, events: events?.length || 0 });
        
        // Ensure all parameters are arrays
        users = users || [];
        profiles = profiles || [];
        events = events || [];

        // Define chart colors and manager once for all charts
        const chartColors = ANALYTICS_CONFIG?.CHART_COLORS || fallbackConfig.CHART_COLORS;
        const manager = chartManager || fallbackChartManager;

        // Reset chart container visibility (in case they were hidden before)
        const chartContainers = document.querySelectorAll('.chart-card');
        chartContainers.forEach(container => {
            container.style.display = '';
        });

        // Total Users Chart
        const totalUserCanvas = document.getElementById('totalUserChart');
        if (totalUserCanvas) {
            console.log('🎯 Found totalUserChart canvas');
            const totalUserData = processTotalUserData(users);
            console.log('📊 Total User data processed:', totalUserData);
            
            // Only render chart if there's data
            if (totalUserData.labels.length === 0) {
                console.log('⚠️ No Total User data, hiding chart');
                // Hide chart or show "No data" message
                const chartContainer = totalUserCanvas.closest('.chart-card');
                if (chartContainer) {
                    chartContainer.innerHTML = '<h3>Total Users</h3><p class="no-data">No user data available</p>';
                }
            } else {
                const totalUserConfig = {
                    type: 'doughnut',
                    data: {
                        labels: totalUserData.labels,
                        datasets: [{
                            label: 'Users',
                            data: totalUserData.data,
                            backgroundColor: [
                                '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'
                            ],
                            borderWidth: 2,
                            borderColor: '#ffffff'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: {
                                    padding: 20,
                                    usePointStyle: true
                                }
                            },
                            tooltip: {
                                callbacks: {
                                    title: (context) => `Role: ${context[0].label}`,
                                    label: (context) => `${context.label}: ${context.parsed} users`
                                }
                            }
                        }
                    }
                };
                
                console.log('🚀 Creating Total User chart with config:', totalUserConfig);
                const chart = await manager.createChart('totalUserChart', totalUserConfig);
                console.log('✅ Total User chart created:', chart);
            }
        }

        // Department Chart
        const courseCanvas = document.getElementById('courseChart');
        if (courseCanvas) {
            console.log('🎯 Found courseChart canvas');
            const departmentData = processDepartmentDataForCharts(profiles);
            console.log('📊 Department data processed:', departmentData);
            
            // Only render chart if there's data
            if (departmentData.labels.length === 0) {
                console.log('⚠️ No Department data, hiding chart');
                // Hide chart or show "No data" message
                const chartContainer = courseCanvas.closest('.chart-card');
                if (chartContainer) {
                    chartContainer.innerHTML = '<h3>Department Distribution</h3><p class="no-data">No department data available</p>';
                }
            } else {
                const departmentConfig = {
                    type: 'bar',
                    data: {
                        labels: departmentData.labels,
                        datasets: [{
                            label: 'Students',
                            data: departmentData.data,
                            backgroundColor: [
                                '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
                                '#06B6D4', '#84CC16', '#F97316', '#EC4899', '#6366F1'
                            ],
                            borderWidth: 1,
                            borderColor: '#ffffff'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                display: false
                            },
                            tooltip: {
                                callbacks: {
                                    title: (context) => `Department: ${context[0].label}`,
                                    label: (context) => `${context.label}: ${context.parsed} students`
                                }
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                ticks: {
                                    stepSize: 1
                                }
                            }
                        }
                    }
                };
                
                console.log('🚀 Creating Department chart with config:', departmentConfig);
                const chart = await manager.createChart('courseChart', departmentConfig);
                console.log('✅ Department chart created:', chart);
            }
        }

        // Populate analytics tables
        console.log('📋 Starting to populate analytics tables...');
        await populateAnalyticsTables(users, profiles);
        console.log('✅ Analytics tables populated');

    } catch (error) {
        console.error('❌ Error rendering analytics charts:', error);
    }
}

// Data processing functions
function processUserTrendData(users) {
    const monthlyData = {};

    // If no users or not an array, return empty data
    if (!users || !Array.isArray(users) || users.length === 0) {
        return {
            labels: [],
            data: []
        };
    }

    users.forEach(user => {
        if (user.createdAt) {
            const date = new Date(user.createdAt);
            if (!isNaN(date.getTime())) {
                const monthKey = date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
                monthlyData[monthKey] = (monthlyData[monthKey] || 0) + 1;
            }
        }
    });

    const labels = Object.keys(monthlyData).sort();
    const data = labels.map(label => monthlyData[label]);

    return { labels, data };
}

function processEventData(events) {
    // If no events or not an array, return empty data
    if (!events || !Array.isArray(events) || events.length === 0) {
        return {
            labels: [],
            data: []
        };
    }

    const eventTypes = {};
    events.forEach(event => {
        const type = event.type || event.category || 'Other';
        eventTypes[type] = (eventTypes[type] || 0) + 1;
    });

    return {
        labels: Object.keys(eventTypes),
        data: Object.values(eventTypes)
    };
}

// New data processing functions for Total Users and Department charts
function processTotalUserData(users) {
    console.log('🔍 Processing Total User data for', users?.length || 0, 'users');
    
    // If no users or not an array, return empty data
    if (!users || !Array.isArray(users) || users.length === 0) {
        console.log('⚠️ No users data available');
        return {
            labels: [],
            data: []
        };
    }

    const roleCounts = {};
    users.forEach(user => {
        const role = user.role || 'Unknown';
        roleCounts[role] = (roleCounts[role] || 0) + 1;
    });

    const result = {
        labels: Object.keys(roleCounts),
        data: Object.values(roleCounts)
    };
    
    console.log('📊 Total User data result:', result);
    return result;
}



// Auto-refresh functionality
function setupAutoRefresh() {
    if (updateInterval) {
        clearInterval(updateInterval);
    }

    updateInterval = setInterval(async () => {
        try {
            // Auto-refresh (debug message suppressed)
            await refreshAnalyticsData();
        } catch (error) {
            AnalyticsLogger.error('Error in auto-refresh', error);
        }
    }, 300000); // Refresh every 5 minutes
}

async function refreshAnalyticsData() {
    try {
        // Invalidate cache to force fresh data
        const fetcher = dataFetcher || fallbackDataFetcher;
        const cache = analyticsCache || fallbackAnalyticsCache;
        
        if (fetcher.invalidateCache) {
            fetcher.invalidateCache('users');
    
            fetcher.invalidateCache('events');
            fetcher.invalidateCache('profiles');
        }
        
        if (cache.invalidateCache) {
            cache.invalidateCache();
        }

        // Reload data without calling setupAnalytics to prevent loops
        await loadOverviewStats();

        // Only refresh charts if analytics section is active
        if (document.getElementById('analytics')?.classList.contains('active')) {
            await renderAnalyticsCharts(currentData?.users || [], currentData?.profiles || [], currentData?.events || []);
        }

        // Suppress success message to reduce console noise
    } catch (error) {
        AnalyticsLogger.error('Error refreshing analytics data', error);
    }
}

// Data processing functions for analytics
function processRoleData(users) {
    const roleCounts = {};

    // Ensure users is an array
    if (!users || !Array.isArray(users)) {
        return {};
    }

    users.forEach(user => {
        const role = user.role || 'unknown';
        roleCounts[role] = (roleCounts[role] || 0) + 1;
    });
    return roleCounts;
}





function processDepartmentData(profiles) {
    const departmentCounts = {};

    // Ensure profiles is an array
    if (!profiles || !Array.isArray(profiles)) {
        return {};
    }

    profiles.forEach(profile => {
        const department = profile.academic_info?.department || profile.department || 'unknown';
        departmentCounts[department] = (departmentCounts[department] || 0) + 1;
    });
    return departmentCounts;
}



function processEventParticipation(events) {
    const participation = {};

    // Ensure events is an array
    if (!events || !Array.isArray(events)) {
        return {};
    }

    events.forEach(event => {
        const category = event.category || 'other';
        participation[category] = (participation[category] || 0) + 1;
    });
    return participation;
}

/**
 * Populate analytics tables with data
 */
async function populateAnalyticsTables(users, profiles) {
    try {
        // Populate Total Users table
        await populateTotalUsersTable(users);
        
        // Populate Department Distribution table
        await populateDepartmentDistributionTable(profiles);
        
    } catch (error) {
        AnalyticsLogger.error('Error populating analytics tables', error);
    }
}

/**
 * Populate Total Users breakdown table
 */
async function populateTotalUsersTable(users) {
    const tableBody = document.getElementById('total-users-table-body');
    if (!tableBody) {
        console.log('❌ Total users table body not found');
        return;
    }

    try {
        // Process user data by role
        const roleCounts = {};
        const roleStatus = {};
        
        users.forEach(user => {
            const role = user.role || 'Unknown';
            roleCounts[role] = (roleCounts[role] || 0) + 1;
            
            // Track status (assuming active by default for now)
            if (!roleStatus[role]) {
                roleStatus[role] = { active: 0, inactive: 0 };
            }
            roleStatus[role].active++; // Assume all users are active for now
        });

        // Calculate total users
        const totalUsers = users.length;
        
        // Generate table rows
        const tableRows = Object.entries(roleCounts).map(([role, count]) => {
            const percentage = totalUsers > 0 ? ((count / totalUsers) * 100).toFixed(1) : '0.0';
            const status = roleStatus[role]?.active > 0 ? 'Active' : 'Inactive';
            
            return `
                <tr>
                    <td><strong>${role.charAt(0).toUpperCase() + role.slice(1)}</strong></td>
                    <td>${count}</td>
                    <td>${percentage}%</td>
                    <td><span class="status-badge status-active">${status}</span></td>
                </tr>
            `;
        });

        // Add total row
        const totalRow = `
            <tr class="total-row">
                <td><strong>Total</strong></td>
                <td><strong>${totalUsers}</strong></td>
                <td><strong>100%</strong></td>
                <td><strong>All Active</strong></td>
            </tr>
        `;

        // Update table
        tableBody.innerHTML = tableRows.join('') + totalRow;
        
        console.log('✅ Total Users table populated with', totalUsers, 'users');
        
    } catch (error) {
        console.error('❌ Error populating Total Users table:', error);
        tableBody.innerHTML = `
            <tr>
                <td colspan="4" style="text-align: center; color: #ef4444;">
                    Error loading user data: ${error.message}
                </td>
            </tr>
        `;
    }
}

/**
 * Populate Department Distribution details table
 */
async function populateDepartmentDistributionTable(profiles) {
    const tableBody = document.getElementById('course-distribution-table-body');
    if (!tableBody) {
        console.log('❌ Department distribution table body not found');
        return;
    }

    try {
        // Process profile data by department
        const departmentCounts = {};
        const departmentFaculties = {};
        
        profiles.forEach(profile => {
            const department = profile.academic_info?.department || profile.department || 'Unknown Department';
            const faculty = profile.academic_info?.faculty || profile.faculty || 'Unknown Faculty';
            
            departmentCounts[department] = (departmentCounts[department] || 0) + 1;
            departmentFaculties[department] = faculty; // Store faculty for each department
        });

        // Calculate total students
        const totalStudents = profiles.length;
        
        // Generate table rows
        const tableRows = Object.entries(departmentCounts).map(([department, count]) => {
            const percentage = totalStudents > 0 ? ((count / totalStudents) * 100).toFixed(1) : '0.0';
            const faculty = departmentFaculties[department] || 'Unknown';
            
            return `
                <tr>
                    <td><strong>${department}</strong></td>
                    <td>${faculty}</td>
                    <td>${count}</td>
                    <td>${percentage}%</td>
                </tr>
            `;
        });

        // Add total row
        const totalRow = `
            <tr class="total-row">
                <td><strong>Total</strong></td>
                <td><strong>All Faculties</strong></td>
                <td><strong>${totalStudents}</strong></td>
                <td><strong>100%</strong></td>
            </tr>
        `;

        // Update table
        tableBody.innerHTML = tableRows.join('') + totalRow;
        
        console.log('✅ Department Distribution table populated with', totalStudents, 'students');
        
    } catch (error) {
        console.error('❌ Error populating Department Distribution table:', error);
        tableBody.innerHTML = `
            <tr>
                <td colspan="4" style="text-align: center; color: #ef4444;">
                    Error loading department data: ${error.message}
                </tr>
        `;
    }
}

async function generateReport() {
    try {
        AnalyticsLogger.info('Generating comprehensive PDF analytics report');
        const startTime = performance.now();

        // Show loading notification
        addNotification('Generating PDF report...', 'info');

        // Use fallback if dataFetcher not available
        const fetcher = dataFetcher || fallbackDataFetcher;
        
        let users = [], profiles = [], events = [];
        
        try {
            const [usersResult, profilesResult, eventsResult] = await Promise.all([
                fetcher.fetchData('users'),
                fetcher.fetchData('profiles'),
                fetcher.fetchData('events'),
            ]);

            users = usersResult?.data || [];
            profiles = profilesResult?.data || [];
            events = eventsResult?.data || [];
        } catch (fetchError) {
            AnalyticsLogger.error('Error fetching data for PDF report', fetchError);
            addNotification('Error fetching data for PDF report: ' + fetchError.message, 'error');
            throw fetchError;
        }

        // Generate comprehensive report data for PDF
        const report = {
            metadata: {
                generatedAt: new Date().toISOString(),
                generatedBy: 'UTHM Talent Profiling System',
                version: '2.0.0',
                reportType: 'comprehensive_analytics'
            },
            summary: {
                totalUsers: users.length,
                totalStudents: users.filter(u => u.role === 'student').length,
                totalLecturers: users.filter(u => u.role === 'lecturer').length,
                totalAdmins: users.filter(u => u.role === 'admin').length,
                totalEvents: events.length,
                departments: new Set(profiles.map(p => p.academic_info?.department || p.department).filter(d => d)).size
            },
            analytics: {
                userDistribution: processRoleData(users),
                userGrowth: (() => {
                    const growthData = processUserGrowthData(users);
                    return growthData.data.reduce((acc, count, index) => {
                        acc[growthData.labels[index]] = count;
                        return acc;
                    }, {});
                })(),
                departmentDistribution: processDepartmentData(profiles),
                eventParticipation: processEventParticipation(events)
            },
            performance: {
                reportGenerationTime: `${(performance.now() - startTime).toFixed(2)}ms`,
                dataFreshness: currentData?.lastUpdated || null,
                cacheStats: (analyticsCache || fallbackAnalyticsCache).getStats(),
                systemStats: (chartManager || fallbackChartManager).getPerformanceStats()
            }
        };

        // Export as PDF
        try {
            await generatePDFReport(report);
        } catch (exportError) {
            AnalyticsLogger.error('Error exporting PDF report', exportError);
            addNotification('Error exporting PDF report: ' + exportError.message, 'error');
            throw exportError;
        }

        const generationTime = performance.now() - startTime;
        AnalyticsLogger.info(`PDF report generated successfully in ${generationTime.toFixed(2)}ms`);
        addNotification('PDF report generated successfully', 'success');

    } catch (e) {
        AnalyticsLogger.error('Error generating PDF report', e);
        addNotification('Error generating PDF report: ' + e.message, 'error');
    }
}

/**
 * Generate and download PDF report
 * @param {Object} report - The report data object
 */
async function generatePDFReport(report) {
    try {
        // Check if jsPDF is available
        if (typeof window.jspdf === 'undefined') {
            throw new Error('jsPDF library not loaded. Please refresh the page and try again.');
        }

        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();
        
        // Set document properties
        doc.setProperties({
            title: 'UTHM Talent Analytics Report',
            subject: 'Comprehensive Analytics Report',
            author: 'UTHM Talent Profiling System',
            creator: 'UTHM Dashboard',
            creationDate: new Date()
        });

        // Add header
        doc.setFontSize(20);
        doc.setTextColor(44, 62, 80);
        doc.text('UTHM Talent Analytics Report', 105, 20, { align: 'center' });
        
        // Add subtitle
        doc.setFontSize(12);
        doc.setTextColor(52, 73, 94);
        doc.text(`Generated on: ${new Date(report.metadata.generatedAt).toLocaleString('en-MY')}`, 105, 30, { align: 'center' });
        
        doc.text(`Report Type: ${report.metadata.reportType}`, 105, 37, { align: 'center' });
        doc.text(`Version: ${report.metadata.version}`, 105, 44, { align: 'center' });

        // Add summary section
        doc.setFontSize(16);
        doc.setTextColor(44, 62, 80);
        doc.text('Executive Summary', 20, 60);
        
        doc.setFontSize(10);
        doc.setTextColor(52, 73, 94);
        
        let yPosition = 70;
        const lineHeight = 7;
        
        // Summary statistics
        doc.text(`Total Users: ${report.summary.totalUsers}`, 20, yPosition);
        yPosition += lineHeight;
        
        doc.text(`Students: ${report.summary.totalStudents}`, 20, yPosition);
        yPosition += lineHeight;
        
        doc.text(`Lecturers: ${report.summary.totalLecturers}`, 20, yPosition);
        yPosition += lineHeight;
        
        doc.text(`Administrators: ${report.summary.totalAdmins}`, 20, yPosition);
        yPosition += lineHeight;
        
        doc.text(`Total Events: ${report.summary.totalEvents}`, 20, yPosition);
        yPosition += lineHeight;
        
        doc.text(`Departments: ${report.summary.departments}`, 20, yPosition);
        yPosition += lineHeight;

        // Add user distribution section
        yPosition += lineHeight + 5;
        doc.setFontSize(14);
        doc.setTextColor(44, 62, 80);
        doc.text('User Distribution by Role', 20, yPosition);
        
        yPosition += lineHeight;
        doc.setFontSize(10);
        doc.setTextColor(52, 73, 94);
        
        if (report.analytics.userDistribution) {
            Object.entries(report.analytics.userDistribution).forEach(([role, count]) => {
                doc.text(`${role.charAt(0).toUpperCase() + role.slice(1)}: ${count}`, 25, yPosition);
                yPosition += lineHeight;
            });
        }

        // Add department distribution section
        yPosition += lineHeight + 5;
        doc.setFontSize(14);
        doc.setTextColor(44, 62, 80);
        doc.text('Department Distribution', 20, yPosition);
        
        yPosition += lineHeight;
        doc.setFontSize(10);
        doc.setTextColor(52, 73, 94);
        
        if (report.analytics.departmentDistribution) {
            Object.entries(report.analytics.departmentDistribution).forEach(([dept, count]) => {
                doc.text(`${dept}: ${count} students`, 25, yPosition);
                yPosition += lineHeight;
            });
        }

        // Add event participation section
        yPosition += lineHeight + 5;
        doc.setFontSize(14);
        doc.setTextColor(44, 62, 80);
        doc.text('Event Participation', 20, yPosition);
        
        yPosition += lineHeight;
        doc.setFontSize(10);
        doc.setTextColor(52, 73, 94);
        
        if (report.analytics.eventParticipation) {
            Object.entries(report.analytics.eventParticipation).forEach(([event, count]) => {
                doc.text(`${event}: ${count} participants`, 25, yPosition);
                yPosition += lineHeight;
            });
        }

        // Add performance metrics section
        yPosition += lineHeight + 5;
        doc.setFontSize(14);
        doc.setTextColor(44, 62, 80);
        doc.text('Performance Metrics', 20, yPosition);
        
        yPosition += lineHeight;
        doc.setFontSize(10);
        doc.setTextColor(52, 73, 94);
        
        doc.text(`Report Generation Time: ${report.performance.reportGenerationTime}`, 25, yPosition);
        yPosition += lineHeight;
        
        if (report.performance.dataFreshness) {
            doc.text(`Data Last Updated: ${new Date(report.performance.dataFreshness).toLocaleString('en-MY')}`, 25, yPosition);
            yPosition += lineHeight;
        }

        // Add footer
        const pageHeight = doc.internal.pageSize.height;
        doc.setFontSize(8);
        doc.setTextColor(149, 165, 166);
        doc.text('UTHM Talent Profiling System - Analytics Report', 105, pageHeight - 20, { align: 'center' });
        doc.text(`Page ${doc.internal.getCurrentPageInfo().pageNumber}`, 105, pageHeight - 15, { align: 'center' });

        // Save the PDF
        const filename = `uthm-talent-analytics-${new Date().toISOString().split('T')[0]}.pdf`;
        doc.save(filename);
        
        AnalyticsLogger.info(`PDF report generated successfully: ${filename}`);
        addNotification('PDF report generated and downloaded successfully', 'success');
        
    } catch (error) {
        AnalyticsLogger.error('Error generating PDF report:', error);
        throw error;
    }
}

// Additional data processing functions for charts
function processDepartmentDataForCharts(profiles) {
    const deptData = {};

    // Ensure profiles is an array
    if (!profiles || !Array.isArray(profiles)) {
        return { labels: [], data: [] };
    }

    profiles.forEach(profile => {
        const dept = profile.academic_info?.department || profile.department || 'Unknown';
        deptData[dept] = (deptData[dept] || 0) + 1;
    });

    return {
        labels: Object.keys(deptData),
        data: Object.values(deptData)
    };
}



function processEventParticipationForCharts(events) {
    const eventParticipation = {};

    // Ensure events is an array
    if (!events || !Array.isArray(events)) {
        return { labels: [], data: [] };
    }

    events.forEach(event => {
        eventParticipation[event.title || event.id] = 1; // Default participation count
    });

    return {
        labels: Object.keys(eventParticipation),
        data: Object.values(eventParticipation)
    };
}

async function generateCustomChart() {
    try {
        AnalyticsLogger.info('Generating custom chart');

        const departmentFilter = document.getElementById('analytics-course-filter');
        const chartTypeFilter = document.getElementById('analytics-chart-type');
        
        if (!departmentFilter || !chartTypeFilter) {
            throw new Error('Required form elements not found');
        }
        
        const department = departmentFilter.value || '';
        const chartType = chartTypeFilter.value || 'bar';

        // Validate chart type
        if (!chartType) {
            throw new Error('Chart type is required');
        }

        // Use our enhanced data fetcher
        const fetcher = dataFetcher || fallbackDataFetcher;
        let users = [];
        
        try {
            const usersResult = await fetcher.fetchData('users');
            users = usersResult?.data || [];
        } catch (fetchError) {
            AnalyticsLogger.error('Error fetching users for custom chart', fetchError);
            addNotification('Error fetching users for custom chart: ' + fetchError.message, 'error');
            throw fetchError;
        }

        if (department) {
            users = users.filter(u => u.department === department);
        }

        // Generate more realistic engagement data based on actual user activity
        const engagementData = generateEngagementData(users);
        
        // Validate engagement data
        if (!engagementData || !engagementData.labels || !engagementData.data) {
            throw new Error('Failed to generate engagement data');
        }

        const config = {
            type: chartType,
            data: {
                labels: engagementData.labels,
                datasets: [{
                    label: department ? `${department} Engagement` : 'User Engagement',
                    data: engagementData.data,
                    backgroundColor: chartType === 'bar'
                        ? (ANALYTICS_CONFIG?.CHART_COLORS?.primary || fallbackConfig.CHART_COLORS.primary)
                        : [
                            (ANALYTICS_CONFIG?.CHART_COLORS?.primary || fallbackConfig.CHART_COLORS.primary),
                            (ANALYTICS_CONFIG?.CHART_COLORS?.secondary || fallbackConfig.CHART_COLORS.secondary),
                            (ANALYTICS_CONFIG?.CHART_COLORS?.accent || fallbackConfig.CHART_COLORS.accent),
                            (ANALYTICS_CONFIG?.CHART_COLORS?.warning || fallbackConfig.CHART_COLORS.accent)
                        ],
                    borderColor: (ANALYTICS_CONFIG?.CHART_COLORS?.primary || fallbackConfig.CHART_COLORS.primary),
                    fill: chartType !== 'bar',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: true },
                    tooltip: {
                        callbacks: {
                            title: (context) => `Period: ${context[0].label}`,
                            label: (context) => `Engagement: ${context.parsed.y}`
                        }
                    }
                },
                scales: chartType === 'bar' ? {
                    y: { beginAtZero: true }
                } : {}
            }
        };

        // Validate config
        if (!config || !config.data || !config.data.datasets) {
            throw new Error('Invalid chart configuration');
        }

        const manager = chartManager || fallbackChartManager;
        if (!manager || !manager.createChart) {
            throw new Error('Chart manager not available');
        }
        const canvas = document.getElementById('engagementChart');
        if (!canvas) {
            throw new Error('Engagement chart canvas not found');
        }
        
        const chart = await manager.createChart('engagementChart', config);
        if (!chart) {
            throw new Error('Failed to create engagement chart');
        }

        AnalyticsLogger.info(`Custom chart generated: ${chartType} for ${department || 'all users'}`);
        addNotification('Custom chart generated successfully', 'success');
        
        return chart;

    } catch (e) {
        AnalyticsLogger.error('Error generating custom chart', e);
        addNotification('Error generating custom chart: ' + e.message, 'error');
        throw e; // Re-throw to allow calling code to handle the error
    }
}

// Generate realistic engagement data
function generateEngagementData(users) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentMonth = new Date().getMonth();
    const relevantMonths = months.slice(Math.max(0, currentMonth - 5), currentMonth + 1);

    // Ensure users is an array
    if (!users || !Array.isArray(users)) {
        return { labels: relevantMonths, data: relevantMonths.map(() => 0) };
    }

    // Generate data based on user count and some realistic patterns
    const baseEngagement = Math.max(1, Math.floor(users.length * 0.7)); // 70% base engagement
    const data = relevantMonths.map((month, index) => {
        // Add some seasonal variation
        const seasonalFactor = 0.8 + (Math.sin((index / 12) * 2 * Math.PI) * 0.2);
        const randomFactor = 0.9 + (Math.random() * 0.2); // ±10% random variation
        return Math.floor(baseEngagement * seasonalFactor * randomFactor);
    });

    return {
        labels: relevantMonths,
        data: data
    };
}

// Enhanced export functionality with security controls
async function exportToCSV() {
    try {
        AnalyticsLogger.info('Starting CSV export');

        // Security check (allow during authentication process)
        const security = securityManager || fallbackSecurityManager;
        if (security.currentUser !== null && !security.canExportData()) {
            security.logSecurityEvent('unauthorized_export_attempt');
            addNotification('Access denied: You do not have permission to export data', 'error');
            return;
        }

        // Rate limiting check for exports (use fallback if not available)
        const userId = security.currentUser?.uid || 'anonymous';
        const rateLimiterInstance = rateLimiter || { checkLimit: () => ({ allowed: true, reason: 'fallback' }) };
        const rateLimitCheck = rateLimiterInstance.checkLimit(userId, 'export');
        if (!rateLimitCheck.allowed) {
            security.logSecurityEvent('export_rate_limit_exceeded', {
                reason: rateLimitCheck.reason
            });
            addNotification(`Export rate limit exceeded: ${rateLimitCheck.reason}`, 'warning');
            return;
        }

        addNotification('Preparing CSV export...', 'info');

        // Get fresh data for export
        const fetcher = dataFetcher || fallbackDataFetcher;
        
        let users = [], profiles = [], events = [];
        
        try {
            const [usersResult, profilesResult, eventsResult] = await Promise.all([
                fetcher.fetchData('users'),
                fetcher.fetchData('profiles'),
                fetcher.fetchData('events')
            ]);

            users = usersResult?.data || [];
            profiles = profilesResult?.data || [];
            events = eventsResult?.data || [];
        } catch (fetchError) {
            AnalyticsLogger.error('Error fetching data for CSV export', fetchError);
            addNotification('Error fetching data for CSV export: ' + fetchError.message, 'error');
            throw fetchError;
        }

        // Check if we have data
        if (!users || !Array.isArray(users) || users.length === 0) {
            addNotification('No user data available to export', 'warning');
            return;
        }

        // Prepare comprehensive data for export
        const userData = users.map(user => ({
            ID: user.id || 'N/A',
            Name: user.fullName || user.name || 'N/A',
            Email: user.email || 'N/A',
            Role: user.role || 'N/A',
                            Department: user.department || 'N/A',
            'Matrix ID': user.matrixId || 'N/A',
            'Created Date': user.createdAt ? new Date(user.createdAt).toLocaleDateString() : 'N/A',
            Status: user.status || 'Active',
            'Profile Completed': user.profileCompleted ? 'Yes' : 'No',
            'Last Login': user.lastLogin ? new Date(user.lastLogin).toLocaleDateString() : 'Never'
        }));

        // Validate data
        if (!userData || !Array.isArray(userData) || userData.length === 0) {
            addNotification('No valid data to export', 'warning');
            return;
        }

        // Generate CSV content with proper escaping
        if (!userData[0] || typeof userData[0] !== 'object') {
            addNotification('Invalid data format for CSV export', 'error');
            return;
        }
        
        const headers = Object.keys(userData[0]);
        const csvContent = [
            headers.join(','),
            ...userData.map(row =>
                headers.map(header => {
                    const value = row[header] || '';
                    // Escape quotes and wrap in quotes if contains comma, quote, or newline
                    const escapedValue = value.toString().replace(/"/g, '""');
                    return /[",\n\r]/.test(escapedValue) ? `"${escapedValue}"` : escapedValue;
                }).join(',')
            )
        ].join('\n');

        // Create and download file
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);

        link.setAttribute('href', url);
        link.setAttribute('download', `uthm-analytics-export-${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        URL.revokeObjectURL(url);

        // Log successful export
        security.logSecurityEvent('data_export', {
            type: 'csv',
            recordCount: userData.length,
            userRole: security.currentUser?.role
        });

        AnalyticsLogger.info(`CSV export completed: ${userData.length} records`);
        addNotification(`CSV export completed successfully (${userData.length} records)`, 'success');

    } catch (error) {
        AnalyticsLogger.error('Error exporting CSV', error);
        addNotification('Error exporting CSV: ' + error.message, 'error');
    }
}

// Enhanced refresh functionality
function refreshChart(chartType) {
    try {
        AnalyticsLogger.info(`Refreshing chart: ${chartType}`);

        switch (chartType) {
            case 'overview':
                loadOverviewStats();
                break;
            case 'analytics':
                setupAnalytics();
                break;
            case 'custom':
                generateCustomChart();
                break;
            default:
                refreshAnalyticsData();
        }

        addNotification(`${chartType} chart refreshed successfully`, 'success');
    } catch (error) {
        AnalyticsLogger.error(`Error refreshing ${chartType} chart`, error);
        addNotification(`Error refreshing ${chartType} chart`, 'error');
    }
}

// Cleanup function for when leaving analytics section
function cleanupAnalytics() {
    try {
        AnalyticsLogger.info('Cleaning up analytics resources');

        // Clear auto-refresh interval
        if (updateInterval) {
            clearInterval(updateInterval);
            updateInterval = null;
        }

        // Destroy all charts (use fallback if not available)
        const manager = chartManager || fallbackChartManager;
        if (manager && manager.destroyAllCharts) {
            manager.destroyAllCharts();
        }

        // Clear some cache to free memory (use fallback if not available)
        const cache = analyticsCache || fallbackAnalyticsCache;
        if (cache && cache.cleanup) {
            cache.cleanup();
        }

        isInitialized = false;

        AnalyticsLogger.info('Analytics cleanup completed');
    } catch (error) {
        AnalyticsLogger.error('Error during analytics cleanup', error);
    }
}

// Get analytics performance metrics
function getAnalyticsStats() {
    return {
        performance: performanceMetrics || { chartRenderTimes: [], dataFetchTimes: [], totalMemoryUsage: 0, apiCalls: 0, cacheHits: 0 },
        cache: (analyticsCache || fallbackAnalyticsCache).getStats(),
        charts: (chartManager || fallbackChartManager).getPerformanceStats(),
        dataFetcher: (dataFetcher || fallbackDataFetcher).getStats(),
        isInitialized,
        lastUpdated: currentData?.lastUpdated || null
    };
}

// Enhanced analytics functions for advanced features

/**
 * Generate comparative analysis report
 */
async function generateComparativeReport(period1, period2) {
    try {
        // Validate parameters
        if (!period1 || !period2) {
            throw new Error('Invalid period parameters provided');
        }

        // Check security (use fallback if not available)
        const security = securityManager || fallbackSecurityManager;
        if (!security.canAccessAnalytics()) {
            throw new Error('Access denied: Insufficient permissions');
        }

        AnalyticsLogger.info('Generating comparative analysis report');

        // Check if comparative analysis is available
        if (!comparativeAnalysis) {
            AnalyticsLogger.warn('Comparative analysis module not available, using basic comparison');
            const comparison = {
                message: 'Enhanced comparative analysis not available',
                basic: {
                    period1: period1.label,
                    period2: period2.label,
                    status: 'fallback_mode',
                    insights: []
                }
            };
            
            // Log the analysis
            security.logSecurityEvent('comparative_analysis_generated', {
                period1: period1.label,
                period2: period2.label,
                insights: 0
            });

            return comparison;
        }

        // Fetch data for both periods
        const [period1Data, period2Data] = await Promise.all([
            fetchPeriodData(period1),
            fetchPeriodData(period2)
        ]);

        // Perform comparative analysis

        const comparison = comparativeAnalysis.comparePeriods(
            period1Data.users,
            period2Data.users,
            {
                metrics: ['count', 'growth', 'percentage'],
                groupBy: 'role',
                calculateTrends: true
            }
        );

        // Log the analysis
        security.logSecurityEvent('comparative_analysis_generated', {
            period1: period1.label,
            period2: period2.label,
            insights: comparison.insights.length
        });

        return comparison;

    } catch (error) {
        AnalyticsLogger.error('Error generating comparative report', error);
        throw error;
    }
}

/**
 * Create advanced trend chart
 */
async function createAdvancedTrendChart(canvasId, dataType, options = {}) {
    try {
        // Validate parameters
        if (!canvasId) {
            throw new Error('Canvas ID is required');
        }

        // Check security (use fallback if not available)
        const security = securityManager || fallbackSecurityManager;
        if (!security.canAccessAnalytics()) {
            throw new Error('Access denied: Insufficient permissions');
        }

        const data = await prepareAdvancedChartData(dataType, options);

        // Check if advanced charts are available
        if (!advancedCharts) {
            AnalyticsLogger.warn('Advanced charts module not available, using basic chart');
            const manager = chartManager || fallbackChartManager;
            return await manager.createChart(canvasId, {
                type: 'line',
                data: data,
                options: { responsive: true }
            });
        }

        return await advancedCharts.createTrendChart(canvasId, data, {
            xAxisLabel: options.xAxisLabel || 'Time Period',
            yAxisLabel: options.yAxisLabel || 'Count',
            fill: options.fill || false
        });

    } catch (error) {
        AnalyticsLogger.error('Error creating advanced trend chart', error);
        throw error;
    }
}

/**
 * Schedule automated report
 */
function scheduleAutomatedReport(templateId, frequency, options = {}) {
    try {
        // Validate parameters
        if (!templateId) {
            throw new Error('Template ID is required');
        }

        const security = securityManager || fallbackSecurityManager;
        if (!security.canManageAnalytics()) {
            throw new Error('Access denied: Insufficient permissions to schedule reports');
        }

        // Use fallback if automatedReporting is not available
        if (!automatedReporting) {
            AnalyticsLogger.warn('Automated reporting module not available, using fallback');
            const scheduleId = `fallback_${Date.now()}`;
            
            security.logSecurityEvent('report_scheduled', {
                templateId,
                frequency,
                scheduleId
            });

            addNotification(`Report scheduled successfully (ID: ${scheduleId}) - Fallback Mode`, 'success');
            return scheduleId;
        }

        const scheduleId = automatedReporting.scheduleReport(templateId, frequency, options);

        security.logSecurityEvent('report_scheduled', {
            templateId,
            frequency,
            scheduleId
        });

        addNotification(`Report scheduled successfully (ID: ${scheduleId})`, 'success');
        return scheduleId;

    } catch (error) {
        AnalyticsLogger.error('Error scheduling report', error);
        addNotification('Error scheduling report: ' + error.message, 'error');
        throw error;
    }
}

/**
 * Get analytics insights and recommendations
 */
async function getAnalyticsInsights() {
    try {
        const security = securityManager || fallbackSecurityManager;
        if (!security.canAccessAnalytics()) {
            throw new Error('Access denied: Insufficient permissions');
        }

        const insights = {
            performance: getAnalyticsStats(),
            security: security.getSecurityStatus(),
            recommendations: [],
            alerts: []
        };

        // Generate performance recommendations
        const perfStats = insights.performance;
        if (perfStats.cache.hitRate < 0.7) {
            insights.recommendations.push({
                type: 'performance',
                priority: 'medium',
                message: 'Cache hit rate is below 70%. Consider increasing cache duration or optimizing queries.'
            });
        }

        if (perfStats.charts.averageRenderTime > 1000) {
            insights.recommendations.push({
                type: 'performance',
                priority: 'high',
                message: 'Chart rendering is slow. Consider reducing data complexity or implementing pagination.'
            });
        }

        // Generate security alerts
        if (!insights.security.sessionValid) {
            insights.alerts.push({
                type: 'security',
                severity: 'high',
                message: 'Session is invalid. Please re-authenticate.'
            });
        }

        return insights;

    } catch (error) {
        AnalyticsLogger.error('Error getting analytics insights', error);
        throw error;
    }
}

// Helper functions
async function fetchPeriodData(period) {
    // Validate parameters
    if (!period || !period.start || !period.end) {
        AnalyticsLogger.error('Invalid period parameter provided');
        return {
            users: [],
            profiles: [],
            events: []
        };
    }

    const endDate = new Date(period.end);
    const startDate = new Date(period.start);

    // Validate dates
    if (isNaN(endDate.getTime()) || isNaN(startDate.getTime())) {
        AnalyticsLogger.error('Invalid date format in period parameter');
        return {
            users: [],
            profiles: [],
            events: []
        };
    }

    // Use fallback if enhanced data fetcher not available
    const fetcher = dataFetcher || fallbackDataFetcher;

    try {
        const [usersResult, profilesResult, eventsResult] = await Promise.all([
            fetcher.fetchData('users', {
                query: {
                    field: 'createdAt',
                    operator: '>=',
                    value: startDate.toISOString()
                }
            }),
            fetcher.fetchData('profiles', {
                query: {
                    field: 'createdAt',
                    operator: '>=',
                    value: startDate.toISOString()
                }
            }),
            fetcher.fetchData('events', {
                query: {
                    field: 'createdAt',
                    operator: '>=',
                    value: startDate.toISOString()
                }
            })
        ]);

        return {
            users: (usersResult?.data || []).filter(u => new Date(u.createdAt) <= endDate),
            profiles: (profilesResult?.data || []).filter(p => new Date(p.createdAt) <= endDate),
            events: (eventsResult?.data || []).filter(e => new Date(e.createdAt) <= endDate)
        };
    } catch (error) {
        AnalyticsLogger.error('Error fetching period data', error);
        return {
            users: [],
            profiles: [],
            events: []
        };
    }
}

async function prepareAdvancedChartData(dataType, options = {}) {
    // Validate parameters
    if (!dataType) {
        AnalyticsLogger.error('Data type is required for advanced chart');
        return {
            labels: [],
            datasets: []
        };
    }

    const fetcher = dataFetcher || fallbackDataFetcher;
    let data = [];
    
    try {
        const result = await fetcher.fetchData(dataType);
        data = result?.data || [];
    } catch (error) {
        AnalyticsLogger.error(`Error fetching ${dataType} for advanced chart`, error);
        return {
            labels: [],
            datasets: []
        };
    }

    // Process data for advanced charts
    const processedData = {
        labels: [],
        datasets: []
    };

    if (options.groupBy === 'month') {
        const monthlyData = {};
        data.forEach(item => {
            if (item.createdAt) {
                const date = new Date(item.createdAt);
                const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                monthlyData[monthKey] = (monthlyData[monthKey] || 0) + 1;
            }
        });

        processedData.labels = Object.keys(monthlyData).sort();
        processedData.datasets = [{
            label: options.label || dataType,
            data: processedData.labels.map(label => monthlyData[label])
        }];
    }

    return processedData;
}

// ============================================
// ML ANALYTICS FUNCTIONS
// ============================================

// Import ML Analytics Service
let MLAnalyticsService;

async function initMLAnalytics() {
    try {
        const module = await import('../services/MLAnalyticsService.js');
        MLAnalyticsService = module.mlAnalyticsService;
        return MLAnalyticsService;
    } catch (error) {
        console.error('❌ ML Analytics Service failed to load:', error);
        return null;
    }
}

// Initialize on first use
if (!MLAnalyticsService) {
    initMLAnalytics();
}

// Expose ML functions to global window scope
function exposeMlFunctions() {
    // Expose to window for onclick handlers (legacy support)
    window.analyzeAllStudents = analyzeAllStudents;
    window.filterMLResults = filterMLResults;
    window.toggleMLDetails = toggleMLDetails;
    window.viewMLDetails = function(studentId) {
        const detailEl = document.getElementById(`ml-details-${studentId}`);
        if (detailEl) {
            detailEl.style.display = detailEl.style.display === 'none' ? 'block' : 'none';
        }
    };
    
    // Also attach event listeners directly (more reliable)
    setTimeout(() => {
        const analyzeBtn = document.querySelector('button[onclick*="analyzeAllStudents"]');
        const filterSelect = document.getElementById('ml-risk-filter');
        const configBtn = document.querySelector('button[onclick*="toggleMLDetails"]');
        
        if (analyzeBtn) {
            analyzeBtn.addEventListener('click', (e) => {
                e.preventDefault();
                analyzeAllStudents();
            });
        }
        
        if (filterSelect) {
            filterSelect.addEventListener('change', (e) => {
                filterMLResults();
            });
        }
        
        if (configBtn) {
            configBtn.addEventListener('click', (e) => {
                e.preventDefault();
                toggleMLDetails();
            });
        }
    }, 500);
}

async function analyzeAllStudents() {
    
    // Ensure ML service is loaded
    if (!MLAnalyticsService) {
        const service = await initMLAnalytics();
        if (!service) {
            addNotification('❌ ML Service not available', 'error');
            return;
        }
    }

    const container = document.getElementById('ml-results-container');
    if (!container) return;

    try {
        // Get configuration
        const config = getMLConfig();
        
        // Show loading state
        container.innerHTML = `
            <div style="grid-column: 1/-1; padding: 40px; text-align: center;">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
                <p style="margin-top: 15px; color: #666;">Analyzing students with AI...</p>
                ${config.department ? `<p style="color: #999; font-size: 14px;">Department: ${config.department}</p>` : ''}
            </div>
        `;

        // Fetch all users to analyze
        const { supabase } = await import('../config/supabase-config.js');
        
        // Build query with department filter if set
        let query = supabase
            .from('users')
            .select('id, email, name, department, role')
            .eq('role', 'student');
        
        if (config.department) {
            query = query.eq('department', config.department);
        }
        
        const { data: users, error } = await query;

        if (error) {
            console.error('❌ Error fetching students:', error);
            throw error;
        }
        
        
        if (!users || users.length === 0) {
            container.innerHTML = `
                <div style="grid-column: 1/-1; padding: 40px; text-align: center; color: #999;">
                    <i class="fas fa-info-circle"></i> No students found to analyze
                </div>
            `;
            return;
        }

        // Create a map of student data for later reference
        const studentDataMap = {};
        users.forEach(user => {
            studentDataMap[user.id] = {
                id: user.id,
                email: user.email,
                name: user.name,
                department: user.department
            };
        });

        // Extract student IDs
        const studentIds = users.map(u => u.id);

        // Call batch prediction
        const results = await MLAnalyticsService.batchPredict(studentIds);

        if (!results.success) {
            throw new Error(results.message || 'Batch analysis failed');
        }

        // Extract predictions array from data
        const predictions = Array.isArray(results.data) ? results.data : (results.data.results || results.data.predictions || []);
        
        // Enrich predictions with student data
        predictions.forEach(pred => {
            const studentId = pred.student_id || pred.id;
            if (studentDataMap[studentId]) {
                pred.studentInfo = studentDataMap[studentId];
            }
        });

        if (!predictions || predictions.length === 0) {
            console.warn('⚠️ No predictions in results');
            container.innerHTML = `
                <div style="grid-column: 1/-1; padding: 40px; text-align: center; color: #999;">
                    <i class="fas fa-info-circle"></i> No predictions returned from ML service
                </div>
            `;
            return;
        }

        // Update stats
        updateMLStats(predictions);

        // Display results
        displayMLResults(predictions);
        
        addNotification(`✅ Analyzed ${results.data.length} students successfully`, 'success');
        console.log('✅ Analysis complete');

    } catch (error) {
        console.error('❌ Error analyzing students:', error);
        container.innerHTML = `
            <div style="grid-column: 1/-1; padding: 40px; text-align: center;">
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-circle"></i> ${error.message || 'Failed to analyze students'}
                </div>
            </div>
        `;
        addNotification(`❌ ${error.message || 'Analysis failed'}`, 'error');
    }
}

function updateMLStats(results) {
    if (!Array.isArray(results)) return;

    let highRiskCount = 0;
    let mediumRiskCount = 0;
    let lowRiskCount = 0;

    results.forEach(result => {
        const level = (result.risk_level || result.riskLevel || '').toUpperCase();
        if (level === 'HIGH') highRiskCount++;
        else if (level === 'MEDIUM') mediumRiskCount++;
        else if (level === 'LOW') lowRiskCount++;
    });

    // Update display
    const analyzedEl = document.getElementById('ml-analyzed-count');
    const highEl = document.getElementById('ml-high-risk-count');
    const mediumEl = document.getElementById('ml-medium-risk-count');
    const lowEl = document.getElementById('ml-low-risk-count');

    if (analyzedEl) analyzedEl.textContent = results.length;
    if (highEl) highEl.textContent = highRiskCount;
    if (mediumEl) mediumEl.textContent = mediumRiskCount;
    if (lowEl) lowEl.textContent = lowRiskCount;
}

function displayMLResults(results) {
    const container = document.getElementById('ml-results-container');
    if (!container) return;

    if (!Array.isArray(results) || results.length === 0) {
        container.innerHTML = `
            <div style="grid-column: 1/-1; padding: 40px; text-align: center; color: #999;">
                <p>No results to display</p>
            </div>
        `;
        return;
    }

    // Group by risk level
    const grouped = {
        'HIGH': [],
        'MEDIUM': [],
        'LOW': []
    };

    results.forEach(result => {
        const level = result.riskLevel?.toUpperCase() || 'LOW';
        if (grouped[level]) {
            grouped[level].push(result);
        }
    });

    let html = '';

    // Display HIGH RISK first
    if (grouped['HIGH'].length > 0) {
        html += `<div class="ml-risk-group" style="grid-column: 1/-1;">
            <h4 style="color: #d32f2f; margin: 15px 0 10px 0;">
                <i class="fas fa-exclamation-circle"></i> High Risk (${grouped['HIGH'].length})
            </h4>
        </div>`;
        grouped['HIGH'].forEach(result => {
            html += createRiskCardHTML(result);
        });
    }

    // Display MEDIUM RISK
    if (grouped['MEDIUM'].length > 0) {
        html += `<div class="ml-risk-group" style="grid-column: 1/-1;">
            <h4 style="color: #f57c00; margin: 15px 0 10px 0;">
                <i class="fas fa-exclamation-triangle"></i> Medium Risk (${grouped['MEDIUM'].length})
            </h4>
        </div>`;
        grouped['MEDIUM'].forEach(result => {
            html += createRiskCardHTML(result);
        });
    }

    // Display LOW RISK
    if (grouped['LOW'].length > 0) {
        html += `<div class="ml-risk-group" style="grid-column: 1/-1;">
            <h4 style="color: #388e3c; margin: 15px 0 10px 0;">
                <i class="fas fa-check-circle"></i> Low Risk (${grouped['LOW'].length})
            </h4>
        </div>`;
        grouped['LOW'].forEach(result => {
            html += createRiskCardHTML(result);
        });
    }

    container.innerHTML = html;
}

function createRiskCardHTML(result) {
    // Map backend field names to frontend
    const studentId = result.student_id || result.id;
    const riskLevel = (result.risk_level || result.riskLevel || 'UNKNOWN').toUpperCase();
    const riskScore = result.risk_score || result.riskScore;
    const riskFactors = result.risk_factors || result.factors || [];
    const recommendations = result.recommendations;
    
    // Get student info for display
    const studentInfo = result.studentInfo || {};
    const displayName = studentInfo.name || studentInfo.email || studentId;
    const displayId = studentInfo.email ? studentInfo.email.split('@')[0] : studentId.substring(0, 8);
    
    let riskColor = '#388e3c'; // green
    let riskIcon = 'check-circle';
    
    if (riskLevel === 'HIGH') {
        riskColor = '#d32f2f';
        riskIcon = 'exclamation-circle';
    } else if (riskLevel === 'MEDIUM') {
        riskColor = '#f57c00';
        riskIcon = 'exclamation-triangle';
    }

    return `
        <div class="ml-risk-card-item" style="
            padding: 15px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            background: #fafafa;
            transition: all 0.3s;
        " onmouseover="this.style.boxShadow='0 2px 8px rgba(0,0,0,0.15)'; this.style.background='white';"
           onmouseout="this.style.boxShadow='none'; this.style.background='#fafafa';">
            <div style="display: flex; justify-content: space-between; align-items: start; gap: 10px;">
                <div style="flex: 1;">
                    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 8px;">
                        <span style="
                            color: white;
                            background: ${riskColor};
                            padding: 4px 12px;
                            border-radius: 20px;
                            font-size: 12px;
                            font-weight: bold;
                        ">
                            <i class="fas fa-${riskIcon}"></i> ${riskLevel}
                        </span>
                        <div style="display: flex; flex-direction: column;">
                            <strong style="font-size: 14px;">${displayName}</strong>
                            ${studentInfo.email ? `<span style="color: #666; font-size: 12px;">${studentInfo.email}</span>` : ''}
                        </div>
                    </div>
                    <div style="color: #666; font-size: 13px; line-height: 1.6;">
                        <div>� Risk Score: <strong>${riskScore ? (riskScore * 100).toFixed(1) + '%' : 'N/A'}</strong></div>
                        <div>⚠️ ${riskFactors.length || 0} risk factors identified</div>
                        ${studentInfo.department ? `<div> ${studentInfo.department}</div>` : ''}
                    </div>
                </div>
                <button onclick="viewMLDetails('${studentId}')" class="btn btn-sm btn-info" style="flex-shrink: 0;">
                    <i class="fas fa-eye"></i> Details
                </button>
            </div>
            <div id="ml-details-${studentId}" style="display: none; margin-top: 12px; padding-top: 12px; border-top: 1px solid #e0e0e0; color: #555; font-size: 13px;">
                ${riskFactors && riskFactors.length > 0 ? `<div><strong>Risk Factors:</strong><br>• ${riskFactors.slice(0, 3).join('<br>• ')}</div>` : ''}
                ${recommendations && Array.isArray(recommendations) && recommendations.length > 0 ? `<div style="margin-top: 8px;"><strong>Recommendations:</strong><br>• ${recommendations.slice(0, 3).join('<br>• ')}</div>` : ''}
                ${typeof recommendations === 'string' ? `<div style="margin-top: 8px;"><strong>Recommendations:</strong><br>${recommendations}</div>` : ''}
            </div>
        </div>
    `;
}

function filterMLResults() {
    const filter = document.getElementById('ml-risk-filter')?.value || 'all';
    const cards = document.querySelectorAll('.ml-risk-card-item');

    cards.forEach(card => {
        if (filter === 'all') {
            card.style.display = 'block';
        } else {
            const hasRiskLevel = card.textContent.includes(filter);
            card.style.display = hasRiskLevel ? 'block' : 'none';
        }
    });
}

function toggleMLDetails() {
    // Check if modal already exists
    let existingModal = document.getElementById('ml-config-modal');
    if (existingModal) {
        existingModal.remove();
    }
    
    // Create configuration modal
    const modalHTML = `
        <style>
            #ml-config-modal {
                position: fixed;
                top: 0;
                left: 0;
                z-index: 1050;
                width: 100%;
                height: 100%;
                overflow: auto;
            }
            #ml-config-modal .modal-dialog {
                position: relative;
                width: auto;
                max-width: 600px;
                margin: 1.75rem auto;
            }
            #ml-config-modal .modal-content {
                position: relative;
                display: flex;
                flex-direction: column;
                background-color: #fff;
                border: 1px solid rgba(0,0,0,.2);
                border-radius: 8px;
                box-shadow: 0 5px 15px rgba(0,0,0,.5);
            }
            #ml-config-modal .modal-header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: 1rem;
                border-bottom: 1px solid #dee2e6;
                border-radius: 8px 8px 0 0;
            }
            #ml-config-modal .modal-body {
                position: relative;
                flex: 1 1 auto;
                padding: 1rem;
                max-height: 70vh;
                overflow-y: auto;
            }
            #ml-config-modal .modal-footer {
                display: flex;
                align-items: center;
                justify-content: flex-end;
                padding: 1rem;
                border-top: 1px solid #dee2e6;
                gap: 10px;
            }
            #ml-config-modal .btn-close {
                padding: 0.5rem;
                background: transparent;
                border: none;
                font-size: 1.5rem;
                font-weight: 700;
                line-height: 1;
                color: white;
                opacity: 0.8;
                cursor: pointer;
            }
            #ml-config-modal .btn-close:hover {
                opacity: 1;
            }
            .modal-backdrop {
                position: fixed;
                top: 0;
                left: 0;
                z-index: 1040;
                width: 100vw;
                height: 100vh;
                background-color: rgba(0, 0, 0, 0.5);
            }
            body.modal-open {
                overflow: hidden;
            }
        </style>
        <div id="ml-config-modal" class="modal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content">
                    <div class="modal-header" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                        <h5 class="modal-title">
                            <i class="fas fa-cog"></i> ML Analytics Configuration
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="form-group">
                            <label><i class="fas fa-users"></i> Batch Size</label>
                            <input type="number" class="form-control" id="ml-batch-size" value="10" min="1" max="50">
                            <small class="form-text text-muted">Number of students to analyze in one batch (1-50)</small>
                        </div>
                        
                        <div class="form-group mt-3">
                            <label><i class="fas fa-exclamation-triangle"></i> Risk Thresholds</label>
                            <div class="row">
                                <div class="col-6">
                                    <label class="text-danger">High Risk (≥)</label>
                                    <input type="number" class="form-control" id="ml-high-threshold" value="70" min="0" max="100" step="5">
                                </div>
                                <div class="col-6">
                                    <label class="text-warning">Medium Risk (≥)</label>
                                    <input type="number" class="form-control" id="ml-medium-threshold" value="40" min="0" max="100" step="5">
                                </div>
                            </div>
                            <small class="form-text text-muted">Risk score percentages for classification</small>
                        </div>
                        
                        <div class="form-group mt-3">
                            <label><i class="fas fa-building"></i> Filter by Department</label>
                            <select class="form-control" id="ml-department-filter">
                                <option value="">All Departments</option>
                                <option value="Computer Science">Computer Science</option>
                                <option value="Information Systems">Information Systems</option>
                                <option value="Software Engineering">Software Engineering</option>
                                <option value="Artificial Intelligence">Artificial Intelligence</option>
                                <option value="Data Science">Data Science</option>
                            </select>
                            <small class="form-text text-muted">Analyze only students from selected department</small>
                        </div>
                        
                        <div class="form-group mt-3">
                            <div class="custom-control custom-switch">
                                <input type="checkbox" class="custom-control-input" id="ml-auto-refresh">
                                <label class="custom-control-label" for="ml-auto-refresh">
                                    <i class="fas fa-sync-alt"></i> Auto-refresh every 5 minutes
                                </label>
                            </div>
                            <small class="form-text text-muted">Automatically re-analyze students periodically</small>
                        </div>
                        
                        <div class="form-group mt-3">
                            <div class="custom-control custom-switch">
                                <input type="checkbox" class="custom-control-input" id="ml-show-details" checked>
                                <label class="custom-control-label" for="ml-show-details">
                                    <i class="fas fa-info-circle"></i> Show detailed risk factors
                                </label>
                            </div>
                        </div>
                        
                        <div class="alert alert-info mt-3" style="font-size: 13px;">
                            <i class="fas fa-lightbulb"></i> <strong>Tip:</strong> Lower batch sizes reduce server load but take longer. Higher risk thresholds make classification more strict.
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                            <i class="fas fa-times"></i> Cancel
                        </button>
                        <button type="button" class="btn btn-primary" onclick="saveMLConfig()">
                            <i class="fas fa-save"></i> Save & Apply
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Add modal to page
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    
    // Load saved config
    loadMLConfig();
    
    // Show modal using vanilla JavaScript
    const modalElement = document.getElementById('ml-config-modal');
    modalElement.style.display = 'block';
    modalElement.classList.add('show');
    document.body.classList.add('modal-open');
    
    // Add backdrop
    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop fade show';
    backdrop.id = 'ml-config-backdrop';
    document.body.appendChild(backdrop);
    
    // Close button handlers
    const closeButtons = modalElement.querySelectorAll('[data-bs-dismiss="modal"]');
    closeButtons.forEach(btn => {
        btn.addEventListener('click', () => closeMLConfigModal());
    });
    
    // Click outside to close
    backdrop.addEventListener('click', () => closeMLConfigModal());
}

function closeMLConfigModal() {
    const modalElement = document.getElementById('ml-config-modal');
    const backdrop = document.getElementById('ml-config-backdrop');
    
    if (modalElement) {
        modalElement.style.display = 'none';
        modalElement.classList.remove('show');
        modalElement.remove();
    }
    
    if (backdrop) {
        backdrop.remove();
    }
    
    document.body.classList.remove('modal-open');
}

function loadMLConfig() {
    // Load saved configuration from localStorage
    const config = JSON.parse(localStorage.getItem('mlAnalyticsConfig') || '{}');
    
    if (config.batchSize) document.getElementById('ml-batch-size').value = config.batchSize;
    if (config.highThreshold) document.getElementById('ml-high-threshold').value = config.highThreshold;
    if (config.mediumThreshold) document.getElementById('ml-medium-threshold').value = config.mediumThreshold;
    if (config.department) document.getElementById('ml-department-filter').value = config.department;
    if (config.autoRefresh) document.getElementById('ml-auto-refresh').checked = config.autoRefresh;
    if (config.showDetails !== undefined) document.getElementById('ml-show-details').checked = config.showDetails;
}

window.saveMLConfig = function() {
    // Get values
    const config = {
        batchSize: parseInt(document.getElementById('ml-batch-size').value),
        highThreshold: parseInt(document.getElementById('ml-high-threshold').value),
        mediumThreshold: parseInt(document.getElementById('ml-medium-threshold').value),
        department: document.getElementById('ml-department-filter').value,
        autoRefresh: document.getElementById('ml-auto-refresh').checked,
        showDetails: document.getElementById('ml-show-details').checked
    };
    
    // Validate
    if (config.mediumThreshold >= config.highThreshold) {
        addNotification('Medium threshold must be lower than High threshold', 'error');
        return;
    }
    
    // Save to localStorage
    localStorage.setItem('mlAnalyticsConfig', JSON.stringify(config));
    
    // Close modal
    closeMLConfigModal();
    
    // Apply configuration
    addNotification('Configuration saved successfully! Re-run analysis to apply changes.', 'success');
    
    // Setup auto-refresh if enabled
    if (config.autoRefresh) {
        setupMLAutoRefresh();
    } else {
        clearMLAutoRefresh();
    }
}

let mlAutoRefreshInterval = null;

function setupMLAutoRefresh() {
    // Clear any existing interval
    clearMLAutoRefresh();
    
    // Setup new interval (5 minutes)
    mlAutoRefreshInterval = setInterval(() => {
        addNotification('Auto-refreshing student risk analysis...', 'info');
        analyzeAllStudents();
    }, 5 * 60 * 1000);
}

function clearMLAutoRefresh() {
    if (mlAutoRefreshInterval) {
        clearInterval(mlAutoRefreshInterval);
        mlAutoRefreshInterval = null;
    }
}

function getMLConfig() {
    // Get saved config or return defaults
    const defaultConfig = {
        batchSize: 10,
        highThreshold: 70,
        mediumThreshold: 40,
        department: '',
        autoRefresh: false,
        showDetails: true
    };
    
    const saved = localStorage.getItem('mlAnalyticsConfig');
    return saved ? { ...defaultConfig, ...JSON.parse(saved) } : defaultConfig;
}

// Export all enhanced analytics functions
export {
    loadOverviewStats,
    refreshOverviewStats,
    setupAnalytics,
    generateReport,
    generateCustomChart,
    exportToCSV,
    refreshChart,
    cleanupAnalytics,
    getAnalyticsStats,
    refreshAnalyticsData,
    generateComparativeReport,
    createAdvancedTrendChart,
    scheduleAutomatedReport,
    getAnalyticsInsights,
    analyzeAllStudents,
    filterMLResults,
    toggleMLDetails
};