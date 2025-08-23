// Supabase integration - using backend API instead
import { API_ENDPOINTS, makeAuthenticatedRequest, testBackendConnection } from '../../config/backend-config.js';
import { addNotification, closeModal } from '../../ui/notifications.js';

function setupEventsSection() {
    // Setting up events section
    console.log('Setting up events section with Supabase integration');

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

// Search function for events
function searchInEvents(searchTerm) {
    if (!searchTerm || searchTerm.trim() === '') {
        renderEventsTable(allEventsCache);
        return;
    }
    
    const filteredEvents = allEventsCache.filter(event =>
        (event.title || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
        (event.description || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
        (event.category || '').toLowerCase().includes(searchTerm.toLowerCase())
    );
    
    renderEventsTable(filteredEvents);
}

let allEventsCache = [];

function filterEvents() {
    const searchTerm = document.getElementById('event-search')?.value.toLowerCase() || '';
    const categoryFilter = document.getElementById('event-category-filter')?.value || '';

    let filteredEvents = allEventsCache;

    if (searchTerm) {
        filteredEvents = filteredEvents.filter(event =>
            (event.title || '').toLowerCase().includes(searchTerm) ||
            (event.description || '').toLowerCase().includes(searchTerm)
        );
    }

    if (categoryFilter) {
        filteredEvents = filteredEvents.filter(event =>
            event.category === categoryFilter
        );
    }

    renderEventsTable(filteredEvents);
}

async function loadEventsTable() {
    const tableBody = document.querySelector('#events-table-body');
    if (!tableBody) {
        console.error('Events table body not found in DOM');
        return;
    }

    // Show loading state
    tableBody.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 2rem;">Loading events from Supabase...</td></tr>';

    try {
        console.log('Loading events from Supabase...');
        
        // Check if backend is available
        const isBackendConnected = await testBackendConnection();
        if (!isBackendConnected) {
            throw new Error('Backend connection failed');
        }

        // Fetch real events from Supabase via backend API
        const response = await makeAuthenticatedRequest(
            API_ENDPOINTS.events.list,
            { method: 'GET' }
        );

        if (!response.ok) {
            throw new Error(`Failed to fetch events: ${response.status} ${response.statusText}`);
        }

        const eventsData = await response.json();
        const events = eventsData.events || eventsData || [];

        console.log('Events loaded:', events.length);
        allEventsCache = events; // Cache events for filtering
        renderEventsTable(events);
        populateEventCategoryFilter();
        
    } catch (e) {
        console.error('Error loading events:', e);
        tableBody.innerHTML = `<tr><td colspan="6" style="text-align: center; padding: 2rem; color: #dc2626;">
            <i class="fas fa-exclamation-triangle"></i> Error loading events: ${e.message}
            <br><br>
            <button class="btn btn-sm btn-primary" onclick="loadEventsTable()">
                <i class="fas fa-redo"></i> Retry
            </button>
        </td></tr>`;
    }
}

function renderEventsTable(events) {
    const tableBody = document.querySelector('#events-table-body');
    if (!tableBody) {
        console.error('Events table body not found in renderEventsTable');
        return;
    }

    if (events.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 2rem; color: #6b7280;">No events found</td></tr>';
        return;
    }

    tableBody.innerHTML = events.map(event => {
        // Format image display
        const imageDisplay = event.imageUrl ?
            `<img src="${event.imageUrl}" alt="Event image" style="width: 50px; height: 50px; object-fit: cover; border-radius: 4px;">` :
            '<span style="color: #6b7280;">No image</span>';

        // Format register URL
        const registerUrlDisplay = event.registerUrl ?
            `<a href="${event.registerUrl}" target="_blank" style="color: #2563eb; text-decoration: none;">
                <i class="fas fa-external-link-alt"></i> Register
            </a>` :
            '<span style="color: #6b7280;">No URL</span>';

        // Truncate description if too long
        const description = event.description ?
            (event.description.length > 50 ? event.description.substring(0, 50) + '...' : event.description) :
            '<span style="color: #6b7280;">No description</span>';

        // Format assigned badges display
        const badgesDisplay = event.assignedBadges && event.assignedBadges.length > 0 ?
            event.assignedBadges.map(badge =>
                `<span class="badge-mini" style="display: inline-block; margin: 0.1rem; padding: 0.2rem 0.4rem; background: linear-gradient(135deg, #fbbf24, #f59e0b); color: white; border-radius: 12px; font-size: 0.7rem; font-weight: 500;">
                    ${badge.icon} ${badge.name}
                </span>`
            ).join('') :
            '<span style="color: #6b7280; font-size: 0.8rem;">No badges</span>';

        return `
            <tr>
                <td style="font-weight: 500;">${event.title || 'Untitled'}</td>
                <td style="max-width: 200px;">${description}</td>
                <td>
                    <span class="status-badge" style="background-color: #dbeafe; color: #1e40af; padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem;">
                        ${event.category || 'Uncategorized'}
                    </span>
                </td>
                <td>${imageDisplay}</td>
                <td>${registerUrlDisplay}</td>
                <td style="max-width: 150px;">${badgesDisplay}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="window.showEditEventModal('${event.id}')" title="Edit event">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="window.deleteEvent('${event.id}')" title="Delete event">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

function populateEventCategoryFilter() {
    const categories = ['Academic', 'Competition', 'Workshop', 'Seminar', 'Conference', 'Training', 'Other'];
    const filter = document.getElementById('event-category-filter');
    if (filter) {
        filter.innerHTML = '<option value="">All Categories</option>' +
            categories.map(cat => `<option value="${cat}">${cat}</option>`).join('');
    }
}

async function showAddEventModal() {
    const modal = document.getElementById('add-event-modal');
    if (modal) {
        modal.classList.add('show');
        modal.style.display = 'flex';

        // Clear form
        const form = document.getElementById('add-event-form');
        if (form) form.reset();

        // Hide image preview
        const preview = document.getElementById('add-event-image-preview');
        if (preview) preview.style.display = 'none';

        // Load available badges for assignment
        await loadAvailableBadges();

        // Clear any previous badge selections
        clearBadgeSelections();
    }
}

async function showEditEventModal(id) {
    console.log('Opening edit modal for event:', id);
    
    try {
        // Fetch event data from Supabase via backend API
        const response = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.events.get}/${id}`,
            { method: 'GET' }
        );

        if (!response.ok) {
            throw new Error(`Failed to fetch event: ${response.status}`);
        }

        const event = await response.json();
        console.log('Event data for editing:', event);

        document.getElementById('edit-event-id').value = id;
        document.getElementById('edit-event-title').value = event.title || '';
        document.getElementById('edit-event-description').value = event.description || '';
        document.getElementById('edit-event-category').value = event.category || '';
        document.getElementById('edit-event-register-url').value = event.registerUrl || '';
        document.getElementById('edit-event-image').value = event.imageUrl || '';

        // Show image preview if exists, hide if not
        const preview = document.getElementById('edit-event-image-preview');
        if (preview) {
            if (event.imageUrl && event.imageUrl.trim() !== '') {
                preview.src = event.imageUrl;
                preview.style.display = 'block';
            } else {
                preview.style.display = 'none';
                preview.src = '';
            }
        }

        const modal = document.getElementById('edit-event-modal');
        modal.classList.add('show');
        modal.style.display = 'flex';
        
    } catch (e) {
        console.error('Error loading event for editing:', e);
        addNotification('Error loading event: ' + e.message, 'error');
    }
}

async function handleAddEvent(form) {
    if (!form || form.tagName !== 'FORM') {
        console.error('Invalid form element passed to handleAddEvent');
        addNotification('Form error: Invalid form element', 'error');
        return;
    }

    // Get form values directly from form elements
    const title = document.getElementById('add-event-title')?.value;
    const description = document.getElementById('add-event-description')?.value;
    const category = document.getElementById('add-event-category')?.value;
    const registerUrl = document.getElementById('add-event-register-url')?.value;
    const imageUrl = document.getElementById('add-event-image')?.value;

    // Validate required fields
    if (!title || !description || !category || !registerUrl) {
        addNotification('Please fill in all required fields', 'error');
        return;
    }

    // Get selected badges for this event
    const selectedBadges = getSelectedBadges();

    const eventData = {
        title: title.trim(),
        description: description.trim(),
        category: category.trim(),
        registerUrl: registerUrl.trim(),
        imageUrl: imageUrl ? imageUrl.trim() : '',
        assignedBadges: selectedBadges, // Add assigned badges
        favoriteUserIds: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };

    try {
        console.log('Adding event to Supabase:', eventData);
        
        // Create event in Supabase via backend API
        const response = await makeAuthenticatedRequest(
            API_ENDPOINTS.events.create,
            {
                method: 'POST',
                body: JSON.stringify(eventData)
            }
        );

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to create event: ${response.status}`);
        }

        const newEvent = await response.json();
        const eventId = newEvent.id;

        closeModal('add-event-modal');
        form.reset(); // Clear the form
        loadEventsTable();

        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }

        // Send notifications to all users about the new event
        await sendNewEventNotifications(eventData.title, eventId);

        // Show success message with badge info
        if (selectedBadges.length > 0) {
            addNotification(`Event added successfully to Supabase with ${selectedBadges.length} badge(s) assigned!`, 'success');
        } else {
            addNotification('Event added successfully to Supabase', 'success');
        }
    } catch (e) {
        console.error('Error adding event:', e);
        addNotification('Error adding event: ' + e.message, 'error');
    }
}

async function handleEditEvent(form) {
    if (!form || form.tagName !== 'FORM') {
        console.error('Invalid form element passed to handleEditEvent');
        addNotification('Form error: Invalid form element', 'error');
        return;
    }

    // Get form values directly from form elements
    const eventId = document.getElementById('edit-event-id')?.value;
    const title = document.getElementById('edit-event-title')?.value;
    const description = document.getElementById('edit-event-description')?.value;
    const category = document.getElementById('edit-event-category')?.value;
    const registerUrl = document.getElementById('edit-event-register-url')?.value;
    const imageUrl = document.getElementById('edit-event-image')?.value;

    // Validate required fields
    if (!eventId || !title || !description || !category || !registerUrl) {
        addNotification('Please fill in all required fields', 'error');
        return;
    }

    const eventData = {
        title: title.trim(),
        description: description.trim(),
        category: category.trim(),
        registerUrl: registerUrl.trim(),
        imageUrl: imageUrl ? imageUrl.trim() : '',
        updatedAt: new Date().toISOString()
    };

    try {
        console.log('Updating event in Supabase:', eventId, eventData);
        
        // Update event in Supabase via backend API
        const response = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.events.update}/${eventId}`,
            {
                method: 'PUT',
                body: JSON.stringify(eventData)
            }
        );

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to update event: ${response.status}`);
        }

        closeModal('edit-event-modal');
        loadEventsTable();
        addNotification('Event updated successfully in Supabase', 'success');

        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }
    } catch (e) {
        console.error('Error updating event:', e);
        addNotification('Error updating event: ' + e.message, 'error');
    }
}

async function deleteEvent(id) {
    if (!confirm('Are you sure you want to delete this event?')) return;

    try {
        console.log('Deleting event from Supabase:', id);
        
        // Delete event from Supabase via backend API
        const response = await makeAuthenticatedRequest(
            `${API_ENDPOINTS.events.delete}/${id}`,
            { method: 'DELETE' }
        );

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `Failed to delete event: ${response.status}`);
        }

        loadEventsTable();
        addNotification('Event deleted successfully from Supabase', 'success');

        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }
    } catch (e) {
        console.error('Error deleting event:', e);
        addNotification('Error deleting event: ' + e.message, 'error');
    }
}

// ===== BADGE ASSIGNMENT FUNCTIONS =====

async function loadAvailableBadges() {
    try {
        console.log('Achievement system removed - no badges to load');
        
        const badgeSelectionGrid = document.getElementById('add-event-badge-selection');
        if (!badgeSelectionGrid) {
            console.warn('Badge selection grid not found');
            return;
        }

        // Show removal message
        badgeSelectionGrid.innerHTML = `
            <div class="no-badges-message">
                <i class="fas fa-info-circle"></i>
                <p>Achievement system has been removed</p>
                <small>This feature is no longer available for talent profiling</small>
            </div>
        `;

    } catch (error) {
        console.error('Error in loadAvailableBadges:', error);
        addNotification('Achievement system removed', 'info');
    }
}

function toggleBadgeSelection(badgeId, badgeElement) {
    badgeElement.classList.toggle('selected');

    // Update the selection indicator
    const indicator = badgeElement.querySelector('.selection-indicator');
    if (badgeElement.classList.contains('selected')) {
        indicator.innerHTML = '<i class="fas fa-check"></i>';
    } else {
        indicator.innerHTML = '';
    }
}

function getSelectedBadges() {
    const selectedBadges = [];
    const selectedElements = document.querySelectorAll('#add-event-badge-selection .badge-option.selected');

    selectedElements.forEach(element => {
        const badgeId = element.dataset.badgeId;
        // Achievement system removed - no badges available
        console.log('Badge selection not available - achievement system removed');
    });

    return selectedBadges;
}

function clearBadgeSelections() {
    const selectedElements = document.querySelectorAll('#add-event-badge-selection .badge-option.selected');
    selectedElements.forEach(element => {
        element.classList.remove('selected');
        const indicator = element.querySelector('.selection-indicator');
        if (indicator) {
            indicator.innerHTML = '';
        }
    });
}

// Send notifications to all users about new events
async function sendNewEventNotifications(eventTitle, eventId) {
    try {
        console.log('Sending new event notifications via Supabase...');

        // Get all users (students and lecturers) from Supabase
        const usersResponse = await makeAuthenticatedRequest(
            API_ENDPOINTS.users.list,
            { method: 'GET' }
        );

        if (!usersResponse.ok) {
            console.warn('Failed to fetch users for notifications');
            return;
        }

        const usersData = await usersResponse.json();
        const users = usersData.users || usersData || [];
        
        // Filter users by role
        const eligibleUsers = users.filter(user => 
            user.role === 'student' || user.role === 'lecturer'
        );

        let notificationCount = 0;

        // Create notifications in Supabase via backend API
        for (const user of eligibleUsers) {
            try {
                const notificationData = {
                    userId: user.id,
                    title: 'New Event Available!',
                    message: `Check out the new event: ${eventTitle}`,
                    type: 'event',
                    isRead: false,
                    createdAt: new Date().toISOString(),
                    data: {
                        eventId: eventId,
                        eventTitle: eventTitle,
                    },
                    actionUrl: `/event/${eventId}`,
                };

                // Send notification via backend API
                await makeAuthenticatedRequest(
                    API_ENDPOINTS.notifications?.create || '/api/notifications',
                    {
                        method: 'POST',
                        body: JSON.stringify(notificationData)
                    }
                );

                notificationCount++;
            } catch (error) {
                console.warn(`Failed to send notification to user ${user.id}:`, error);
            }
        }

        console.log(`Successfully sent ${notificationCount} event notifications via Supabase`);

    } catch (error) {
        console.error('Error sending new event notifications:', error);
    }
}

export {
    setupEventsSection,
    loadEventsTable,
    showAddEventModal,
    showEditEventModal,
    handleAddEvent,
    handleEditEvent,
    deleteEvent,
    sendNewEventNotifications
};
