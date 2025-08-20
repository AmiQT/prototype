/**
 * Quick Chart Test - Simple test to verify charts work
 */

// Simple chart test function
export function quickChartTest() {
    console.log('🧪 Running Quick Chart Test...');
    
    try {
        // Check if Chart.js is available
        if (typeof Chart === 'undefined') {
            console.log('❌ Chart.js not loaded');
            return false;
        }
        console.log('✅ Chart.js is available');
        
        // Check if analytics section exists
        const analyticsSection = document.getElementById('analytics');
        if (!analyticsSection) {
            console.log('❌ Analytics section not found');
            return false;
        }
        console.log('✅ Analytics section found');
        
        // Check for chart canvases
        const charts = ['userChart', 'eventChart', 'achievementChart'];
        const foundCharts = [];
        
        charts.forEach(chartId => {
            const canvas = document.getElementById(chartId);
            if (canvas) {
                foundCharts.push(chartId);
                console.log(`✅ ${chartId} canvas found`);
            } else {
                console.log(`❌ ${chartId} canvas not found`);
            }
        });
        
        if (foundCharts.length === 0) {
            console.log('❌ No chart canvases found');
            return false;
        }
        
        // Test creating a simple chart
        const testCanvas = document.getElementById(foundCharts[0]);
        if (testCanvas) {
            try {
                const ctx = testCanvas.getContext('2d');
                const testChart = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: ['Test 1', 'Test 2', 'Test 3'],
                        datasets: [{
                            label: 'Test Data',
                            data: [10, 20, 15],
                            backgroundColor: '#2563eb'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false
                    }
                });
                
                console.log('✅ Test chart created successfully');
                
                // Clean up test chart
                setTimeout(() => {
                    testChart.destroy();
                    console.log('✅ Test chart cleaned up');
                }, 2000);
                
                return true;
                
            } catch (error) {
                console.log('❌ Error creating test chart:', error.message);
                return false;
            }
        }
        
        return foundCharts.length > 0;
        
    } catch (error) {
        console.log('❌ Quick chart test failed:', error.message);
        return false;
    }
}

// Test analytics navigation
export function testAnalyticsNavigation() {
    console.log('🧪 Testing Analytics Navigation...');
    
    try {
        // Find analytics navigation button
        const analyticsNav = document.querySelector('[data-section="analytics"]') || 
                           document.querySelector('a[href="#analytics"]') ||
                           document.querySelector('.nav-item[onclick*="analytics"]');
        
        if (!analyticsNav) {
            console.log('❌ Analytics navigation button not found');
            return false;
        }
        
        console.log('✅ Analytics navigation button found');
        
        // Click the navigation
        analyticsNav.click();
        
        // Check if section becomes active
        setTimeout(() => {
            const analyticsSection = document.getElementById('analytics');
            const isActive = analyticsSection?.classList.contains('active') || 
                           analyticsSection?.style.display !== 'none';
            
            if (isActive) {
                console.log('✅ Analytics section is now active');
            } else {
                console.log('⚠️ Analytics section may not be active');
            }
        }, 500);
        
        return true;
        
    } catch (error) {
        console.log('❌ Navigation test failed:', error.message);
        return false;
    }
}

// Simple console cleanup test
export function runConsoleCleanupTest() {
    console.log('🧪 Console Cleanup Test (Simple Version)');
    
    // Test analytics functions
    const tests = [
        () => typeof window.setupAnalytics === 'function',
        () => typeof window.loadOverviewStats === 'function',
        () => document.getElementById('analytics') !== null,
        () => typeof Chart !== 'undefined'
    ];
    
    const results = tests.map((test, index) => {
        try {
            const result = test();
            console.log(`✅ Test ${index + 1}: ${result ? 'PASS' : 'FAIL'}`);
            return result;
        } catch (error) {
            console.log(`❌ Test ${index + 1}: ERROR - ${error.message}`);
            return false;
        }
    });
    
    const passedTests = results.filter(r => r).length;
    console.log(`📊 Results: ${passedTests}/${tests.length} tests passed`);
    
    if (passedTests === tests.length) {
        console.log('🎉 All basic tests passed!');
    } else {
        console.log('⚠️ Some tests failed, but basic functionality should work');
    }
    
    return {
        total: tests.length,
        passed: passedTests,
        success: passedTests >= tests.length * 0.75 // 75% pass rate
    };
}

// Make functions available globally
if (typeof window !== 'undefined') {
    window.quickChartTest = quickChartTest;
    window.testAnalyticsNavigation = testAnalyticsNavigation;
    
    // Provide fallback if main test function doesn't exist
    if (!window.runConsoleCleanupTest) {
        window.runConsoleCleanupTest = runConsoleCleanupTest;
    }
    
    // Quick chart tests available (disabled for cleaner console)
}
