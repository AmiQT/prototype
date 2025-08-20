/**
 * System Monitoring Dashboard
 * Integrates with backend sync status and health monitoring APIs
 */

import { BACKEND_CONFIG, makeAuthenticatedRequest, testBackendConnection } from '../config/backend-config.js';
import { addNotification } from '../ui/notifications.js';

// Get API endpoints from the config
const API_ENDPOINTS = BACKEND_CONFIG.endpoints;

let monitoringInterval = null;
let systemStatus = {
    backend: 'unknown',
    database: 'unknown',
    lastCheck: null,
    uptime: 0
};

/**
 * Initialize system monitoring
 */
export async function initializeSystemMonitoring() {
    try {
        // Initializing system monitoring
        
        // Initial status check
        await checkSystemStatus();
        
        // Set up periodic monitoring (every 30 seconds)
        if (monitoringInterval) {
            clearInterval(monitoringInterval);
        }
        
        monitoringInterval = setInterval(async () => {
            await checkSystemStatus();
        }, 30000);
        
        // System monitoring initialized successfully
        
    } catch (error) {
        console.error('Error initializing system monitoring:', error);
        addNotification('Failed to initialize system monitoring', 'error');
    }
}

/**
 * Check overall system status
 */
export async function checkSystemStatus() {
    try {
        const startTime = performance.now();
        
        // Check backend connectivity
        const backendStatus = await testBackendConnection();
        
        let databaseStatus = 'unknown';
        let databaseCounts = {};
        let currentUser = null;
        
        if (backendStatus) {
            try {
                // Get sync status from backend
                const syncResponse = await makeAuthenticatedRequest(API_ENDPOINTS.system.status);
                
                if (syncResponse) {
                    databaseStatus = syncResponse.status === 'ready' ? 'connected' : 'error';
                    databaseCounts = syncResponse.database_counts || {};
                    currentUser = syncResponse.current_user || null;
                }
            } catch (error) {
                console.error('Error getting sync status:', error);
                databaseStatus = 'error';
            }
        }
        
        const responseTime = performance.now() - startTime;
        
        // Update system status
        systemStatus = {
            backend: backendStatus ? 'online' : 'offline',
            database: databaseStatus,
            lastCheck: new Date().toISOString(),
            responseTime: Math.round(responseTime),
            databaseCounts,
            currentUser
        };
        
        // Update UI if monitoring section is active
        updateSystemStatusUI();
        
        return systemStatus;
        
    } catch (error) {
        console.error('Error checking system status:', error);
        systemStatus = {
            backend: 'error',
            database: 'error',
            lastCheck: new Date().toISOString(),
            error: error.message
        };
        
        updateSystemStatusUI();
        return systemStatus;
    }
}

/**
 * Update system status UI elements
 */
function updateSystemStatusUI() {
    // Update status indicators
    updateStatusIndicator('backend-status', systemStatus.backend);
    updateStatusIndicator('database-status', systemStatus.database);
    
    // Update last check time
    const lastCheckElement = document.getElementById('last-status-check');
    if (lastCheckElement && systemStatus.lastCheck) {
        const checkTime = new Date(systemStatus.lastCheck);
        lastCheckElement.textContent = checkTime.toLocaleTimeString();
    }
    
    // Update response time
    const responseTimeElement = document.getElementById('response-time');
    if (responseTimeElement && systemStatus.responseTime) {
        responseTimeElement.textContent = `${systemStatus.responseTime}ms`;
    }
    
    // Update database counts
    if (systemStatus.databaseCounts) {
        updateDatabaseCounts(systemStatus.databaseCounts);
    }
    
    // Update current user info
    if (systemStatus.currentUser) {
        updateCurrentUserInfo(systemStatus.currentUser);
    }
}

/**
 * Update status indicator elements
 */
function updateStatusIndicator(elementId, status) {
    const element = document.getElementById(elementId);
    if (!element) return;
    
    // Remove existing status classes
    element.classList.remove('status-online', 'status-offline', 'status-error', 'status-unknown');
    
    // Add appropriate status class
    switch (status) {
        case 'online':
        case 'connected':
        case 'ready':
            element.classList.add('status-online');
            element.textContent = 'Online';
            break;
        case 'offline':
            element.classList.add('status-offline');
            element.textContent = 'Offline';
            break;
        case 'error':
            element.classList.add('status-error');
            element.textContent = 'Error';
            break;
        default:
            element.classList.add('status-unknown');
            element.textContent = 'Unknown';
    }
}

