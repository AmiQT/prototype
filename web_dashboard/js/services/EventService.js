/**
 * Event Service - OOP approach for event management
 * Extends BaseService for common functionality
 */
import { BaseService } from '../core/BaseService.js';
import { makeAuthenticatedRequest, API_ENDPOINTS } from '../config/backend-config.js';

export class EventService extends BaseService {
    constructor() {
        super(API_ENDPOINTS.events);
        this.events = [];
        this.filteredEvents = [];
        this.currentFilters = {
            category: '',
            search: ''
        };
        this.categories = [
            'Academic', 'Competition', 'Workshop', 
            'Seminar', 'Conference', 'Training', 'Other'
        ];
    }

    // Implement makeRequest from BaseService
    async makeRequest(endpoint, options) {
        return await makeAuthenticatedRequest(endpoint, options);
    }

    // Load all events
    async loadEvents() {
        try {
            const response = await this.request(this.apiEndpoint);
            this.events = Array.isArray(response) ? response : response.events || [];
            this.applyFilters();
            this.notify({ type: 'events_loaded', data: this.filteredEvents });
            return this.events;
        } catch (error) {
            this.handleError(error);
            return [];
        }
    }

    // Create new event
    async createEvent(eventData) {
        try {

            const response = await this.request(this.apiEndpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(eventData)
            });
            
            this.events.push(response);
            this.applyFilters();
            this.notify({ type: 'event_created', data: response });
            return response;
        } catch (error) {
            this.handleError(error);
            throw error;
        }
    }

    // Update event
    async updateEvent(eventId, eventData) {
        try {

            const response = await this.request(`${this.apiEndpoint}/${eventId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(eventData)
            });
            
            const index = this.events.findIndex(e => e.id === eventId);
            if (index !== -1) {
                this.events[index] = response;
                this.applyFilters();
            }
            
            this.notify({ type: 'event_updated', data: response });
            return response;
        } catch (error) {
            this.handleError(error);
            throw error;
        }
    }

    // Delete event
    async deleteEvent(eventId) {
        try {
            await this.request(`${this.apiEndpoint}/${eventId}`, {
                method: 'DELETE'
            });
            
            this.events = this.events.filter(e => e.id !== eventId);
            this.applyFilters();
            this.notify({ type: 'event_deleted', data: { id: eventId } });
            return true;
        } catch (error) {
            this.handleError(error);
            throw error;
        }
    }

    // Apply filters
    applyFilters() {
        let filtered = [...this.events];
        
        // Category filter
        if (this.currentFilters.category) {
            filtered = filtered.filter(event => event.category === this.currentFilters.category);
        }
        
        // Search filter
        if (this.currentFilters.search) {
            const searchTerm = this.currentFilters.search.toLowerCase();
            filtered = filtered.filter(event => 
                event.title?.toLowerCase().includes(searchTerm) ||
                event.description?.toLowerCase().includes(searchTerm) ||
                event.category?.toLowerCase().includes(searchTerm)
            );
        }
        
        this.filteredEvents = filtered;
        this.notify({ type: 'events_filtered', data: this.filteredEvents });
    }

    // Set filters
    setFilters(filters) {
        this.currentFilters = { ...this.currentFilters, ...filters };
        this.applyFilters();
    }

    // Get paginated events
    getPaginatedEvents(page = 1, limit = 10) {
        return this.paginate(this.filteredEvents, page, limit);
    }

    // Search events with debouncing
    searchEvents = this.debounce((searchTerm) => {
        this.setFilters({ search: searchTerm });
    }, 300);

    // Get available categories
    getCategories() {
        return this.categories;
    }

    // Refresh data
    async refresh() {
        await super.refresh();
        await this.loadEvents();
    }

    // Get event by ID
    getEventById(eventId) {
        return this.events.find(event => event.id === eventId);
    }

    // Get events by category
    getEventsByCategory(category) {
        return this.events.filter(event => event.category === category);
    }

    // Get upcoming events
    getUpcomingEvents() {
        const now = new Date();
        return this.events.filter(event => {
            if (!event.date) return true; // Include events without dates
            const eventDate = new Date(event.date);
            return eventDate >= now;
        }).sort((a, b) => {
            if (!a.date) return 1;
            if (!b.date) return -1;
            return new Date(a.date) - new Date(b.date);
        });
    }

    // Get event statistics
    getStatistics() {
        const stats = {
            total: this.events.length,
            byCategory: {},
            withRegistration: 0,
            upcoming: 0
        };

        const now = new Date();

        this.events.forEach(event => {
            // Count by category
            const category = event.category || 'Other';
            stats.byCategory[category] = (stats.byCategory[category] || 0) + 1;
            
            // Count events with registration
            if (event.registration_url) {
                stats.withRegistration++;
            }
            

            
            // Count upcoming events
            if (event.date && new Date(event.date) >= now) {
                stats.upcoming++;
            }
        });

        return stats;
    }

    // Validate event data
    validateEventData(eventData) {
        const errors = [];
        
        if (!eventData.title || eventData.title.trim() === '') {
            errors.push('Title is required');
        }
        
        if (!eventData.description || eventData.description.trim() === '') {
            errors.push('Description is required');
        }
        
        if (!eventData.category || eventData.category.trim() === '') {
            errors.push('Category is required');
        }
        
        if (eventData.registration_url && !this.isValidUrl(eventData.registration_url)) {
            errors.push('Registration URL is not valid');
        }
        
        if (eventData.image_url && !this.isValidUrl(eventData.image_url)) {
            errors.push('Image URL is not valid');
        }
        
        return errors;
    }

    // Helper method to validate URLs
    isValidUrl(string) {
        try {
            new URL(string);
            return true;
        } catch (_) {
            return false;
        }
    }

    // Truncate text for display
    truncateText(text, maxLength = 50) {
        if (!text || text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    }
}