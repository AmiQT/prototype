/**
 * Test authentication timing and analytics loading
 */

// Test authentication state monitoring
function testAuthenticationTiming() {
    console.log('🧪 Testing Authentication Timing...');
    
    let authStateChanges = 0;
    let lastAuthState = null;
    
    // Supabase auth integration - this test is deprecated
    // const unsubscribe = firebase.auth().onAuthStateChanged((user) => {
        authStateChanges++;
        lastAuthState = user ? 'authenticated' : 'unauthenticated';
        
        console.log(`Auth state change #${authStateChanges}: ${lastAuthState}`);
        
        if (user) {
            console.log('✅ User authenticated:', {
                uid: user.uid,
                email: user.email
            });
        } else {
            console.log('ℹ️ User not authenticated');
        }
    });
    
    // Test analytics loading after auth
    setTimeout(async () => {
        try {
            console.log('🔄 Testing analytics loading after auth delay...');
            
            // Import analytics module
            const analytics = await import('../features/analytics.js');
            
            // Test loading overview stats
            await analytics.loadOverviewStats();
            console.log('✅ Overview stats loaded successfully after auth');
            
            // Test setup analytics
            await analytics.setupAnalytics();
            console.log('✅ Analytics setup completed successfully after auth');
            
        } catch (error) {
            console.log('⚠️ Analytics loading after auth failed:', error.message);
        }
        
        // Cleanup
        unsubscribe();
    }, 3000); // Wait 3 seconds for auth to settle
    
    return {
        getAuthStateChanges: () => authStateChanges,
        getLastAuthState: () => lastAuthState
    };
}

// Test security manager state
async function testSecurityManagerState() {
    console.log('🧪 Testing Security Manager State...');
    
    try {
        const { securityManager } = await import('../utils/security-manager.js');
        
        console.log('Security Manager Status:', {
            currentUser: securityManager.currentUser,
            canAccessAnalytics: securityManager.canAccessAnalytics(),
            canExportData: securityManager.canExportData(),
            sessionValid: securityManager.validateSession()
        });
        
        return true;
    } catch (error) {
        console.log('⚠️ Security manager test failed:', error.message);
        return false;
    }
}

// Test data fetcher with authentication
async function testDataFetcherAuth() {
    console.log('🧪 Testing Data Fetcher Authentication...');
    
    try {
        const { dataFetcher } = await import('../utils/analytics-data-fetcher.js');
        
        // Test fetching with current auth state
        const result = await dataFetcher.fetchData('users', { limit: 1 });
        
        console.log('✅ Data fetcher test successful:', {
            recordCount: result.data.length,
            fromCache: result.fromCache
        });
        
        return true;
    } catch (error) {
        console.log('⚠️ Data fetcher test failed:', error.message);
        return false;
    }
}

// Comprehensive authentication and analytics test
async function runAuthAnalyticsTest() {
    console.log('🚀 Starting Authentication & Analytics Integration Test...');
    
    const results = {
        authTiming: testAuthenticationTiming(),
        securityManager: await testSecurityManagerState(),
        dataFetcher: await testDataFetcherAuth()
    };
    
    // Wait for auth timing test to complete
    setTimeout(() => {
        console.log('📋 Auth & Analytics Test Results:', {
            authStateChanges: results.authTiming.getAuthStateChanges(),
            lastAuthState: results.authTiming.getLastAuthState(),
            securityManagerWorking: results.securityManager,
            dataFetcherWorking: results.dataFetcher
        });
    }, 4000);
    
    return results;
}

// Monitor analytics loading in real-time
function monitorAnalyticsLoading() {
    console.log('👀 Monitoring Analytics Loading...');
    
    // Monitor console for analytics messages
    const originalLog = console.log;
    const originalError = console.error;
    
    const analyticsMessages = [];
    
    console.log = function(...args) {
        const message = args.join(' ');
        if (message.includes('[Analytics') || message.includes('analytics') || message.includes('Analytics')) {
            analyticsMessages.push({
                type: 'log',
                timestamp: new Date().toISOString(),
                message: message
            });
        }
        originalLog.apply(console, args);
    };
    
    console.error = function(...args) {
        const message = args.join(' ');
        if (message.includes('[Analytics') || message.includes('analytics') || message.includes('Analytics')) {
            analyticsMessages.push({
                type: 'error',
                timestamp: new Date().toISOString(),
                message: message
            });
        }
        originalError.apply(console, args);
    };
    
    // Restore original functions after 10 seconds
    setTimeout(() => {
        console.log = originalLog;
        console.error = originalError;
        
        console.log('📊 Analytics Loading Messages Captured:', analyticsMessages);
    }, 10000);
    
    return analyticsMessages;
}

// Make tests available globally
window.testAuthenticationTiming = testAuthenticationTiming;
window.testSecurityManagerState = testSecurityManagerState;
window.testDataFetcherAuth = testDataFetcherAuth;
window.runAuthAnalyticsTest = runAuthAnalyticsTest;
window.monitorAnalyticsLoading = monitorAnalyticsLoading;

// Auto-run in development
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    console.log('🧪 Auth & Analytics tests available:');
    console.log('   - runAuthAnalyticsTest()');
    console.log('   - monitorAnalyticsLoading()');
    console.log('   - testAuthenticationTiming()');
}

export { 
    testAuthenticationTiming, 
    testSecurityManagerState, 
    testDataFetcherAuth, 
    runAuthAnalyticsTest,
    monitorAnalyticsLoading 
};
