import { TIME_PERIODS } from '../config/analytics-config.js';

/**
 * Advanced date range picker for analytics filtering
 */
export class DateRangePicker {
    constructor(containerId, options = {}) {
        this.container = document.getElementById(containerId);
        this.options = {
            defaultPeriod: TIME_PERIODS.LAST_30_DAYS,
            showPresets: true,
            showCustomRange: true,
            onRangeChange: null,
            ...options
        };
        
        this.currentRange = null;
        this.init();
    }
    
    init() {
        if (!this.container) {
            console.error('DateRangePicker: Container not found');
            return;
        }
        
        this.render();
        this.setupEventListeners();
        this.setDefaultRange();
    }
    
    render() {
        this.container.innerHTML = `
            <div class="date-range-picker">
                <div class="date-range-header">
                    <h4>Date Range</h4>
                    <button class="btn-reset" title="Reset to default">
                        <i class="fas fa-refresh"></i>
                    </button>
                </div>
                
                ${this.options.showPresets ? this.renderPresets() : ''}
                
                ${this.options.showCustomRange ? this.renderCustomRange() : ''}
                
                <div class="date-range-actions">
                    <button class="btn btn-primary btn-apply">Apply</button>
                    <button class="btn btn-secondary btn-cancel">Cancel</button>
                </div>
                
                <div class="current-range">
                    <small>Current: <span class="range-display">Last 30 Days</span></small>
                </div>
            </div>
        `;
    }
    
    renderPresets() {
        const presets = Object.entries(TIME_PERIODS).map(([key, period]) => {
            return `
                <button class="preset-btn" data-period="${key}">
                    ${period.label}
                </button>
            `;
        }).join('');
        
        return `
            <div class="date-presets">
                <label>Quick Select:</label>
                <div class="preset-buttons">
                    ${presets}
                </div>
            </div>
        `;
    }
    
    renderCustomRange() {
        return `
            <div class="custom-range">
                <label>Custom Range:</label>
                <div class="date-inputs">
                    <div class="input-group">
                        <label for="start-date">From:</label>
                        <input type="date" id="start-date" class="date-input">
                    </div>
                    <div class="input-group">
                        <label for="end-date">To:</label>
                        <input type="date" id="end-date" class="date-input">
                    </div>
                </div>
            </div>
        `;
    }
    
