import { db, auth } from '../../core/firebase.js';
import { addNotification, closeModal, closeAndCleanupModal } from '../../ui/notifications.js';

let achievementsCache = [];
let achievementsSectionInitialized = false;

// ===== SETUP AND INITIALIZATION =====

function setupAchievementsSection() {
    // Prevent multiple initializations
    if (achievementsSectionInitialized) {
        return;
    }
    
    // Setup form submission
    const form = document.getElementById('add-achievement-form');
    if (form) {
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            handleAddAchievement(form);
        });
    }

    // Setup edit form submission
    const editForm = document.getElementById('edit-achievement-form');
    if (editForm) {
        editForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const badgeId = document.getElementById('edit-achievement-id').value;
            handleEditBadge(editForm, badgeId);
        });
    }

    // Setup real-time preview updates
    setupBadgePreview();
    setupEditBadgePreview();
    
    // Setup search and filter functionality
    setupBadgeSearchAndFilter();
    
    // Load existing achievements
    loadAchievementsData();
    
    // Load badge table
    loadBadgesTable();
    
    // Load verification queue
    loadVerificationQueue();
    
    // Mark as initialized
    achievementsSectionInitialized = true;
}

function setupBadgePreview() {
    const nameInput = document.getElementById('achievement-name');
    const pointsInput = document.getElementById('achievement-points');
    const iconSelect = document.getElementById('achievement-icon');
    const colorSelect = document.getElementById('achievement-color');
    
    const badgePreview = document.getElementById('badge-preview');
    const badgeIcon = badgePreview.querySelector('.badge-icon');
    const badgeName = badgePreview.querySelector('.badge-name');
    const badgePoints = badgePreview.querySelector('.badge-points');

    function updatePreview() {
        const name = nameInput.value || 'Badge Name';
        const points = pointsInput.value || '0';
        const icon = iconSelect.value || '🏆';
        const color = colorSelect.value || 'gold';

        badgeIcon.textContent = icon;
        badgeName.textContent = name.length > 12 ? name.substring(0, 12) + '...' : name;
        badgePoints.textContent = `${points} pts`;

        // Update color theme
        badgePreview.className = `badge-preview ${color}`;
    }

    // Add event listeners for real-time updates
    if (nameInput) nameInput.addEventListener('input', updatePreview);
    if (pointsInput) pointsInput.addEventListener('input', updatePreview);
    if (iconSelect) iconSelect.addEventListener('change', updatePreview);
    if (colorSelect) colorSelect.addEventListener('change', updatePreview);

    // Initialize preview
    updatePreview();
}

function setupEditBadgePreview() {
    const nameInput = document.getElementById('edit-achievement-name');
    const pointsInput = document.getElementById('edit-achievement-points');
    const iconSelect = document.getElementById('edit-achievement-icon');
    const colorSelect = document.getElementById('edit-achievement-color');

    function updateEditPreview() {
        const name = nameInput?.value || 'Badge Name';
        const points = pointsInput?.value || '0';
        const icon = iconSelect?.value || '🏆';
        const color = colorSelect?.value || 'gold';

        const badgePreview = document.getElementById('edit-badge-preview');
        if (badgePreview) {
            const badgeIcon = badgePreview.querySelector('.badge-icon');
            const badgeName = badgePreview.querySelector('.badge-name');
            const badgePoints = badgePreview.querySelector('.badge-points');

            badgeIcon.textContent = icon;
            badgeName.textContent = name.length > 12 ? name.substring(0, 12) + '...' : name;
            badgePoints.textContent = `${points} pts`;

            // Update color theme
            badgePreview.className = `badge-preview ${color}`;
        }
    }

    // Add event listeners for real-time updates
    if (nameInput) nameInput.addEventListener('input', updateEditPreview);
    if (pointsInput) pointsInput.addEventListener('input', updateEditPreview);
    if (iconSelect) iconSelect.addEventListener('change', updateEditPreview);
    if (colorSelect) colorSelect.addEventListener('change', updateEditPreview);

    // Initialize preview
    updateEditPreview();
}

function setupBadgeSearchAndFilter() {
    const searchInput = document.getElementById('badge-search');
    const categoryFilter = document.getElementById('badge-category-filter');
    
    if (searchInput) {
        searchInput.addEventListener('input', debounce(filterBadges, 300));
    }
    
    if (categoryFilter) {
        categoryFilter.addEventListener('change', filterBadges);
    }
}

// Debounce function for search
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

// ===== MODAL FUNCTIONS =====

function showAddAchievementModal() {
    const modal = document.getElementById('add-achievement-modal');
    const form = document.getElementById('add-achievement-form');
    
    if (form) {
        form.reset();
        // Reset preview to defaults
        const badgePreview = document.getElementById('badge-preview');
        if (badgePreview) {
            badgePreview.className = 'badge-preview gold';
            badgePreview.querySelector('.badge-icon').textContent = '🏆';
            badgePreview.querySelector('.badge-name').textContent = 'Badge Name';
            badgePreview.querySelector('.badge-points').textContent = '0 pts';
        }
    }
    
    if (modal) {
        modal.classList.add('show');
        modal.style.display = 'flex';
    }
}

// ===== CRUD OPERATIONS =====

async function handleAddAchievement(form) {
    try {
        // Prevent multiple submissions
        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn.disabled) {
            return;
        }
        
        const formData = new FormData(form);
        
        // Get form values
        const achievementData = {
            name: document.getElementById('achievement-name')?.value?.trim(),
            category: document.getElementById('achievement-category')?.value,
            description: document.getElementById('achievement-description')?.value?.trim(),
            points: parseInt(document.getElementById('achievement-points')?.value) || 0,
            difficulty: document.getElementById('achievement-difficulty')?.value,
            requirements: document.getElementById('achievement-requirements')?.value?.trim(),
            icon: document.getElementById('achievement-icon')?.value || '🏆',
            color: document.getElementById('achievement-color')?.value || 'gold',
            createdAt: new Date().toISOString(),
            createdBy: 'admin', // TODO: Get from auth
            isActive: true,
            timesAwarded: 0
        };

        // Validation
        if (!achievementData.name || !achievementData.category || !achievementData.description) {
            addNotification('Please fill in all required fields', 'error');
            return;
        }

        if (achievementData.points < 1 || achievementData.points > 1000) {
            addNotification('Points must be between 1 and 1000', 'error');
            return;
        }

        // Add loading state
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creating...';
        submitBtn.disabled = true;

        // Save to Firebase
        await db.collection('achievements').add(achievementData);

        addNotification(`Achievement badge "${achievementData.name}" created successfully!`, 'success');
        closeModal('add-achievement-modal');
        form.reset();
        
        // Refresh achievements data
        await loadAchievementsData();
        
        // Refresh badge management table
        loadBadgesTable();
        
        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }

    } catch (error) {
        console.error('Error creating achievement:', error);
        addNotification('Error creating achievement: ' + error.message, 'error');
    } finally {
        // Reset button state
        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn) {
            submitBtn.innerHTML = '<i class="fas fa-plus"></i> Create Badge';
            submitBtn.disabled = false;
        }
    }
}

