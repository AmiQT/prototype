/**
 * Chart Testing Utility
 * Test charts with sample data and verify they render correctly
 */

import { SampleDataGenerator } from '../utils/sample-data-generator.js';

export class ChartTester {
    
    /**
     * Test all analytics charts with sample data
     */
    static async testChartsWithSampleData() {
        console.log('🧪 Testing charts with sample data...');
        
        try {
            // Get sample data
            const sampleData = SampleDataGenerator.getSampleDataSet();
            console.log('✅ Sample data generated:', {
                users: sampleData.users.length,
                achievements: sampleData.achievements.length,
                events: sampleData.events.length,
                badgeClaims: sampleData.badgeClaims.length
            });
            
            // Navigate to analytics section
            const analyticsNav = document.querySelector('[data-section="analytics"]');
            if (analyticsNav) {
                analyticsNav.click();
                console.log('✅ Navigated to analytics section');
            }
            
            // Wait for section to load
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // Check if charts exist
            const charts = this.checkChartCanvases();
            console.log('📊 Chart canvases found:', charts);
            
            // Test chart rendering with sample data
            await this.renderTestCharts(sampleData);
            
            return {
                success: true,
                sampleData,
                charts
            };
            
        } catch (error) {
            console.error('❌ Chart testing failed:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    /**
     * Check which chart canvases exist in the DOM
     */
    static checkChartCanvases() {
        const expectedCharts = [
            'userChart',
            'eventChart', 
            'achievementChart',
            'userGrowthChart'
        ];
        
        const foundCharts = {};
        
        expectedCharts.forEach(chartId => {
            const canvas = document.getElementById(chartId);
            foundCharts[chartId] = {
                exists: !!canvas,
                visible: canvas ? canvas.offsetParent !== null : false,
                dimensions: canvas ? `${canvas.width}x${canvas.height}` : 'N/A'
            };
        });
        
        return foundCharts;
    }
    
    /**
     * Render test charts with sample data
     */
    static async renderTestCharts(sampleData) {
        console.log('🎨 Rendering test charts...');
        
        try {
            // Import analytics module
            const analytics = await import('../features/analytics.js');
            
            // Test user chart
            await this.testUserChart(sampleData.users);
            
            // Test event chart  
            await this.testEventChart(sampleData.events);
            
            // Test achievement chart
            await this.testAchievementChart(sampleData.achievements);
            
            console.log('✅ All test charts rendered successfully');
            
        } catch (error) {
            console.error('❌ Error rendering test charts:', error);
            throw error;
        }
    }
    
    /**
     * Test user chart with sample data
     */
    static async testUserChart(users) {
        const canvas = document.getElementById('userChart');
        if (!canvas) {
            console.log('⚠️ User chart canvas not found');
            return;
        }
        
        try {
            // Process user data for chart
            const monthlyData = this.processUserTrendData(users);
            
            // Create chart manually for testing
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: monthlyData.labels,
                    datasets: [{
                        label: 'User Registrations',
                        data: monthlyData.data,
                        borderColor: '#2563eb',
                        backgroundColor: 'rgba(37, 99, 235, 0.1)',
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true }
                    },
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
            
            console.log('✅ User chart rendered with', monthlyData.data.length, 'data points');
            
        } catch (error) {
            console.error('❌ User chart test failed:', error);
        }
    }
    
    /**
     * Test event chart with sample data
     */
    static async testEventChart(events) {
        const canvas = document.getElementById('eventChart');
        if (!canvas) {
            console.log('⚠️ Event chart canvas not found');
            return;
        }
        
        try {
            // Process event data for chart
            const eventData = this.processEventData(events);
            
            // Create chart manually for testing
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: eventData.labels,
                    datasets: [{
                        label: 'Event Participation',
                        data: eventData.data,
                        backgroundColor: '#10b981',
                        borderColor: '#10b981',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false }
                    },
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
            
            console.log('✅ Event chart rendered with', eventData.data.length, 'categories');
            
        } catch (error) {
            console.error('❌ Event chart test failed:', error);
        }
    }
    
    /**
     * Test achievement chart with sample data
     */
    static async testAchievementChart(achievements) {
        const canvas = document.getElementById('achievementChart');
        if (!canvas) {
            console.log('⚠️ Achievement chart canvas not found');
            return;
        }
        
        try {
            // Process achievement data for chart
            const achievementData = this.processAchievementData(achievements);
            
            // Create chart manually for testing
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: achievementData.labels,
                    datasets: [{
                        data: achievementData.data,
                        backgroundColor: [
                            '#2563eb',
                            '#10b981', 
                            '#f59e0b',
                            '#ef4444',
                            '#8b5cf6'
                        ],
                        borderWidth: 2,
                        borderColor: '#ffffff'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom'
                        }
                    }
                }
            });
            
            console.log('✅ Achievement chart rendered with', achievementData.data.length, 'categories');
            
        } catch (error) {
            console.error('❌ Achievement chart test failed:', error);
        }
    }
    
    /**
     * Process user trend data (same as in analytics.js)
     */
    static processUserTrendData(users) {
        const monthlyData = {};
        
        users.forEach(user => {
            if (user.createdAt) {
                const date = new Date(user.createdAt);
                if (!isNaN(date.getTime())) {
                    const monthKey = date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
                    monthlyData[monthKey] = (monthlyData[monthKey] || 0) + 1;
                }
            }
        });
        
        const labels = Object.keys(monthlyData).sort();
        const data = labels.map(label => monthlyData[label]);
        
        return { labels, data };
    }
    
    /**
     * Process event data (same as in analytics.js)
     */
    static processEventData(events) {
        const eventTypes = {};
        events.forEach(event => {
            const type = event.type || event.category || 'Other';
            eventTypes[type] = (eventTypes[type] || 0) + 1;
        });
        
        return {
            labels: Object.keys(eventTypes),
            data: Object.values(eventTypes)
        };
    }
    
    /**
     * Process achievement data (same as in analytics.js)
     */
    static processAchievementData(achievements) {
        const typeData = {};
        achievements.forEach(achievement => {
            const type = achievement.type || 'other';
            typeData[type] = (typeData[type] || 0) + 1;
        });
        
        return {
            labels: Object.keys(typeData),
            data: Object.values(typeData)
        };
    }
    
    /**
     * Quick chart visibility test
     */
    static testChartVisibility() {
        console.log('👀 Testing chart visibility...');
        
        const charts = this.checkChartCanvases();
        
        Object.entries(charts).forEach(([chartId, info]) => {
            if (info.exists) {
                console.log(`✅ ${chartId}: Found (${info.dimensions}) ${info.visible ? 'Visible' : 'Hidden'}`);
            } else {
                console.log(`❌ ${chartId}: Not found`);
            }
        });
        
        return charts;
    }
}

// Make available globally
window.ChartTester = ChartTester;
window.testCharts = () => ChartTester.testChartsWithSampleData();
window.checkCharts = () => ChartTester.testChartVisibility();

// Auto-run in development
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    console.log('🧪 Chart testing available:');
    console.log('   - testCharts() - Test all charts with sample data');
    console.log('   - checkCharts() - Check chart canvas visibility');
}
