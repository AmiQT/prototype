/**
 * Comparative analysis engine for analytics data
 */
export class ComparativeAnalysis {
    constructor() {
        this.analysisCache = new Map();
    }
    
    /**
     * Compare data between two time periods
     */
    comparePeriods(currentData, previousData, options = {}) {
        const {
            metrics = ['count', 'growth', 'percentage'],
            groupBy = null,
            calculateTrends = true
        } = options;
        
        const comparison = {
            current: this.analyzeDataset(currentData, groupBy),
            previous: this.analyzeDataset(previousData, groupBy),
            changes: {},
            trends: {},
            insights: []
        };
        
        // Calculate changes
        if (metrics.includes('count')) {
            comparison.changes.absolute = comparison.current.total - comparison.previous.total;
            comparison.changes.percentage = comparison.previous.total > 0 
                ? ((comparison.changes.absolute / comparison.previous.total) * 100).toFixed(1)
                : 'N/A';
        }
        
        if (metrics.includes('growth')) {
            comparison.changes.growthRate = this.calculateGrowthRate(
                comparison.previous.total, 
                comparison.current.total
            );
        }
        
        // Group-by comparisons
        if (groupBy && comparison.current.groups && comparison.previous.groups) {
            comparison.changes.groups = this.compareGroups(
                comparison.current.groups,
                comparison.previous.groups
            );
        }
        
        // Calculate trends
        if (calculateTrends) {
            comparison.trends = this.calculateTrends(currentData, previousData);
        }
        
        // Generate insights
        comparison.insights = this.generateInsights(comparison);
        
        return comparison;
    }
    
    /**
     * Compare multiple datasets
     */
    compareMultipleDatasets(datasets, options = {}) {
        const {
            labels = [],
            metrics = ['count', 'average', 'distribution'],
            normalizeData = false
        } = options;
        
        const comparison = {
            datasets: {},
            summary: {},
            correlations: {},
            rankings: {},
            insights: []
        };
        
        // Analyze each dataset
        datasets.forEach((data, index) => {
            const label = labels[index] || `Dataset ${index + 1}`;
            comparison.datasets[label] = this.analyzeDataset(data);
        });
        
        // Calculate summary statistics
        comparison.summary = this.calculateSummaryStats(comparison.datasets);
        
        // Calculate correlations if multiple numeric datasets
        if (datasets.length > 1) {
            comparison.correlations = this.calculateCorrelations(datasets, labels);
        }
        
        // Rank datasets by various metrics
        comparison.rankings = this.rankDatasets(comparison.datasets);
        
        // Generate comparative insights
        comparison.insights = this.generateComparativeInsights(comparison);
        
        return comparison;
    }
    
    /**
     * Analyze a single dataset
     */
    analyzeDataset(data, groupBy = null) {
        const analysis = {
            total: data.length,
            groups: {},
            statistics: {},
            distribution: {},
            trends: {}
        };
        
        if (data.length === 0) return analysis;
        
        // Group data if specified
        if (groupBy) {
            analysis.groups = this.groupData(data, groupBy);
        }
        
        // Calculate basic statistics
        analysis.statistics = this.calculateStatistics(data);
        
        // Calculate distribution
        analysis.distribution = this.calculateDistribution(data);
        
        return analysis;
    }
    
    /**
     * Group data by specified field
     */
    groupData(data, groupBy) {
        const groups = {};
        
        data.forEach(item => {
            const key = this.getGroupKey(item, groupBy);
            if (!groups[key]) {
                groups[key] = [];
            }
            groups[key].push(item);
        });
        
        // Convert to counts and percentages
        const total = data.length;
        const result = {};
        
        Object.keys(groups).forEach(key => {
            result[key] = {
                count: groups[key].length,
                percentage: ((groups[key].length / total) * 100).toFixed(1),
                data: groups[key]
            };
        });
        
        return result;
    }
    
    /**
     * Get group key for item
     */
    getGroupKey(item, groupBy) {
        if (typeof groupBy === 'string') {
            return item[groupBy] || 'Unknown';
        }
        
        if (typeof groupBy === 'function') {
            return groupBy(item);
        }
        
        if (Array.isArray(groupBy)) {
            return groupBy.map(field => item[field] || 'Unknown').join(' - ');
        }
        
        return 'All';
    }
    
    /**
     * Calculate basic statistics
     */
    calculateStatistics(data) {
        if (data.length === 0) return {};
        
        // Find numeric fields
        const numericFields = this.findNumericFields(data);
        const stats = {};
        
        numericFields.forEach(field => {
            const values = data.map(item => item[field]).filter(val => typeof val === 'number');
            
            if (values.length > 0) {
                stats[field] = {
                    min: Math.min(...values),
                    max: Math.max(...values),
                    mean: values.reduce((sum, val) => sum + val, 0) / values.length,
                    median: this.calculateMedian(values),
                    stdDev: this.calculateStandardDeviation(values)
                };
            }
        });
        
        return stats;
    }
    
    /**
     * Find numeric fields in data
     */
    findNumericFields(data) {
        if (data.length === 0) return [];
        
        const sample = data[0];
        return Object.keys(sample).filter(key => 
            typeof sample[key] === 'number' && !isNaN(sample[key])
        );
    }
    
    /**
     * Calculate median
     */
    calculateMedian(values) {
        const sorted = [...values].sort((a, b) => a - b);
        const mid = Math.floor(sorted.length / 2);
        
        return sorted.length % 2 === 0
            ? (sorted[mid - 1] + sorted[mid]) / 2
            : sorted[mid];
    }
    