async function loadAchievementsData() {
    try {
        const achievementsSnap = await db.collection('achievements').orderBy('createdAt', 'desc').get();
        achievementsCache = achievementsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        
        // Update achievement statistics
        updateAchievementStats();
        
    } catch (error) {
        console.error('Error loading achievements:', error);
        addNotification('Error loading achievements', 'error');
    }
}

function updateAchievementStats() {
    const totalBadgesEl = document.getElementById('total-badges');
    const monthlyAwardsEl = document.getElementById('monthly-awards');
    const topAchieverEl = document.getElementById('top-achiever');

    if (totalBadgesEl) {
        totalBadgesEl.textContent = achievementsCache.length;
    }

    if (monthlyAwardsEl) {
        // Calculate monthly awards (placeholder for now)
        const monthlyCount = achievementsCache.reduce((sum, achievement) => sum + (achievement.timesAwarded || 0), 0);
        monthlyAwardsEl.textContent = monthlyCount;
    }

    if (topAchieverEl) {
        // Placeholder for top achiever
        topAchieverEl.textContent = achievementsCache.length > 0 ? 'Loading...' : 'No data';
    }
}

// ===== HELPER FUNCTIONS =====

function getAchievementsByCategory(category) {
    return achievementsCache.filter(achievement => achievement.category === category);
}

function getAchievementById(id) {
    return achievementsCache.find(achievement => achievement.id === id);
}

// ===== VERIFICATION WORKFLOW FUNCTIONS =====

let verificationQueueCache = [];

async function loadVerificationQueue() {
    try {
        const verificationSnap = await db.collection('badgeClaims')
            .where('status', '==', 'pending')
            .orderBy('submittedAt', 'desc')
            .get();
            
        verificationQueueCache = verificationSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        
        renderVerificationQueue();
        
    } catch (error) {
        console.error('Error loading verification queue:', error);
        addNotification('Error loading verification queue', 'error');
    }
}

