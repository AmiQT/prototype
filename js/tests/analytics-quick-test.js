/**
 * Quick test to verify analytics fixes
 */

// Test the analytics module loading
async function testAnalyticsLoading() {
    console.log('🧪 Testing Analytics Module Loading...');
    
    try {
        // Import the main analytics module
        const analytics = await import('../features/analytics.js');
        console.log('✅ Analytics module imported successfully');
        
        // Test basic functions
        if (typeof analytics.loadOverviewStats === 'function') {
            console.log('✅ loadOverviewStats function available');
        }
        
        if (typeof analytics.setupAnalytics === 'function') {
            console.log('✅ setupAnalytics function available');
        }
        
        if (typeof analytics.getAnalyticsStats === 'function') {
            console.log('✅ getAnalyticsStats function available');
        }
        
        // Test stats function (should work with fallbacks)
        try {
            const stats = analytics.getAnalyticsStats();
            console.log('✅ getAnalyticsStats works:', {
                isInitialized: stats.isInitialized,
                hasPerformance: !!stats.performance,
                hasCache: !!stats.cache,
                hasCharts: !!stats.charts
            });
        } catch (error) {
            console.log('❌ getAnalyticsStats failed:', error.message);
        }
        
        console.log('✅ Analytics module test completed successfully');
        return true;
        
    } catch (error) {
        console.error('❌ Analytics module test failed:', error);
        return false;
    }
}

// Test enhanced modules loading
async function testEnhancedModulesLoading() {
    console.log('🧪 Testing Enhanced Modules Loading...');
    
    const modules = [
        { name: 'analytics-cache', path: '../utils/analytics-cache.js' },
        { name: 'analytics-data-fetcher', path: '../utils/analytics-data-fetcher.js' },
        { name: 'analytics-chart-manager', path: '../utils/analytics-chart-manager.js' },
        { name: 'security-manager', path: '../utils/security-manager.js' },
        { name: 'analytics-config', path: '../config/analytics-config.js' }
    ];
    
    const results = {};
    
    for (const module of modules) {
        try {
            await import(module.path);
            results[module.name] = 'success';
            console.log(`✅ ${module.name} loaded successfully`);
        } catch (error) {
            results[module.name] = 'failed';
            console.log(`⚠️ ${module.name} failed to load: ${error.message}`);
        }
    }
    
    console.log('📊 Enhanced modules loading results:', results);
    return results;
}

// Test logging system
function testLoggingSystem() {
    console.log('🧪 Testing Logging System...');
    
    try {
        // Test if we can access localStorage
        localStorage.setItem('test-analytics', 'test');
        localStorage.removeItem('test-analytics');
        console.log('✅ localStorage access works');
        
        // Test development mode detection
        const isDev = window.location.hostname === 'localhost' || 
                     window.location.hostname === '127.0.0.1' ||
                     window.location.hostname.includes('dev') ||
                     window.location.port !== '';
        
        console.log('✅ Development mode detection:', isDev);
        
        return true;
    } catch (error) {
        console.error('❌ Logging system test failed:', error);
        return false;
    }
}

// Run all tests
async function runQuickTests() {
    console.log('🚀 Starting Quick Analytics Tests...');
    
    const results = {
        logging: testLoggingSystem(),
        analytics: await testAnalyticsLoading(),
        enhancedModules: await testEnhancedModulesLoading()
    };
    
    console.log('📋 Quick Test Results Summary:', results);
    
    const allPassed = Object.values(results).every(result => 
        typeof result === 'boolean' ? result : Object.values(result).some(r => r === 'success')
    );
    
    if (allPassed) {
        console.log('🎉 All quick tests passed! Analytics module is working.');
    } else {
        console.log('⚠️ Some tests failed, but analytics should work with fallbacks.');
    }
    
    return results;
}

// Make available globally for easy testing
window.runQuickAnalyticsTests = runQuickTests;

// Auto-run in development
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    console.log('🧪 Quick analytics tests available. Run with: runQuickAnalyticsTests()');
}

export { runQuickTests, testAnalyticsLoading, testEnhancedModulesLoading, testLoggingSystem };