    /**
     * Calculate standard deviation
     */
    calculateStandardDeviation(values) {
        const mean = values.reduce((sum, val) => sum + val, 0) / values.length;
        const squaredDiffs = values.map(val => Math.pow(val - mean, 2));
        const avgSquaredDiff = squaredDiffs.reduce((sum, val) => sum + val, 0) / values.length;
        return Math.sqrt(avgSquaredDiff);
    }
    
    /**
     * Calculate distribution
     */
    calculateDistribution(data) {
        const distribution = {};
        
        // Time-based distribution if createdAt exists
        if (data.length > 0 && data[0].createdAt) {
            distribution.temporal = this.calculateTemporalDistribution(data);
        }
        
        // Categorical distributions
        const categoricalFields = this.findCategoricalFields(data);
        categoricalFields.forEach(field => {
            distribution[field] = this.calculateCategoricalDistribution(data, field);
        });
        
        return distribution;
    }
    
    /**
     * Calculate temporal distribution
     */
    calculateTemporalDistribution(data) {
        const periods = {
            hourly: {},
            daily: {},
            weekly: {},
            monthly: {}
        };
        
        data.forEach(item => {
            const date = new Date(item.createdAt);
            if (isNaN(date.getTime())) return;
            
            const hour = date.getHours();
            const day = date.getDay();
            const week = this.getWeekNumber(date);
            const month = date.getMonth();
            
            periods.hourly[hour] = (periods.hourly[hour] || 0) + 1;
            periods.daily[day] = (periods.daily[day] || 0) + 1;
            periods.weekly[week] = (periods.weekly[week] || 0) + 1;
            periods.monthly[month] = (periods.monthly[month] || 0) + 1;
        });
        
        return periods;
    }
    
    /**
     * Find categorical fields
     */
    findCategoricalFields(data) {
        if (data.length === 0) return [];
        
        const sample = data[0];
        return Object.keys(sample).filter(key => 
            typeof sample[key] === 'string' && 
            !key.includes('Id') && 
            !key.includes('At') &&
            key !== 'email'
        );
    }
    
    /**
     * Calculate categorical distribution
     */
    calculateCategoricalDistribution(data, field) {
        const counts = {};
        
        data.forEach(item => {
            const value = item[field] || 'Unknown';
            counts[value] = (counts[value] || 0) + 1;
        });
        
        return counts;
    }
    
    /**
     * Compare groups between periods
     */
    compareGroups(currentGroups, previousGroups) {
        const comparison = {};
        
        // Get all unique group keys
        const allKeys = new Set([
            ...Object.keys(currentGroups),
            ...Object.keys(previousGroups)
        ]);
        
        allKeys.forEach(key => {
            const current = currentGroups[key]?.count || 0;
            const previous = previousGroups[key]?.count || 0;
            
            comparison[key] = {
                current,
                previous,
                change: current - previous,
                percentageChange: previous > 0 
                    ? ((current - previous) / previous * 100).toFixed(1)
                    : current > 0 ? 'New' : 'N/A'
            };
        });
        
        return comparison;
    }
    
    /**
     * Calculate growth rate
     */
    calculateGrowthRate(previous, current) {
        if (previous === 0) {
            return current > 0 ? 'Infinite' : 0;
        }
        
        return ((current - previous) / previous * 100).toFixed(1);
    }
    
    /**
     * Calculate trends
     */
    calculateTrends(currentData, previousData) {
        const trends = {
            direction: 'stable',
            strength: 0,
            confidence: 0
        };
        
        const currentTotal = currentData.length;
        const previousTotal = previousData.length;
        
        if (currentTotal > previousTotal * 1.1) {
            trends.direction = 'increasing';
            trends.strength = ((currentTotal - previousTotal) / previousTotal * 100);
        } else if (currentTotal < previousTotal * 0.9) {
            trends.direction = 'decreasing';
            trends.strength = ((previousTotal - currentTotal) / previousTotal * 100);
        }
        
        // Simple confidence calculation based on data size
        trends.confidence = Math.min(90, Math.max(10, (currentTotal + previousTotal) / 10));
        
        return trends;
    }
    
    /**
     * Generate insights from comparison
     */
    generateInsights(comparison) {
        const insights = [];
        
        // Growth insights
        if (comparison.changes.percentage !== 'N/A') {
            const change = parseFloat(comparison.changes.percentage);
            if (change > 20) {
                insights.push({
                    type: 'growth',
                    severity: 'high',
                    message: `Significant growth of ${change}% compared to previous period`
                });
            } else if (change < -20) {
                insights.push({
                    type: 'decline',
                    severity: 'high',
                    message: `Significant decline of ${Math.abs(change)}% compared to previous period`
                });
            }
        }
        
        // Trend insights
        if (comparison.trends.direction !== 'stable') {
            insights.push({
                type: 'trend',
                severity: comparison.trends.strength > 30 ? 'high' : 'medium',
                message: `${comparison.trends.direction} trend with ${comparison.trends.strength.toFixed(1)}% change`
            });
        }
        
        return insights;
    }
    
    /**
     * Get week number
     */
    getWeekNumber(date) {
        const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
        const pastDaysOfYear = (date - firstDayOfYear) / 86400000;
        return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
    }
}

// Create singleton instance
export const comparativeAnalysis = new ComparativeAnalysis();