function renderVerificationQueue() {
    const verificationList = document.querySelector('.verification-list');
    const pendingCount = document.getElementById('pending-count');
    
    if (!verificationList) {
        console.warn('Verification list container not found');
        return;
    }
    
    // Update pending count
    if (pendingCount) {
        pendingCount.textContent = verificationQueueCache.length;
    }
    
    if (verificationQueueCache.length === 0) {
        verificationList.innerHTML = `
            <div class="verification-item empty-state">
                <div class="verification-info">
                    <i class="fas fa-check-circle"></i>
                    <p>No pending verifications</p>
                    <small>All badge claims have been processed</small>
                </div>
            </div>
        `;
        return;
    }
    
    verificationList.innerHTML = verificationQueueCache.map(claim => {
        const timeAgo = getTimeAgo(claim.submittedAt);
        const badge = getAchievementById(claim.badgeId);
        
        return `
            <div class="verification-item" data-claim-id="${claim.id}">
                <div class="verification-info">
                    <div class="claim-header">
                        <strong>${claim.studentName}</strong> - ${badge ? badge.name : 'Unknown Badge'}
                        <span class="claim-time">${timeAgo}</span>
                    </div>
                    <div class="claim-details">
                        <small>Event: ${claim.eventTitle}</small>
                        <small>Matrix ID: ${claim.studentMatrixId}</small>
                    </div>
                    <div class="claim-evidence">
                        <strong>Evidence:</strong> ${claim.evidence || 'No evidence provided'}
                    </div>
                </div>
                <div class="verification-actions">
                    <button class="btn btn-sm btn-success" onclick="approveBadgeClaim('${claim.id}')" title="Approve claim">
                        <i class="fas fa-check"></i> Approve
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="rejectBadgeClaim('${claim.id}')" title="Reject claim">
                        <i class="fas fa-times"></i> Reject
                    </button>
                    <button class="btn btn-sm btn-secondary" onclick="viewClaimDetails('${claim.id}')" title="View details">
                        <i class="fas fa-eye"></i> Details
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

async function approveBadgeClaim(claimId) {
    try {
        const claim = verificationQueueCache.find(c => c.id === claimId);
        if (!claim) {
            addNotification('Claim not found', 'error');
            return;
        }
        
        // Update claim status
        await db.collection('badgeClaims').doc(claimId).update({
            status: 'approved',
            approvedAt: new Date().toISOString(),
            approvedBy: auth.currentUser?.email || 'admin'
        });
        
        // Add badge to student's achievements
        await addBadgeToStudent(claim.studentId, claim.badgeId, claim.eventId);
        
        // Remove from verification queue
        verificationQueueCache = verificationQueueCache.filter(c => c.id !== claimId);
        renderVerificationQueue();
        
        addNotification(`Badge claim approved for ${claim.studentName}`, 'success');
        
        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }
        
    } catch (error) {
        console.error('Error approving badge claim:', error);
        addNotification('Error approving claim: ' + error.message, 'error');
    }
}

async function rejectBadgeClaim(claimId) {
    try {
        const claim = verificationQueueCache.find(c => c.id === claimId);
        if (!claim) {
            addNotification('Claim not found', 'error');
            return;
        }
        
        // Update claim status
        await db.collection('badgeClaims').doc(claimId).update({
            status: 'rejected',
            rejectedAt: new Date().toISOString(),
            rejectedBy: auth.currentUser?.email || 'admin'
        });
        
        // Remove from verification queue
        verificationQueueCache = verificationQueueCache.filter(c => c.id !== claimId);
        renderVerificationQueue();
        
        addNotification(`Badge claim rejected for ${claim.studentName}`, 'info');
        
        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }
        
    } catch (error) {
        console.error('Error rejecting badge claim:', error);
        addNotification('Error rejecting claim: ' + error.message, 'error');
    }
}

async function addBadgeToStudent(studentId, badgeId, eventId) {
    try {
        const badge = getAchievementById(badgeId);
        if (!badge) {
            throw new Error('Badge not found');
        }
        
        const studentAchievement = {
            studentId: studentId,
            badgeId: badgeId,
            eventId: eventId,
            badgeName: badge.name,
            badgeIcon: badge.icon,
            badgePoints: badge.points,
            awardedAt: new Date().toISOString(),
            awardedBy: auth.currentUser?.email || 'admin'
        };
        
        await db.collection('studentAchievements').add(studentAchievement);
        
    } catch (error) {
        console.error('Error adding badge to student:', error);
        throw error;
    }
}

function viewClaimDetails(claimId) {
    const claim = verificationQueueCache.find(c => c.id === claimId);
    if (!claim) {
        addNotification('Claim not found', 'error');
        return;
    }
    
    // Show claim details in a modal (placeholder for now)
    const details = `
        Student: ${claim.studentName}
        Matrix ID: ${claim.studentMatrixId}
        Event: ${claim.eventTitle}
        Badge: ${getAchievementById(claim.badgeId)?.name || 'Unknown'}
        Evidence: ${claim.evidence || 'None provided'}
        Submitted: ${new Date(claim.submittedAt).toLocaleString()}
    `;
    
    alert(details); // Replace with proper modal later
}

function getTimeAgo(timestamp) {
    const now = new Date();
    const time = new Date(timestamp);
    const diffInSeconds = Math.floor((now - time) / 1000);
    
    if (diffInSeconds < 60) return 'Just now';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
    return `${Math.floor(diffInSeconds / 86400)}d ago`;
}

// ===== STUDENT BADGE CLAIMING FUNCTIONS =====

let availableEventsCache = [];
let studentClaimsCache = [];

async function loadAllEventsForAssignment() {
    try {
        // Load ALL events in the system
        const eventsSnap = await db.collection('events').get();
        
        if (eventsSnap.docs.length === 0) {
            addNotification('No events found in the system. Please create some events first.', 'info');
        }
            
        availableEventsCache = eventsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        
        // Force render with the data
        renderAllEventsForAssignment();
        
    } catch (error) {
        console.error('Error loading events:', error);
        addNotification('Error loading events: ' + error.message, 'error');
    }
}

function renderAllEventsForAssignment() {
    const eventsContainer = document.getElementById('available-events-container');
    if (!eventsContainer) {
        console.error('Events container not found!');
        return;
    }
    
    if (availableEventsCache.length === 0) {
        eventsContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-calendar-times"></i>
                <h3>No Events Found</h3>
                <p>There are no events in the system yet.</p>
            </div>
        `;
        return;
    }
    
    const eventsHTML = availableEventsCache.map(event => {
        const badges = event.assignedBadges || [];
        const badgeDisplay = badges.length > 0 ? badges.map(badge => 
            `<span class="badge-mini" style="display: inline-block; margin: 0.1rem; padding: 0.2rem 0.4rem; background: linear-gradient(135deg, #fbbf24, #f59e0b); color: white; border-radius: 12px; font-size: 0.7rem; font-weight: 500;">
                ${badge.icon} ${badge.name} (${badge.points} pts)
            </span>`
        ).join('') : '<span class="text-muted">No badges assigned</span>';
        
        return `
            <div class="event-card" data-event-id="${event.id}" style="display: block; visibility: visible; background: white; border: 1px solid #ccc; margin: 10px 0; padding: 15px; border-radius: 8px;">
                <div class="event-header">
                    <h3 style="color: #333; margin: 0 0 10px 0;">${event.title || 'Untitled Event'}</h3>
                    <span class="event-category" style="background: #007bff; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px;">${event.category || 'Uncategorized'}</span>
                </div>
                <div class="event-description" style="color: #666; margin: 10px 0;">
                    ${event.description || 'No description available'}
                </div>
                <div class="event-badges">
                    <h4 style="margin: 10px 0 5px 0; color: #333;">Assigned Badges:</h4>
                    <div class="badges-grid">
                        ${badgeDisplay}
                    </div>
                </div>
                <div class="event-actions" style="margin-top: 15px;">
                    <button class="btn btn-primary" onclick="showAssignBadgeModal('${event.id}')" style="background: #007bff; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; margin-right: 10px;">
                        <i class="fas fa-user-plus"></i> Assign Badge
                    </button>
                    ${badges.length > 0 ? `<button class="btn btn-secondary" onclick="showClaimBadgeModal('${event.id}')" style="background: #6c757d; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;">
                        <i class="fas fa-trophy"></i> View Claims
                    </button>` : ''}
                </div>
            </div>
        `;
    }).join('');
    
    // Create a clean container with proper styling
    const newContainer = document.createElement('div');
    newContainer.id = 'available-events-container';
    newContainer.className = 'events-grid';
    newContainer.style.cssText = `
        display: grid !important;
        grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)) !important;
        gap: 20px !important;
        min-height: 400px !important;
        height: auto !important;
        width: 100% !important;
        padding: 20px !important;
        background-color: #f8f9fa !important;
        border-radius: 8px !important;
        visibility: visible !important;
        opacity: 1 !important;
        position: relative !important;
        z-index: 1 !important;
    `;
    
    // Add all the event cards
    newContainer.innerHTML = eventsHTML;
    
    // Replace the old container
    eventsContainer.parentNode.replaceChild(newContainer, eventsContainer);
    
    // Force the tab pane to be visible
    const tabPane = document.getElementById('available-events-tab');
    if (tabPane) {
        tabPane.style.setProperty('display', 'block', 'important');
        tabPane.classList.add('active');
        
        // Force parent to be visible too
        const parent = tabPane.parentElement;
        if (parent) {
            parent.style.setProperty('display', 'block', 'important');
            parent.style.setProperty('visibility', 'visible', 'important');
            parent.style.setProperty('height', 'auto', 'important');
            parent.style.setProperty('min-height', '400px', 'important');
        }
    }
}

async function showAssignBadgeModal(eventId) {
    const event = availableEventsCache.find(e => e.id === eventId);
    if (!event) {
        addNotification('Event not found', 'error');
        return;
    }
    
    // Load all available badges for selection
    if (!achievementsCache || achievementsCache.length === 0) {
        await loadAchievementsData();
    }

    // Remove any existing modal first to prevent duplicates
    const existingModal = document.getElementById('assign-badge-modal');
    if (existingModal) {
        console.log('Removing existing assign-badge-modal');
        existingModal.remove();
    }

    // Create modal dynamically
    const modal = document.createElement('div');
    modal.id = 'assign-badge-modal';
    modal.className = 'modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fas fa-user-plus"></i> Assign Badge to Student - ${event.title}</h3>
                <span class="close" onclick="closeAndCleanupModal('assign-badge-modal')">&times;</span>
            </div>
            <form id="assign-badge-form">
                <div class="form-group">
                    <label for="assign-student-name">
                        <i class="fas fa-user"></i> Student Name *
                    </label>
                    <input type="text" id="assign-student-name" required placeholder="Student's full name">
                </div>
                
                <div class="form-group">
                    <label for="assign-student-matrix">
                        <i class="fas fa-id-card"></i> Matrix Number *
                    </label>
                    <input type="text" id="assign-student-matrix" required placeholder="e.g., BB123456">
                </div>
                
                <div class="form-group">
                    <label for="assign-badge-select">
                        <i class="fas fa-trophy"></i> Select Badge *
                    </label>
                    <select id="assign-badge-select" required>
                        <option value="">Choose a badge to assign...</option>
                        ${achievementsCache.map(badge => 
                            `<option value="${badge.id}">${badge.icon} ${badge.name} (${badge.points} pts)</option>`
                        ).join('')}
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="assign-reason">
                        <i class="fas fa-comment"></i> Reason for Assignment
                    </label>
                    <textarea id="assign-reason" rows="3" placeholder="Optional: Explain why this badge is being assigned..."></textarea>
                </div>
                
                <div class="form-actions">
                    <button type="button" class="btn btn-secondary" onclick="closeAndCleanupModal('assign-badge-modal')">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-check"></i> Assign Badge
                    </button>
                </div>
            </form>
        </div>
    `;
    
    // Add modal to body
    document.body.appendChild(modal);
    
    // Setup form submission with single-use protection
    const form = document.getElementById('assign-badge-form');
    let isSubmitting = false;
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        if (isSubmitting) return; // Prevent double submission
        isSubmitting = true;

        try {
            await handleAssignBadge(form, eventId);
        } finally {
            isSubmitting = false;
        }
    });
    
    // Show modal
    modal.classList.add('show');
    modal.style.display = 'flex';
}

async function showClaimBadgeModal(eventId) {
    const event = availableEventsCache.find(e => e.id === eventId);
    if (!event) {
        addNotification('Event not found', 'error');
        return;
    }
    
    // Remove any existing modal first to prevent duplicates
    const existingModal = document.getElementById('claim-badge-modal');
    if (existingModal) {
        console.log('Removing existing claim-badge-modal');
        existingModal.remove();
    }

    // Create modal dynamically
    const modal = document.createElement('div');
    modal.id = 'claim-badge-modal';
    modal.className = 'modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fas fa-trophy"></i> Claim Badge - ${event.title}</h3>
                <span class="close" onclick="closeAndCleanupModal('claim-badge-modal')">&times;</span>
            </div>
            <form id="claim-badge-form">
                <div class="form-group">
                    <label for="claim-student-name">
                        <i class="fas fa-user"></i> Student Name *
                    </label>
                    <input type="text" id="claim-student-name" required placeholder="Your full name">
                </div>
                
                <div class="form-group">
                    <label for="claim-student-matrix">
                        <i class="fas fa-id-card"></i> Matrix Number *
                    </label>
                    <input type="text" id="claim-student-matrix" required placeholder="e.g., BB123456">
                </div>
                
                <div class="form-group">
                    <label for="claim-badge-select">
                        <i class="fas fa-award"></i> Select Badge to Claim *
                    </label>
                    <select id="claim-badge-select" required>
                        <option value="">Choose a badge...</option>
                        ${(event.assignedBadges || []).map(badge => 
                            `<option value="${badge.id}">${badge.icon} ${badge.name} (${badge.points} pts)</option>`
                        ).join('')}
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="claim-evidence">
                        <i class="fas fa-file-alt"></i> Evidence of Participation *
                    </label>
                    <textarea id="claim-evidence" required rows="4" placeholder="Describe how you participated in this event. Include any certificates, photos, or other evidence..."></textarea>
                </div>
                
                <div class="form-actions">
                    <button type="button" class="btn btn-secondary" onclick="closeAndCleanupModal('claim-badge-modal')">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-paper-plane"></i> Submit Claim
                    </button>
                </div>
            </form>
        </div>
    `;
    
    // Add modal to body
    document.body.appendChild(modal);
    
    // Setup form submission with single-use protection
    const form = document.getElementById('claim-badge-form');
    let isSubmitting = false;
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        if (isSubmitting) return; // Prevent double submission
        isSubmitting = true;

        try {
            await handleBadgeClaim(form, eventId);
        } finally {
            isSubmitting = false;
        }
    });
    
    // Show modal
    modal.classList.add('show');
    modal.style.display = 'flex';
}

