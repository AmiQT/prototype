/**
 * Chart Testing Utility for UTHM Talent Profiling Dashboard
 * Tests the new Total User and Department charts
 */

class ChartTester {
    constructor() {
        this.testData = null;
    }

    /**
     * Test all charts with sample data
     */
    static async testChartsWithSampleData() {
        console.log('🧪 Testing charts with sample data...');
        
        try {
            // Generate sample data
            const sampleData = this.generateSampleData();
            
            // Test total user chart
            await this.testTotalUserChart(sampleData.users);
            
                    // Test department chart
        await this.testDepartmentChart(sampleData.profiles);
            
            console.log('✅ All test charts rendered successfully');
            
        } catch (error) {
            console.error('❌ Error rendering test charts:', error);
            throw error;
        }
    }

    /**
     * Test total user chart with sample data
     */
    static async testTotalUserChart(users) {
        const canvas = document.getElementById('totalUserChart');
        if (!canvas) {
            console.log('⚠️ Total User chart canvas not found');
            return;
        }
        
        try {
            // Process user data for chart
            const roleData = this.processRoleData(users);
            
            // Create chart manually for testing
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: Object.keys(roleData),
                    datasets: [{
                        label: 'Total Users',
                        data: Object.values(roleData),
                        backgroundColor: ['#2563eb', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'],
                        borderColor: '#ffffff',
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true }
                    }
                }
            });
            
            console.log('✅ Total User chart rendered with', Object.keys(roleData).length, 'roles');
            
        } catch (error) {
            console.error('❌ Total User chart test failed:', error);
        }
    }

    /**
     * Test department chart with sample data
     */
    static async testDepartmentChart(profiles) {
        const canvas = document.getElementById('courseChart');
        if (!canvas) {
            console.log('⚠️ Department chart canvas not found');
            return;
        }
        
        try {
            // Process department data for chart
            const departmentData = this.processDepartmentData(profiles);
            
            // Create chart manually for testing
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: departmentData.labels,
                    datasets: [{
                        label: 'Department Distribution',
                        data: departmentData.data,
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
            
            console.log('✅ Department chart rendered with', departmentData.data.length, 'departments');
            
        } catch (error) {
            console.error('❌ Department chart test failed:', error);
        }
    }

    /**
     * Check if chart canvases exist and are visible
     */
    static checkChartCanvases() {
        const expectedCharts = [
            'totalUserChart',
            'courseChart'
        ];
        
        const results = {};
        
        expectedCharts.forEach(chartId => {
            const canvas = document.getElementById(chartId);
            if (canvas) {
                const rect = canvas.getBoundingClientRect();
                results[chartId] = {
                    exists: true,
                    dimensions: `${rect.width}x${rect.height}`,
                    visible: rect.width > 0 && rect.height > 0
                };
            } else {
                results[chartId] = {
                    exists: false,
                    dimensions: 'N/A',
                    visible: false
                };
            }
        });
        
        return results;
    }

    /**
     * Generate sample data for testing
     */
    static generateSampleData() {
        return {
            users: [
                { role: 'student', name: 'Student 1' },
                { role: 'student', name: 'Student 2' },
                { role: 'lecturer', name: 'Lecturer 1' },
                { role: 'admin', name: 'Admin 1' },
                { role: 'student', name: 'Student 3' }
            ],
            profiles: [
                { academic_info: { department: 'Computer Science', faculty: 'FSKTM' }, name: 'Profile 1' },
                { academic_info: { department: 'Computer Science', faculty: 'FSKTM' }, name: 'Profile 2' },
                { academic_info: { department: 'Information Technology', faculty: 'FSKTM' }, name: 'Profile 3' },
                { academic_info: { department: 'Software Engineering', faculty: 'FSKTM' }, name: 'Profile 4' },
                { academic_info: { department: 'Computer Science', faculty: 'FSKTM' }, name: 'Profile 5' }
            ]
        };
    }

    /**
     * Process role data for total user chart
     */
    static processRoleData(users) {
        const roleCounts = {};
        
        if (!users || !Array.isArray(users)) {
            return {};
        }
        
        users.forEach(user => {
            const role = user.role || 'Unknown';
            roleCounts[role] = (roleCounts[role] || 0) + 1;
        });
        
        return roleCounts;
    }
    
    /**
     * Process department data for department chart
     */
    static processDepartmentData(profiles) {
        const departmentCounts = {};
        
        if (!profiles || !Array.isArray(profiles)) {
            return {};
        }
        
        profiles.forEach(profile => {
            const department = profile.academic_info?.department || profile.department || 'Unknown';
            departmentCounts[department] = (departmentCounts[department] || 0) + 1;
        });
        
        return departmentCounts;
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
    // Chart testing available
}
