// Fallback to working version while fixing OOP imports
import { initializeComponents } from './core/component-loader.js';
import { testBackendConnection, makeAuthenticatedRequest, API_ENDPOINTS, BACKEND_CONFIG } from './config/backend-config.js';
import { auth } from './config/supabase-config.js';
import { initializeSystemMonitoring, checkSystemStatus, createTestData, testBackendConnectivity } from './features/system-monitoring.js';
import { setupNavigation, updateActiveNav, setupUserModals, setupDarkModeToggle, removeNotification, changeTheme, toggleReducedMotion, toggleHighContrast, saveSettings, resetSettings, changePassword } from './ui/notifications.js';
import { setupUserFilters, loadUsersTable, showAddUserModal, toggleDepartmentField, toggleEditDepartmentField, showEditUserModal, handleAddUser, handleEditUser, deleteUser, cleanup as cleanupUsers } from './features/users/users.js';
import { setupEventsSection, loadEventsTable, showAddEventModal, showEditEventModal, handleAddEvent, handleEditEvent, deleteEvent, cleanup as cleanupEvents } from './features/events/events.js';
import { loadOverviewStats, refreshOverviewStats, setupAnalytics, generateReport, generateCustomChart, exportToCSV, refreshChart, cleanupAnalytics } from './features/analytics.js';
import { AIAssistantService } from './services/AIAssistantService.js';

const aiState = {
    enabled: Boolean(BACKEND_CONFIG && BACKEND_CONFIG.baseUrl),
    processing: false,
    elements: {},
    defaultMessage: null,
};

async function bootDashboard() {
    await initializeApp();
}

async function setupAIAssistant() {
    // Setup floating AI chat instead of panel
    const floatingButton = document.getElementById('floating-ai-button');
    const floatingModal = document.getElementById('floating-ai-modal');
    
    if (!floatingButton || !floatingModal) {
        return;
    }

    aiState.elements = {
        // Floating AI elements
        floatingButton,
        floatingModal,
        messages: document.getElementById('floating-ai-messages'),
        form: document.getElementById('floating-ai-form'),
        input: document.getElementById('floating-ai-input'),
        sendBtn: document.getElementById('floating-ai-send'),
        status: document.getElementById('floating-ai-status'),
        quota: document.getElementById('floating-ai-quota'),
        closeBtn: document.getElementById('floating-ai-close'),
        // Legacy elements for compatibility
        panel: document.getElementById('ai-assistant'),
        indicator: document.getElementById('ai-assistant-indicator'),
        clearHistory: null, // Not needed in floating version
    };

    aiState.defaultMessage = aiState.elements.messages?.innerHTML ?? '';

    if (!aiState.enabled) {
        // Disable floating AI when backend not configured
        aiState.elements.floatingButton.style.opacity = '0.5';
        aiState.elements.floatingButton.title = 'AI Assistant (Backend required)';
        if (aiState.elements.input) {
            aiState.elements.input.disabled = true;
            aiState.elements.input.placeholder = 'Configure backend baseUrl untuk aktifkan AI assistant.';
        }
        if (aiState.elements.sendBtn) {
            aiState.elements.sendBtn.disabled = true;
        }
        setAIStatus('Backend belum dikonfigurasi');
        return;
    }

    // Hide original AI panel and enable floating AI
    document.body.classList.add('floating-ai-active');
    
    // Setup floating AI interactions
    setupFloatingAIInteractions();
    updateAIQuota(AIAssistantService.getQuota());

    if (aiState.elements.form) {
        aiState.elements.form.addEventListener('submit', handleAIFormSubmit);
    }

    // Auto-resize textarea
    if (aiState.elements.input) {
        aiState.elements.input.addEventListener('input', autoResizeTextarea);
    }

    await loadAIHistory(false);
}

