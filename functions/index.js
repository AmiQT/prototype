/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

admin.initializeApp();

exports.createUserProfile = functions.auth.user().onCreate((user) => {
  return admin.firestore().collection('users').doc(user.uid).set({
    id: user.uid,
    uid: user.uid,
    email: user.email,
    name: user.displayName || '',
    role: 'student', // or set as needed
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
  });
});

// Function to create a notification
async function createNotification(userId, title, message, type, data = null, actionUrl = null) {
  const notificationData = {
    userId: userId,
    title: title,
    message: message,
    type: type,
    isRead: false,
    createdAt: new Date().toISOString(),
    data: data,
    actionUrl: actionUrl,
  };

  return admin.firestore().collection('notifications').add(notificationData);
}

// Trigger when a new event is created
exports.onEventCreated = functions.firestore
  .document('events/{eventId}')
  .onCreate(async (snap, context) => {
    const eventData = snap.data();
    const eventId = context.params.eventId;

    try {
      // Get all users to notify about new events
      const usersSnapshot = await admin.firestore().collection('users').get();
      const batch = admin.firestore().batch();

      usersSnapshot.docs.forEach((userDoc) => {
        const userData = userDoc.data();
        if (userData.role === 'student' || userData.role === 'lecturer') {
          const notificationRef = admin.firestore().collection('notifications').doc();
          batch.set(notificationRef, {
            userId: userData.uid,
            title: 'New Event Available!',
            message: `Check out the new event: ${eventData.title}`,
            type: 'event',
            isRead: false,
            createdAt: new Date().toISOString(),
            data: {
              eventId: eventId,
              eventTitle: eventData.title,
            },
            actionUrl: `/event/${eventId}`,
          });
        }
      });

      await batch.commit();
      console.log(`Created notifications for new event: ${eventData.title}`);
    } catch (error) {
      console.error('Error creating event notifications:', error);
    }
  });

// Trigger when a badge claim is updated (approved/rejected)
exports.onBadgeClaimUpdated = functions.firestore
  .document('badgeClaims/{claimId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if status changed from pending to approved/rejected
    if (beforeData.status === 'pending' && afterData.status !== 'pending') {
      const isApproved = afterData.status === 'approved';
      const userId = afterData.userId;

      try {
        await createNotification(
          userId,
          isApproved ? 'Badge Claim Approved!' : 'Badge Claim Rejected',
          isApproved
            ? `Your badge claim has been approved! The badge has been added to your profile.`
            : `Your badge claim was not approved. Please contact an administrator for more information.`,
          'achievement',
          {
            claimId: context.params.claimId,
            badgeId: afterData.badgeId,
            status: afterData.status,
          }
        );

        console.log(`Created notification for badge claim ${context.params.claimId}`);
      } catch (error) {
        console.error('Error creating badge claim notification:', error);
      }
    }
  });

// Trigger when an achievement is verified
exports.onAchievementUpdated = functions.firestore
  .document('achievements/{achievementId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if verification status changed
    if (beforeData.isVerified !== afterData.isVerified) {
      const userId = afterData.userId;
      const isVerified = afterData.isVerified;

      try {
        await createNotification(
          userId,
          isVerified ? 'Achievement Verified!' : 'Achievement Verification Removed',
          isVerified
            ? `Your achievement "${afterData.title}" has been verified!`
            : `The verification for your achievement "${afterData.title}" has been removed.`,
          'achievement',
          {
            achievementId: context.params.achievementId,
            achievementTitle: afterData.title,
            isVerified: isVerified,
          }
        );

        console.log(`Created notification for achievement ${context.params.achievementId}`);
      } catch (error) {
        console.error('Error creating achievement notification:', error);
      }
    }
  });
