// Supabase integration - using backend API instead
import { auth } from '../config/supabase-config.js';

let notifications = [];

function setupNavigation(navigateToSection) {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', function() {
            const section = this.getAttribute('data-section');
            navigateToSection(section);
        });
    });

    const menuToggle = document.getElementById('menu-toggle');
    if (menuToggle) {
        menuToggle.addEventListener('click', () => {
            document.querySelector('.sidebar').classList.toggle('open');
        });
    }

    // Setup global modal click-outside-to-close functionality
    setupModalClickOutside();
}

// Setup click outside modal to close functionality
function setupModalClickOutside() {
    document.addEventListener('click', (event) => {
        // Check if click is on a modal backdrop
        if (event.target.classList.contains('modal') && event.target.classList.contains('show')) {
            const modalId = event.target.id;
            if (modalId) {
                // Use enhanced cleanup for dynamic modals
                if (isDynamicModal(modalId)) {
                    closeAndCleanupModal(modalId);
                } else {
                    closeModal(modalId);
                }
            }
        }
    });
}

function updateActiveNav(section) {
    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    const activeItem = document.querySelector(`[data-section="${section}"]`);
    if (activeItem) {
        activeItem.classList.add('active');
    }
    document.querySelectorAll('.content-section').forEach(sec => sec.classList.remove('active'));
    const activeSection = document.getElementById(section);
    if (activeSection) {
        activeSection.classList.add('active');
    }
    const titles = {
        'overview': 'Dashboard Overview',
        'users': 'User Management',
        'analytics': 'Analytics & Reports',
        'settings': 'System Settings',
        'events': 'Events'
    };
    document.getElementById('page-title').textContent = titles[section] || '';
}

function setupUserModals(handleAddUser, handleEditUser) {
    const addUserForm = document.getElementById('add-user-form');
    if (addUserForm) {
        addUserForm.addEventListener('submit', (event) => {
            event.preventDefault();
            handleAddUser(event.target);
        });
    }

    const editUserForm = document.getElementById('edit-user-form');
    if (editUserForm) {
        editUserForm.addEventListener('submit', (event) => {
            event.preventDefault();
            handleEditUser(event.target);
        });
    }
}

function setupDarkModeToggle() {
    const toggle = document.getElementById('dark-mode-toggle');
    if (toggle) {
        toggle.addEventListener('change', function() {
            document.body.classList.toggle('dark-mode', this.checked);
            localStorage.setItem('darkMode', this.checked);
        });

        const savedMode = localStorage.getItem('darkMode') === 'true';
        toggle.checked = savedMode;
        document.body.classList.toggle('dark-mode', savedMode);
    }
}

function addNotification(message, type = 'info') {
    notifications.push({ message, type, id: Date.now() });
    renderNotifications();
}

function renderNotifications() {
    const container = document.getElementById('notifications');
    if (!container) return;

    container.innerHTML = notifications.map(notification => `
        <div class="notification notification-${notification.type}">
            ${notification.message}
            <button onclick="removeNotification(${notification.id})">&times;</button>
        </div>
    `).join('');
}

function removeNotification(id) {
    notifications = notifications.filter(n => n.id !== id);
    renderNotifications();
}

function closeModal(id) {
    const modal = document.getElementById(id);
    if(modal) {
        modal.style.display = 'none';
        modal.classList.remove('show');

        // Clean up dynamically created modals
        if (isDynamicModal(id)) {
            // Add a small delay to allow for animations
            setTimeout(() => {
                if (modal.parentNode) {
                    modal.parentNode.removeChild(modal);
                }
            }, 300);
        }
    }
}

// Helper function to identify dynamically created modals
function isDynamicModal(id) {
    const dynamicModalIds = [
        'qr-codes-modal'
    ];
    return dynamicModalIds.includes(id);
}

// Enhanced modal management for dynamic modals
function closeAndCleanupModal(id) {
    console.log('closeAndCleanupModal called for:', id);
    const modal = document.getElementById(id);
    if (modal) {
        console.log('Modal found, cleaning up:', id);

        // Hide modal immediately
        modal.style.display = 'none';
        modal.classList.remove('show');

        // Remove event listeners to prevent memory leaks
        const forms = modal.querySelectorAll('form');
        forms.forEach(form => {
            // Clone and replace to remove all event listeners
            const newForm = form.cloneNode(true);
            form.parentNode.replaceChild(newForm, form);
        });

        // Remove from DOM if it's a dynamic modal
        if (isDynamicModal(id)) {
            console.log('Removing dynamic modal from DOM:', id);
            setTimeout(() => {
                if (modal.parentNode) {
                    modal.parentNode.removeChild(modal);
                    console.log('Dynamic modal removed from DOM:', id);
                }
            }, 300);
        }
    } else {
        console.log('Modal not found for cleanup:', id);
    }
}

function logout() {
    auth.signOut().then(() => {
        localStorage.removeItem('currentUser');
        localStorage.removeItem('isLoggedIn');
        window.location.href = 'login.html';
    }).catch((error) => {
        console.error('Error signing out:', error);
    });
}

// Settings functionality
function changeTheme(theme) {
    const html = document.documentElement;
    const themeSelect = document.getElementById('theme-select');
    
    if (theme === 'auto') {
        const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        theme = systemPrefersDark ? 'dark' : 'light';
    }
    
    // Apply theme with smooth transition
    html.style.transition = 'background-color 0.3s ease, color 0.3s ease';
    html.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
    
    // Update theme selector
    if (themeSelect) {
        themeSelect.value = theme;
    }
    
    // Update charts if they exist
    if (typeof updateChartsTheme === 'function') {
        updateChartsTheme(theme);
    }
    
    // Remove transition after animation
    setTimeout(() => {
        html.style.transition = '';
    }, 300);
    
    addNotification(`Switched to ${theme} mode`, 'success');
}

function toggleReducedMotion(enabled) {
    const html = document.documentElement;
    
    if (enabled) {
        html.setAttribute('data-motion', 'reduced');
    } else {
        html.removeAttribute('data-motion');
    }
    
    localStorage.setItem('reducedMotion', enabled);
    addNotification(`Motion ${enabled ? 'reduced' : 'enabled'}`, 'success');
}

function toggleHighContrast(enabled) {
    const html = document.documentElement;
    
    if (enabled) {
        html.setAttribute('data-contrast', 'high');
    } else {
        html.removeAttribute('data-contrast');
    }
    
    localStorage.setItem('highContrast', enabled);
    addNotification(`High contrast ${enabled ? 'enabled' : 'disabled'}`, 'success');
}

function saveSettings() {
    addNotification('Settings saved successfully', 'success');
}

function resetSettings() {
    if (confirm('Are you sure you want to reset all settings to default?')) {
        changeTheme('light');
        toggleReducedMotion(false);
        toggleHighContrast(false);
        addNotification('Settings reset to default', 'success');
    }
}

function changePassword() {
    addNotification('Password change functionality will be implemented soon', 'info');
}

export {
    setupNavigation,
    updateActiveNav,
    setupUserModals,
    setupDarkModeToggle,
    addNotification,
    removeNotification,
    closeModal,
    closeAndCleanupModal,
    logout,
    changeTheme,
    toggleReducedMotion,
    toggleHighContrast,
    saveSettings,
    resetSettings,
    changePassword
};