    setupEventListeners() {
        // Preset buttons
        this.container.querySelectorAll('.preset-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.selectPreset(e.target.dataset.period);
            });
        });
        
        // Custom date inputs
        const startDate = this.container.querySelector('#start-date');
        const endDate = this.container.querySelector('#end-date');
        
        if (startDate && endDate) {
            startDate.addEventListener('change', () => this.validateCustomRange());
            endDate.addEventListener('change', () => this.validateCustomRange());
        }
        
        // Action buttons
        const applyBtn = this.container.querySelector('.btn-apply');
        const cancelBtn = this.container.querySelector('.btn-cancel');
        const resetBtn = this.container.querySelector('.btn-reset');
        
        if (applyBtn) {
            applyBtn.addEventListener('click', () => this.applyRange());
        }
        
        if (cancelBtn) {
            cancelBtn.addEventListener('click', () => this.cancelChanges());
        }
        
        if (resetBtn) {
            resetBtn.addEventListener('click', () => this.resetToDefault());
        }
    }
    
    selectPreset(periodKey) {
        // Clear active states
        this.container.querySelectorAll('.preset-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        
        // Set active state
        const selectedBtn = this.container.querySelector(`[data-period="${periodKey}"]`);
        if (selectedBtn) {
            selectedBtn.classList.add('active');
        }
        
        // Calculate date range
        const period = TIME_PERIODS[periodKey];
        if (period.days) {
            const endDate = new Date();
            const startDate = new Date();
            startDate.setDate(endDate.getDate() - period.days);
            
            this.currentRange = {
                start: startDate,
                end: endDate,
                label: period.label,
                type: 'preset'
            };
        } else {
            // Custom range
            this.currentRange = {
                start: null,
                end: null,
                label: period.label,
                type: 'custom'
            };
        }
        
        this.updateDisplay();
        this.clearCustomInputs();
    }
    
    validateCustomRange() {
        const startInput = this.container.querySelector('#start-date');
        const endInput = this.container.querySelector('#end-date');
        
        if (!startInput || !endInput) return;
        
        const startDate = new Date(startInput.value);
        const endDate = new Date(endInput.value);
        
        if (startInput.value && endInput.value) {
            if (startDate > endDate) {
                this.showError('Start date cannot be after end date');
                return false;
            }
            
            if (startDate > new Date()) {
                this.showError('Start date cannot be in the future');
                return false;
            }
            
            // Clear active preset
            this.container.querySelectorAll('.preset-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            
            this.currentRange = {
                start: startDate,
                end: endDate,
                label: `${startDate.toLocaleDateString()} - ${endDate.toLocaleDateString()}`,
                type: 'custom'
            };
            
            this.updateDisplay();
            this.clearError();
            return true;
        }
        
        return false;
    }
    
    applyRange() {
        if (!this.currentRange) {
            this.showError('Please select a date range');
            return;
        }
        
        if (this.currentRange.type === 'custom' && (!this.currentRange.start || !this.currentRange.end)) {
            this.showError('Please select both start and end dates');
            return;
        }
        
        if (this.options.onRangeChange) {
            this.options.onRangeChange(this.currentRange);
        }
        
        this.clearError();
        
        // Emit custom event
        const event = new CustomEvent('dateRangeApplied', {
            detail: this.currentRange
        });
        this.container.dispatchEvent(event);
    }
    
    cancelChanges() {
        this.setDefaultRange();
        this.clearError();
    }
    
    resetToDefault() {
        this.setDefaultRange();
        this.clearError();
    }
    
    setDefaultRange() {
        const defaultKey = Object.keys(TIME_PERIODS).find(key => 
            TIME_PERIODS[key] === this.options.defaultPeriod
        );
        
        if (defaultKey) {
            this.selectPreset(defaultKey);
        }
    }
    
    updateDisplay() {
        const display = this.container.querySelector('.range-display');
        if (display && this.currentRange) {
            display.textContent = this.currentRange.label;
        }
    }
    
    clearCustomInputs() {
        const startInput = this.container.querySelector('#start-date');
        const endInput = this.container.querySelector('#end-date');
        
        if (startInput) startInput.value = '';
        if (endInput) endInput.value = '';
    }
    
    showError(message) {
        this.clearError();
        
        const errorDiv = document.createElement('div');
        errorDiv.className = 'date-range-error';
        errorDiv.innerHTML = `<i class="fas fa-exclamation-triangle"></i> ${message}`;
        
        this.container.appendChild(errorDiv);
    }
    
    clearError() {
        const error = this.container.querySelector('.date-range-error');
        if (error) {
            error.remove();
        }
    }
    
    getCurrentRange() {
        return this.currentRange;
    }
    
    setRange(startDate, endDate, label = null) {
        this.currentRange = {
            start: new Date(startDate),
            end: new Date(endDate),
            label: label || `${new Date(startDate).toLocaleDateString()} - ${new Date(endDate).toLocaleDateString()}`,
            type: 'programmatic'
        };
        
        this.updateDisplay();
        
        // Update custom inputs
        const startInput = this.container.querySelector('#start-date');
        const endInput = this.container.querySelector('#end-date');
        
        if (startInput) startInput.value = new Date(startDate).toISOString().split('T')[0];
        if (endInput) endInput.value = new Date(endDate).toISOString().split('T')[0];
    }
    
    destroy() {
        if (this.container) {
            this.container.innerHTML = '';
        }
    }
}
