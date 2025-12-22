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
- balance_analyzer: Academic-kokurikulum balance analysis
- ai_action_plan: AI-powered action plan generator

Example usage:
    from app.ml_analytics import MLAnalyticsService, BalanceAnalyzer
    
    # Risk prediction
    service = MLAnalyticsService()
    prediction = await service.predict_student_risk(student_id)
    
    # Balance analysis
    analyzer = BalanceAnalyzer()
    analysis = analyzer.analyze_student(student_data)
"""

from .config import MLConfig
from .predictor import MLPredictor
from .cache_manager import CacheManager
from .data_processor import DataProcessor
from .feature_engineer import FeatureEngineer
from .balance_analyzer import BalanceAnalyzer, BalanceMetrics, BalanceStatus
from .ai_action_plan import AIActionPlanGenerator

__all__ = [
    "MLConfig",
    "MLPredictor",
    "CacheManager",
    "DataProcessor",
    "FeatureEngineer",
    "BalanceAnalyzer",
    "BalanceMetrics",
    "BalanceStatus",
    "AIActionPlanGenerator",
]
