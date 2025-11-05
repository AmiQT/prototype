import { BACKEND_CONFIG, getAuthHeaders } from '../config/backend-config.js';

/**
 * ML Analytics Service
 * Integrates ML prediction and analytics from backend
 */
class MLAnalyticsService {
  constructor() {
    // Use localhost:8000 by default in development
    const baseUrl = BACKEND_CONFIG.baseUrl || 'http://localhost:8000';
    this.baseUrl = `${baseUrl}/api/ml`;
    this.cache = new Map();
    this.cacheTimeout = 24 * 60 * 60 * 1000; // 24 hours
  }

  /**
   * Check if ML Analytics service is healthy
   */
  async checkHealth() {
    try {
      const headers = typeof getAuthHeaders === 'function' ? await getAuthHeaders() : { 'Content-Type': 'application/json' };
      const response = await fetch(`${this.baseUrl}/health`, {
        method: 'GET',
        headers: headers
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      return {
        success: true,
        status: data.status,
        model: data.model,
        cache: data.cache,
        message: data.message
      };
    } catch (error) {
      console.error('ML Health check failed:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get risk prediction for a student
   * @param {string} studentId - Student ID
   * @returns {Object} Prediction result with risk score, factors, recommendations
   */
  async predictStudentRisk(studentId) {
    try {
      // Check cache first
      const cached = this.getFromCache(`predict_${studentId}`);
      if (cached) {
        console.log(`Cache hit for student ${studentId}`);
        return {
          success: true,
          data: cached
        };
      }

      const headers = typeof getAuthHeaders === 'function' ? await getAuthHeaders() : { 'Content-Type': 'application/json' };
      const response = await fetch(
        `${this.baseUrl}/student/${studentId}/predict`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...headers
          },
          body: JSON.stringify({})
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      // Cache the result
      this.saveToCache(`predict_${studentId}`, data);
      
      return {
        success: true,
        data: data
      };
    } catch (error) {
      console.error(`Risk prediction failed for ${studentId}:`, error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get detailed performance breakdown for a student
   * @param {string} studentId - Student ID
   * @returns {Object} Performance metrics breakdown
   */
  async getPerformanceBreakdown(studentId) {
    try {
      // Check cache first
      const cached = this.getFromCache(`performance_${studentId}`);
      if (cached) {
        console.log(`Cache hit for performance ${studentId}`);
        return {
          success: true,
          data: cached
        };
      }

      const headers = typeof getAuthHeaders === 'function' ? await getAuthHeaders() : { 'Content-Type': 'application/json' };
      const response = await fetch(
        `${this.baseUrl}/student/${studentId}/performance`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            ...headers
          }
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      // Cache the result
      this.saveToCache(`performance_${studentId}`, data);
      
      return {
        success: true,
        data: data
      };
    } catch (error) {
      console.error(`Performance breakdown failed for ${studentId}:`, error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get action recommendations based on risk level
   * @param {string} riskLevel - Risk level (low, medium, high)
   * @returns {Array} Array of recommended actions
   */
  async getRecommendations(riskLevel = 'high') {
    try {
      const headers = typeof getAuthHeaders === 'function' ? await getAuthHeaders() : { 'Content-Type': 'application/json' };
      const response = await fetch(
        `${this.baseUrl}/recommendations/${riskLevel}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            ...headers
          }
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      return {
        success: true,
        data: data
      };
    } catch (error) {
      console.error(`Failed to get recommendations for level ${riskLevel}:`, error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Batch predict for multiple students
   * @param {Array} studentIds - Array of student IDs
   * @returns {Array} Prediction results for all students
   */
  async batchPredict(studentIds) {
    try {
      const headers = typeof getAuthHeaders === 'function' ? await getAuthHeaders() : { 'Content-Type': 'application/json' };
      const response = await fetch(
        `${this.baseUrl}/batch/predict`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...headers
          },
          body: JSON.stringify({
            student_ids: studentIds
          })
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      return {
        success: true,
        data: data
      };
    } catch (error) {
      console.error('Batch prediction failed:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Format risk score for display
   * @param {number} score - Risk score (0-1)
   * @returns {Object} Formatted display info
   */
  formatRiskScore(score) {
    if (score >= 0.8) {
      return {
        level: 'HIGH',
        color: 'danger',
        bgClass: 'bg-danger',
        icon: '🔴'
      };
    } else if (score >= 0.5) {
      return {
        level: 'MEDIUM',
        color: 'warning',
        bgClass: 'bg-warning',
        icon: '🟡'
      };
    } else {
      return {
        level: 'LOW',
        color: 'success',
        bgClass: 'bg-success',
        icon: '🟢'
      };
    }
  }

  /**
   * Cache management
   */
  saveToCache(key, data) {
    this.cache.set(key, {
      data: data,
      timestamp: Date.now()
    });
  }

  getFromCache(key) {
    const cached = this.cache.get(key);
    if (!cached) return null;
    
    // Check if cache is expired
    if (Date.now() - cached.timestamp > this.cacheTimeout) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }

  clearCache() {
    this.cache.clear();
  }

  invalidateStudentCache(studentId) {
    this.cache.delete(`predict_${studentId}`);
    this.cache.delete(`performance_${studentId}`);
  }
}

// Export singleton instance
export const mlAnalyticsService = new MLAnalyticsService();
