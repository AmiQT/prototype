import { mlAnalyticsService } from '../services/MLAnalyticsService.js';

/**
 * ML Risk Card Component
 * Displays student risk prediction and recommendations
 */
export class MLRiskCard {
  constructor(containerId, studentId) {
    this.container = document.getElementById(containerId);
    this.studentId = studentId;
    this.prediction = null;
    this.isLoading = false;
    
    if (!this.container) {
      console.error(`MLRiskCard: Container ${containerId} not found`);
      return;
    }
    
    this.init();
  }

  async init() {
    this.showLoading();
    await this.loadPrediction();
  }

  showLoading() {
    this.container.innerHTML = `
      <div class="ml-risk-card loading">
        <div class="spinner-border text-primary" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
        <p>Analyzing student profile...</p>
      </div>
    `;
  }

  async loadPrediction() {
    try {
      this.isLoading = true;
      const result = await mlAnalyticsService.predictStudentRisk(this.studentId);
      
      if (result.success) {
        this.prediction = result.data;
        this.render();
      } else {
        const errorMsg = result.error || 'Unknown error occurred';
        this.showError(`Failed to load prediction: ${errorMsg}`);
      }
    } catch (error) {
      console.error('Error loading prediction:', error);
      this.showError(`Error loading student analysis: ${error.message}`);
    } finally {
      this.isLoading = false;
    }
  }

  render() {
    if (!this.prediction) return;

    const riskFormat = mlAnalyticsService.formatRiskScore(this.prediction.risk_score);
    const riskPercentage = Math.round(this.prediction.risk_score * 100);

    this.container.innerHTML = `
      <div class="ml-risk-card">
        <!-- Header with Risk Level -->
        <div class="risk-header ${riskFormat.bgClass}">
          <div class="risk-badge">
            <span class="risk-emoji">${this.prediction.risk_emoji || riskFormat.icon}</span>
            <span class="risk-level">${this.prediction.risk_level.toUpperCase()}</span>
          </div>
          <div class="risk-score">
            <span class="score-number">${riskPercentage}%</span>
            <small>Risk Score</small>
          </div>
        </div>

        <!-- Risk Factors -->
        <div class="risk-section">
          <h5><i class="fas fa-exclamation-circle"></i> Risk Factors</h5>
          <ul class="risk-factors-list">
            ${this.prediction.risk_factors.map(factor => `
              <li>${factor}</li>
            `).join('')}
          </ul>
        </div>

        <!-- Strengths -->
        ${this.prediction.strengths && this.prediction.strengths.length > 0 ? `
          <div class="risk-section">
            <h5><i class="fas fa-star"></i> Strengths</h5>
            <ul class="strengths-list">
              ${this.prediction.strengths.map(strength => `
                <li>${strength}</li>
              `).join('')}
            </ul>
          </div>
        ` : ''}

        <!-- Recommendations -->
        <div class="risk-section">
          <h5><i class="fas fa-lightbulb"></i> Recommendations</h5>
          <ul class="recommendations-list">
            ${this.prediction.recommendations.map(rec => `
              <li>${rec}</li>
            `).join('')}
          </ul>
        </div>

        <!-- Gemini AI Insights (if available) -->
        ${this.prediction.gemini_insights ? `
          <div class="risk-section gemini-insights">
            <h5><i class="fas fa-brain"></i> AI Analysis</h5>
            <div class="ai-insights-content">
              <p><strong>Confidence:</strong> ${Math.round(this.prediction.gemini_insights.confidence * 100)}%</p>
              <div class="ai-recommendations">
                ${this.prediction.gemini_insights.recommendations.map((rec, idx) => `
                  <div class="ai-rec-item">
                    <strong>Action ${idx + 1}:</strong>
                    <p>${rec}</p>
                  </div>
                `).join('')}
              </div>
            </div>
          </div>
        ` : ''}

        <!-- Performance Metrics -->
        ${this.prediction.performance_metrics ? `
          <div class="risk-section">
            <h5><i class="fas fa-chart-bar"></i> Performance Breakdown</h5>
            <div class="performance-grid">
              ${Object.entries(this.prediction.performance_metrics).map(([key, metric]) => `
                <div class="performance-item">
                  <small>${this.formatLabel(key)}</small>
                  <div class="metric-bar">
                    <div class="metric-fill" style="width: ${Math.min(metric.score * 100, 100)}%"></div>
                  </div>
                  <small class="metric-status ${this.getMetricClass(metric.level)}">${metric.level}</small>
                </div>
              `).join('')}
            </div>
          </div>
        ` : ''}

        <!-- Action Buttons -->
        <div class="risk-actions">
          <button class="btn btn-sm btn-primary refresh-btn">
            <i class="fas fa-sync"></i> Refresh Analysis
          </button>
          <button class="btn btn-sm btn-info details-btn">
            <i class="fas fa-chevron-down"></i> Show More
          </button>
        </div>

        <!-- Detailed Info (Hidden by default) -->
        <div class="detailed-info" style="display: none; padding: 20px; background: #f8f9fa; border-top: 1px solid #dee2e6;">
          ${this.prediction.gemini_insights ? `
            <h6><i class="fas fa-brain text-primary"></i> Full AI Analysis</h6>
            <div class="mb-3">
              <strong>AI Risk Factors:</strong>
              <ul class="mt-2">
                ${this.prediction.gemini_insights.risk_factors.map(f => `<li>${f}</li>`).join('')}
              </ul>
            </div>
            <div class="mb-3">
              <strong>AI Strengths:</strong>
              <ul class="mt-2">
                ${this.prediction.gemini_insights.strengths.map(s => `<li>${s}</li>`).join('')}
              </ul>
            </div>
            <div>
              <strong>Full AI Recommendations:</strong>
              <ol class="mt-2">
                ${this.prediction.gemini_insights.recommendations.map(r => `<li>${r}</li>`).join('')}
              </ol>
            </div>
          ` : '<p class="text-muted">No additional details available</p>'}
        </div>
      </div>
    `;

    this.setupEventListeners();
  }

