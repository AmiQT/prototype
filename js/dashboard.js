/**
 * Main Dashboard Application
 * Handles navigation, data loading, and UI interactions
 */

import { initializeComponents } from './core/component-loader.js';
import { testBackendConnection, makeAuthenticatedRequest, API_ENDPOINTS } from './config/backend-config.js';
// import { auth } from './config/supabase-config.js'; // Temporarily disabled
import { initializeSystemMonitoring, checkSystemStatus, createTestData, testBackendConnectivity } from './features/system-monitoring.js';
import { setupNavigation, updateActiveNav, setupUserModals, setupDarkModeToggle, closeModal, closeAndCleanupModal, logout, removeNotification, changeTheme, toggleReducedMotion, toggleHighContrast, saveSettings, resetSettings, changePassword } from './ui/notifications.js';
import { setupUserFilters, loadUsersTable, showAddUserModal, toggleDepartmentField, toggleEditDepartmentField, showEditUserModal, handleAddUser, handleEditUser, deleteUser, unsubscribeUsers } from './features/users/users.js';
import { setupEventsSection, loadEventsTable, showAddEventModal, showEditEventModal, handleAddEvent, handleEditEvent, deleteEvent } from './features/events/events.js';
import { loadOverviewStats, refreshOverviewStats, setupAnalytics, generateReport, generateCustomChart, exportToCSV, refreshChart, cleanupAnalytics } from './features/analytics.js';

// Import test functions in development
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    // All test imports disabled for cleaner console
    
    // Ultimate fallback functions
    window.runConsoleCleanupTest = () => {
        // Console cleanup test - disabled for cleaner console
    };

    // Chart test disabled for cleaner console
    // import('./tests/chart-test.js').then(module => {
    //     window.testCharts = module.ChartTester.testChartsWithSampleData;
    //     window.checkCharts = module.ChartTester.testChartVisibility;
    // }).catch(error => {
    //     console.log('Chart test functions not available:', error.message);
    // });

    // Sample data generator disabled for cleaner console
    // import('./utils/sample-data-generator.js').then(module => {
    //     window.addSampleData = () => module.SampleDataGenerator.addSampleDataToSupabase();
    //     window.getSampleData = () => module.SampleDataGenerator.getSampleDataSet();
    // }).catch(() => {
    //     // Fallback sample data functions
    //     window.addSampleData = () => {
    //         console.log('⚠️ Sample data generator not available');
    //         console.log('ℹ️ Charts will show with fallback sample data when empty');
    //     };
    //     window.getSampleData = () => ({ message: 'Sample data generator not available' });
    // });
    // Fallback sample data functions (disabled for cleaner console)
    window.addSampleData = () => {
        // Sample data generator not available
    };
    window.getSampleData = () => ({ message: 'Sample data generator not available' });

    // Data cleanup utility disabled for cleaner console
    // import('./utils/data-cleanup.js').then(module => {
    //     window.clearSampleData = () => module.DataCleanup.clearSampleData();
    //     window.countDocuments = () => module.DataCleanup.countDocuments();
    //     window.listSampleData = () => module.DataCleanup.listSampleData();
    // }).catch(() => {
    //     window.clearSampleData = () => {
    //         console.log('⚠️ Data cleanup utility not available');
    //     };
    // });
    window.clearSampleData = () => {
        // Data cleanup utility not available
    };

// Make navigateToSection available immediately to prevent errors
window.navigateToSection = function(section) {
    console.log('navigateToSection called before initialization:', section);
    // This will be replaced with the real function when the app initializes
};

document.addEventListener('DOMContentLoaded', function() {
    // Initialize components first
    initializeComponents();
    
    // Then initialize auth
    // auth.onAuthStateChange((event, session) => { // Temporarily disabled
    //     if (session && session.user) {
    //         initializeApp();
    //     } else {
    //         window.location.href = 'login.html';
    //     }
    // });
    initializeApp(); // Temporarily initialize app without auth
});

async function initializeApp() {
    setupNavigation(navigateToSection);
    setupUserModals(handleAddUser, handleEditUser);
    setupDarkModeToggle();
    setupEventsSection();
    setupAnalytics();

    // Initialize backend integration
    try {
        await initializeSystemMonitoring();
        // Backend integration initialized
    } catch (error) {
        // Backend integration failed, using Supabase fallback
    }

    // Initial section load
    navigateToSection('overview');

    // Make functions globally available
    window.navigateToSection = navigateToSection;
    window.showAddUserModal = showAddUserModal;
    window.showEditUserModal = showEditUserModal;
    window.deleteUser = deleteUser;
    window.showAddEventModal = showAddEventModal;
    window.showEditEventModal = showEditEventModal;
    window.deleteEvent = deleteEvent;

    // Achievement management functions removed
    window.switchStudentTab = switchStudentTab;
    window.generateReport = generateReport;
    window.generateCustomChart = generateCustomChart;
    window.exportToCSV = exportToCSV;
    window.refreshChart = refreshChart;
    window.logout = logout;
    window.closeModal = closeModal;
    window.closeAndCleanupModal = closeAndCleanupModal;
    window.toggleDepartmentField = toggleDepartmentField;
    window.toggleEditDepartmentField = toggleEditDepartmentField;
    window.removeNotification = removeNotification;
    window.changeTheme = changeTheme;
    window.toggleReducedMotion = toggleReducedMotion;
    window.toggleHighContrast = toggleHighContrast;
    window.saveSettings = saveSettings;
    window.resetSettings = resetSettings;
    window.changePassword = changePassword;
    window.downloadQRCode = downloadQRCode;
    window.printQRCode = printQRCode;
    window.testQRCode = testQRCode;
    window.testQRCodeLibrary = testQRCodeLibrary;
    
    // Backend integration functions
    window.checkSystemStatus = checkSystemStatus;
    window.createTestData = createTestData;
    window.testBackendConnectivity = testBackendConnectivity;
    
    // Analytics functions
    window.loadOverviewStats = loadOverviewStats;
    window.refreshOverviewStats = loadOverviewStats; // Alias for backward compatibility
    
}

