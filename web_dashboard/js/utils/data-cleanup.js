/**
 * Data Cleanup Utility
 * Simple functions to clean up sample/test data
 */

import { db } from '../core/firebase.js';

export class DataCleanup {
    
    /**
     * Clear sample data from Firebase
     */
    static async clearSampleData() {
        try {
            console.log('🧹 Clearing sample data from Firebase...');
            
            const collections = ['users', 'achievements', 'events', 'badgeClaims', 'profiles'];
            let totalDeleted = 0;
            
            for (const collectionName of collections) {
                console.log(`🔍 Checking ${collectionName} collection...`);
                
                const snapshot = await db.collection(collectionName).get();
                const deletePromises = [];
                
                snapshot.docs.forEach(doc => {
                    const docId = doc.id;
                    // Delete documents that look like sample data
                    if (docId.startsWith('user_') || 
                        docId.startsWith('achievement_') || 
                        docId.startsWith('event_') || 
                        docId.startsWith('claim_') ||
                        docId.startsWith('profile_')) {
                        deletePromises.push(doc.ref.delete());
                        totalDeleted++;
                    }
                });
                
                if (deletePromises.length > 0) {
                    await Promise.all(deletePromises);
                    console.log(`✅ Deleted ${deletePromises.length} sample documents from ${collectionName}`);
                } else {
                    console.log(`ℹ️ No sample data found in ${collectionName}`);
                }
            }
            
            console.log(`✅ Sample data cleanup completed! Deleted ${totalDeleted} documents total.`);
            
            return {
                success: true,
                deletedCount: totalDeleted,
                message: `Deleted ${totalDeleted} sample documents`
            };
            
        } catch (error) {
            console.error('❌ Error clearing sample data:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    /**
     * Clear all data from specific collection (use with caution!)
     */
    static async clearCollection(collectionName) {
        try {
            console.log(`🧹 Clearing all data from ${collectionName} collection...`);
            
            const snapshot = await db.collection(collectionName).get();
            const deletePromises = snapshot.docs.map(doc => doc.ref.delete());
            
            await Promise.all(deletePromises);
            
            console.log(`✅ Cleared ${deletePromises.length} documents from ${collectionName}`);
            
            return {
                success: true,
                deletedCount: deletePromises.length
            };
            
        } catch (error) {
            console.error(`❌ Error clearing ${collectionName}:`, error);
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    /**
     * Count documents in collections
     */
    static async countDocuments() {
        try {
            console.log('📊 Counting documents in collections...');
            
            const collections = ['users', 'achievements', 'events', 'badgeClaims', 'profiles'];
            const counts = {};
            
            for (const collectionName of collections) {
                const snapshot = await db.collection(collectionName).get();
                counts[collectionName] = snapshot.size;
                console.log(`📄 ${collectionName}: ${snapshot.size} documents`);
            }
            
            const total = Object.values(counts).reduce((sum, count) => sum + count, 0);
            console.log(`📊 Total documents: ${total}`);
            
            return {
                counts,
                total
            };
            
        } catch (error) {
            console.error('❌ Error counting documents:', error);
            return {
                error: error.message
            };
        }
    }
    
    /**
     * List sample data documents
     */
    static async listSampleData() {
        try {
            console.log('🔍 Listing sample data documents...');
            
            const collections = ['users', 'achievements', 'events', 'badgeClaims', 'profiles'];
            const sampleDocs = {};
            let totalSample = 0;
            
            for (const collectionName of collections) {
                const snapshot = await db.collection(collectionName).get();
                const sampleIds = [];
                
                snapshot.docs.forEach(doc => {
                    const docId = doc.id;
                    if (docId.startsWith('user_') || 
                        docId.startsWith('achievement_') || 
                        docId.startsWith('event_') || 
                        docId.startsWith('claim_') ||
                        docId.startsWith('profile_')) {
                        sampleIds.push(docId);
                        totalSample++;
                    }
                });
                
                sampleDocs[collectionName] = sampleIds;
                if (sampleIds.length > 0) {
                    console.log(`📄 ${collectionName}: ${sampleIds.length} sample documents`);
                }
            }
            
            console.log(`📊 Total sample documents: ${totalSample}`);
            
            return {
                sampleDocs,
                totalSample
            };
            
        } catch (error) {
            console.error('❌ Error listing sample data:', error);
            return {
                error: error.message
            };
        }
    }
}

// Make available globally for easy use
if (typeof window !== 'undefined') {
    window.clearSampleData = () => DataCleanup.clearSampleData();
    window.countDocuments = () => DataCleanup.countDocuments();
    window.listSampleData = () => DataCleanup.listSampleData();
    
    // Data cleanup functions available
}

export default DataCleanup;
