/**
 * Main Application Controller - Orchestrates all controllers
 * Implements proper MVC architecture with OOP principles
 */
import { UserController } from '../controllers/UserController.js';
import { EventController } from '../controllers/EventController.js';
import { initializeComponents } from './component-loader.js';
import { testBackendConnection } from '../config/backend-config.js';
import { initializeSystemMonitoring } from '../features/system-monitoring.js';
import { setupNavigation, setupDarkModeToggle } from '../ui/notifications.js';

export class AppController {
    constructor() {
        this.userController = new UserController();
        this.eventController = new EventController();
        this.isInitialized = false;
        this.currentSection = 'overview';
        
        // Performance monitoring
        this.performanceMetrics = {
            loadTime: 0,
            apiCalls: 0,
            errors: 0,
            memoryUsage: 0
        };
    }

    // Initialize the entire application
    async initialize() {
        if (this.isInitialized) return;
        
        const startTime = performance.now();
        
        try {
            console.log('🚀 Initializing UTHM Talent Profiling Dashboard...');
            
            // Initialize core components
            await this.initializeCore();
            
            // Initialize controllers
            await this.initializeControllers();
            
            // Setup navigation and UI
            this.setupNavigation();
            
            // Load initial section
            await this.loadSection(this.currentSection);
            
            // Setup performance monitoring
            this.setupPerformanceMonitoring();
            
            this.isInitialized = true;
            this.performanceMetrics.loadTime = performance.now() - startTime;
            
            console.log(`✅ Dashboard initialized successfully in ${this.performanceMetrics.loadTime.toFixed(2)}ms`);
            
        } catch (error) {
            console.error('❌ Failed to initialize dashboard:', error);
            this.handleInitializationError(error);
        }
    }

    // Initialize core components
    async initializeCore() {
        try {
            // Load dynamic components
            await initializeComponents();
            
            // Test backend connection
            const isBackendConnected = await testBackendConnection();
            if (!isBackendConnected) {
                console.warn('⚠️ Backend connection failed, some features may be limited');
            }
            
            // Initialize system monitoring
            await initializeSystemMonitoring();
            
        } catch (error) {
            console.error('Core initialization failed:', error);
            throw error;
        }
    }

    // Initialize all controllers
    async initializeControllers() {
        try {
            // Initialize controllers in parallel for better performance
            await Promise.all([
                this.userController.initialize(),
                this.eventController.initialize()
            ]);
            
            console.log('✅ All controllers initialized');
        } catch (error) {
            console.error('Controller initialization failed:', error);
            throw error;
        }
    }

    // Setup navigation system
    setupNavigation() {
        // Setup basic navigation
        setupNavigation();
        setupDarkModeToggle();
        
        // Setup section navigation
        const navItems = document.querySelectorAll('.nav-item');
        navItems.forEach(item => {
            item.addEventListener('click', (e) => {
                const section = item.getAttribute('data-section');
                if (section) {
                    this.navigateToSection(section);
                }
            });
        });
        
        // Setup global keyboard shortcuts
        this.setupKeyboardShortcuts();
    }