async function handleAssignBadge(form, eventId) {
    try {
        const studentName = document.getElementById('assign-student-name').value.trim();
        const studentMatrix = document.getElementById('assign-student-matrix').value.trim();
        const badgeId = document.getElementById('assign-badge-select').value;
        const reason = document.getElementById('assign-reason').value.trim();
        
        if (!studentName || !studentMatrix || !badgeId) {
            addNotification('Please fill in all required fields', 'error');
            return;
        }
        
        const event = availableEventsCache.find(e => e.id === eventId);
        const badge = achievementsCache.find(b => b.id === badgeId);
        
        if (!event || !badge) {
            addNotification('Invalid event or badge selection', 'error');
            return;
        }
        
        // Directly add badge to student (no claim process needed)
        const studentAchievement = {
            studentId: studentMatrix,
            studentName: studentName,
            studentMatrixId: studentMatrix,
            badgeId: badgeId,
            badgeName: badge.name,
            badgeIcon: badge.icon,
            badgePoints: badge.points,
            eventId: eventId,
            eventTitle: event.title,
            awardedAt: new Date().toISOString(),
            awardedBy: auth.currentUser?.email || 'admin',
            reason: reason || 'Direct assignment by admin',
            status: 'awarded'
        };
        
        await db.collection('studentAchievements').add(studentAchievement);
        
        closeAndCleanupModal('assign-badge-modal');
        addNotification(`Badge "${badge.name}" assigned to ${studentName} successfully!`, 'success');
        
        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }
        
    } catch (error) {
        console.error('Error assigning badge:', error);
        addNotification('Error assigning badge: ' + error.message, 'error');
    }
}