function setAIIndicator(status, text) {
    const indicator = aiState.elements.indicator;
    if (!indicator) return;

    indicator.classList.remove('online', 'offline');
    indicator.classList.add(status === 'online' ? 'online' : 'offline');
    const statusSpan = indicator.querySelector('.status');
    if (statusSpan) {
        statusSpan.textContent = text ?? (status === 'online' ? 'Online' : 'Offline');
    }
}

function setAIStatus(message) {
    if (aiState.elements.status) {
        aiState.elements.status.textContent = message;
    }
}

function updateAIQuota(quota) {
    if (!quota || !aiState.elements.quota) return;
    const used = quota.quotaUsed ?? quota.used ?? 0;
    const limit = quota.quotaLimit ?? quota.limit ?? 50;
    aiState.elements.quota.textContent = `Quota: ${used}/${limit}`;
}

async function handleAIFormSubmit(event) {
    event.preventDefault();

    if (!aiState.enabled || aiState.processing) {
        return;
    }

    const command = aiState.elements.input?.value.trim();
    if (!command) {
        setAIStatus('Sila masukkan arahan.');
        return;
    }

    aiState.processing = true;
    setAIStatus('Processing...');
    toggleAIInput(true);

    appendAIMessage({ role: 'user', message: command });
    showTypingIndicator();

    try {
        const response = await AIAssistantService.sendCommand(command);
        hideTypingIndicator();
        updateAIQuota(AIAssistantService.getQuota());
        appendAIResponse(response);
        aiState.elements.input.value = '';
        setAIStatus('Siap untuk membantu! ✨');
        
        // Auto-resize textarea after clearing
        autoResizeTextarea();
    } catch (error) {
        hideTypingIndicator();
        console.error('AI command failed:', error);
        appendAIMessage({
            role: 'assistant',
            message: 'Maaf, arahan gagal diproses.',
            error: error.message || 'Unknown error',
        });
        setAIStatus('AI gagal respon. Cuba lagi atau semak sambungan backend.');
    } finally {
        aiState.processing = false;
        toggleAIInput(false);
    }
}

function toggleAIInput(disabled) {
    if (aiState.elements.input) {
        aiState.elements.input.disabled = disabled;
    }
    if (aiState.elements.sendBtn) {
        aiState.elements.sendBtn.disabled = disabled;
        aiState.elements.sendBtn.classList.toggle('disabled', disabled);
    }
}

// Removed filterTechnicalDetails function - no longer needed since we hide all JSON data

function setupFloatingAIInteractions() {
    const { floatingButton, floatingModal, closeBtn } = aiState.elements;
    
    // Toggle modal visibility
    floatingButton.addEventListener('click', () => {
        const isVisible = floatingModal.classList.contains('show');
        if (isVisible) {
            hideFloatingAI();
        } else {
            showFloatingAI();
        }
    });
    
    // Close modal
    closeBtn.addEventListener('click', hideFloatingAI);
    
    // Close on outside click
    document.addEventListener('click', (e) => {
        if (!floatingModal.contains(e.target) && !floatingButton.contains(e.target)) {
            if (floatingModal.classList.contains('show')) {
                hideFloatingAI();
            }
        }
    });
    
    // Close on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && floatingModal.classList.contains('show')) {
            hideFloatingAI();
        }
    });
}

function showFloatingAI() {
    const { floatingModal, floatingButton, input } = aiState.elements;
    
    floatingModal.classList.add('show');
    floatingButton.classList.remove('pulse');
    
    // Focus input after animation
    setTimeout(() => {
        if (input && !input.disabled) {
            input.focus();
        }
    }, 300);
}

function hideFloatingAI() {
    const { floatingModal, floatingButton } = aiState.elements;
    
    floatingModal.classList.remove('show');
    floatingButton.classList.add('pulse');
}

function autoResizeTextarea() {
    const textarea = aiState.elements.input;
    if (!textarea) return;
    
    textarea.style.height = 'auto';
    const newHeight = Math.min(textarea.scrollHeight, 80); // Max 80px
    textarea.style.height = newHeight + 'px';
}

