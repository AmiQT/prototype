// Firebase removed - using backend API instead

/**
 * Security manager for analytics access control and data protection
 */
export class SecurityManager {
    constructor() {
        this.currentUser = null;
        this.permissions = new Map();
        this.sessionData = new Map();
        this.securityConfig = {
            sessionTimeout: 30 * 60 * 1000, // 30 minutes
            maxFailedAttempts: 5,
            lockoutDuration: 15 * 60 * 1000, // 15 minutes
            sensitiveDataFields: ['email', 'matrixId', 'personalInfo'],
            allowedRoles: ['admin', 'lecturer'],
            analyticsPermissions: {
                'admin': ['read', 'write', 'export', 'delete', 'manage'],
                'lecturer': ['read', 'export'],
                'student': []
            }
        };
        
        this.init();
    }
    
    async init() {
        // Monitor auth state
        auth.onAuthStateChanged((user) => {
            this.handleAuthStateChange(user);
        });
        
        // Setup session monitoring
        this.startSessionMonitoring();
    }
    
    async handleAuthStateChange(user) {
        if (user) {
            await this.loadUserPermissions(user);
            this.startSession(user);
        } else {
            this.clearSession();
        }
    }
    
    async loadUserPermissions(user) {
        try {
            const userDoc = await db.collection('users').doc(user.uid).get();
            if (userDoc.exists) {
                const userData = userDoc.data();
                this.currentUser = {
                    uid: user.uid,
                    email: user.email,
                    role: userData.role,
                    department: userData.department,
                    permissions: this.securityConfig.analyticsPermissions[userData.role] || []
                };
                
                this.permissions.set(user.uid, this.currentUser.permissions);
                // User permissions loaded (logging suppressed)
            }
        } catch (error) {
            console.error('Error loading user permissions:', error);
            this.currentUser = null;
        }
    }
    
    startSession(user) {
        const sessionId = this.generateSessionId();
        const sessionData = {
            userId: user.uid,
            startTime: Date.now(),
            lastActivity: Date.now(),
            sessionId,
            ipAddress: this.getClientIP(),
            userAgent: navigator.userAgent
        };
        
        this.sessionData.set(user.uid, sessionData);
        localStorage.setItem('analyticsSession', JSON.stringify({
            sessionId,
            startTime: sessionData.startTime
        }));
    }
    
    clearSession() {
        if (this.currentUser) {
            this.sessionData.delete(this.currentUser.uid);
        }
        this.currentUser = null;
        this.permissions.clear();
        localStorage.removeItem('analyticsSession');
    }
    
    /**
     * Check if user has permission for specific action
     */
    hasPermission(action) {
        if (!this.currentUser) {
            return false;
        }
        
        // Check if user role is allowed
        if (!this.securityConfig.allowedRoles.includes(this.currentUser.role)) {
            return false;
        }
        
        // Check specific permission
        return this.currentUser.permissions.includes(action);
    }
    
    /**
     * Check if user can access analytics
     */
    canAccessAnalytics() {
        // Allow access during authentication process
        if (this.currentUser === null) {
            return true; // Temporary access during auth
        }
        return this.hasPermission('read');
    }
    
    /**
     * Check if user can export data
     */
    canExportData() {
        return this.hasPermission('export');
    }
    
    /**
     * Check if user can manage analytics
     */
    canManageAnalytics() {
        return this.hasPermission('manage');
    }
    
    /**
     * Sanitize data based on user permissions
     */
    sanitizeData(data, dataType = 'general') {
        if (!this.currentUser) {
            return [];
        }
        
        // Admin can see all data
        if (this.currentUser.role === 'admin') {
            return data;
        }
        
        // Lecturers can see limited data
        if (this.currentUser.role === 'lecturer') {
            return this.sanitizeForLecturer(data, dataType);
        }
        
        // Students cannot access analytics data
        return [];
    }
    
    sanitizeForLecturer(data, dataType) {
        return data.map(item => {
            const sanitized = { ...item };
            
            // Remove sensitive fields
            this.securityConfig.sensitiveDataFields.forEach(field => {
                if (sanitized[field]) {
                    sanitized[field] = this.maskSensitiveData(sanitized[field]);
                }
            });
            
            // Department-based filtering for some data types
            if (dataType === 'users' && this.currentUser.department) {
                if (item.department !== this.currentUser.department) {
                    // Mask data from other departments
                    sanitized.name = 'User from ' + (item.department || 'Other Department');
                    sanitized.email = '***@***.***';
                }
            }
            
            return sanitized;
        });
    }
    