async function handleBadgeClaim(form, eventId) {
    try {
        const studentName = document.getElementById('claim-student-name').value.trim();
        const studentMatrix = document.getElementById('claim-student-matrix').value.trim();
        const badgeId = document.getElementById('claim-badge-select').value;
        const evidence = document.getElementById('claim-evidence').value.trim();
        
        if (!studentName || !studentMatrix || !badgeId || !evidence) {
            addNotification('Please fill in all required fields', 'error');
            return;
        }
        
        const event = availableEventsCache.find(e => e.id === eventId);
        const badge = event.assignedBadges.find(b => b.id === badgeId);
        
        if (!event || !badge) {
            addNotification('Invalid event or badge selection', 'error');
            return;
        }
        
        // Create badge claim
        const claimData = {
            studentId: studentMatrix, // Use matrix ID as student ID
            studentName: studentName,
            studentMatrixId: studentMatrix,
            badgeId: badgeId,
            eventId: eventId,
            eventTitle: event.title,
            evidence: evidence,
            status: 'pending',
            submittedAt: new Date().toISOString()
        };
        
        await db.collection('badgeClaims').add(claimData);
        
        closeAndCleanupModal('claim-badge-modal');
        addNotification('Badge claim submitted successfully! It will be reviewed by a lecturer.', 'success');
        
        // Reload verification queue for lecturers
        loadVerificationQueue();
        
    } catch (error) {
        console.error('Error submitting badge claim:', error);
        addNotification('Error submitting claim: ' + error.message, 'error');
    }
}

async function loadStudentClaims() {
    try {
        // Load recent badge claims (both pending and approved)
        const claimsSnap = await db.collection('badgeClaims')
            .orderBy('submittedAt', 'desc')
            .limit(20) // Show last 20 claims
            .get();
            
        const claims = [];
        for (const doc of claimsSnap.docs) {
            const claimData = doc.data();
            
            // Get student info
            let studentName = 'Unknown Student';
            let studentMatrixId = 'Unknown';
            
            if (claimData.studentId) {
                try {
                    const studentDoc = await db.collection('users').doc(claimData.studentId).get();
                    if (studentDoc.exists) {
                        const studentData = studentDoc.data();
                        studentName = studentData.name || 'Unknown Student';
                        studentMatrixId = studentData.matrixId || 'Unknown';
                    }
                } catch (error) {
                    console.error('Error fetching student info:', error);
                }
            }
            
            claims.push({
                id: doc.id,
                ...claimData,
                studentName,
                studentMatrixId
            });
        }
        
        studentClaimsCache = claims;
        renderStudentClaims();
        
    } catch (error) {
        console.error('Error loading student claims:', error);
        addNotification('Error loading claims: ' + error.message, 'error');
    }
}

function renderStudentClaims() {
    const claimsContainer = document.getElementById('student-claims-container');
    if (!claimsContainer) {
        console.warn('Student claims container not found');
        return;
    }
    
    if (studentClaimsCache.length === 0) {
        claimsContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <h3>No Recent Claims</h3>
                <p>No badge claims have been submitted recently.</p>
            </div>
        `;
        return;
    }
    
    const claimsHTML = studentClaimsCache.map(claim => {
        const badge = getAchievementById(claim.badgeId);
        const statusClass = claim.status === 'approved' ? 'success' : 
                           claim.status === 'rejected' ? 'danger' : 'warning';
        const statusIcon = claim.status === 'approved' ? 'check-circle' : 
                          claim.status === 'rejected' ? 'times-circle' : 'clock';
        
        return `
            <div class="claim-card ${statusClass}">
                <div class="claim-header">
                    <div class="claim-badge">
                        ${badge ? badge.icon : '🏆'} ${badge ? badge.name : 'Unknown Badge'}
                    </div>
                    <div class="claim-status">
                        <i class="fas fa-${statusIcon}"></i>
                        ${claim.status.charAt(0).toUpperCase() + claim.status.slice(1)}
                    </div>
                </div>
                <div class="claim-details">
                    <p><strong>Student:</strong> ${claim.studentName} (${claim.studentMatrixId})</p>
                    <p><strong>Event:</strong> ${claim.eventTitle}</p>
                    <p><strong>Submitted:</strong> ${new Date(claim.submittedAt).toLocaleDateString()}</p>
                    ${claim.status === 'approved' ? `<p><strong>Awarded:</strong> ${new Date(claim.approvedAt).toLocaleDateString()}</p>` : ''}
                    ${claim.evidence ? `<p><strong>Evidence:</strong> ${claim.evidence.substring(0, 100)}${claim.evidence.length > 100 ? '...' : ''}</p>` : ''}
                </div>
            </div>
        `;
    }).join('');
    
    // Create a clean container for claims
    const newContainer = document.createElement('div');
    newContainer.id = 'student-claims-container';
    newContainer.className = 'claims-grid';
    newContainer.style.cssText = `
        display: grid !important;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)) !important;
        gap: 20px !important;
        min-height: 400px !important;
        height: auto !important;
        width: 100% !important;
        padding: 20px !important;
        background-color: #f8f9fa !important;
        border-radius: 8px !important;
        visibility: visible !important;
        opacity: 1 !important;
        position: relative !important;
        z-index: 1 !important;
    `;
    
    newContainer.innerHTML = claimsHTML;
    
    // Replace the old container
    claimsContainer.parentNode.replaceChild(newContainer, claimsContainer);
}

// Test function removed - no more dummy data

// ===== BADGE TABLE MANAGEMENT =====

async function loadBadgesTable() {
    try {
        // Load achievements data if not already cached
        if (!achievementsCache || achievementsCache.length === 0) {
            await loadAchievementsData();
        }
        
        renderBadgesTable(achievementsCache);
        
    } catch (error) {
        console.error('Error loading badges table:', error);
        addNotification('Error loading badges table: ' + error.message, 'error');
    }
}

function renderBadgesTable(badges) {
    const tableBody = document.getElementById('badges-table-body');
    if (!tableBody) {
        console.warn('Badges table body not found');
        return;
    }
    
    if (!badges || badges.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="6" class="empty-state">
                    <i class="fas fa-trophy"></i>
                    <h3>No Badges Created</h3>
                    <p>Create your first achievement badge to get started.</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tableBody.innerHTML = badges.map(badge => {
        const createdDate = new Date(badge.createdAt).toLocaleDateString();
        const difficultyClass = badge.difficulty || 'beginner';
        
        return `
            <tr data-badge-id="${badge.id}">
                <td>
                    <div class="badge-display">
                        <span class="badge-icon-mini">${badge.icon || '🏆'}</span>
                        <div class="badge-info">
                            <div class="badge-name">${badge.name}</div>
                            <div class="badge-description">${badge.description.substring(0, 50)}${badge.description.length > 50 ? '...' : ''}</div>
                        </div>
                    </div>
                </td>
                <td>
                    <span class="category-badge ${badge.category}">${badge.category}</span>
                </td>
                <td>
                    <span class="points-badge">${badge.points} pts</span>
                </td>
                <td>
                    <span class="difficulty-badge ${difficultyClass}">${badge.difficulty || 'Beginner'}</span>
                </td>
                <td>${createdDate}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="showEditBadgeModal('${badge.id}')" title="Edit badge">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="showDeleteBadgeModal('${badge.id}')" title="Delete badge">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

