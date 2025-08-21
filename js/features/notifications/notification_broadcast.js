// Firebase removed - using backend API instead
import { addNotification, closeModal } from '../../ui/notifications.js';

let notificationBroadcastInitialized = false;

// Initialize notification broadcast section
export function setupNotificationBroadcast() {
    if (notificationBroadcastInitialized) return;
    
    console.log('Setting up notification broadcast...');
    
    // Setup event listeners
    setupBroadcastEventListeners();
    
    notificationBroadcastInitialized = true;
}

function setupBroadcastEventListeners() {
    // Send notification form
    const sendNotificationForm = document.getElementById('send-notification-form');
    if (sendNotificationForm) {
        sendNotificationForm.addEventListener('submit', handleSendNotification);
    }
    
    // Target audience change
    const targetAudienceSelect = document.getElementById('target-audience');
    if (targetAudienceSelect) {
        targetAudienceSelect.addEventListener('change', handleTargetAudienceChange);
    }
}

async function handleSendNotification(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    
    const notificationData = {
        title: formData.get('title'),
        message: formData.get('message'),
        type: formData.get('type') || 'system',
        targetAudience: formData.get('target-audience'),
        actionUrl: formData.get('action-url') || null,
    };
    
    // Validate required fields
    if (!notificationData.title || !notificationData.message) {
        addNotification('Please fill in all required fields', 'error');
        return;
    }
    
    try {
        await sendBroadcastNotification(notificationData);
        
        // Reset form and close modal
        form.reset();
        closeModal('send-notification-modal');
        
        addNotification('Notification sent successfully!', 'success');
        
    } catch (error) {
        console.error('Error sending notification:', error);
        addNotification('Error sending notification: ' + error.message, 'error');
    }
}

async function sendBroadcastNotification(notificationData) {
    console.log('Sending broadcast notification:', notificationData);
    
    // Get target users based on audience selection
    let targetUsers = [];
    
    switch (notificationData.targetAudience) {
        case 'all':
            targetUsers = await getAllActiveUsers();
            break;
        case 'students':
            targetUsers = await getUsersByRole('student');
            break;
        case 'lecturers':
            targetUsers = await getUsersByRole('lecturer');
            break;
        case 'admins':
            targetUsers = await getUsersByRole('admin');
            break;
        default:
            throw new Error('Invalid target audience');
    }
    
    if (targetUsers.length === 0) {
        throw new Error('No users found for the selected audience');
    }
    
    // Create notifications for all target users
    const batch = db.batch();
    let notificationCount = 0;
    
    targetUsers.forEach((user) => {
        const notificationRef = db.collection('notifications').doc();
        
        batch.set(notificationRef, {
            userId: user.uid,
            title: notificationData.title,
            message: notificationData.message,
            type: notificationData.type,
            isRead: false,
            createdAt: new Date().toISOString(),
            data: {
                broadcast: true,
                targetAudience: notificationData.targetAudience,
                sentBy: 'admin', // You might want to get actual admin info
            },
            actionUrl: notificationData.actionUrl,
        });
        
        notificationCount++;
    });
    
    await batch.commit();
    console.log(`Successfully sent ${notificationCount} notifications`);
    
    return notificationCount;
}

async function getAllActiveUsers() {
    try {
        const snapshot = await db.collection('users')
            .where('isActive', '==', true)
            .get();
        
        return snapshot.docs.map(doc => doc.data());
    } catch (error) {
        console.error('Error getting all active users:', error);
        return [];
    }
}

async function getUsersByRole(role) {
    try {
        const snapshot = await db.collection('users')
            .where('role', '==', role)
            .where('isActive', '==', true)
            .get();
        
        return snapshot.docs.map(doc => doc.data());
    } catch (error) {
        console.error(`Error getting users by role ${role}:`, error);
        return [];
    }
}

function handleTargetAudienceChange(event) {
    const selectedAudience = event.target.value;
    console.log('Target audience changed to:', selectedAudience);
    
    // You can add logic here to show/hide additional options
    // or update the UI based on the selected audience
}

// Show send notification modal
export function showSendNotificationModal() {
    const modal = document.getElementById('send-notification-modal');
    if (modal) {
        modal.style.display = 'block';
        modal.classList.add('show');
        
        // Focus on title field
        const titleField = document.getElementById('notification-title');
        if (titleField) {
            setTimeout(() => titleField.focus(), 100);
        }
    }
}

// Send quick notification (for common scenarios)
export async function sendQuickNotification(type, targetAudience = 'all') {
    const quickNotifications = {
        'maintenance': {
            title: 'System Maintenance',
            message: 'The system will undergo maintenance tonight from 11 PM to 1 AM. Please save your work.',
            type: 'system'
        },
        'new-feature': {
            title: 'New Feature Available!',
            message: 'We\'ve added new features to enhance your experience. Check them out!',
            type: 'system'
        },
        'event-reminder': {
            title: 'Upcoming Events',
            message: 'Don\'t forget to check out the upcoming events this week!',
            type: 'event'
        },
        'profile-reminder': {
            title: 'Complete Your Profile',
            message: 'Complete your profile to get the most out of the platform.',
            type: 'reminder'
        }
    };
    
    const notificationTemplate = quickNotifications[type];
    if (!notificationTemplate) {
        throw new Error('Invalid quick notification type');
    }
    
    try {
        const count = await sendBroadcastNotification({
            ...notificationTemplate,
            targetAudience: targetAudience
        });
        
        addNotification(`Quick notification sent to ${count} users`, 'success');
        return count;
        
    } catch (error) {
        console.error('Error sending quick notification:', error);
        addNotification('Error sending quick notification: ' + error.message, 'error');
        throw error;
    }
}

// Get notification statistics
export async function getNotificationStats() {
    try {
        const snapshot = await db.collection('notifications')
            .orderBy('createdAt', 'desc')
            .limit(100)
            .get();
        
        const notifications = snapshot.docs.map(doc => doc.data());
        
        const stats = {
            total: notifications.length,
            unread: notifications.filter(n => !n.isRead).length,
            byType: {},
            recent: notifications.slice(0, 10)
        };
        
        // Count by type
        notifications.forEach(notification => {
            const type = notification.type || 'unknown';
            stats.byType[type] = (stats.byType[type] || 0) + 1;
        });
        
        return stats;
        
    } catch (error) {
        console.error('Error getting notification stats:', error);
        return null;
    }
}

// Export functions
export {
    setupNotificationBroadcast,
    sendBroadcastNotification,
    showSendNotificationModal,
    sendQuickNotification,
    getNotificationStats
};