function showTypingIndicator() {
    const container = aiState.elements.messages;
    if (!container) return;
    
    const typingDiv = document.createElement('div');
    typingDiv.id = 'ai-typing-indicator';
    typingDiv.classList.add('floating-ai-typing');
    typingDiv.innerHTML = `
        <div class="floating-ai-message-avatar">
            <i class="fas fa-robot"></i>
        </div>
        <div class="floating-ai-typing-dots">
            <div class="floating-ai-typing-dot"></div>
            <div class="floating-ai-typing-dot"></div>
            <div class="floating-ai-typing-dot"></div>
        </div>
    `;
    
    container.appendChild(typingDiv);
    container.scrollTop = container.scrollHeight;
}

function hideTypingIndicator() {
    const typingIndicator = document.getElementById('ai-typing-indicator');
    if (typingIndicator) {
        typingIndicator.remove();
    }
}

// Markdown parser untuk format AI responses
function parseMarkdown(text) {
    if (!text) return '';
    
    // Escape HTML to prevent XSS
    let html = text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
    
    // Convert markdown to HTML
    // Bold: **text** or __text__
    html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/__(.+?)__/g, '<strong>$1</strong>');
    
    // Italic: *text* or _text_
    html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');
    html = html.replace(/_(.+?)_/g, '<em>$1</em>');
    
    // Code: `code`
    html = html.replace(/`(.+?)`/g, '<code>$1</code>');
    
    // Line breaks: \n\n -> <br><br>, \n -> <br>
    html = html.replace(/\n\n/g, '<br><br>');
    html = html.replace(/\n/g, '<br>');
    
    // Links: [text](url)
    html = html.replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
    
    return html;
}

function appendAIMessage({ role, message, source, steps, data, error }) {
    const container = aiState.elements.messages;
    if (!container) return;

    const wrapper = document.createElement('div');
    wrapper.classList.add('floating-ai-message');
    wrapper.classList.add(role === 'user' ? 'floating-ai-message-user' : 'floating-ai-message-assistant');

    const avatar = document.createElement('div');
    avatar.classList.add('floating-ai-message-avatar');
    avatar.innerHTML = `<i class="fas ${role === 'user' ? 'fa-user' : 'fa-robot'}"></i>`;

    const content = document.createElement('div');
    content.classList.add('floating-ai-message-content');

    // Hide technical source information from users
    // if (source) {
    //     const meta = document.createElement('small');
    //     meta.textContent = `Source: ${source}`;
    //     meta.style.display = 'block';
    //     meta.style.marginBottom = '0.25rem';
    //     meta.style.color = 'var(--text-muted)';
    //     content.appendChild(meta);
    // }

    const paragraph = document.createElement('div');
    // Use innerHTML with parsed markdown for assistant, textContent for user
    if (role === 'assistant') {
        paragraph.innerHTML = parseMarkdown(message);
    } else {
        paragraph.textContent = message;
        // Force white color for user messages (backup)
        paragraph.style.color = 'white';
        paragraph.style.fontWeight = '500';
    }
    content.appendChild(paragraph);

    if (error) {
        const err = document.createElement('small');
        err.style.color = 'var(--danger-strong)';
        err.textContent = error;
        content.appendChild(err);
    }

    if (steps && steps.length) {
        // Filter out technical steps that users don't need to see
        const userRelevantSteps = steps.filter(step => {
            const label = (step.label || '').toLowerCase();
            const detail = (step.detail || '').toLowerCase();
            
            // Skip technical model information
            return !label.includes('openrouter') && 
                   !detail.includes('qwen') && 
                   !detail.includes('free') &&
                   !detail.includes('model') &&
                   label !== 'openrouter';
        });
        
        if (userRelevantSteps.length > 0) {
            const stepList = document.createElement('div');
            stepList.classList.add('ai-message-steps');
            const list = document.createElement('ol');
            for (const step of userRelevantSteps) {
                const item = document.createElement('li');
                const label = step.label ? `${step.label}` : 'Step';
                if (step.detail) {
                    item.innerHTML = `<strong>${label}:</strong> ${step.detail}`;
                } else {
                    item.textContent = label;
                }
                list.appendChild(item);
            }
            stepList.appendChild(list);
            content.appendChild(stepList);
        }
    }

    // Completely hide all JSON data display - users only need clean text responses
    // if (data) {
    //     // Filter out technical details - only show user-relevant data
    //     const filteredData = filterTechnicalDetails(data);
    //     if (filteredData && Object.keys(filteredData).length > 0) {
    //         const dataBlock = document.createElement('pre');
    //         dataBlock.classList.add('ai-message-json');
    //         dataBlock.textContent = typeof filteredData === 'string' ? filteredData : JSON.stringify(filteredData, null, 2);
    //         content.appendChild(dataBlock);
    //     }
    // }

    wrapper.appendChild(role === 'user' ? content : avatar);
    wrapper.appendChild(role === 'user' ? avatar : content);

    container.appendChild(wrapper);
    container.scrollTop = container.scrollHeight;
}

