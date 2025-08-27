/**
 * Local Testing Configuration
 * Use this for local development and testing before deploying to Vercel
 */

// Local development environment detection
const isLocalDevelopment = window.location.hostname === 'localhost' || 
                          window.location.hostname === '127.0.0.1' ||
                          window.location.port === '3000';

// Local testing configuration
export const LOCAL_TEST_CONFIG = {
    // Enable local testing features
    enableLocalTesting: isLocalDevelopment,
    
    // Local database simulation
    useLocalData: isLocalDevelopment,
    
    // Chart testing
    enableChartTesting: isLocalDevelopment,
    
    // Debug logging
    enableDebugLogging: isLocalDevelopment,
    
    // Sample data for testing
    sampleData: {
        users: [
            { id: 1, role: 'student', name: 'Test Student 1', email: 'student1@test.com' },
            { id: 2, role: 'student', name: 'Test Student 2', email: 'student2@test.com' },
            { id: 3, role: 'lecturer', name: 'Test Lecturer 1', email: 'lecturer1@test.com' },
            { id: 4, role: 'admin', name: 'Test Admin 1', email: 'admin1@test.com' },
            { id: 5, role: 'student', name: 'Test Student 3', email: 'student3@test.com' }
        ],
        profiles: [
                    { id: 1, academic_info: { department: 'Computer Science', faculty: 'FSKTM' }, full_name: 'Test Student 1' },
        { id: 2, academic_info: { department: 'Information Technology', faculty: 'FSKTM' }, full_name: 'Test Student 2' },
        { id: 3, academic_info: { department: 'Software Engineering', faculty: 'FSKTM' }, full_name: 'Test Student 3' },
        { id: 4, academic_info: { department: 'Computer Science', faculty: 'FSKTM' }, full_name: 'Test Student 4' },
        { id: 5, academic_info: { department: 'Information Technology', faculty: 'FSKTM' }, full_name: 'Test Student 5' }
        ],
        events: [
            { id: 1, title: 'Test Event 1', category: 'Workshop', description: 'Test workshop event' },
            { id: 2, title: 'Test Event 2', category: 'Seminar', description: 'Test seminar event' },
            { id: 3, title: 'Test Event 3', category: 'Competition', description: 'Test competition event' }
        ]
    }
};