    maskSensitiveData(value) {
        if (typeof value === 'string') {
            if (value.includes('@')) {
                // Email masking
                const [local, domain] = value.split('@');
                return `${local.substring(0, 2)}***@${domain}`;
            } else if (value.length > 4) {
                // General string masking
                return value.substring(0, 2) + '*'.repeat(value.length - 4) + value.substring(value.length - 2);
            }
        }
        return '***';
    }
    
    /**
     * Log security events
     */
    logSecurityEvent(event, details = {}) {
        const logEntry = {
            timestamp: new Date().toISOString(),
            event,
            userId: this.currentUser?.uid,
            userRole: this.currentUser?.role,
            sessionId: this.sessionData.get(this.currentUser?.uid)?.sessionId,
            details,
            ipAddress: this.getClientIP(),
            userAgent: navigator.userAgent
        };
        
        // Store in localStorage for now (in production, send to security service)
        const securityLogs = JSON.parse(localStorage.getItem('securityLogs') || '[]');
        securityLogs.push(logEntry);
        
        // Keep only last 1000 entries
        if (securityLogs.length > 1000) {
            securityLogs.shift();
        }
        
        localStorage.setItem('securityLogs', JSON.stringify(securityLogs));
        
        // Log critical events to console (disabled for cleaner console)
        // if (['unauthorized_access', 'permission_denied', 'suspicious_activity'].includes(event)) {
        //     console.warn('Security Event:', logEntry);
        // }
    }
    
    /**
     * Validate session
     */
    validateSession() {
        if (!this.currentUser) {
            return false;
        }
        
        const session = this.sessionData.get(this.currentUser.uid);
        if (!session) {
            return false;
        }
        
        const now = Date.now();
        const sessionAge = now - session.startTime;
        const inactivityTime = now - session.lastActivity;
        
        // Check session timeout
        if (sessionAge > this.securityConfig.sessionTimeout || 
            inactivityTime > this.securityConfig.sessionTimeout) {
            this.logSecurityEvent('session_expired', { sessionAge, inactivityTime });
            this.clearSession();
            return false;
        }
        
        // Update last activity
        session.lastActivity = now;
        return true;
    }
    
    /**
     * Update session activity
     */
    updateActivity() {
        if (this.currentUser) {
            const session = this.sessionData.get(this.currentUser.uid);
            if (session) {
                session.lastActivity = Date.now();
            }
        }
    }
    
    /**
     * Start session monitoring
     */
    startSessionMonitoring() {
        // Check session validity every minute
        setInterval(() => {
            this.validateSession();
        }, 60000);
        
        // Track user activity
        ['click', 'keypress', 'scroll'].forEach(event => {
            document.addEventListener(event, () => {
                this.updateActivity();
            }, { passive: true });
        });
    }
    
    /**
     * Generate secure session ID
     */
    generateSessionId() {
        const array = new Uint8Array(16);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }
    
    /**
     * Get client IP (limited in browser environment)
     */
    getClientIP() {
        // In a real application, this would be handled server-side
        return 'client-side-unknown';
    }
    
    /**
     * Get security status
     */
    getSecurityStatus() {
        return {
            isAuthenticated: !!this.currentUser,
            user: this.currentUser ? {
                uid: this.currentUser.uid,
                role: this.currentUser.role,
                permissions: this.currentUser.permissions
            } : null,
            sessionValid: this.validateSession(),
            sessionData: this.currentUser ? this.sessionData.get(this.currentUser.uid) : null
        };
    }
    
    /**
     * Encrypt sensitive data (basic implementation)
     */
    encryptData(data) {
        // In production, use proper encryption
        return btoa(JSON.stringify(data));
    }
    
    /**
     * Decrypt sensitive data (basic implementation)
     */
    decryptData(encryptedData) {
        try {
            return JSON.parse(atob(encryptedData));
        } catch {
            return null;
        }
    }
}

// Create singleton instance
export const securityManager = new SecurityManager();
