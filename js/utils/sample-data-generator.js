/**
 * Sample Data Generator for Analytics Charts
 * Creates realistic sample data when no real data exists
 */

import { db } from '../core/firebase.js';

export class SampleDataGenerator {
    
    /**
     * Generate sample users
     */
    static generateSampleUsers(count = 20) {
        const users = [];
        const roles = ['student', 'lecturer', 'admin'];
        const departments = ['Computer Science', 'Engineering', 'Business', 'Arts', 'Science'];
        const names = [
            'Ahmad Rahman', 'Siti Nurhaliza', 'Muhammad Ali', 'Fatimah Zahra', 'Hassan Ibrahim',
            'Aishah Binti Omar', 'Zulkifli Mahmud', 'Noor Azlina', 'Rashid Abdullah', 'Mariam Yusof',
            'Farid Kamil', 'Zarina Ahmad', 'Hafiz Rahman', 'Nurul Ain', 'Azman Hashim',
            'Salmah Ismail', 'Kamal Ariffin', 'Rozita Che Wan', 'Ismail Sabri', 'Noraini Kassim'
        ];
        
        for (let i = 0; i < count; i++) {
            const createdDate = new Date();
            createdDate.setDate(createdDate.getDate() - Math.floor(Math.random() * 180)); // Last 6 months
            
            users.push({
                id: `user_${i + 1}`,
                name: names[i % names.length],
                email: `user${i + 1}@uthm.edu.my`,
                role: roles[Math.floor(Math.random() * roles.length)],
                department: departments[Math.floor(Math.random() * departments.length)],
                matrixId: `A${String(20240001 + i).padStart(8, '0')}`,
                createdAt: createdDate.toISOString(),
                lastLogin: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
                profileCompleted: Math.random() > 0.3,
                status: 'active'
            });
        }
        
        return users;
    }
    
    /**
     * Generate sample achievements
     */
    static generateSampleAchievements(count = 30) {
        const achievements = [];
        const types = ['academic', 'leadership', 'competition', 'skill', 'community'];
        const titles = [
            'Dean\'s List Achievement', 'Programming Competition Winner', 'Leadership Excellence',
            'Community Service Award', 'Research Publication', 'Innovation Challenge',
            'Academic Excellence', 'Team Leadership', 'Technical Skills Mastery',
            'Public Speaking Award', 'Project Management', 'Entrepreneurship Award'
        ];
        
        for (let i = 0; i < count; i++) {
            const createdDate = new Date();
            createdDate.setDate(createdDate.getDate() - Math.floor(Math.random() * 365)); // Last year
            
            achievements.push({
                id: `achievement_${i + 1}`,
                title: titles[i % titles.length],
                description: `Outstanding achievement in ${types[Math.floor(Math.random() * types.length)]}`,
                type: types[Math.floor(Math.random() * types.length)],
                points: Math.floor(Math.random() * 100) + 10,
                isVerified: Math.random() > 0.2, // 80% verified
                createdAt: createdDate.toISOString(),
                userId: `user_${Math.floor(Math.random() * 20) + 1}`,
                verifiedBy: Math.random() > 0.2 ? `lecturer_${Math.floor(Math.random() * 5) + 1}` : null
            });
        }
        
        return achievements;
    }
    
    /**
     * Generate sample events
     */
    static generateSampleEvents(count = 15) {
        const events = [];
        const types = ['workshop', 'seminar', 'competition', 'training', 'conference'];
        const titles = [
            'AI & Machine Learning Workshop', 'Leadership Development Seminar', 'Programming Competition',
            'Soft Skills Training', 'Research Conference', 'Innovation Showcase',
            'Career Development Workshop', 'Technical Writing Seminar', 'Hackathon 2024',
            'Industry Talk Series', 'Entrepreneurship Bootcamp', 'Digital Marketing Workshop'
        ];
        
        for (let i = 0; i < count; i++) {
            const startDate = new Date();
            startDate.setDate(startDate.getDate() + Math.floor(Math.random() * 90)); // Next 3 months
            
            const endDate = new Date(startDate);
            endDate.setHours(endDate.getHours() + Math.floor(Math.random() * 8) + 2); // 2-10 hours duration
            
            events.push({
                id: `event_${i + 1}`,
                title: titles[i % titles.length],
                description: `Join us for an exciting ${types[Math.floor(Math.random() * types.length)]} event`,
                type: types[Math.floor(Math.random() * types.length)],
                startDate: startDate.toISOString(),
                endDate: endDate.toISOString(),
                location: `Hall ${String.fromCharCode(65 + Math.floor(Math.random() * 5))}`, // Hall A-E
                maxParticipants: Math.floor(Math.random() * 100) + 20,
                currentParticipants: Math.floor(Math.random() * 50) + 5,
                createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
                createdBy: `lecturer_${Math.floor(Math.random() * 5) + 1}`,
                status: 'active'
            });
        }
        
        return events;
    }
    