function appendAIResponse(response) {
    if (!response) return;

    appendAIMessage({
        role: 'assistant',
        message: response.message || 'Completed.',
        source: response.source,
        steps: response.steps,
        data: response.data,
        error: !response.success && response.data?.error ? response.data.error : undefined,
    });
}

async function loadAIHistory(forceRefresh = false) {
    if (!aiState.enabled) {
        return;
    }

    try {
        const { history } = await AIAssistantService.getHistory(10);
        const container = aiState.elements.messages;
        if (!container) return;

        container.innerHTML = aiState.defaultMessage || '';

        if (Array.isArray(history) && history.length) {
            for (const entry of history.reverse()) {
                if (entry.command) {
                    appendAIMessage({ role: 'user', message: entry.command });
                }
                if (entry.response) {
                    const resp = entry.response;
                    appendAIMessage({
                        role: 'assistant',
                        message: resp.message || 'Completed.',
                        source: resp.source,
                        steps: resp.steps,
                        data: resp.data,
                        error: !resp.success && resp.data?.error ? resp.data.error : undefined,
                    });
                }
            }
            setAIStatus(forceRefresh ? 'History refreshed.' : 'History loaded.');
        } else if (forceRefresh) {
            setAIStatus('History kosong.');
        }
    } catch (error) {
        console.warn('Failed to load AI history:', error);
        setAIStatus('Gagal load history.');
    }
}

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
    //     window.addSampleData = () => module.SampleDataGenerator.addSampleDataToBackend();
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
}

async function initializeApp() {
    setupNavigation(navigateToSection);
    setupUserModals(handleAddUser, handleEditUser);
    setupDarkModeToggle();
    setupEventsSection();
    setupAnalytics();
    await setupAIAssistant();

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
    if (section === 'student-claiming') {
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

// Theme initialization function
function initializeTheme() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    const themeSelect = document.getElementById('theme-select');
    const html = document.documentElement;
    
    // Apply saved theme
    html.setAttribute('data-theme', savedTheme);
    
    // Update theme selector if it exists
    if (themeSelect) {
        themeSelect.value = savedTheme;
    }
    
    // Listen for system theme changes
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQuery.addEventListener('change', (e) => {
        if (localStorage.getItem('theme') === 'auto') {
            const newTheme = e.matches ? 'dark' : 'light';
            html.setAttribute('data-theme', newTheme);
        }
    });
    
    console.log(`🎨 Theme initialized: ${savedTheme}`);
}

// Global modal control functions (renamed to avoid conflicts)
function closeModalCustom(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'none';
        modal.style.visibility = 'hidden';
        modal.style.opacity = '0';
        modal.classList.remove('show');
        console.log(`✅ Modal ${modalId} closed`);
    }
}

function openModalCustom(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        modal.classList.add('show');
        console.log(`✅ Modal ${modalId} opened`);
    }
}

