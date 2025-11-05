"""
ML Analytics Router

FastAPI endpoints for ML analytics, student risk predictions, and cache management.
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
import logging
from datetime import timedelta

from app.ml_analytics import MLPredictor, CacheManager, MLConfig

logger = logging.getLogger(__name__)

# Initialize router
router = APIRouter(prefix="/api/ml", tags=["ML Analytics"])

# Initialize ML services
cache_manager = CacheManager(
    max_size=MLConfig.CACHE_MAX_SIZE,
    default_ttl=MLConfig.CACHE_TTL,
)
predictor = MLPredictor(cache_manager=cache_manager)


@router.get("/health")
async def health_check():
    """
    Check ML system health

    Returns:
        Health status including API configuration and cache stats
    """
    health = predictor.health_check()
    return {
        "status": health["status"],
        "gemini_api_configured": health["gemini_api_configured"],
        "model": health["model"],
        "cache": health["cache_status"],
        "message": "ML Analytics service is operational" if health["status"] == "healthy" else "ML service degraded",
    }


@router.post("/student/{student_id}/predict")
async def predict_student_risk(
    student_id: str,
    student_data: Optional[dict] = None,
):
    """
    Predict student risk

    Predicts student risk level based on their profile data.
    Results are cached for 24 hours to respect API rate limits.

    Args:
        student_id: Student ID
        student_data: Student data dictionary with features

    Returns:
        Risk prediction with factors, strengths, recommendations
    """
    try:
        if not student_data:
            student_data = {"id": student_id}

        prediction = await predictor.predict_student_risk(student_data)
        return prediction

    except Exception as e:
        logger.error(f"Error predicting risk for {student_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@router.get("/student/{student_id}/performance")
async def get_student_performance(
    student_id: str,
    student_data: Optional[dict] = None,
):
    """
    Get student performance analysis

    Provides detailed performance breakdown for a student.

    Args:
        student_id: Student ID
        student_data: Optional student data (if not in cache)

    Returns:
        Performance metrics including academic, engagement, activity, profile, social
    """
    try:
        # Check cache for prediction
        cached = cache_manager.get(f"prediction_{student_id}")

        if cached:
            return {
                "student_id": student_id,
                "performance_metrics": cached.get("performance_metrics"),
                "risk_level": cached.get("risk_level"),
                "risk_emoji": cached.get("risk_emoji"),
                "from_cache": True,
            }

        # If not cached, generate prediction
        if not student_data:
            student_data = {"id": student_id}

        prediction = await predictor.predict_student_risk(student_data)
        return {
            "student_id": student_id,
            "performance_metrics": prediction.get("performance_metrics"),
            "risk_level": prediction.get("risk_level"),
            "risk_emoji": prediction.get("risk_emoji"),
            "from_cache": False,
        }

    except Exception as e:
        logger.error(f"Error getting performance for {student_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/cache/invalidate")
async def invalidate_cache(
    student_id: Optional[str] = Query(None),
):
    """
    Invalidate cache

    Clears cached predictions to force fresh analysis.
    Admin endpoint - should be protected.

    Args:
        student_id: Specific student to invalidate, or None for all

    Returns:
        Confirmation message
    """
    try:
        predictor.invalidate_cache(student_id)

        if student_id:
            return {
                "status": "success",
                "message": f"Cache invalidated for student {student_id}",
            }
        else:
            return {
                "status": "success",
                "message": "All cache invalidated",
            }

    except Exception as e:
        logger.error(f"Error invalidating cache: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_ml_stats():
    """
    Get ML system statistics

    Returns cache hit rates, prediction counts, and system performance.

    Returns:
        System statistics
    """
    try:
        cache_stats = predictor.get_cache_stats()

        return {
            "cache": cache_stats,
            "configuration": {
                "model": MLConfig.GEMINI_MODEL,
                "cache_ttl_hours": MLConfig.CACHE_TTL.total_seconds() / 3600,
                "cache_max_size": MLConfig.CACHE_MAX_SIZE,
                "batch_size": MLConfig.BATCH_PROCESS_SIZE,
            },
            "gemini_api_configured": bool(MLConfig.GEMINI_API_KEY),
        }

    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch/predict")
async def batch_predict(body: dict = None):
    """
    Batch predict risk for multiple students

    Args:
        body: Request body with student_ids list
              Example: {"student_ids": ["CD21110001", "CD21110002"]}

    Returns:
        List of predictions
    """
    try:
        if body is None:
            raise HTTPException(status_code=400, detail="Request body required")

        # Get student IDs from request
        student_ids = body.get("student_ids", [])

        if not student_ids:
            raise HTTPException(status_code=400, detail="student_ids list required")

        logger.info(f"Starting batch prediction for {len(student_ids)} students")
        
        # Create minimal student data from IDs for prediction
        # Use 'id' field name to match data processor expectations
        students_data = [
            {"id": sid}
            for sid in student_ids
        ]
        
        predictions = await predictor.batch_predict(students_data)

        return {
            "status": "success",
            "total": len(student_ids),
            "predicted": len(predictions),
            "results": predictions,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in batch prediction: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recommendations/{risk_level}")
async def get_recommendations_by_risk(risk_level: str):
    """
    Get generic recommendations for a risk level

    Args:
        risk_level: 'low', 'medium', or 'high'

    Returns:
        Recommendations for the risk level
    """
    if risk_level not in ["low", "medium", "high"]:
        raise HTTPException(
            status_code=400,
            detail="risk_level must be 'low', 'medium', or 'high'",
        )

    recommendations = {
        "low": {
            "emoji": "🟢",
            "actions": [
                "Monitor regularly",
                "Encourage continued engagement",
                "Celebrate achievements",
            ],
        },
        "medium": {
            "emoji": "🟡",
            "actions": [
                "Reach out this week",
                "Understand concerns",
                "Offer relevant support",
                "Schedule follow-up",
            ],
        },
        "high": {
            "emoji": "🔴",
            "actions": [
                "Contact immediately",
                "Assess situation",
                "Develop intervention plan",
                "Involve counselor/advisor",
                "Weekly follow-ups",
            ],
        },
    }

    return {
        "risk_level": risk_level,
        "emoji": recommendations[risk_level]["emoji"],
        "recommended_actions": recommendations[risk_level]["actions"],
    }