    // Setup keyboard shortcuts for power users
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Only trigger if not in input field
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
            
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case '1':
                        e.preventDefault();
                        this.navigateToSection('overview');
                        break;
                    case '2':
                        e.preventDefault();
                        this.navigateToSection('users');
                        break;
                    case '3':
                        e.preventDefault();
                        this.navigateToSection('events');
                        break;
                    case '4':
                        e.preventDefault();
                        this.navigateToSection('analytics');
                        break;
                    case 'r':
                        e.preventDefault();
                        this.refreshCurrentSection();
                        break;
                }
            }
        });
    }

    // Navigate to a specific section
    async navigateToSection(sectionName) {
        if (this.currentSection === sectionName) return;
        
        try {
            // Update navigation UI
            this.updateNavigationUI(sectionName);
            
            // Load section content
            await this.loadSection(sectionName);
            
            this.currentSection = sectionName;
            
            // Update page title
            this.updatePageTitle(sectionName);
            
        } catch (error) {
            console.error(`Failed to navigate to ${sectionName}:`, error);
        }
    }

    // Load specific section content
    async loadSection(sectionName) {
        // Hide all sections
        const sections = document.querySelectorAll('.content-section');
        sections.forEach(section => section.classList.remove('active'));
        
        // Show target section
        const targetSection = document.getElementById(sectionName);
        if (targetSection) {
            targetSection.classList.add('active');
        }
        
        // Load section-specific data
        switch (sectionName) {
            case 'overview':
                await this.loadOverviewSection();
                break;
            case 'users':
                await this.loadUsersSection();
                break;
            case 'events':
                await this.loadEventsSection();
                break;
            case 'analytics':
                await this.loadAnalyticsSection();
                break;
            case 'settings':
                await this.loadSettingsSection();
                break;
        }
    }

    // Load overview section
    async loadOverviewSection() {
        try {
            // Get statistics from controllers
            const userStats = this.userController.userService.getStatistics();
            const eventStats = this.eventController.eventService.getStatistics();
            
            // Update overview cards
            this.updateOverviewStats(userStats, eventStats);
            
        } catch (error) {
            console.error('Failed to load overview:', error);
        }
    }

    // Load users section
    async loadUsersSection() {
        // Users are automatically loaded by UserController
        // Just ensure the controller is ready
        if (!this.userController.isInitialized) {
            await this.userController.initialize();
        }
    }

    // Load events section
    async loadEventsSection() {
        // Events are automatically loaded by EventController
        // Just ensure the controller is ready
        if (!this.eventController.isInitialized) {
            await this.eventController.initialize();
        }
    }

    // Load analytics section
    async loadAnalyticsSection() {
        // Analytics will be loaded by existing analytics module
        // This is a placeholder for future OOP analytics implementation
    }

    // Load settings section
    async loadSettingsSection() {
        // Settings are mostly static, no special loading needed
    }

    // Update navigation UI
    updateNavigationUI(sectionName) {
        // Remove active class from all nav items
        const navItems = document.querySelectorAll('.nav-item');
        navItems.forEach(item => item.classList.remove('active'));
        
        // Add active class to current nav item
        const activeNavItem = document.querySelector(`[data-section="${sectionName}"]`);
        if (activeNavItem) {
            activeNavItem.classList.add('active');
        }
    }

    // Update page title
    updatePageTitle(sectionName) {
        const titles = {
            overview: 'Dashboard Overview',
            users: 'User Management',
            events: 'Event Management',
            analytics: 'Analytics & Reports',
            settings: 'Settings'
        };
        
        const pageTitle = document.getElementById('page-title');
        if (pageTitle && titles[sectionName]) {
            pageTitle.textContent = titles[sectionName];
        }
    }

    // Update overview statistics
    updateOverviewStats(userStats, eventStats) {
        // Update user stats
        const totalUsersElement = document.getElementById('total-users');
        if (totalUsersElement) {
            totalUsersElement.textContent = userStats.total;
        }
        
        // Update event stats
        const totalEventsElement = document.getElementById('total-events');
        if (totalEventsElement) {
            totalEventsElement.textContent = eventStats.total;
        }
        
        // Update profiles count (same as users for now)
        const totalProfilesElement = document.getElementById('total-profiles');
        if (totalProfilesElement) {
            totalProfilesElement.textContent = userStats.byRole.student || 0;
        }
    }

    // Setup performance monitoring
    setupPerformanceMonitoring() {
        // Monitor memory usage
        if (performance.memory) {
            setInterval(() => {
                this.performanceMetrics.memoryUsage = performance.memory.usedJSHeapSize;
            }, 10000); // Check every 10 seconds
        }
        
        // Monitor API calls
        const originalFetch = window.fetch;
        window.fetch = (...args) => {
            this.performanceMetrics.apiCalls++;
            return originalFetch.apply(window, args);
        };
        
        // Monitor errors
        window.addEventListener('error', () => {
            this.performanceMetrics.errors++;
        });
    }

    // Refresh current section
    async refreshCurrentSection() {
        switch (this.currentSection) {
            case 'users':
                await this.userController.refresh();
                break;
            case 'events':
                await this.eventController.refresh();
                break;
            case 'overview':
                await this.loadOverviewSection();
                break;
        }
    }

    // Handle initialization errors
    handleInitializationError(error) {
        const errorMessage = `
            <div class="error-container">
                <h2>⚠️ Initialization Error</h2>
                <p>The dashboard failed to initialize properly. Please try refreshing the page.</p>
                <p><strong>Error:</strong> ${error.message}</p>
                <button onclick="location.reload()" class="btn btn-primary">Refresh Page</button>
            </div>
        `;
        
        document.body.innerHTML = errorMessage;
    }

    // Get performance metrics
    getPerformanceMetrics() {
        return {
            ...this.performanceMetrics,
            uptime: performance.now()
        };
    }

    // Cleanup all resources
    cleanup() {
        this.userController.cleanup();
        this.eventController.cleanup();
        this.isInitialized = false;
    }

    // Export global functions for HTML onclick handlers
    exportGlobalFunctions() {
        // User functions
        window.showAddUserModal = () => this.userController.showAddUserModal();
        window.showEditUserModal = (id) => this.userController.showEditUserModal(id);
        window.deleteUser = (id) => this.userController.handleDeleteUser(id);
        window.toggleDepartmentField = () => this.userController.toggleDepartmentField();
        window.toggleEditDepartmentField = () => this.userController.toggleDepartmentField(true);
        
        // Event functions
        window.showAddEventModal = () => this.eventController.showAddEventModal();
        window.showEditEventModal = (id) => this.eventController.showEditEventModal(id);
        window.deleteEvent = (id) => this.eventController.handleDeleteEvent(id);
        
        // Navigation functions
        window.navigateToSection = (section) => this.navigateToSection(section);
        window.refreshCurrentSection = () => this.refreshCurrentSection();
        
        // App functions
        window.appController = this;
    }
}