// Hide all modals function
function hideAllModals() {
    const modalIds = [
        'add-user-modal',
        'edit-user-modal', 
        'add-event-modal',
        'edit-event-modal',
        'add-achievement-modal',
        'edit-achievement-modal',
        'delete-achievement-modal'
    ];
    
    modalIds.forEach(modalId => {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.style.display = 'none';
            modal.style.visibility = 'hidden';
            modal.style.opacity = '0';
            modal.classList.remove('show');
        }
    });
    
    console.log('✅ All modals hidden');
}

// Logout function
async function logout() {
    if (confirm('Are you sure you want to logout?')) {
        try {
            // Check if Supabase is properly configured before attempting sign out
            if (auth && typeof auth.signOut === 'function') {
                const { error } = await auth.signOut();
                if (error && error.code === 'SUPABASE_NOT_CONFIGURED') {
                    console.warn('Supabase not configured, clearing local session only');
                } else if (error) {
                    console.error('Error during logout:', error);
                }
            }
        } catch (error) {
            console.error('Logout error:', error);
        }
        window.location.href = 'login.html';
    }
}

// Close and cleanup modal function
function closeAndCleanupModalCustom(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'none';
        modal.style.visibility = 'hidden';
        modal.style.opacity = '0';
        modal.classList.remove('show');
        
        // Clear form data if it's a form modal
        const form = modal.querySelector('form');
        if (form) {
            form.reset();
        }
        
        console.log(`✅ Modal ${modalId} closed and cleaned up`);
    }
}

// Make functions globally available (use existing ones if they exist)
if (!window.closeModal) {
    window.closeModal = closeModalCustom;
}
if (!window.openModal) {
    window.openModal = openModalCustom;
}
if (!window.logout) {
    window.logout = logout;
}
if (!window.closeAndCleanupModal) {
    window.closeAndCleanupModal = closeAndCleanupModalCustom;
}
window.hideAllModals = hideAllModals;

// Single, consolidated DOMContentLoaded listener
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🚀 Initializing UTHM Talent Profiling Dashboard...');
    
    initializeTheme();
    
    try {
        // Check if Supabase is properly configured before attempting auth
        if (!auth || typeof auth.getSession !== 'function') {
            console.error('❌ Supabase auth not properly initialized');
            alert('Application not properly configured. Please contact system administrator.');
            return;
        }

        const { data, error } = await auth.getSession();

        if (error) {
            console.error('Supabase getSession error:', error.message);
            console.log('🔄 Redirecting to login due to error...');
            
            // Prevent infinite redirect loop by checking current page
            if (!window.location.href.includes('login.html')) {
                window.location.href = 'login.html';
            }
            return;
        }

        console.log('📊 Dashboard session data:', data);
        if (data?.session?.user) {
            console.log('✅ User is authenticated. Booting dashboard...');
            await initializeComponents();
            await bootDashboard();
        } else {
            console.log('🔒 User not authenticated, redirecting to login...');
            console.log('🔄 Redirecting to login due to no session...');
            
            // Prevent infinite redirect loop by checking current page
            if (!window.location.href.includes('login.html')) {
                window.location.href = 'login.html';
            }
            return;
        }

        // Listen for auth state changes (only if not already set up)
        if (!window.__authStateChangeListenerSetup) {
            auth.onAuthStateChange((_event, session) => {
                if (!session?.user) {
                    console.log('🔒 Session expired or user logged out, redirecting to login...');
                    
                    // Prevent infinite redirect loop by checking current page
                    if (!window.location.href.includes('login.html')) {
                        window.location.href = 'login.html';
                    }
                }
            });
            
            window.__authStateChangeListenerSetup = true;
        }

    } catch (error) {
        console.error('🚨 Dashboard initialization failed:', error);
        
        // Prevent infinite redirect loop by checking current page
        if (!window.location.href.includes('login.html')) {
            window.location.href = 'login.html';
        }
    }
});