/**
 * Update database counts display
 */
function updateDatabaseCounts(counts) {
    const countsContainer = document.getElementById('database-counts');
    if (!countsContainer) return;
    
    const countItems = [
        { key: 'users', label: 'Users', icon: 'fas fa-users' },
        { key: 'profiles', label: 'Profiles', icon: 'fas fa-user-circle' },
        { key: 'achievements', label: 'Achievements', icon: 'fas fa-trophy' },
        { key: 'events', label: 'Events', icon: 'fas fa-calendar' },
        { key: 'showcases', label: 'Showcases', icon: 'fas fa-star' }
    ];
    
    countsContainer.innerHTML = countItems.map(item => `
        <div class="count-item">
            <i class="${item.icon}"></i>
            <span class="count-label">${item.label}</span>
            <span class="count-value">${counts[item.key] || 0}</span>
        </div>
    `).join('');
}

/**
 * Update current user info display
 */
function updateCurrentUserInfo(user) {
    const userInfoContainer = document.getElementById('current-user-info');
    if (!userInfoContainer) return;
    
    userInfoContainer.innerHTML = `
        <div class="user-info-item">
            <i class="fas fa-envelope"></i>
            <span>${user.email || 'Unknown'}</span>
        </div>
        <div class="user-info-item">
            <i class="fas fa-user-tag"></i>
            <span>${user.role || 'Unknown'}</span>
        </div>
    `;
}

/**
 * Create test data via backend API
 */
export async function createTestData() {
    try {
        addNotification('Creating test data...', 'info');
        
        const response = await makeAuthenticatedRequest(
            API_ENDPOINTS.system.createTestData,
            { method: 'POST' }
        );
        
        if (response && response.status === 'completed') {
            addNotification(
                `Test data created successfully! ${response.message}`,
                'success'
            );
            
            // Refresh system status to show updated counts
            await checkSystemStatus();
            
            return response;
        } else {
            throw new Error('Invalid response from backend');
        }
        
    } catch (error) {
        console.error('Error creating test data:', error);
        addNotification(`Failed to create test data: ${error.message}`, 'error');
        throw error;
    }
}

/**
 * Get current user information from backend
 */
export async function getCurrentUserInfo() {
    try {
        const response = await makeAuthenticatedRequest(API_ENDPOINTS.system.userInfo);
        
        if (response) {
            return {
                firebase: response.firebase_user,
                database: response.database_user
            };
        }
        
        return null;
        
    } catch (error) {
        console.error('Error getting user info:', error);
        throw error;
    }
}

/**
 * Test backend connectivity and show results
 */
export async function testBackendConnectivity() {
    try {
        addNotification('Testing backend connectivity...', 'info');
        
        const startTime = performance.now();
        const isConnected = await testBackendConnection();
        const responseTime = Math.round(performance.now() - startTime);
        
        if (isConnected) {
            addNotification(
                `Backend is online (${responseTime}ms response time)`,
                'success'
            );
            
            // Get additional system info
            await checkSystemStatus();
        } else {
            addNotification('Backend is offline or unreachable', 'error');
        }
        
        return { isConnected, responseTime };
        
    } catch (error) {
        console.error('Error testing backend connectivity:', error);
        addNotification(`Connectivity test failed: ${error.message}`, 'error');
        throw error;
    }
}

/**
 * Cleanup monitoring resources
 */
export function cleanupSystemMonitoring() {
    if (monitoringInterval) {
        clearInterval(monitoringInterval);
        monitoringInterval = null;
    }
    
    // System monitoring cleanup completed
}

/**
 * Get current system status
 */
export function getSystemStatus() {
    return { ...systemStatus };
}

/**
 * Force refresh system status
 */
export async function refreshSystemStatus() {
    try {
        addNotification('Refreshing system status...', 'info');
        const status = await checkSystemStatus();
        addNotification('System status refreshed', 'success');
        return status;
    } catch (error) {
        addNotification('Failed to refresh system status', 'error');
        throw error;
    }
}