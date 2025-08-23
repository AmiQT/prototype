/**
 * Event Controller - MVC Pattern Implementation
 * Handles UI interactions for event management
 */
import { EventService } from '../services/EventService.js';
import { addNotification, closeModal } from '../ui/notifications.js';

export class EventController {
    constructor() {
        this.eventService = new EventService();
        this.currentPage = 1;
        this.pageLimit = 10;
        this.isInitialized = false;
        
        // Bind methods to preserve 'this' context
        this.handleAddEvent = this.handleAddEvent.bind(this);
        this.handleEditEvent = this.handleEditEvent.bind(this);
        this.handleDeleteEvent = this.handleDeleteEvent.bind(this);
        this.handleSearch = this.handleSearch.bind(this);
        this.handleFilterChange = this.handleFilterChange.bind(this);
    }

    // Initialize controller
    async initialize() {
        if (this.isInitialized) return;
        
        try {
            // Subscribe to service events
            this.eventService.subscribe(this.handleServiceEvent.bind(this));
            
            // Setup UI event listeners
            this.setupEventListeners();
            
            // Load initial data
            await this.eventService.loadEvents();
            
            // Start auto-refresh
            this.eventService.startAutoRefresh();
            
            this.isInitialized = true;
            console.log('EventController initialized successfully');
        } catch (error) {
            console.error('Failed to initialize EventController:', error);
            addNotification('Failed to initialize event management', 'error');
        }
    }