function filterBadges() {
    const searchTerm = document.getElementById('badge-search')?.value.toLowerCase() || '';
    const categoryFilter = document.getElementById('badge-category-filter')?.value || '';
    
    let filteredBadges = achievementsCache;
    
    if (searchTerm) {
        filteredBadges = filteredBadges.filter(badge => 
            badge.name.toLowerCase().includes(searchTerm) ||
            badge.description.toLowerCase().includes(searchTerm)
        );
    }
    
    if (categoryFilter) {
        filteredBadges = filteredBadges.filter(badge => 
            badge.category === categoryFilter
        );
    }
    
    renderBadgesTable(filteredBadges);
}

// ===== EDIT BADGE FUNCTIONS =====

function showEditBadgeModal(badgeId) {
    const badge = getAchievementById(badgeId);
    if (!badge) {
        addNotification('Badge not found', 'error');
        return;
    }
    
    // Populate the edit form
    populateEditForm(badge);
    
    // Show the modal
    const modal = document.getElementById('edit-achievement-modal');
    if (modal) {
        modal.classList.add('show');
        modal.style.display = 'flex';
    }
}

function populateEditForm(badge) {
    // Set badge ID
    document.getElementById('edit-achievement-id').value = badge.id;
    
    // Populate form fields
    document.getElementById('edit-achievement-name').value = badge.name || '';
    document.getElementById('edit-achievement-category').value = badge.category || '';
    document.getElementById('edit-achievement-description').value = badge.description || '';
    document.getElementById('edit-achievement-points').value = badge.points || 0;
    document.getElementById('edit-achievement-difficulty').value = badge.difficulty || '';
    document.getElementById('edit-achievement-requirements').value = badge.requirements || '';
    document.getElementById('edit-achievement-icon').value = badge.icon || '🏆';
    document.getElementById('edit-achievement-color').value = badge.color || 'gold';
    
    // Update preview
    updateEditBadgePreview();
}

function updateEditBadgePreview() {
    const nameInput = document.getElementById('edit-achievement-name');
    const pointsInput = document.getElementById('edit-achievement-points');
    const iconSelect = document.getElementById('edit-achievement-icon');
    const colorSelect = document.getElementById('edit-achievement-color');
    
    const badgePreview = document.getElementById('edit-badge-preview');
    if (!badgePreview) return;
    
    const badgeIcon = badgePreview.querySelector('.badge-icon');
    const badgeName = badgePreview.querySelector('.badge-name');
    const badgePoints = badgePreview.querySelector('.badge-points');

    const name = nameInput?.value || 'Badge Name';
    const points = pointsInput?.value || '0';
    const icon = iconSelect?.value || '🏆';
    const color = colorSelect?.value || 'gold';

    badgeIcon.textContent = icon;
    badgeName.textContent = name.length > 12 ? name.substring(0, 12) + '...' : name;
    badgePoints.textContent = `${points} pts`;

    // Update color theme
    badgePreview.className = `badge-preview ${color}`;
}

async function handleEditBadge(form, badgeId) {
    try {
        // Prevent multiple submissions
        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn.disabled) {
            return;
        }
        
        // Get form values
        const achievementData = {
            name: document.getElementById('edit-achievement-name')?.value?.trim(),
            category: document.getElementById('edit-achievement-category')?.value,
            description: document.getElementById('edit-achievement-description')?.value?.trim(),
            points: parseInt(document.getElementById('edit-achievement-points')?.value) || 0,
            difficulty: document.getElementById('edit-achievement-difficulty')?.value,
            requirements: document.getElementById('edit-achievement-requirements')?.value?.trim(),
            icon: document.getElementById('edit-achievement-icon')?.value || '🏆',
            color: document.getElementById('edit-achievement-color')?.value || 'gold',
            updatedAt: new Date().toISOString()
        };

        // Validation
        if (!achievementData.name || !achievementData.category || !achievementData.description) {
            addNotification('Please fill in all required fields', 'error');
            return;
        }

        if (achievementData.points < 1 || achievementData.points > 1000) {
            addNotification('Points must be between 1 and 1000', 'error');
            return;
        }

        // Add loading state
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Updating...';
        submitBtn.disabled = true;

        // Update in Firebase
        await db.collection('achievements').doc(badgeId).update(achievementData);

        addNotification(`Achievement badge "${achievementData.name}" updated successfully!`, 'success');
        closeModal('edit-achievement-modal');
        form.reset();
        
        // Refresh data
        await loadAchievementsData();
        loadBadgesTable();
        
        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }

    } catch (error) {
        console.error('Error updating achievement:', error);
        addNotification('Error updating achievement: ' + error.message, 'error');
    } finally {
        // Reset button state
        if (submitBtn) {
            submitBtn.innerHTML = '<i class="fas fa-save"></i> Update Badge';
            submitBtn.disabled = false;
        }
    }
}

// ===== DELETE BADGE FUNCTIONS =====

let badgeToDelete = null;

function showDeleteBadgeModal(badgeId) {
    console.log('showDeleteBadgeModal called with badgeId:', badgeId);
    
    const badge = getAchievementById(badgeId);
    if (!badge) {
        console.error('Badge not found for ID:', badgeId);
        addNotification('Badge not found', 'error');
        return;
    }
    
    console.log('Found badge:', badge);
    badgeToDelete = badge;
    
    // Reset modal state before populating new content
    resetDeleteModal();
    
    // Populate badge details
    populateDeleteModal(badge);
    
    // Check badge usage
    checkBadgeUsage(badgeId);
    
    // Show the modal
    const modal = document.getElementById('delete-achievement-modal');
    if (modal) {
        modal.classList.add('show');
        modal.style.display = 'flex';
        console.log('Delete modal shown');
    } else {
        console.error('Delete modal not found');
    }
}

