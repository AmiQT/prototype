/**
 * Test to verify console cleanup and check for loops
 */

// Monitor console messages for a period
function monitorConsoleMessages(duration = 10000) {
    console.log('🧪 Monitoring console messages for', duration / 1000, 'seconds...');
    
    const messages = [];
    const originalLog = console.log;
    const originalWarn = console.warn;
    const originalError = console.error;
    
    // Intercept console messages
    console.log = function(...args) {
        const message = args.join(' ');
        messages.push({ type: 'log', message, timestamp: Date.now() });
        originalLog.apply(console, args);
    };
    
    console.warn = function(...args) {
        const message = args.join(' ');
        messages.push({ type: 'warn', message, timestamp: Date.now() });
        originalWarn.apply(console, args);
    };
    
    console.error = function(...args) {
        const message = args.join(' ');
        messages.push({ type: 'error', message, timestamp: Date.now() });
        originalError.apply(console, args);
    };
    
    // Restore after duration
    setTimeout(() => {
        console.log = originalLog;
        console.warn = originalWarn;
        console.error = originalError;
        
        // Analyze messages
        const analyticsMessages = messages.filter(m => 
            m.message.includes('Analytics') || 
            m.message.includes('analytics') ||
            m.message.includes('[Analytics')
        );
        
        const repeatedMessages = findRepeatedMessages(analyticsMessages);
        
        console.log('📊 Console Message Analysis:');
        console.log('Total messages:', messages.length);
        console.log('Analytics messages:', analyticsMessages.length);
        console.log('Repeated analytics messages:', repeatedMessages.length);
        
        if (repeatedMessages.length > 0) {
            console.log('⚠️ Found repeated messages (potential loops):');
            repeatedMessages.forEach(msg => {
                console.log(`  - "${msg.message}" (${msg.count} times)`);
            });
        } else {
            console.log('✅ No repeated messages detected');
        }
        
        return {
            total: messages.length,
            analytics: analyticsMessages.length,
            repeated: repeatedMessages.length,
            messages: analyticsMessages
        };
    }, duration);
}

// Find repeated messages
function findRepeatedMessages(messages) {
    const counts = {};
    
    messages.forEach(msg => {
        const key = msg.message.substring(0, 100); // First 100 chars
        counts[key] = (counts[key] || 0) + 1;
    });
    
    return Object.entries(counts)
        .filter(([message, count]) => count > 2)
        .map(([message, count]) => ({ message, count }));
}

// Test analytics section navigation
async function testAnalyticsNavigation() {
    console.log('🧪 Testing analytics section navigation...');
    
    try {
        // Simulate clicking analytics section
        const analyticsSection = document.querySelector('[data-section="analytics"]');
        if (analyticsSection) {
            analyticsSection.click();
            console.log('✅ Analytics section clicked');
            
            // Wait a bit and check if section is active
            setTimeout(() => {
                const isActive = document.getElementById('analytics')?.classList.contains('active');
                console.log('Analytics section active:', isActive);
            }, 1000);
        } else {
            console.log('⚠️ Analytics navigation button not found');
        }
    } catch (error) {
        console.log('❌ Error testing analytics navigation:', error.message);
    }
}

// Test for memory leaks
function testMemoryUsage() {
    console.log('🧪 Testing memory usage...');
    
    if (performance.memory) {
        const initial = performance.memory.usedJSHeapSize;
        console.log('Initial memory usage:', (initial / 1024 / 1024).toFixed(2), 'MB');
        
        // Test after 5 seconds
        setTimeout(() => {
            const current = performance.memory.usedJSHeapSize;
            const increase = current - initial;
            console.log('Memory usage after 5s:', (current / 1024 / 1024).toFixed(2), 'MB');
            console.log('Memory increase:', (increase / 1024 / 1024).toFixed(2), 'MB');
            
            if (increase > 10 * 1024 * 1024) { // 10MB increase
                console.log('⚠️ Significant memory increase detected');
            } else {
                console.log('✅ Memory usage looks normal');
            }
        }, 5000);
    } else {
        console.log('⚠️ Performance.memory not available');
    }
}

// Check for infinite loops by monitoring function calls
function detectPotentialLoops() {
    console.log('🧪 Checking for potential infinite loops...');
    
    const callCounts = {};
    const originalSetupAnalytics = window.setupAnalytics;
    const originalLoadOverviewStats = window.loadOverviewStats;
    
    if (originalSetupAnalytics) {
        window.setupAnalytics = function(...args) {
            callCounts.setupAnalytics = (callCounts.setupAnalytics || 0) + 1;
            return originalSetupAnalytics.apply(this, args);
        };
    }
    
    if (originalLoadOverviewStats) {
        window.loadOverviewStats = function(...args) {
            callCounts.loadOverviewStats = (callCounts.loadOverviewStats || 0) + 1;
            return originalLoadOverviewStats.apply(this, args);
        };
    }
    
    // Check after 10 seconds
    setTimeout(() => {
        console.log('📊 Function call counts:', callCounts);
        
        Object.entries(callCounts).forEach(([func, count]) => {
            if (count > 5) {
                console.log(`⚠️ ${func} called ${count} times - potential loop`);
            } else {
                console.log(`✅ ${func} called ${count} times - normal`);
            }
        });
        
        // Restore original functions
        if (originalSetupAnalytics) window.setupAnalytics = originalSetupAnalytics;
        if (originalLoadOverviewStats) window.loadOverviewStats = originalLoadOverviewStats;
    }, 10000);
}

// Run comprehensive cleanup test
function runConsoleCleanupTest() {
    console.log('🚀 Starting Console Cleanup Test...');
    
    // Start monitoring
    monitorConsoleMessages(15000);
    
    // Test navigation
    setTimeout(() => testAnalyticsNavigation(), 2000);
    
    // Test memory
    testMemoryUsage();
    
    // Check for loops
    detectPotentialLoops();
    
    console.log('✅ Console cleanup test started - results in 15 seconds');
}

// Make available globally
window.monitorConsoleMessages = monitorConsoleMessages;
window.testAnalyticsNavigation = testAnalyticsNavigation;
window.runConsoleCleanupTest = runConsoleCleanupTest;

// Auto-run in development
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    // Console cleanup tests available
}

export { monitorConsoleMessages, testAnalyticsNavigation, runConsoleCleanupTest };