    // Setup UI event listeners
    setupEventListeners() {
        // Search input
        const searchInput = document.getElementById('event-search');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.handleSearch(e.target.value);
            });
        }

        // Category filter
        const categoryFilter = document.getElementById('event-category-filter');
        if (categoryFilter) {
            categoryFilter.addEventListener('change', (e) => {
                this.handleFilterChange({ category: e.target.value });
            });
        }

        // Add event form
        const addEventForm = document.getElementById('add-event-form');
        if (addEventForm) {
            addEventForm.addEventListener('submit', this.handleAddEvent);
        }

        // Edit event form
        const editEventForm = document.getElementById('edit-event-form');
        if (editEventForm) {
            editEventForm.addEventListener('submit', this.handleEditEvent);
        }

        // Pagination controls
        this.setupPaginationListeners();
    }

    // Setup pagination event listeners
    setupPaginationListeners() {
        const prevBtn = document.getElementById('events-prev-page');
        const nextBtn = document.getElementById('events-next-page');
        
        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                if (this.currentPage > 1) {
                    this.currentPage--;
                    this.renderEvents();
                }
            });
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                const paginatedData = this.eventService.getPaginatedEvents(this.currentPage + 1, this.pageLimit);
                if (paginatedData.pagination.hasNext) {
                    this.currentPage++;
                    this.renderEvents();
                }
            });
        }
    }

    // Handle service events
    handleServiceEvent(event) {
        switch (event.type) {
            case 'events_loaded':
            case 'events_filtered':
                this.renderEvents();
                break;
            case 'event_created':
                addNotification('Event created successfully', 'success');
                this.renderEvents();
                break;
            case 'event_updated':
                addNotification('Event updated successfully', 'success');
                this.renderEvents();
                break;
            case 'event_deleted':
                addNotification('Event deleted successfully', 'success');
                this.renderEvents();
                break;
            case 'error':
                addNotification(event.message, 'error');
                break;
        }
    }

    // Handle search input
    handleSearch(searchTerm) {
        this.currentPage = 1;
        this.eventService.searchEvents(searchTerm);
    }

    // Handle filter changes
    handleFilterChange(filters) {
        this.currentPage = 1;
        this.eventService.setFilters(filters);
    }

    // Handle add event form submission
    async handleAddEvent(event) {
        event.preventDefault();
        
        try {
            const formData = new FormData(event.target);
            const eventData = {
                title: formData.get('title'),
                description: formData.get('description'),
                category: formData.get('category'),
                image_url: formData.get('image_url'),
                registration_url: formData.get('registration_url'),
                badges: formData.get('badges')
            };

            // Validate event data
            const errors = this.eventService.validateEventData(eventData);
            if (errors.length > 0) {
                throw new Error(errors.join(', '));
            }

            await this.eventService.createEvent(eventData);
            closeModal('add-event-modal');
            event.target.reset();
        } catch (error) {
            addNotification(error.message, 'error');
        }
    }

    // Handle edit event form submission
    async handleEditEvent(event) {
        event.preventDefault();
        
        try {
            const formData = new FormData(event.target);
            const eventId = formData.get('id');
            const eventData = {
                title: formData.get('title'),
                description: formData.get('description'),
                category: formData.get('category'),
                image_url: formData.get('image_url'),
                registration_url: formData.get('registration_url'),
                badges: formData.get('badges')
            };

            // Validate event data
            const errors = this.eventService.validateEventData(eventData);
            if (errors.length > 0) {
                throw new Error(errors.join(', '));
            }

            await this.eventService.updateEvent(eventId, eventData);
            closeModal('edit-event-modal');
        } catch (error) {
            addNotification(error.message, 'error');
        }
    }

    // Handle delete event
    async handleDeleteEvent(eventId) {
        if (!confirm('Are you sure you want to delete this event? This action cannot be undone.')) {
            return;
        }

        try {
            await this.eventService.deleteEvent(eventId);
        } catch (error) {
            addNotification(error.message, 'error');
        }
    }

    // Show add event modal
    showAddEventModal() {
        const modal = document.getElementById('add-event-modal');
        if (modal) {
            modal.style.display = 'block';
            
            // Reset form
            const form = document.getElementById('add-event-form');
            if (form) form.reset();
        }
    }

    // Show edit event modal
    showEditEventModal(eventId) {
        const modal = document.getElementById('edit-event-modal');
        if (!modal) return;
        
        try {
            const event = this.eventService.getEventById(eventId);
            if (!event) {
                throw new Error('Event not found');
            }
            
            // Populate form fields
            document.getElementById('edit-event-id').value = event.id;
            document.getElementById('edit-event-title').value = event.title || '';
            document.getElementById('edit-event-description').value = event.description || '';
            document.getElementById('edit-event-category').value = event.category || '';
            document.getElementById('edit-event-image').value = event.image_url || '';
            document.getElementById('edit-event-register-url').value = event.registration_url || '';
            
            // Handle badges
            if (event.badges && Array.isArray(event.badges)) {
                const badgesField = document.getElementById('edit-event-badges');
                if (badgesField) {
                    badgesField.value = event.badges.join(', ');
                }
            }
            
            modal.style.display = 'block';
        } catch (error) {
            addNotification('Error loading event data', 'error');
        }
    }

    // Render events table
    renderEvents() {
        const tableBody = document.querySelector('#events-table-body');
        if (!tableBody) return;
        
        const paginatedData = this.eventService.getPaginatedEvents(this.currentPage, this.pageLimit);
        const events = paginatedData.data;
        
        if (events.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="7">No events found</td></tr>';
            this.updatePaginationControls(paginatedData.pagination);
            return;
        }
        
        tableBody.innerHTML = events.map(event => `
            <tr>
                <td>${event.title || 'N/A'}</td>
                <td>${this.eventService.truncateText(event.description || 'N/A', 50)}</td>
                <td><span class="badge badge-primary">${event.category || 'General'}</span></td>
                <td>
                    ${event.image_url ? 
                        `<img src="${event.image_url}" alt="Event" style="width: 50px; height: 50px; object-fit: cover; border-radius: 4px;" onerror="this.style.display='none'">` : 
                        '<span class="text-muted">No image</span>'
                    }
                </td>
                <td>
                    ${event.registration_url ? 
                        `<a href="${event.registration_url}" target="_blank" class="btn btn-sm btn-primary">Register</a>` : 
                        '<span class="text-muted">No registration</span>'
                    }
                </td>
                <td>
                    ${event.badges && event.badges.length > 0 ? 
                        event.badges.map(badge => `<span class="badge badge-success">${badge}</span>`).join(' ') : 
                        '<span class="text-muted">No badges</span>'
                    }
                </td>
                <td>
                    <button class="btn btn-sm btn-secondary" onclick="eventController.showEditEventModal('${event.id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="eventController.handleDeleteEvent('${event.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `).join('');
        
        this.updatePaginationControls(paginatedData.pagination);
        this.updateEventStats();
    }

    // Update pagination controls
    updatePaginationControls(pagination) {
        const prevBtn = document.getElementById('events-prev-page');
        const nextBtn = document.getElementById('events-next-page');
        const pageInfo = document.getElementById('events-page-info');
        
        if (prevBtn) prevBtn.disabled = !pagination.hasPrev;
        if (nextBtn) nextBtn.disabled = !pagination.hasNext;
        if (pageInfo) {
            pageInfo.textContent = `Page ${pagination.page} of ${pagination.totalPages} (${pagination.total} total)`;
        }
    }

    // Update event statistics
    updateEventStats() {
        const stats = this.eventService.getStatistics();
        
        // Update total events count
        const totalEventsElement = document.getElementById('total-events');
        if (totalEventsElement) {
            totalEventsElement.textContent = stats.total;
        }
        
        // Update upcoming events count
        const upcomingEventsElement = document.getElementById('upcoming-events');
        if (upcomingEventsElement) {
            upcomingEventsElement.textContent = stats.upcoming;
        }
        
        // Update category breakdown if element exists
        const categoryStatsElement = document.getElementById('event-category-stats');
        if (categoryStatsElement) {
            categoryStatsElement.innerHTML = Object.entries(stats.byCategory)
                .map(([category, count]) => `<span class="stat-item">${category}: ${count}</span>`)
                .join(' | ');
        }
    }

    // Cleanup resources
    cleanup() {
        this.eventService.cleanup();
        this.isInitialized = false;
    }

    // Refresh data
    async refresh() {
        await this.eventService.refresh();
    }

    // Get upcoming events for dashboard
    getUpcomingEvents() {
        return this.eventService.getUpcomingEvents();
    }

    // Get events by category
    getEventsByCategory(category) {
        return this.eventService.getEventsByCategory(category);
    }
}