function populateDeleteModal(badge) {
    const detailsContainer = document.getElementById('delete-badge-details');
    if (!detailsContainer) return;
    
    const createdDate = new Date(badge.createdAt).toLocaleDateString();
    const difficultyClass = badge.difficulty || 'beginner';
    
    detailsContainer.innerHTML = `
        <div class="badge-info-card">
            <div class="badge-header">
                <span class="badge-icon-large">${badge.icon || '🏆'}</span>
                <div class="badge-title">
                    <h4>${badge.name}</h4>
                    <span class="category-badge ${badge.category}">${badge.category}</span>
                </div>
            </div>
            <div class="badge-content">
                <p><strong>Description:</strong> ${badge.description}</p>
                <div class="badge-stats">
                    <span class="points-badge">${badge.points} pts</span>
                    <span class="difficulty-badge ${difficultyClass}">${badge.difficulty || 'Beginner'}</span>
                </div>
                <p><strong>Created:</strong> ${createdDate}</p>
                ${badge.requirements ? `<p><strong>Requirements:</strong> ${badge.requirements}</p>` : ''}
            </div>
        </div>
    `;
}

async function checkBadgeUsage(badgeId) {
    try {
        // Check if badge is assigned to any events
        const eventsSnap = await db.collection('events')
            .where('assignedBadges', '!=', null)
            .get();
            
        const eventsWithBadge = eventsSnap.docs.filter(doc => {
            const event = doc.data();
            return event.assignedBadges && event.assignedBadges.some(badge => badge.id === badgeId);
        });
        
        // Check if badge has been awarded to any students
        const claimsSnap = await db.collection('badgeClaims')
            .where('badgeId', '==', badgeId)
            .get();
            
        const hasClaims = !claimsSnap.empty;
        
        // Show appropriate warning
        const usageWarning = document.getElementById('usage-warning');
        const safeDelete = document.getElementById('safe-delete');
        const confirmBtn = document.getElementById('confirm-delete-btn');
        
        if (eventsWithBadge.length > 0 || hasClaims) {
            // Badge is in use - show warning
            if (usageWarning) usageWarning.style.display = 'block';
            if (safeDelete) safeDelete.style.display = 'none';
            if (confirmBtn) {
                confirmBtn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Delete Anyway';
                confirmBtn.className = 'btn btn-danger btn-warning';
            }
        } else {
            // Safe to delete
            if (usageWarning) usageWarning.style.display = 'none';
            if (safeDelete) safeDelete.style.display = 'block';
            if (confirmBtn) {
                confirmBtn.innerHTML = '<i class="fas fa-trash"></i> Delete Badge';
                confirmBtn.className = 'btn btn-danger';
            }
        }
        
    } catch (error) {
        console.error('Error checking badge usage:', error);
        // Default to showing warning if we can't check
        const usageWarning = document.getElementById('usage-warning');
        if (usageWarning) usageWarning.style.display = 'block';
    }
}

async function confirmDeleteBadge() {
    if (!badgeToDelete) {
        addNotification('No badge selected for deletion', 'error');
        return;
    }
    
    try {
        const confirmBtn = document.getElementById('confirm-delete-btn');
        if (confirmBtn) {
            confirmBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Deleting...';
            confirmBtn.disabled = true;
        }
        
        console.log('Attempting to delete badge:', badgeToDelete.id, badgeToDelete.name);
        
        // Delete from Firebase
        await db.collection('achievements').doc(badgeToDelete.id).delete();
        
        console.log('Badge deleted successfully from Firebase');
        
        addNotification(`Badge "${badgeToDelete.name}" deleted successfully!`, 'success');
        
        // Reset modal state completely
        resetDeleteModal();
        
        // Close modal
        if (typeof closeModal === 'function') {
            closeModal('delete-achievement-modal');
        } else {
            const modal = document.getElementById('delete-achievement-modal');
            if (modal) {
                modal.style.display = 'none';
                modal.classList.remove('show');
            }
        }
        
        // Reset badge to delete
        badgeToDelete = null;
        
        // Refresh data
        await loadAchievementsData();
        loadBadgesTable();
        
        // Refresh overview stats
        if (typeof window.refreshOverviewStats === 'function') {
            await window.refreshOverviewStats();
        }
        
    } catch (error) {
        console.error('Error deleting badge:', error);
        addNotification('Error deleting badge: ' + error.message, 'error');
        
        // Reset button state on error
        resetDeleteModalButton();
    }
}

function resetDeleteModal() {
    // Reset button state
    resetDeleteModalButton();
    
    // Clear badge details
    const detailsContainer = document.getElementById('delete-badge-details');
    if (detailsContainer) {
        detailsContainer.innerHTML = '';
    }
    
    // Reset usage warning/safe messages
    const usageWarning = document.getElementById('usage-warning');
    const safeDelete = document.getElementById('safe-delete');
    
    if (usageWarning) {
        usageWarning.style.display = 'none';
    }
    if (safeDelete) {
        safeDelete.style.display = 'none';
    }
    
    console.log('Delete modal state reset successfully');
}

function resetDeleteModalButton() {
    const confirmBtn = document.getElementById('confirm-delete-btn');
    if (confirmBtn) {
        confirmBtn.innerHTML = '<i class="fas fa-trash"></i> Delete Badge';
        confirmBtn.disabled = false;
        confirmBtn.className = 'btn btn-danger';
    }
}

// ===== QR CODE CLAIM PROCESSING =====

// Process QR code badge claims automatically
async function processQRCodeClaim(claimId, action, reason = '') {
    try {
        const claimRef = doc(db, 'badgeClaims', claimId);
        const claimDoc = await getDoc(claimRef);
        
        if (!claimDoc.exists()) {
            throw new Error('Claim not found');
        }
        
        const claimData = claimDoc.data();
        const updateData = {
            status: action, // 'approved' or 'rejected'
            processedAt: new Date().toISOString(),
            processedBy: auth.currentUser?.uid || 'admin',
            updatedAt: new Date().toISOString()
        };
        
        if (action === 'rejected' && reason) {
            updateData.rejectionReason = reason;
        }
        
        // Update the claim
        await updateDoc(claimRef, updateData);
        
        // If approved, create the achievement
        if (action === 'approved') {
            await createAchievementFromClaim(claimData);
        }
        
        // Send notification to student
        await sendClaimNotification(claimData.userId, action, claimData.badgeName);
        
        // Refresh the claims list
        await loadStudentClaims();
        
        addNotification(`Claim ${action} successfully`, 'success');
        
    } catch (error) {
        console.error('Error processing QR code claim:', error);
        addNotification(`Error processing claim: ${error.message}`, 'error');
    }
}