    /**
     * Generate sample badge claims
     */
    static generateSampleBadgeClaims(count = 25) {
        const claims = [];
        const statuses = ['pending', 'approved', 'rejected'];
        
        for (let i = 0; i < count; i++) {
            const createdDate = new Date();
            createdDate.setDate(createdDate.getDate() - Math.floor(Math.random() * 60)); // Last 2 months
            
            claims.push({
                id: `claim_${i + 1}`,
                userId: `user_${Math.floor(Math.random() * 20) + 1}`,
                achievementId: `achievement_${Math.floor(Math.random() * 30) + 1}`,
                eventId: `event_${Math.floor(Math.random() * 15) + 1}`,
                status: statuses[Math.floor(Math.random() * statuses.length)],
                evidence: `Evidence document ${i + 1}`,
                submittedAt: createdDate.toISOString(),
                reviewedAt: Math.random() > 0.3 ? new Date(createdDate.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString() : null,
                reviewedBy: Math.random() > 0.3 ? `lecturer_${Math.floor(Math.random() * 5) + 1}` : null,
                comments: Math.random() > 0.5 ? 'Well documented achievement' : null
            });
        }
        
        return claims;
    }
    
    /**
     * Add sample data to Firebase (for testing)
     */
    static async addSampleDataToFirebase() {
        try {
            console.log('🎯 Adding sample data to Firebase...');
            
            const users = this.generateSampleUsers(20);
            const achievements = this.generateSampleAchievements(30);
            const events = this.generateSampleEvents(15);
            
            // Add users
            const userPromises = users.map(user => 
                db.collection('users').doc(user.id).set(user)
            );
            
            // Add achievements
            const achievementPromises = achievements.map(achievement => 
                db.collection('achievements').doc(achievement.id).set(achievement)
            );
            
            // Add events
            const eventPromises = events.map(event => 
                db.collection('events').doc(event.id).set(event)
            );
            
            // Add badge claims
            
            await Promise.all([
                ...userPromises,
                ...achievementPromises,
                ...eventPromises,
                ...claimPromises
            ]);
            
            console.log('✅ Sample data added successfully!');
            console.log(`Added: ${users.length} users, ${achievements.length} achievements, ${events.length} events`);
            
            return {
                users: users.length,
                achievements: achievements.length,
                events: events.length,
            };
            
        } catch (error) {
            console.error('❌ Error adding sample data:', error);
            throw error;
        }
    }
    
    /**
     * Clear all sample data from Firebase
     */
    static async clearSampleData() {
        try {
            console.log('🧹 Clearing sample data from Firebase...');
            
            const collections = ['users', 'achievements', 'events'];
            const deletePromises = [];
            
            for (const collectionName of collections) {
                const snapshot = await db.collection(collectionName).get();
                snapshot.docs.forEach(doc => {
                    if (doc.id.startsWith('user_') || doc.id.startsWith('achievement_') || 
                        doc.id.startsWith('event_') || doc.id.startsWith('claim_')) {
                        deletePromises.push(doc.ref.delete());
                    }
                });
            }
            
            await Promise.all(deletePromises);
            console.log('✅ Sample data cleared successfully!');
            
        } catch (error) {
            console.error('❌ Error clearing sample data:', error);
            throw error;
        }
    }
    
    /**
     * Get sample data for immediate use (without Firebase)
     */
    static getSampleDataSet() {
        return {
            users: this.generateSampleUsers(20),
            achievements: this.generateSampleAchievements(30),
            events: this.generateSampleEvents(15),
        };
    }
}

// Make available globally for easy testing
window.SampleDataGenerator = SampleDataGenerator;

// Auto-run in development
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    window.addSampleData = () => SampleDataGenerator.addSampleDataToFirebase();
    window.clearSampleData = () => SampleDataGenerator.clearSampleData();
    window.getSampleData = () => SampleDataGenerator.getSampleDataSet();
    
    // Sample data generator available
}
