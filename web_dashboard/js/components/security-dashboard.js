import { securityManager } from '../utils/security-manager.js';
import { rateLimiter } from '../utils/rate-limiter.js';

/**
 * Security dashboard component for monitoring and managing security
 */
export class SecurityDashboard {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.updateInterval = null;
        this.init();
    }
    
    init() {
        if (!this.container) {
            console.error('SecurityDashboard: Container not found');
            return;
        }
        
        this.render();
        this.setupEventListeners();
        this.startAutoUpdate();
    }
    
    render() {
        this.container.innerHTML = `
            <div class="security-dashboard">
                <div class="security-header">
                    <h3><i class="fas fa-shield-alt"></i> Security Status</h3>
                    <button class="btn btn-sm btn-secondary refresh-btn">
                        <i class="fas fa-sync"></i> Refresh
                    </button>
                </div>
                
                <div class="security-grid">
                    <div class="security-card">
                        <h4>Authentication Status</h4>
                        <div id="auth-status" class="status-content">
                            Loading...
                        </div>
                    </div>
                    
                    <div class="security-card">
                        <h4>Session Information</h4>
                        <div id="session-info" class="status-content">
                            Loading...
                        </div>
                    </div>
                    
                    <div class="security-card">
                        <h4>Rate Limiting Status</h4>
                        <div id="rate-limit-status" class="status-content">
                            Loading...
                        </div>
                    </div>
                    
                    <div class="security-card">
                        <h4>Recent Security Events</h4>
                        <div id="security-events" class="status-content">
                            Loading...
                        </div>
                    </div>
                </div>
                
                <div class="security-actions">
                    <button class="btn btn-warning clear-logs-btn">
                        <i class="fas fa-trash"></i> Clear Security Logs
                    </button>
                    <button class="btn btn-info export-logs-btn">
                        <i class="fas fa-download"></i> Export Security Logs
                    </button>
                    <button class="btn btn-danger reset-limits-btn">
                        <i class="fas fa-refresh"></i> Reset Rate Limits
                    </button>
                </div>
            </div>
        `;
        
        this.updateStatus();
    }
    
    setupEventListeners() {
        const refreshBtn = this.container.querySelector('.refresh-btn');
        const clearLogsBtn = this.container.querySelector('.clear-logs-btn');
        const exportLogsBtn = this.container.querySelector('.export-logs-btn');
        const resetLimitsBtn = this.container.querySelector('.reset-limits-btn');
        
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.updateStatus());
        }
        
        if (clearLogsBtn) {
            clearLogsBtn.addEventListener('click', () => this.clearSecurityLogs());
        }
        
        if (exportLogsBtn) {
            exportLogsBtn.addEventListener('click', () => this.exportSecurityLogs());
        }
        
        if (resetLimitsBtn) {
            resetLimitsBtn.addEventListener('click', () => this.resetRateLimits());
        }
    }
    
    updateStatus() {
        this.updateAuthStatus();
        this.updateSessionInfo();
        this.updateRateLimitStatus();
        this.updateSecurityEvents();
    }
    
    updateAuthStatus() {
        const authStatusEl = this.container.querySelector('#auth-status');
        const securityStatus = securityManager.getSecurityStatus();
        
        if (securityStatus.isAuthenticated) {
            authStatusEl.innerHTML = `
                <div class="status-item success">
                    <i class="fas fa-check-circle"></i>
                    <span>Authenticated</span>
                </div>
                <div class="user-info">
                    <strong>User:</strong> ${securityStatus.user.uid}<br>
                    <strong>Role:</strong> ${securityStatus.user.role}<br>
                    <strong>Permissions:</strong> ${securityStatus.user.permissions.join(', ')}
                </div>
            `;
        } else {
            authStatusEl.innerHTML = `
                <div class="status-item error">
                    <i class="fas fa-times-circle"></i>
                    <span>Not Authenticated</span>
                </div>
            `;
        }
    }
    
    updateSessionInfo() {
        const sessionInfoEl = this.container.querySelector('#session-info');
        const securityStatus = securityManager.getSecurityStatus();
        
        if (securityStatus.sessionData) {
            const session = securityStatus.sessionData;
            const sessionAge = Date.now() - session.startTime;
            const lastActivity = Date.now() - session.lastActivity;
            
            sessionInfoEl.innerHTML = `
                <div class="session-details">
                    <div><strong>Session ID:</strong> ${session.sessionId.substring(0, 8)}...</div>
                    <div><strong>Duration:</strong> ${this.formatDuration(sessionAge)}</div>
                    <div><strong>Last Activity:</strong> ${this.formatDuration(lastActivity)} ago</div>
                    <div><strong>Status:</strong> 
                        <span class="status-badge ${securityStatus.sessionValid ? 'success' : 'error'}">
                            ${securityStatus.sessionValid ? 'Valid' : 'Invalid'}
                        </span>
                    </div>
                </div>
            `;
        } else {
            sessionInfoEl.innerHTML = `
                <div class="status-item warning">
                    <i class="fas fa-exclamation-triangle"></i>
                    <span>No Active Session</span>
                </div>
            `;
        }
    }
    
    updateRateLimitStatus() {
        const rateLimitEl = this.container.querySelector('#rate-limit-status');
        const usageStats = rateLimiter.getUsageStats();
        
        rateLimitEl.innerHTML = `
            <div class="rate-limit-info">
                <div class="global-limits">
                    <h5>Global Usage</h5>
                    <div>Last Minute: ${usageStats.global.lastMinute}/${usageStats.global.limits.perMinute}</div>
                    <div>Last Hour: ${usageStats.global.lastHour}/${usageStats.global.limits.perHour}</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${(usageStats.global.lastMinute / usageStats.global.limits.perMinute) * 100}%"></div>
                    </div>
                </div>
                <div class="endpoint-limits">
                    <h5>Endpoint Usage</h5>
                    ${Object.entries(usageStats.endpoints).map(([endpoint, stats]) => `
                        <div class="endpoint-stat">
                            <span>${endpoint}:</span> ${stats.lastMinute} requests
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }
    
    updateSecurityEvents() {
        const eventsEl = this.container.querySelector('#security-events');
        const logs = JSON.parse(localStorage.getItem('securityLogs') || '[]');
        const recentLogs = logs.slice(-10).reverse(); // Last 10 events
        
        if (recentLogs.length === 0) {
            eventsEl.innerHTML = '<div class="no-events">No recent security events</div>';
            return;
        }
        
        eventsEl.innerHTML = `
            <div class="events-list">
                ${recentLogs.map(log => `
                    <div class="event-item ${this.getEventSeverity(log.event)}">
                        <div class="event-header">
                            <span class="event-type">${log.event}</span>
                            <span class="event-time">${new Date(log.timestamp).toLocaleTimeString()}</span>
                        </div>
                        <div class="event-details">
                            ${log.details ? JSON.stringify(log.details) : 'No additional details'}
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }
    
    getEventSeverity(eventType) {
        const highSeverity = ['unauthorized_access', 'permission_denied', 'suspicious_activity'];
        const mediumSeverity = ['rate_limit_exceeded', 'session_expired'];
        
        if (highSeverity.includes(eventType)) return 'high-severity';
        if (mediumSeverity.includes(eventType)) return 'medium-severity';
        return 'low-severity';
    }
    
    formatDuration(ms) {
        const seconds = Math.floor(ms / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        
        if (hours > 0) return `${hours}h ${minutes % 60}m`;
        if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
        return `${seconds}s`;
    }
    
    clearSecurityLogs() {
        if (confirm('Are you sure you want to clear all security logs?')) {
            localStorage.removeItem('securityLogs');
            this.updateSecurityEvents();
            console.log('Security logs cleared');
        }
    }
    
    exportSecurityLogs() {
        const logs = JSON.parse(localStorage.getItem('securityLogs') || '[]');
        
        if (logs.length === 0) {
            alert('No security logs to export');
            return;
        }
        
        const csvContent = this.convertLogsToCSV(logs);
        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = URL.createObjectURL(blob);
        
        const link = document.createElement('a');
        link.href = url;
        link.download = `security-logs-${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        
        URL.revokeObjectURL(url);
        console.log('Security logs exported');
    }
    
    convertLogsToCSV(logs) {
        const headers = ['Timestamp', 'Event', 'User ID', 'User Role', 'Session ID', 'Details'];
        const rows = logs.map(log => [
            log.timestamp,
            log.event,
            log.userId || '',
            log.userRole || '',
            log.sessionId || '',
            JSON.stringify(log.details || {})
        ]);
        
        return [headers, ...rows].map(row => 
            row.map(cell => `"${cell.toString().replace(/"/g, '""')}"`).join(',')
        ).join('\n');
    }
    
    resetRateLimits() {
        if (confirm('Are you sure you want to reset all rate limits?')) {
            rateLimiter.resetAll();
            this.updateRateLimitStatus();
            console.log('Rate limits reset');
        }
    }
    
    startAutoUpdate() {
        this.updateInterval = setInterval(() => {
            this.updateStatus();
        }, 30000); // Update every 30 seconds
    }
    
    destroy() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
        }
        
        if (this.container) {
            this.container.innerHTML = '';
        }
    }
}
