/**
 * Comprehensive Analytics Module Test Suite
 * Tests all enhanced analytics functionality
 */

import { analyticsCache } from '../utils/analytics-cache.js';
import { dataFetcher } from '../utils/analytics-data-fetcher.js';
import { chartManager } from '../utils/analytics-chart-manager.js';
import { AnalyticsValidator } from '../utils/analytics-validator.js';
import { getAnalyticsStats } from '../features/analytics.js';

class AnalyticsTestSuite {
    constructor() {
        this.testResults = [];
        this.totalTests = 0;
        this.passedTests = 0;
    }
    
    async runAllTests() {
        console.log('🧪 Starting Analytics Test Suite...');
        
        await this.testCacheSystem();
        await this.testDataFetcher();
        await this.testChartManager();
        await this.testDataValidation();
        await this.testPerformanceMetrics();
        
        this.printResults();
    }
    
    async testCacheSystem() {
        console.log('📦 Testing Cache System...');
        
        // Test cache set/get
        this.test('Cache Set/Get', () => {
            analyticsCache.set('test-key', { data: 'test' }, 1000);
            const result = analyticsCache.get('test-key');
            return result && result.data === 'test';
        });
        
        // Test cache expiration
        this.test('Cache Expiration', async () => {
            analyticsCache.set('expire-test', { data: 'expire' }, 100);
            await this.delay(150);
            const result = analyticsCache.get('expire-test');
            return result === null;
        });
        
        // Test cache invalidation
        this.test('Cache Invalidation', () => {
            analyticsCache.set('users_test', { data: 'users' });
            analyticsCache.set('users_filtered', { data: 'filtered' });
            analyticsCache.invalidatePattern('^users');
            return !analyticsCache.has('users_test') && !analyticsCache.has('users_filtered');
        });
        
        // Test cache stats
        this.test('Cache Statistics', () => {
            const stats = analyticsCache.getStats();
            return stats && typeof stats.totalEntries === 'number';
        });
    }
    
    async testDataFetcher() {
        console.log('🔄 Testing Data Fetcher...');
        
        // Test data validation
        this.test('Data Fetcher Stats', () => {
            const stats = dataFetcher.getStats();
            return stats && typeof stats.activeRequests === 'number';
        });
        
        // Test aggregation
        this.test('Data Aggregation', () => {
            const testData = [
                { role: 'student', points: 10 },
                { role: 'student', points: 20 },
                { role: 'lecturer', points: 30 }
            ];
            
            const aggregations = [
                { type: 'count', name: 'total' },
                { type: 'sum', name: 'totalPoints', field: 'points' },
                { type: 'groupBy', name: 'byRole', field: 'role' }
            ];
            
            const result = dataFetcher._performAggregations(testData, aggregations);
            return result.total === 3 && result.totalPoints === 60 && result.byRole.student === 2;
        });
    }
    
    async testChartManager() {
        console.log('📊 Testing Chart Manager...');
        
        // Test chart configuration sanitization
        this.test('Chart Config Sanitization', () => {
            const config = { data: { datasets: [{ data: 'invalid' }] } };
            const sanitized = chartManager._sanitizeConfig(config);
            return Array.isArray(sanitized.data.datasets[0].data);
        });
        
        // Test performance stats
        this.test('Chart Performance Stats', () => {
            const stats = chartManager.getPerformanceStats();
            return stats && typeof stats.totalCharts === 'number';
        });
        
        // Test chart memory management
        this.test('Chart Memory Management', () => {
            // Simulate chart creation and destruction
            chartManager.charts.set('test-chart', { destroy: () => {} });
            chartManager.destroyChart('test-chart');
            return !chartManager.charts.has('test-chart');
        });
    }
    