  setupEventListeners() {
    const refreshBtn = this.container.querySelector('.refresh-btn');
    const detailsBtn = this.container.querySelector('.details-btn');

    if (refreshBtn) {
      refreshBtn.addEventListener('click', () => {
        // Clear cache and reload
        mlAnalyticsService.invalidateStudentCache(this.studentId);
        this.loadPrediction();
      });
    }

    if (detailsBtn) {
      detailsBtn.addEventListener('click', () => {
        // Toggle details visibility instead of modal
        const detailsSection = this.container.querySelector('.detailed-info');
        if (detailsSection) {
          detailsSection.style.display = detailsSection.style.display === 'none' ? 'block' : 'none';
          detailsBtn.innerHTML = detailsSection.style.display === 'none' 
            ? '<i class="fas fa-chevron-down"></i> Show More' 
            : '<i class="fas fa-chevron-up"></i> Show Less';
        }
      });
    }
  }

  showError(message) {
    this.container.innerHTML = `
      <div class="ml-risk-card error">
        <div class="alert alert-danger">
          <i class="fas fa-times-circle"></i> ${message}
        </div>
        <button class="btn btn-sm btn-primary retry-btn">
          <i class="fas fa-redo"></i> Retry
        </button>
      </div>
    `;

    const retryBtn = this.container.querySelector('.retry-btn');
    if (retryBtn) {
      retryBtn.addEventListener('click', () => this.init());
    }
  }

  formatLabel(key) {
    return key.split('_')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  getMetricClass(level) {
    switch(level) {
      case 'Excellent': return 'text-success';
      case 'Good': return 'text-info';
      case 'Needs Improvement': return 'text-warning';
      case 'Inactive': return 'text-danger';
      default: return 'text-secondary';
    }
  }

  refresh() {
    this.loadPrediction();
  }
}
