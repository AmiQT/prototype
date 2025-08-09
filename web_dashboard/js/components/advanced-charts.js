import { chartManager } from '../utils/analytics-chart-manager.js';
import { ANALYTICS_CONFIG, CHART_TYPES } from '../config/analytics-config.js';

/**
 * Advanced chart components with interactive features
 */
export class AdvancedCharts {
    constructor() {
        this.chartInstances = new Map();
        this.interactionHandlers = new Map();
    }
    
    /**
     * Create a trend analysis chart with multiple time series
     */
    async createTrendChart(canvasId, data, options = {}) {
        const config = {
            type: CHART_TYPES.LINE,
            data: {
                labels: data.labels,
                datasets: data.datasets.map((dataset, index) => ({
                    label: dataset.label,
                    data: dataset.data,
                    borderColor: this.getColorByIndex(index),
                    backgroundColor: this.getColorByIndex(index, 0.1),
                    fill: options.fill || false,
                    tension: 0.4,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    borderWidth: 2
                }))
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    mode: 'index',
                    intersect: false
                },
                plugins: {
                    legend: {
                        position: 'top',
                        labels: {
                            usePointStyle: true,
                            padding: 20
                        }
                    },
                    tooltip: {
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        titleColor: 'white',
                        bodyColor: 'white',
                        borderColor: 'rgba(255, 255, 255, 0.1)',
                        borderWidth: 1,
                        callbacks: {
                            title: (context) => `Period: ${context[0].label}`,
                            label: (context) => `${context.dataset.label}: ${context.parsed.y.toLocaleString()}`
                        }
                    },
                    zoom: {
                        zoom: {
                            wheel: { enabled: true },
                            pinch: { enabled: true },
                            mode: 'x'
                        },
                        pan: {
                            enabled: true,
                            mode: 'x'
                        }
                    }
                },
                scales: {
                    x: {
                        display: true,
                        title: { display: true, text: options.xAxisLabel || 'Time Period' }
                    },
                    y: {
                        display: true,
                        title: { display: true, text: options.yAxisLabel || 'Count' },
                        beginAtZero: true
                    }
                }
            }
        };
        
