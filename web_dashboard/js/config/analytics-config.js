// Analytics Configuration
export const ANALYTICS_CONFIG = {
    // Cache settings
    CACHE_DURATION: 5 * 60 * 1000, // 5 minutes
    MAX_CACHE_SIZE: 50, // Maximum number of cached queries
    
    // Performance settings
    MAX_RECORDS_PER_QUERY: 1000,
    CHART_ANIMATION_DURATION: 750,
    DEBOUNCE_DELAY: 300,
    
    // Chart configurations
    CHART_COLORS: {
        primary: '#2563eb',
        secondary: '#10b981',
        accent: '#f59e0b',
        danger: '#e11d48',
        warning: '#f97316',
        info: '#06b6d4',
        success: '#059669',
        muted: '#6b7280'
    },
    
    // Default chart options
    DEFAULT_CHART_OPTIONS: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: true,
                position: 'top'
            },
            tooltip: {
                enabled: true,
                mode: 'index',
                intersect: false
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                grid: {
                    color: 'rgba(0, 0, 0, 0.1)'
                }
            },
            x: {
                grid: {
                    color: 'rgba(0, 0, 0, 0.1)'
                }
            }
        }
    },
    
    // Data validation rules
    VALIDATION_RULES: {
        minDataPoints: 1,
        maxDataPoints: 1000,
        requiredFields: ['id', 'createdAt'],
        dateFormats: ['ISO8601', 'timestamp']
    },
    
    // Export settings
    EXPORT_CONFIG: {
        csv: {
            delimiter: ',',
            encoding: 'utf-8',
            includeHeaders: true
        },
        maxExportRecords: 10000
    },
    
    // Error handling
    ERROR_CONFIG: {
        maxRetries: 3,
        retryDelay: 1000,
        timeoutDuration: 30000
    },
    
    // Feature flags
    FEATURES: {
        realTimeUpdates: true,
        advancedCharts: false,
        exportToPDF: false,
        customDashboards: false,
        userBehaviorTracking: false
    }
};

// Chart type definitions
export const CHART_TYPES = {
    LINE: 'line',
    BAR: 'bar',
    DOUGHNUT: 'doughnut',
    PIE: 'pie',
    AREA: 'area',
    SCATTER: 'scatter'
};

// Metric definitions
export const METRICS = {
    USERS: {
        total: 'Total Users',
        active: 'Active Users',
        new: 'New Users',
        byRole: 'Users by Role',
        byDepartment: 'Users by Department',
        growth: 'User Growth'
    },

    EVENTS: {
        total: 'Total Events',
        active: 'Active Events',
        participation: 'Event Participation',
        byCategory: 'Events by Category'
    },
    ENGAGEMENT: {
        dailyActive: 'Daily Active Users',
        sessionDuration: 'Average Session Duration',
        pageViews: 'Page Views',
        bounceRate: 'Bounce Rate'
    }
};

// Time period definitions
export const TIME_PERIODS = {
    LAST_7_DAYS: { days: 7, label: 'Last 7 Days' },
    LAST_30_DAYS: { days: 30, label: 'Last 30 Days' },
    LAST_90_DAYS: { days: 90, label: 'Last 90 Days' },
    LAST_YEAR: { days: 365, label: 'Last Year' },
    CUSTOM: { days: null, label: 'Custom Range' }
};
