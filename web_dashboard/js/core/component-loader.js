// ===== COMPONENT LOADER UTILITY =====
// Dynamically loads HTML components to keep main file clean

/**
 * Loads an HTML component and injects it into the specified container
 * @param {string} componentPath - Path to the component HTML file
 * @param {string} containerId - ID of the container to inject the component
 * @returns {Promise<void>}
 */
async function loadComponent(componentPath, containerId = 'body') {
    try {
        const response = await fetch(componentPath);
        if (!response.ok) {
            throw new Error(`Failed to load component: ${componentPath}`);
        }
        
        const html = await response.text();
        
        // Find the container element
        const container = containerId === 'body' 
            ? document.body 
            : document.getElementById(containerId);
            
        if (!container) {
            throw new Error(`Container element not found: ${containerId}`);
        }
        
        // Inject the HTML
        container.insertAdjacentHTML('beforeend', html);
        
        // Component loaded successfully
        
    } catch (error) {
        console.error(`❌ Error loading component ${componentPath}:`, error);
    }
}

/**
 * Loads multiple components in parallel
 * @param {Array<{path: string, container?: string}>} components - Array of component configurations
 * @returns {Promise<void>}
 */
async function loadComponents(components) {
    const loadPromises = components.map(component => 
        loadComponent(component.path, component.container || 'body')
    );
    
    try {
        await Promise.all(loadPromises);
        // All components loaded successfully
    } catch (error) {
        console.error('❌ Error loading some components:', error);
    }
}

/**
 * Loads all modal components
 * @returns {Promise<void>}
 */
async function loadModalComponents() {
    const modalComponents = [
        { path: './modals/add-user-modal.html' },
        { path: './modals/edit-user-modal.html' },
        { path: './modals/add-event-modal.html' },
        { path: './modals/edit-event-modal.html' }
    ];
    
    await loadComponents(modalComponents);
    
    // FORCE HIDE ALL MODALS AFTER LOADING
    setTimeout(() => {
        const modalIds = [
            'add-user-modal',
            'edit-user-modal', 
            'add-event-modal',
            'edit-event-modal'
        ];
        
        modalIds.forEach(modalId => {
            const modal = document.getElementById(modalId);
            if (modal) {
                modal.style.display = 'none';
                modal.style.visibility = 'hidden';
                modal.style.opacity = '0';
                modal.classList.remove('show');
                console.log(`✅ Modal ${modalId} properly hidden`);
            }
        });
        
        console.log('✅ All modals properly hidden after loading');
    }, 100);
}

/**
 * Initialize component loading on page load
 */
function initializeComponents() {
    // Load modal components when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', loadModalComponents);
    } else {
        loadModalComponents();
    }
}

// Export functions for use in other modules
export { 
    loadComponent, 
    loadComponents, 
    loadModalComponents, 
    initializeComponents 
};