        const chart = await chartManager.createChart(canvasId, config);
        this.chartInstances.set(canvasId, chart);
        this.setupChartInteractions(canvasId, chart);
        return chart;
    }
    
    /**
     * Create a comparative bar chart with drill-down capability
     */
    async createComparativeChart(canvasId, data, options = {}) {
        const config = {
            type: CHART_TYPES.BAR,
            data: {
                labels: data.labels,
                datasets: data.datasets.map((dataset, index) => ({
                    label: dataset.label,
                    data: dataset.data,
                    backgroundColor: this.getColorByIndex(index, 0.8),
                    borderColor: this.getColorByIndex(index),
                    borderWidth: 1,
                    hoverBackgroundColor: this.getColorByIndex(index, 0.9),
                    hoverBorderColor: this.getColorByIndex(index),
                    hoverBorderWidth: 2
                }))
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'top'
                    },
                    tooltip: {
                        callbacks: {
                            title: (context) => `Category: ${context[0].label}`,
                            label: (context) => {
                                const total = context.dataset.data.reduce((sum, val) => sum + val, 0);
                                const percentage = ((context.parsed.y / total) * 100).toFixed(1);
                                return `${context.dataset.label}: ${context.parsed.y} (${percentage}%)`;
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        title: { display: true, text: options.xAxisLabel || 'Categories' }
                    },
                    y: {
                        title: { display: true, text: options.yAxisLabel || 'Count' },
                        beginAtZero: true
                    }
                },
                onClick: (event, elements) => {
                    if (elements.length > 0 && options.onDrillDown) {
                        const element = elements[0];
                        const datasetIndex = element.datasetIndex;
                        const index = element.index;
                        const label = data.labels[index];
                        const value = data.datasets[datasetIndex].data[index];
                        
                        options.onDrillDown({
                            category: label,
                            value: value,
                            dataset: data.datasets[datasetIndex].label
                        });
                    }
                }
            }
        };
        
        const chart = await chartManager.createChart(canvasId, config);
        this.chartInstances.set(canvasId, chart);
        return chart;
    }
    
    /**
     * Create a heatmap-style chart for correlation analysis
     */
    async createHeatmapChart(canvasId, data, options = {}) {
        // Convert data to scatter plot format for heatmap effect
        const scatterData = [];
        
        data.matrix.forEach((row, y) => {
            row.forEach((value, x) => {
                scatterData.push({
                    x: x,
                    y: y,
                    v: value // value for color intensity
                });
            });
        });
        
        const config = {
            type: 'scatter',
            data: {
                datasets: [{
                    label: options.label || 'Correlation',
                    data: scatterData,
                    backgroundColor: (context) => {
                        const value = context.parsed.v;
                        const intensity = Math.abs(value);
                        const color = value >= 0 ? 'rgba(34, 197, 94' : 'rgba(239, 68, 68'; // green for positive, red for negative
                        return `${color}, ${intensity})`;
                    },
                    pointRadius: 15,
                    pointHoverRadius: 18
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            title: () => 'Correlation',
                            label: (context) => {
                                const xLabel = data.xLabels[context.parsed.x] || context.parsed.x;
                                const yLabel = data.yLabels[context.parsed.y] || context.parsed.y;
                                return `${xLabel} vs ${yLabel}: ${context.parsed.v.toFixed(3)}`;
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        type: 'linear',
                        position: 'bottom',
                        title: { display: true, text: options.xAxisLabel || 'X Axis' },
                        ticks: {
                            callback: (value) => data.xLabels[value] || value
                        }
                    },
                    y: {
                        type: 'linear',
                        title: { display: true, text: options.yAxisLabel || 'Y Axis' },
                        ticks: {
                            callback: (value) => data.yLabels[value] || value
                        }
                    }
                }
            }
        };
        
        const chart = await chartManager.createChart(canvasId, config);
        this.chartInstances.set(canvasId, chart);
        return chart;
    }
    
    /**
     * Create a multi-axis chart for different metrics
     */
    async createMultiAxisChart(canvasId, data, options = {}) {
        const config = {
            type: 'line',
            data: {
                labels: data.labels,
                datasets: data.datasets.map((dataset, index) => ({
                    label: dataset.label,
                    data: dataset.data,
                    borderColor: this.getColorByIndex(index),
                    backgroundColor: this.getColorByIndex(index, 0.1),
                    yAxisID: dataset.yAxisID || 'y',
                    tension: 0.4,
                    fill: false
                }))
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    mode: 'index',
                    intersect: false
                },
                plugins: {
                    legend: {
                        position: 'top'
                    }
                },
                scales: {
                    x: {
                        display: true,
                        title: { display: true, text: options.xAxisLabel || 'Time' }
                    },
                    y: {
                        type: 'linear',
                        display: true,
                        position: 'left',
                        title: { display: true, text: options.yAxisLabel || 'Primary Metric' }
                    },
                    y1: {
                        type: 'linear',
                        display: true,
                        position: 'right',
                        title: { display: true, text: options.y1AxisLabel || 'Secondary Metric' },
                        grid: {
                            drawOnChartArea: false
                        }
                    }
                }
            }
        };
        
        const chart = await chartManager.createChart(canvasId, config);
        this.chartInstances.set(canvasId, chart);
        return chart;
    }
    
    /**
     * Setup interactive features for charts
     */
    setupChartInteractions(canvasId, chart) {
        const canvas = document.getElementById(canvasId);
        if (!canvas) return;
        
        // Add export button
        this.addChartControls(canvasId);
        
        // Setup keyboard shortcuts
        canvas.addEventListener('keydown', (event) => {
            switch (event.key) {
                case 'r':
                    chart.resetZoom();
                    break;
                case 's':
                    this.exportChart(canvasId);
                    break;
            }
        });
        
        // Make canvas focusable for keyboard events
        canvas.setAttribute('tabindex', '0');
    }
    
    /**
     * Add control buttons to chart
     */
    addChartControls(canvasId) {
        const canvas = document.getElementById(canvasId);
        const container = canvas.parentElement;
        
        if (container.querySelector('.chart-controls')) return; // Already added
        
        const controls = document.createElement('div');
        controls.className = 'chart-controls';
        controls.innerHTML = `
            <button class="chart-control-btn" data-action="reset" title="Reset Zoom">
                <i class="fas fa-search-minus"></i>
            </button>
            <button class="chart-control-btn" data-action="export" title="Export Chart">
                <i class="fas fa-download"></i>
            </button>
            <button class="chart-control-btn" data-action="fullscreen" title="Fullscreen">
                <i class="fas fa-expand"></i>
            </button>
        `;
        
        container.appendChild(controls);
        
        // Setup control event listeners
        controls.addEventListener('click', (event) => {
            const action = event.target.closest('.chart-control-btn')?.dataset.action;
            if (!action) return;
            
            switch (action) {
                case 'reset':
                    this.resetChart(canvasId);
                    break;
                case 'export':
                    this.exportChart(canvasId);
                    break;
                case 'fullscreen':
                    this.toggleFullscreen(canvasId);
                    break;
            }
        });
    }
    
    /**
     * Get color by index for consistent theming
     */
    getColorByIndex(index, alpha = 1) {
        const colors = [
            ANALYTICS_CONFIG.CHART_COLORS.primary,
            ANALYTICS_CONFIG.CHART_COLORS.secondary,
            ANALYTICS_CONFIG.CHART_COLORS.accent,
            ANALYTICS_CONFIG.CHART_COLORS.warning,
            ANALYTICS_CONFIG.CHART_COLORS.info,
            ANALYTICS_CONFIG.CHART_COLORS.success
        ];
        
        const color = colors[index % colors.length];
        
        if (alpha < 1) {
            // Convert hex to rgba
            const hex = color.replace('#', '');
            const r = parseInt(hex.substr(0, 2), 16);
            const g = parseInt(hex.substr(2, 2), 16);
            const b = parseInt(hex.substr(4, 2), 16);
            return `rgba(${r}, ${g}, ${b}, ${alpha})`;
        }
        
        return color;
    }
    
    /**
     * Reset chart zoom/pan
     */
    resetChart(canvasId) {
        const chart = this.chartInstances.get(canvasId);
        if (chart && chart.resetZoom) {
            chart.resetZoom();
        }
    }
    
    /**
     * Export chart as image
     */
    exportChart(canvasId) {
        try {
            const imageUrl = chartManager.exportChart(canvasId);
            const link = document.createElement('a');
            link.download = `chart-${canvasId}-${Date.now()}.png`;
            link.href = imageUrl;
            link.click();
        } catch (error) {
            console.error('Error exporting chart:', error);
        }
    }
    
    /**
     * Toggle fullscreen mode for chart
     */
    toggleFullscreen(canvasId) {
        const canvas = document.getElementById(canvasId);
        const container = canvas.parentElement;
        
        if (container.classList.contains('fullscreen')) {
            container.classList.remove('fullscreen');
            document.exitFullscreen?.();
        } else {
            container.classList.add('fullscreen');
            container.requestFullscreen?.();
        }
    }
    
    /**
     * Destroy all chart instances
     */
    destroy() {
        this.chartInstances.clear();
        this.interactionHandlers.clear();
    }
}

// Create singleton instance
export const advancedCharts = new AdvancedCharts();