// Local testing utilities
export const LocalTestUtils = {
    /**
     * Initialize local testing environment
     */
    init() {
        if (!LOCAL_TEST_CONFIG.enableLocalTesting) {
            console.log('🌐 Production mode - local testing disabled');
            return;
        }
        
        console.log('🧪 Local testing mode enabled');
        console.log('📊 Sample data available for testing');
        console.log('📈 Charts will render with sample data');
        
        // Add testing functions to global scope
        this.setupGlobalTesting();
    },
    
    /**
     * Setup global testing functions
     */
    setupGlobalTesting() {
        // Test charts with sample data
        window.testChartsLocally = () => {
            console.log('🧪 Testing charts with local sample data...');
            
            // Test Total Users chart
            const totalUserCanvas = document.getElementById('totalUserChart');
            if (totalUserCanvas) {
                this.testTotalUserChart();
            }
            
                    // Test Department chart
        const courseCanvas = document.getElementById('courseChart');
        if (courseCanvas) {
            this.testDepartmentChart();
        }
        };
        
        // Test analytics functionality
        window.testAnalyticsLocally = () => {
            console.log('🧪 Testing analytics functionality...');
            this.testAnalyticsFunctions();
        };
        
        // Show local testing status
        window.showLocalTestStatus = () => {
            console.log('📊 Local Testing Status:');
            console.log('- Environment:', isLocalDevelopment ? 'Local Development' : 'Production');
            console.log('- Local Testing:', LOCAL_TEST_CONFIG.enableLocalTesting ? 'Enabled' : 'Disabled');
            console.log('- Sample Data:', LOCAL_TEST_CONFIG.useLocalData ? 'Available' : 'Not Available');
            console.log('- Chart Testing:', LOCAL_TEST_CONFIG.enableChartTesting ? 'Enabled' : 'Disabled');
        };
        
        // Debug analytics data
        window.debugAnalyticsData = () => {
            console.log('🔍 Debugging analytics data...');
            
            // Check if analytics functions exist
            console.log('📊 Analytics functions:', {
                setupAnalytics: typeof window.setupAnalytics === 'function',
                renderAnalyticsCharts: typeof window.renderAnalyticsCharts === 'function',
                populateAnalyticsTables: typeof window.populateAnalyticsTables === 'function'
            });
            
            // Check chart canvases
            console.log('🎨 Chart canvases:', {
                totalUserChart: !!document.getElementById('totalUserChart'),
                courseChart: !!document.getElementById('courseChart')
            });
            
            // Check table bodies
            console.log('📋 Table bodies:', {
                totalUsersTable: !!document.getElementById('total-users-table-body'),
                courseDistributionTable: !!document.getElementById('course-distribution-table-body')
            });
            
            // Check if Chart.js is available
            console.log('📈 Chart.js available:', typeof Chart !== 'undefined');
            
            // Check current data
            if (window.currentData) {
                console.log('💾 Current data:', window.currentData);
            } else {
                console.log('⚠️ No current data found');
            }
        };
        
        // Manually trigger analytics setup
        window.forceAnalyticsSetup = async () => {
            console.log('🚀 Forcing analytics setup...');
            try {
                if (typeof window.setupAnalytics === 'function') {
                    await window.setupAnalytics();
                    console.log('✅ Analytics setup completed');
                } else {
                    console.log('❌ setupAnalytics function not found');
                }
            } catch (error) {
                console.error('❌ Error forcing analytics setup:', error);
            }
        };
        
        // Debug department data access
        window.debugDepartmentData = debugDepartmentData;
        
        // Test PDF report generation
        window.testPDFReportGeneration = testPDFReportGeneration;
        
        console.log('✅ Global testing functions added to window object');
    },
    
    /**
     * Test Total Users chart with sample data
     */
    testTotalUserChart() {
        const canvas = document.getElementById('totalUserChart');
        if (!canvas) {
            console.log('❌ Total User chart canvas not found');
            return;
        }
        
        try {
            // Process sample user data
            const roleCounts = {};
            LOCAL_TEST_CONFIG.sampleData.users.forEach(user => {
                const role = user.role || 'Unknown';
                roleCounts[role] = (roleCounts[role] || 0) + 1;
            });
            
            // Create test chart
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: Object.keys(roleCounts),
                    datasets: [{
                        label: 'Total Users (Test)',
                        data: Object.values(roleCounts),
                        backgroundColor: ['#2563eb', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'],
                        borderColor: '#ffffff',
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom' },
                        tooltip: {
                            callbacks: {
                                label: (context) => {
                                    const total = context.dataset.data.reduce((sum, val) => sum + val, 0);
                                    const percentage = ((context.parsed / total) * 100).toFixed(1);
                                    return `${context.label}: ${context.parsed} (${percentage}%)`;
                                }
                            }
                        }
                    }
                }
            });
            
            console.log('✅ Total User chart rendered with sample data:', roleCounts);
            
        } catch (error) {
            console.error('❌ Error testing Total User chart:', error);
        }
    },
    
    /**
     * Test Department chart with sample data
     */
    testDepartmentChart() {
        const canvas = document.getElementById('courseChart');
        if (!canvas) {
            console.log('❌ Department chart canvas not found');
            return;
        }
        
        try {
            // Process sample profile data
            const departmentCounts = {};
            LOCAL_TEST_CONFIG.sampleData.profiles.forEach(profile => {
                const department = profile.academic_info?.department || profile.department || 'Unknown';
                departmentCounts[department] = (departmentCounts[department] || 0) + 1;
            });
            
            // Create test chart
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: Object.keys(departmentCounts),
                    datasets: [{
                        label: 'Department Distribution (Test)',
                        data: Object.values(departmentCounts),
                        backgroundColor: '#10b981',
                        borderColor: '#10b981',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            callbacks: {
                                label: (context) => `Students: ${context.parsed.y}`
                            }
                        }
                    },
                    scales: {
                        y: { 
                            beginAtZero: true,
                            ticks: { stepSize: 1 }
                        }
                    }
                }
            });
            
            console.log('✅ Department chart rendered with sample data:', departmentCounts);
            
        } catch (error) {
            console.error('❌ Error testing Department chart:', error);
        }
    },
    
    /**
     * Test analytics functions
     */
    testAnalyticsFunctions() {
        const tests = [
            { name: 'Chart.js Available', test: () => typeof Chart !== 'undefined' },
                    { name: 'Analytics Section', test: () => document.getElementById('analytics') !== null },
        { name: 'Total User Chart Canvas', test: () => document.getElementById('totalUserChart') !== null },
        { name: 'Department Chart Canvas', test: () => document.getElementById('courseChart') !== null },
        { name: 'Setup Analytics Function', test: () => typeof window.setupAnalytics === 'function' },
        { name: 'Load Overview Stats Function', test: () => typeof window.loadOverviewStats === 'function' },
        { name: 'PDF Report Button', test: () => document.querySelector('button[onclick="generateReport()"]') !== null },
        { name: 'jsPDF Library', test: () => typeof window.jspdf !== 'undefined' }
        ];
        
        console.log('🧪 Running analytics function tests...');
        
        const results = tests.map(test => {
            try {
                const passed = test.test();
                console.log(`${passed ? '✅' : '❌'} ${test.name}: ${passed ? 'PASS' : 'FAIL'}`);
                return passed;
            } catch (error) {
                console.log(`❌ ${test.name}: ERROR - ${error.message}`);
                return false;
            }
        });
        
        const passedTests = results.filter(r => r).length;
        console.log(`📊 Test Results: ${passedTests}/${tests.length} tests passed`);
        
        if (passedTests === tests.length) {
            console.log('🎉 All analytics tests passed!');
        } else {
            console.log('⚠️ Some tests failed - check console for details');
        }
        
        return results;
    }
};

