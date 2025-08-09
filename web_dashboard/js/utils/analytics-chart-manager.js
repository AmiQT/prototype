import { ANALYTICS_CONFIG, CHART_TYPES } from '../config/analytics-config.js';

/**
 * Advanced chart management with memory leak prevention and performance optimization
 */
export class AnalyticsChartManager {
    constructor() {
        this.charts = new Map();
        this.chartConfigs = new Map();
        this.renderQueue = [];
        this.isProcessingQueue = false;
        this.performanceMetrics = {
            renderTimes: [],
            memoryUsage: [],
            chartCount: 0
        };
        
        // Setup performance monitoring
        this.startPerformanceMonitoring();
    }
    
    /**
     * Create or update a chart with proper cleanup
     */
    async createChart(canvasId, config) {
        try {
            const canvas = document.getElementById(canvasId);
            if (!canvas) {
                throw new Error(`Canvas element not found: ${canvasId}`);
            }
            
            // Destroy existing chart if it exists
            this.destroyChart(canvasId);
            
            // Validate and sanitize config
            const sanitizedConfig = this._sanitizeConfig(config);
            
            // Add to render queue for performance
            return new Promise((resolve, reject) => {
                this.renderQueue.push({
                    canvasId,
                    config: sanitizedConfig,
                    resolve,
                    reject
                });
                
                this._processRenderQueue();
            });
            
        } catch (error) {
            console.error(`[ChartManager] Error creating chart ${canvasId}:`, error);
            throw error;
        }
    }
    
    /**
     * Process render queue to prevent UI blocking
     */
    async _processRenderQueue() {
        if (this.isProcessingQueue || this.renderQueue.length === 0) {
            return;
        }
        
        this.isProcessingQueue = true;
        
        while (this.renderQueue.length > 0) {
            const { canvasId, config, resolve, reject } = this.renderQueue.shift();
            
            try {
                const chart = await this._renderChart(canvasId, config);
                resolve(chart);
            } catch (error) {
                reject(error);
            }
            
            // Small delay to prevent blocking
            await this._delay(10);
        }
        
        this.isProcessingQueue = false;
    }
    
    /**
     * Actually render the chart
     */
    async _renderChart(canvasId, config) {
        const startTime = performance.now();
        
        try {
            const canvas = document.getElementById(canvasId);
            const ctx = canvas.getContext('2d');
            
            // Apply default options
            const mergedConfig = this._mergeWithDefaults(config);
            
            // Create chart with error handling
            const chart = new Chart(ctx, mergedConfig);
            
            // Store chart and config
            this.charts.set(canvasId, chart);
            this.chartConfigs.set(canvasId, config);
            
            const renderTime = performance.now() - startTime;
            this.performanceMetrics.renderTimes.push(renderTime);
            this.performanceMetrics.chartCount++;
            
            console.debug(`[ChartManager] Created chart ${canvasId} in ${renderTime.toFixed(2)}ms`);
            
            // Setup chart event listeners
            this._setupChartEvents(canvasId, chart);
            
            return chart;
            
        } catch (error) {
            console.error(`[ChartManager] Error rendering chart ${canvasId}:`, error);
            throw error;
        }
    }
    
    /**
     * Destroy a specific chart
     */
    destroyChart(canvasId) {
        const chart = this.charts.get(canvasId);
        if (chart) {
            try {
                chart.destroy();
                this.charts.delete(canvasId);
                this.chartConfigs.delete(canvasId);
                this.performanceMetrics.chartCount--;
                
                console.debug(`[ChartManager] Destroyed chart: ${canvasId}`);
            } catch (error) {
                console.error(`[ChartManager] Error destroying chart ${canvasId}:`, error);
            }
        }
    }
    
    /**
     * Destroy all charts
     */
    destroyAllCharts() {
        const chartIds = Array.from(this.charts.keys());
        chartIds.forEach(id => this.destroyChart(id));
        console.debug(`[ChartManager] Destroyed ${chartIds.length} charts`);
    }
    
    /**
     * Update chart data without recreating
     */
    updateChartData(canvasId, newData, newLabels = null) {
        const chart = this.charts.get(canvasId);
        if (!chart) {
            console.warn(`[ChartManager] Chart not found for update: ${canvasId}`);
            return false;
        }
        
        try {
            // Update data
            if (chart.data.datasets && chart.data.datasets.length > 0) {
                chart.data.datasets[0].data = newData;
            }
            
            // Update labels if provided
            if (newLabels) {
                chart.data.labels = newLabels;
            }
            
            // Animate update
            chart.update('active');
            
            console.debug(`[ChartManager] Updated chart data: ${canvasId}`);
            return true;
            
        } catch (error) {
            console.error(`[ChartManager] Error updating chart ${canvasId}:`, error);
            return false;
        }
    }
    
