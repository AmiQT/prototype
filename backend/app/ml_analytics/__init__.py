"""
ML Analytics Module

Handles student risk prediction, engagement analysis, and performance scoring
using Google Gemini API for cloud-based machine learning.

Key components:
- config: ML settings and thresholds
- data_processor: Extract and normalize student data
- feature_engineer: Calculate performance scores and metrics
- predictor: Gemini API integration for predictions
- cache_manager: In-memory caching with TTL

Example usage:
    from app.ml_analytics import MLAnalyticsService
    service = MLAnalyticsService()
    prediction = await service.predict_student_risk(student_id)
"""

from .config import MLConfig
from .predictor import MLPredictor
from .cache_manager import CacheManager
from .data_processor import DataProcessor
from .feature_engineer import FeatureEngineer

__all__ = [
    "MLConfig",
    "MLPredictor",
    "CacheManager",
    "DataProcessor",
    "FeatureEngineer",
]