/**
 * Debug department data access to help troubleshoot "unknown department" issue
 */
function debugDepartmentData() {
    console.log('🔍 Debugging Department Data Access...');
    
    // Test with sample profile data structure
    const sampleProfile = {
        id: 'test-profile',
        user_id: 'test-user',
        full_name: 'Test User',
        academic_info: {
            department: 'Computer Science',
            faculty: 'FSKTM',
            studentId: 'CS12345'
        },
        phone_number: '+60123456789'
    };
    
    console.log('📋 Sample Profile Structure:', sampleProfile);
    
    // Test department access patterns
    console.log('🔍 Department Access Tests:');
    console.log('  - profile.department:', sampleProfile.department);
    console.log('  - profile.academic_info?.department:', sampleProfile.academic_info?.department);
    console.log('  - profile.academic_info?.department || profile.department:', sampleProfile.academic_info?.department || sampleProfile.department);
    
    // Test phone access patterns
    console.log('📱 Phone Access Tests:');
    console.log('  - profile.phone:', sampleProfile.phone);
    console.log('  - profile.phone_number:', sampleProfile.phone_number);
    console.log('  - profile.phone_number || profile.phone:', sampleProfile.phone_number || sampleProfile.phone);
    
    // Test faculty access patterns
    console.log('🏫 Faculty Access Tests:');
    console.log('  - profile.faculty:', sampleProfile.faculty);
    console.log('  - profile.academic_info?.faculty:', sampleProfile.academic_info?.faculty);
    console.log('  - profile.academic_info?.faculty || profile.faculty:', sampleProfile.academic_info?.faculty || sampleProfile.faculty);
    
    // Test student ID access patterns
    console.log('🆔 Student ID Access Tests:');
    console.log('  - profile.student_id:', sampleProfile.student_id);
    console.log('  - profile.academic_info?.studentId:', sampleProfile.academic_info?.studentId);
    console.log('  - profile.academic_info?.studentId || profile.student_id:', sampleProfile.academic_info?.studentId || sampleProfile.student_id);
    
    console.log('✅ Department data debugging completed');
}

/**
 * Test PDF report generation functionality
 */
function testPDFReportGeneration() {
    console.log('🧪 Testing PDF Report Generation...');
    
    // Check if jsPDF is available
    if (typeof window.jspdf === 'undefined') {
        console.error('❌ jsPDF library not loaded');
        console.log('💡 Make sure the jsPDF CDN script is loaded in index.html');
        return false;
    }
    
    console.log('✅ jsPDF library is available');
    
    // Check if generateReport function exists
    if (typeof window.generateReport !== 'function') {
        console.error('❌ generateReport function not found');
        return false;
    }
    
    console.log('✅ generateReport function is available');
    
    // Check if generatePDFReport function exists (should be in analytics.js)
    if (typeof window.generatePDFReport !== 'function') {
        console.log('ℹ️ generatePDFReport function not globally available (expected to be in analytics.js scope)');
    }
    
    // Test with sample data
    try {
        const sampleReport = {
            metadata: {
                generatedAt: new Date().toISOString(),
                generatedBy: 'UTHM Talent Profiling System',
                version: '2.0.0',
                reportType: 'comprehensive_analytics'
            },
            summary: {
                totalUsers: 25,
                totalStudents: 20,
                totalLecturers: 3,
                totalAdmins: 2,
                totalEvents: 8,
                departments: 5
            },
            analytics: {
                userDistribution: { student: 20, lecturer: 3, admin: 2 },
                departmentDistribution: { 'Computer Science': 8, 'Information Technology': 6, 'Software Engineering': 4, 'Data Science': 4, 'Cybersecurity': 3 },
                eventParticipation: { 'Tech Workshop': 15, 'Leadership Seminar': 12, 'Innovation Challenge': 8 }
            },
            performance: {
                reportGenerationTime: '150ms',
                dataFreshness: new Date().toISOString(),
                cacheStats: { hits: 45, misses: 12 },
                systemStats: { chartsRendered: 2, dataProcessed: 150 }
            }
        };
        
        console.log('📊 Sample report data created:', sampleReport);
        console.log('✅ PDF report generation test completed successfully');
        console.log('💡 You can now test the actual PDF generation by clicking the "Generate PDF Report" button');
        
        return true;
        
    } catch (error) {
        console.error('❌ Error testing PDF report generation:', error);
        return false;
    }
}

// Auto-initialize local testing if in local development
if (isLocalDevelopment) {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            LocalTestUtils.init();
        });
    } else {
        LocalTestUtils.init();
    }
}

// Export for use in other modules
export default LOCAL_TEST_CONFIG;