    /**
     * Get chart instance
     */
    getChart(canvasId) {
        return this.charts.get(canvasId);
    }
    
    /**
     * Check if chart exists
     */
    hasChart(canvasId) {
        return this.charts.has(canvasId);
    }
    
    /**
     * Resize all charts
     */
    resizeAllCharts() {
        this.charts.forEach((chart, canvasId) => {
            try {
                chart.resize();
                console.debug(`[ChartManager] Resized chart: ${canvasId}`);
            } catch (error) {
                console.error(`[ChartManager] Error resizing chart ${canvasId}:`, error);
            }
        });
    }
    
    /**
     * Export chart as image
     */
    exportChart(canvasId, format = 'png') {
        const chart = this.charts.get(canvasId);
        if (!chart) {
            throw new Error(`Chart not found: ${canvasId}`);
        }
        
        try {
            const url = chart.toBase64Image(format, 1.0);
            return url;
        } catch (error) {
            console.error(`[ChartManager] Error exporting chart ${canvasId}:`, error);
            throw error;
        }
    }
    
    /**
     * Sanitize chart configuration
     */
    _sanitizeConfig(config) {
        const sanitized = JSON.parse(JSON.stringify(config));
        
        // Ensure required properties
        if (!sanitized.type) {
            sanitized.type = CHART_TYPES.BAR;
        }
        
        if (!sanitized.data) {
            sanitized.data = { labels: [], datasets: [] };
        }
        
        // Validate data
        if (sanitized.data.datasets) {
            sanitized.data.datasets.forEach(dataset => {
                if (!Array.isArray(dataset.data)) {
                    dataset.data = [];
                }
            });
        }
        
        return sanitized;
    }
    
    /**
     * Merge config with defaults
     */
    _mergeWithDefaults(config) {
        const defaults = ANALYTICS_CONFIG.DEFAULT_CHART_OPTIONS;
        
        return {
            ...config,
            options: {
                ...defaults,
                ...config.options,
                plugins: {
                    ...defaults.plugins,
                    ...config.options?.plugins
                },
                scales: {
                    ...defaults.scales,
                    ...config.options?.scales
                }
            }
        };
    }
    
    /**
     * Setup chart event listeners
     */
    _setupChartEvents(canvasId, chart) {
        // Add click handler for interactivity
        chart.options.onClick = (event, elements) => {
            if (elements.length > 0) {
                const element = elements[0];
                const datasetIndex = element.datasetIndex;
                const index = element.index;
                const value = chart.data.datasets[datasetIndex].data[index];
                const label = chart.data.labels[index];
                
                console.debug(`[ChartManager] Chart clicked: ${canvasId}, Label: ${label}, Value: ${value}`);
                
                // Emit custom event
                const customEvent = new CustomEvent('chartClick', {
                    detail: { canvasId, label, value, datasetIndex, index }
                });
                document.dispatchEvent(customEvent);
            }
        };
    }
    
    /**
     * Start performance monitoring
     */
    startPerformanceMonitoring() {
        setInterval(() => {
            this._recordMemoryUsage();
        }, 30000); // Every 30 seconds
    }
    
    /**
     * Record memory usage
     */
    _recordMemoryUsage() {
        if (performance.memory) {
            this.performanceMetrics.memoryUsage.push({
                timestamp: Date.now(),
                used: performance.memory.usedJSHeapSize,
                total: performance.memory.totalJSHeapSize
            });
            
            // Keep only last 100 measurements
            if (this.performanceMetrics.memoryUsage.length > 100) {
                this.performanceMetrics.memoryUsage.shift();
            }
        }
    }
    
    /**
     * Get performance statistics
     */
    getPerformanceStats() {
        const renderTimes = this.performanceMetrics.renderTimes;
        const avgRenderTime = renderTimes.length > 0 
            ? renderTimes.reduce((sum, time) => sum + time, 0) / renderTimes.length 
            : 0;
        
        return {
            totalCharts: this.performanceMetrics.chartCount,
            activeCharts: this.charts.size,
            averageRenderTime: avgRenderTime,
            totalRenders: renderTimes.length,
            memoryUsage: this.performanceMetrics.memoryUsage.slice(-1)[0] || null
        };
    }
    
    /**
     * Delay utility
     */
    _delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Create singleton instance
export const chartManager = new AnalyticsChartManager();
