// Clean Supabase/FastAPI integration - Firebase completely removed
import { API_ENDPOINTS, makeAuthenticatedRequest, testBackendConnection } from '../../config/backend-config.js';
import { addNotification, closeModal } from '../../ui/notifications.js';

let allEventsCache = [];
let refreshInterval = null;

function setupEventsSection() {
    // Setup form submission handlers
    const addEventForm = document.getElementById('add-event-form');
    if (addEventForm) {
        addEventForm.addEventListener('submit', (event) => {
            event.preventDefault();
            handleAddEvent(event.target);
        });
    }

    const editEventForm = document.getElementById('edit-event-form');
    if (editEventForm) {
        editEventForm.addEventListener('submit', (event) => {
            event.preventDefault();
            handleEditEvent(event.target);
        });
    }

    // Setup search functionality
    const searchInput = document.getElementById('event-search');
    if (searchInput) {
        searchInput.addEventListener('input', debounce(filterEvents, 300));
    }

    // Setup category filter
    const categoryFilter = document.getElementById('event-category-filter');
    if (categoryFilter) {
        categoryFilter.addEventListener('change', filterEvents);
    }
}

// Debounce function to limit search frequency
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

async function loadEventsTable() {
    const tableBody = document.querySelector('#events-table-body');
    if (!tableBody) {
        console.error('Events table body not found');
        return;
    }

    tableBody.innerHTML = '<tr><td colspan="7">Loading events from backend...</td></tr>';

    try {
        // Load real events from backend
        console.log('📊 Loading events from backend API...');
        
        const response = await makeAuthenticatedRequest(API_ENDPOINTS.events.list);
        
        if (response && Array.isArray(response)) {
            allEventsCache = response;
            console.log(`Loaded ${allEventsCache.length} events from backend`);
        } else if (response && response.events && Array.isArray(response.events)) {
            allEventsCache = response.events;
            console.log(`Loaded ${allEventsCache.length} events from backend`);
        } else {
            console.warn('No events data received from backend');
            allEventsCache = [];
        }
            
        renderEventsTable(allEventsCache);
        
        // Setup auto-refresh every 30 seconds
        if (refreshInterval) clearInterval(refreshInterval);
        refreshInterval = setInterval(() => {
            loadEventsTable();
        }, 30000);
    } catch (error) {
        console.error('Error loading events from backend:', error);
        tableBody.innerHTML = '<tr><td colspan="7">Error loading events. Please check your connection.</td></tr>';
    }
}

function renderEventsTable(events) {
    const tableBody = document.querySelector('#events-table-body');
    if (!tableBody) return;
    
    if (events.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="7">No events found</td></tr>';
        return;
    }
    
    tableBody.innerHTML = events.map(event => `
        <tr>
            <td>${event.title || 'N/A'}</td>
            <td>${truncateText(event.description || 'N/A', 50)}</td>
            <td><span class="badge badge-primary">${event.category || 'General'}</span></td>
            <td>
                ${event.image_url ? 
                    `<img src="${event.image_url}" alt="Event" style="width: 50px; height: 50px; object-fit: cover; border-radius: 4px;">` : 
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
                <button class="btn btn-sm btn-secondary" onclick="showEditEventModal('${event.id}')">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteEvent('${event.id}')">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

function truncateText(text, maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
}

function filterEvents() {
    const searchInput = document.getElementById('event-search');
    const categoryFilter = document.getElementById('event-category-filter');
    
    let filteredEvents = [...allEventsCache];
    
    // Apply search filter
    if (searchInput && searchInput.value.trim()) {
        const searchTerm = searchInput.value.toLowerCase().trim();
        filteredEvents = filteredEvents.filter(event => 
            event.title?.toLowerCase().includes(searchTerm) ||
            event.description?.toLowerCase().includes(searchTerm) ||
            event.category?.toLowerCase().includes(searchTerm)
        );
    }
    
    // Apply category filter
    if (categoryFilter && categoryFilter.value) {
        filteredEvents = filteredEvents.filter(event => event.category === categoryFilter.value);
    }
    
    renderEventsTable(filteredEvents);
}

function showAddEventModal() {
    const modal = document.getElementById('add-event-modal');
    if (modal) {
        modal.style.display = 'block';
        
        // Reset form
        const form = document.getElementById('add-event-form');
        if (form) form.reset();
    }
}

async function showEditEventModal(eventId) {
    const modal = document.getElementById('edit-event-modal');
    if (!modal) return;
    
    try {
        // Get event data from cache first
        const event = allEventsCache.find(e => e.id === eventId);
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
        
        // Handle badges if they exist
        if (event.badges && Array.isArray(event.badges)) {
            const badgesContainer = document.getElementById('edit-event-badges');
            if (badgesContainer) {
                badgesContainer.value = event.badges.join(', ');
            }
        }
        
        modal.style.display = 'block';
    } catch (error) {
        console.error('Error loading event for edit:', error);
        addNotification('Error loading event data', 'error');
    }
}

async function handleAddEvent(form) {
    try {
        const formData = new FormData(form);
        const eventData = {
            title: formData.get('title'),
            description: formData.get('description'),
            category: formData.get('category'),
            image_url: formData.get('image_url'),
            registration_url: formData.get('registration_url'),
            badges: formData.get('badges') ? formData.get('badges').split(',').map(b => b.trim()).filter(b => b) : []
        };
        
        // Validate required fields
        if (!eventData.title || !eventData.description || !eventData.category) {
            throw new Error('Please fill in all required fields');
        }
        
        // Create event via backend API
        const response = await makeAuthenticatedRequest(API_ENDPOINTS.events, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(eventData)
        });
        
        if (response) {
            addNotification('Event created successfully', 'success');
            closeModal('add-event-modal');
            form.reset();
            await loadEventsTable(); // Refresh the table
        }
    } catch (error) {
        console.error('Error creating event:', error);
        addNotification(error.message || 'Error creating event', 'error');
    }
}

async function handleEditEvent(form) {
    try {
        const formData = new FormData(form);
        const eventId = formData.get('id');
        const eventData = {
            title: formData.get('title'),
            description: formData.get('description'),
            category: formData.get('category'),
            image_url: formData.get('image_url'),
            registration_url: formData.get('registration_url'),
            badges: formData.get('badges') ? formData.get('badges').split(',').map(b => b.trim()).filter(b => b) : []
        };
        
        // Update event via backend API
        const response = await makeAuthenticatedRequest(`${API_ENDPOINTS.events}/${eventId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(eventData)
        });
        
        if (response) {
            addNotification('Event updated successfully', 'success');
            closeModal('edit-event-modal');
            await loadEventsTable(); // Refresh the table
        }
    } catch (error) {
        console.error('Error updating event:', error);
        addNotification(error.message || 'Error updating event', 'error');
    }
}

async function deleteEvent(eventId) {
    if (!confirm('Are you sure you want to delete this event? This action cannot be undone.')) {
        return;
    }
    
    try {
        const response = await makeAuthenticatedRequest(`${API_ENDPOINTS.events}/${eventId}`, {
            method: 'DELETE'
        });
        
        if (response) {
            addNotification('Event deleted successfully', 'success');
            await loadEventsTable(); // Refresh the table
        }
    } catch (error) {
        console.error('Error deleting event:', error);
        addNotification(error.message || 'Error deleting event', 'error');
    }
}

function cleanup() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
        refreshInterval = null;
    }
    allEventsCache = [];
}

// Export functions
export {
    setupEventsSection,
    loadEventsTable,
    showAddEventModal,
    showEditEventModal,
    handleAddEvent,
    handleEditEvent,
    deleteEvent,
    cleanup
};