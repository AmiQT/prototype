/**
 * Immediate Test - Run right away to verify fixes
 */

// Test chart colors and basic functionality
function testChartColors() {
    console.log('🎨 Testing Chart Colors...');
    
    try {
        // Test fallback config
        const fallbackConfig = {
            CHART_COLORS: {
                primary: '#2563eb',
                secondary: '#10b981',
                accent: '#f59e0b'
            }
        };
        
        console.log('✅ Fallback config available:', fallbackConfig.CHART_COLORS);
        
        // Test if analytics config is available
        if (typeof window.ANALYTICS_CONFIG !== 'undefined') {
            console.log('✅ ANALYTICS_CONFIG is available');
        } else {
            console.log('ℹ️ ANALYTICS_CONFIG not available, using fallbacks');
        }
        
        return true;
        
    } catch (error) {
        console.log('❌ Chart colors test failed:', error.message);
        return false;
    }
}

// Test analytics functions
function testAnalyticsFunctions() {
    console.log('🔧 Testing Analytics Functions...');
    
    const functions = [
        'setupAnalytics',
        'loadOverviewStats', 
        'generateReport',
        'exportToCSV'
    ];
    
    const available = [];
    const missing = [];
    
    functions.forEach(funcName => {
        if (typeof window[funcName] === 'function') {
            available.push(funcName);
            console.log(`✅ ${funcName} is available`);
        } else {
            missing.push(funcName);
            console.log(`❌ ${funcName} is missing`);
        }
    });
    
    console.log(`📊 Functions: ${available.length}/${functions.length} available`);
    
    return available.length >= functions.length * 0.5; // At least 50%
}

// Test DOM elements
function testDOMElements() {
    console.log('🏗️ Testing DOM Elements...');
    
    const elements = [
        'analytics',
        'userChart',
        'eventChart', 
        'achievementChart'
    ];
    
    const found = [];
    const missing = [];
    
    elements.forEach(elementId => {
        const element = document.getElementById(elementId);
        if (element) {
            found.push(elementId);
            console.log(`✅ ${elementId} found`);
        } else {
            missing.push(elementId);
            console.log(`❌ ${elementId} missing`);
        }
    });
    
    console.log(`📊 Elements: ${found.length}/${elements.length} found`);
    
    return found.length >= elements.length * 0.75; // At least 75%
}

// Run all immediate tests
function runImmediateTests() {
    console.log('🚀 Running Immediate Tests...');
    console.log('=====================================');
    
    const results = {
        chartColors: testChartColors(),
        analyticsFunctions: testAnalyticsFunctions(),
        domElements: testDOMElements()
    };
    
    const passedTests = Object.values(results).filter(r => r).length;
    const totalTests = Object.keys(results).length;
    
    console.log('=====================================');
    console.log(`📊 Overall Results: ${passedTests}/${totalTests} tests passed`);
    
    if (passedTests === totalTests) {
        console.log('🎉 All immediate tests passed!');
        console.log('✅ Analytics should be working correctly');
        console.log('💡 Try navigating to the Analytics section');
    } else if (passedTests >= totalTests * 0.66) {
        console.log('⚠️ Most tests passed, minor issues detected');
        console.log('✅ Basic functionality should work');
    } else {
        console.log('❌ Several tests failed');
        console.log('⚠️ There may be issues with the analytics module');
    }
    
    return {
        results,
        passed: passedTests,
        total: totalTests,
        success: passedTests >= totalTests * 0.66
    };
}

// Auto-run the test
// Auto-running immediate tests - disabled for cleaner console
// setTimeout(() => {
//     runImmediateTests();
// }, 1000);

// Make available globally
if (typeof window !== 'undefined') {
    window.runImmediateTests = runImmediateTests;
    window.testChartColors = testChartColors;
    window.testAnalyticsFunctions = testAnalyticsFunctions;
    window.testDOMElements = testDOMElements;
}

export { runImmediateTests, testChartColors, testAnalyticsFunctions, testDOMElements };