function navigateToSection(section) {
    updateActiveNav(section);

    // Cleanup previous section resources
    if (section !== 'users' && typeof unsubscribeUsers === 'function') {
        unsubscribeUsers();
    }

    if (section !== 'analytics' && typeof cleanupAnalytics === 'function') {
        cleanupAnalytics();
    }

    // Initialize new section
    if (section === 'overview') {
        loadOverviewStats();
    }
    if (section === 'users') {
        setupUserFilters();
        loadUsersTable();
    }
    if (section === 'analytics') {
        setupAnalytics();
    }
    if (section === 'events') {
        loadEventsTable();
    }
    // Achievements section removed
    if (section === 'student-claiming') {
        // Initialize student badge assignment interface
        // Load all events by default
        loadAllEventsForAssignment();
    }
    if (section === 'settings') {
        // Initialize system monitoring when settings section is accessed
        checkSystemStatus();
    }
}

function switchStudentTab(tabName) {
    // Remove active class from all tabs and panes
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('active'));
    
    // Add active class to selected tab
    const selectedTab = document.querySelector(`[onclick="switchStudentTab('${tabName}')"]`);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }
    
    // Show selected pane
    const selectedPane = document.getElementById(`${tabName}-tab`);
    if (selectedPane) {
        selectedPane.classList.add('active');
    }
    
    // Load data based on tab
    if (tabName === 'available-events') {
        loadAllEventsForAssignment();
    } else if (tabName === 'my-claims') {
        loadStudentClaims();
    }
}

// ===== QR CODE UTILITY FUNCTIONS =====

/**
 * Download QR code as image
 * @param {string} elementId - Element containing QR code
 * @param {string} filename - Filename for download
 */
async function downloadQRCode(elementId, filename = 'qr-code.png') {
    if (window.qrCodeGenerator) {
        await window.qrCodeGenerator.downloadQRCode(elementId, filename);
    } else {
        console.error('QR code generator not available');
    }
}

/**
 * Print QR code
 * @param {string} elementId - Element containing QR code
 */
async function printQRCode(elementId) {
    if (window.qrCodeGenerator) {
        await window.qrCodeGenerator.printQRCode(elementId);
    } else {
        console.error('QR code generator not available');
    }
}

/**
 * Test QR code generation
 */
async function testQRCode() {
    try {
        console.log('Testing QR code generation...');
        
        // Create a test element
        const testElement = document.createElement('div');
        testElement.id = 'test-qr-code';
        testElement.style.width = '200px';
        testElement.style.height = '200px';
        testElement.style.border = '1px solid #ccc';
        testElement.style.margin = '20px';
        document.body.appendChild(testElement);
        
        // Generate test QR code
        const testData = JSON.stringify({
            type: 'test',
            message: 'Hello World',
            timestamp: new Date().toISOString()
        });
        
        await window.qrCodeGenerator.generateQRCode(testData, 'test-qr-code');
        console.log('Test QR code generated successfully!');
        
        // Remove test element after 5 seconds
        setTimeout(() => {
            if (testElement.parentNode) {
                testElement.parentNode.removeChild(testElement);
            }
        }, 5000);
        
    } catch (error) {
        console.error('Test QR code generation failed:', error);
    }
}

/**
 * Test QR code library availability
 */
function testQRCodeLibrary() {
    console.log('=== QR Code Library Test ===');
    console.log('typeof QRCode:', typeof QRCode);
    
    if (typeof QRCode !== 'undefined') {
        console.log('✅ QRCode object is available');
        console.log('QRCode object:', QRCode);
        console.log('QRCode.toCanvas:', typeof QRCode.toCanvas);
        console.log('QRCode.CorrectLevel:', QRCode.CorrectLevel);
        
        if (typeof QRCode.toCanvas === 'function') {
            console.log('✅ QRCode.toCanvas is a function');
        } else {
            console.log('❌ QRCode.toCanvas is not a function');
        }
        
        if (QRCode.CorrectLevel) {
            console.log('✅ QRCode.CorrectLevel is available');
            console.log('QRCode.CorrectLevel.H:', QRCode.CorrectLevel.H);
        } else {
            console.log('❌ QRCode.CorrectLevel is not available');
        }
    } else {
        console.log('❌ QRCode is not defined');
    }
    
    console.log('=== End QR Code Library Test ===');
}

// Close the development imports if block
}