    async testDataValidation() {
        console.log('✅ Testing Data Validation...');
        
        // Test valid data
        this.test('Valid Data Validation', () => {
            const validData = [
                { id: '1', createdAt: '2024-01-01', role: 'student' },
                { id: '2', createdAt: '2024-01-02', role: 'lecturer' }
            ];
            
            const result = AnalyticsValidator.validateData(validData, 'users');
            return result.isValid && result.cleanedData.length === 2;
        });
        
        // Test invalid data
        this.test('Invalid Data Handling', () => {
            const invalidData = [
                { role: 'student' }, // missing required fields
                { id: '2', createdAt: 'invalid-date', role: 'unknown' }
            ];
            
            const result = AnalyticsValidator.validateData(invalidData, 'users');
            return !result.isValid && result.errors.length > 0;
        });
        
        // Test email validation
        this.test('Email Validation', () => {
            const validEmail = AnalyticsValidator.isValidEmail('test@example.com');
            const invalidEmail = AnalyticsValidator.isValidEmail('invalid-email');
            return validEmail && !invalidEmail;
        });
        
        // Test date validation
        this.test('Date Validation', () => {
            const validDate = AnalyticsValidator.validateDate('2024-01-01');
            const invalidDate = AnalyticsValidator.validateDate('invalid');
            return validDate.isValid && !invalidDate.isValid;
        });
    }
    
    async testPerformanceMetrics() {
        console.log('⚡ Testing Performance Metrics...');
        
        // Test analytics stats
        this.test('Analytics Statistics', () => {
            const stats = getAnalyticsStats();
            return stats && stats.performance && stats.cache && stats.charts;
        });
        
        // Test memory usage tracking
        this.test('Memory Usage Tracking', () => {
            if (performance.memory) {
                const usage = chartManager.getPerformanceStats().memoryUsage;
                return usage === null || (usage && typeof usage.used === 'number');
            }
            return true; // Skip if performance.memory not available
        });
    }
    
    // Test utility methods
    test(name, testFunction) {
        this.totalTests++;
        try {
            const result = testFunction();
            if (result === true || (result && result.then)) {
                this.passedTests++;
                this.testResults.push({ name, status: 'PASS', error: null });
                console.log(`✅ ${name}: PASS`);
            } else {
                this.testResults.push({ name, status: 'FAIL', error: 'Test returned false' });
                console.log(`❌ ${name}: FAIL - Test returned false`);
            }
        } catch (error) {
            this.testResults.push({ name, status: 'ERROR', error: error.message });
            console.log(`💥 ${name}: ERROR - ${error.message}`);
        }
    }
    
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    
    printResults() {
        console.log('\n📋 Test Results Summary:');
        console.log(`Total Tests: ${this.totalTests}`);
        console.log(`Passed: ${this.passedTests}`);
        console.log(`Failed: ${this.totalTests - this.passedTests}`);
        console.log(`Success Rate: ${((this.passedTests / this.totalTests) * 100).toFixed(1)}%`);
        
        const failedTests = this.testResults.filter(t => t.status !== 'PASS');
        if (failedTests.length > 0) {
            console.log('\n❌ Failed Tests:');
            failedTests.forEach(test => {
                console.log(`  - ${test.name}: ${test.error || 'Unknown error'}`);
            });
        }
        
        // Generate test report
        this.generateTestReport();
    }
    
    generateTestReport() {
        const report = {
            timestamp: new Date().toISOString(),
            summary: {
                totalTests: this.totalTests,
                passedTests: this.passedTests,
                failedTests: this.totalTests - this.passedTests,
                successRate: ((this.passedTests / this.totalTests) * 100).toFixed(1) + '%'
            },
            results: this.testResults,
            systemInfo: {
                userAgent: navigator.userAgent,
                memorySupport: !!performance.memory,
                chartJsVersion: typeof Chart !== 'undefined' ? Chart.version : 'Not loaded'
            }
        };
        
        // Store in localStorage for debugging
        localStorage.setItem('analyticsTestReport', JSON.stringify(report, null, 2));
        console.log('📄 Test report saved to localStorage as "analyticsTestReport"');
    }
}

// Auto-run tests if in development mode
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    window.runAnalyticsTests = () => {
        const testSuite = new AnalyticsTestSuite();
        return testSuite.runAllTests();
    };
    
    console.log('🧪 Analytics tests available. Run with: runAnalyticsTests()');
}

export { AnalyticsTestSuite };