// Create achievement from approved claim
async function createAchievementFromClaim(claimData) {
    try {
        // Get badge information
        const badgeRef = doc(db, 'achievements', claimData.badgeId);
        const badgeDoc = await getDoc(badgeRef);
        
        if (!badgeDoc.exists()) {
            throw new Error('Badge not found');
        }
        
        const badgeData = badgeDoc.data();
        
        // Create achievement for the user
        const achievementData = {
            userId: claimData.userId,
            title: badgeData.name,
            description: `Earned from ${claimData.eventName} via QR code claim`,
            type: badgeData.category || 'other',
            points: badgeData.points || 0,
            organization: claimData.eventName,
            date: claimData.claimedAt,
            isVerified: true, // Auto-verified since it's from QR code
            verifiedBy: auth.currentUser?.uid || 'admin',
            verifiedAt: new Date().toISOString(),
            claimSource: 'qr_code',
            originalClaimId: claimData.id,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        await addDoc(collection(db, 'achievements'), achievementData);
        
    } catch (error) {
        console.error('Error creating achievement from claim:', error);
        throw error;
    }
}

// Send notification to student about claim status
async function sendClaimNotification(userId, status, badgeName) {
    try {
        const notificationData = {
            userId: userId,
            title: `Badge Claim ${status.charAt(0).toUpperCase() + status.slice(1)}`,
            message: status === 'approved' 
                ? `Your claim for "${badgeName}" has been approved! The badge has been added to your profile.`
                : `Your claim for "${badgeName}" has been rejected. Please contact an administrator for more information.`,
            type: status === 'approved' ? 'success' : 'warning',
            read: false,
            createdAt: new Date().toISOString()
        };
        
        await addDoc(collection(db, 'notifications'), notificationData);
        
    } catch (error) {
        console.error('Error sending claim notification:', error);
    }
}

// Load all badge claims for admin verification
async function loadAllBadgeClaims() {
    try {
        const claimsSnapshot = await getDocs(collection(db, 'badgeClaims'));
        const claims = [];
        
        for (const doc of claimsSnapshot.docs) {
            const claimData = doc.data();
            claims.push({
                id: doc.id,
                ...claimData
            });
        }
        
        // Sort by creation date (newest first)
        claims.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        
        return claims;
        
    } catch (error) {
        console.error('Error loading all badge claims:', error);
        throw error;
    }
}

// Render badge claims table for admin
function renderBadgeClaimsTable(claims) {
    const container = document.getElementById('badge-claims-container');
    if (!container) {
        console.warn('Badge claims container not found');
        return;
    }
    
    if (!claims || claims.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-qr-code"></i>
                <h3>No Badge Claims</h3>
                <p>No badge claims have been submitted yet.</p>
            </div>
        `;
        return;
    }
    
    const claimsHtml = claims.map(claim => {
        const statusClass = claim.status === 'approved' ? 'success' : 
                           claim.status === 'rejected' ? 'danger' : 'warning';
        const statusIcon = claim.status === 'approved' ? 'check-circle' : 
                          claim.status === 'rejected' ? 'times-circle' : 'clock';
        
        const claimMethodIcon = claim.claimMethod === 'qr_code' ? 'qr-code' : 'edit';
        const claimMethodText = claim.claimMethod === 'qr_code' ? 'QR Code' : 'Manual';
        
        return `
            <div class="claim-card ${statusClass}">
                <div class="claim-header">
                    <div class="claim-info">
                        <div class="claim-badge">
                            <i class="fas fa-trophy"></i> ${claim.badgeName || 'Unknown Badge'}
                        </div>
                        <div class="claim-event">
                            <i class="fas fa-calendar"></i> ${claim.eventName || 'Unknown Event'}
                        </div>
                        <div class="claim-method">
                            <i class="fas fa-${claimMethodIcon}"></i> ${claimMethodText}
                        </div>
                    </div>
                    <div class="claim-status">
                        <i class="fas fa-${statusIcon}"></i>
                        ${claim.status.charAt(0).toUpperCase() + claim.status.slice(1)}
                    </div>
                </div>
                <div class="claim-details">
                    <p><strong>Student:</strong> ${claim.userId}</p>
                    <p><strong>Claimed:</strong> ${new Date(claim.claimedAt).toLocaleDateString()}</p>
                    <p><strong>Unique Code:</strong> ${claim.uniqueCode}</p>
                    ${claim.status === 'pending' ? `
                        <div class="claim-actions">
                            <button class="btn btn-success btn-sm" onclick="processQRCodeClaim('${claim.id}', 'approved')">
                                <i class="fas fa-check"></i> Approve
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="rejectClaimWithReason('${claim.id}')">
                                <i class="fas fa-times"></i> Reject
                            </button>
                        </div>
                    ` : ''}
                    ${claim.rejectionReason ? `
                        <div class="rejection-reason">
                            <strong>Rejection Reason:</strong> ${claim.rejectionReason}
                        </div>
                    ` : ''}
                </div>
            </div>
        `;
    }).join('');
    
    container.innerHTML = claimsHtml;
}

// Reject claim with reason
function rejectClaimWithReason(claimId) {
    const reason = prompt('Please provide a reason for rejection:');
    if (reason !== null) {
        processQRCodeClaim(claimId, 'rejected', reason);
    }
}

// ===== PUBLIC API =====

export { 
    setupAchievementsSection,
    showAddAchievementModal,
    handleAddAchievement,
    loadAchievementsData,
    updateAchievementStats,
    getAchievementsByCategory,
    getAchievementById,
    achievementsCache,
    loadVerificationQueue,
    approveBadgeClaim,
    rejectBadgeClaim,
    viewClaimDetails,
    loadAllEventsForAssignment,
    showAssignBadgeModal,
    handleAssignBadge,
    showClaimBadgeModal,
    handleBadgeClaim,
    loadStudentClaims,
    loadBadgesTable,
    showEditBadgeModal,
    handleEditBadge,
    filterBadges,
    showDeleteBadgeModal,
    confirmDeleteBadge,
    resetDeleteModal,
    resetDeleteModalButton,
    // QR Code Claim Processing
    processQRCodeClaim,
    createAchievementFromClaim,
    sendClaimNotification,
    loadAllBadgeClaims,
    renderBadgeClaimsTable,
    rejectClaimWithReason
};