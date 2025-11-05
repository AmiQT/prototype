"""
Feature Engineer

Calculate performance scores and risk indicators based on student features.
Uses weighted calculations to combine multiple metrics into risk predictions.
"""

from typing import Dict, List, Any
import logging
from .config import MLConfig

logger = logging.getLogger(__name__)


class FeatureEngineer:
    """
    Engineer features for ML prediction

    Combines processed features into meaningful indicators:
    - Performance scores
    - Risk factors
    - Strength areas
    - Trend analysis
    """

    @staticmethod
    def calculate_risk_score(features: Dict[str, Any]) -> float:
        """
        Calculate overall risk score (0-1)

        Combines multiple feature scores with configured weights.
        Higher score = higher risk of needing intervention.

        Args:
            features: Processed features dictionary

        Returns:
            Risk score 0-1
        """
        weights = MLConfig.FEATURE_WEIGHTS

        # Extract individual scores (these are already 0-1 normalized)
        academic_score = features.get("academic_score", 0.0)
        engagement_score = features.get("engagement_score", 0.0)
        activity_trend = features.get("activity_trend", 0.0)
        profile_completion = features.get("profile_completion", 0.0)
        social_score = features.get("social_score", 0.0)

        # Convert scores to risk (inverse of positive score)
        # High engagement = low risk
        academic_risk = 1.0 - academic_score
        engagement_risk = 1.0 - engagement_score
        activity_risk = 1.0 - activity_trend
        profile_risk = 1.0 - profile_completion
        social_risk = 1.0 - social_score

        # Calculate weighted risk
        total_risk = (
            (academic_risk * weights["academic_score"])
            + (engagement_risk * weights["engagement_score"])
            + (activity_risk * weights["activity_trend"])
            + (profile_risk * weights["profile_completion"])
            + (social_risk * weights["social_connection"])
        )

        risk_score = min(max(total_risk, 0.0), 1.0)
        logger.debug(
            f"Risk score for {features.get('student_id')}: {risk_score:.2f}"
        )
        return risk_score

    @staticmethod
    def get_risk_factors(features: Dict[str, Any]) -> List[str]:
        """
        Identify top risk factors for a student

        Analyzes features to identify areas of concern.

        Returns:
            List of risk factor descriptions
        """
        risk_factors = []

        # Academic risk
        if features.get("academic_score", 0) < 0.5:
            risk_factors.append(
                f"Low academic performance (Score: {features.get('academic_score', 0):.1%})"
            )

        # Engagement risk
        if features.get("engagement_score", 0) < 0.3:
            risk_factors.append(
                f"Low engagement (Only {features.get('events_attended', 0)} events attended)"
            )

        # Activity risk
        if features.get("days_since_activity", 999) > 14:
            risk_factors.append(
                f"Inactivity ({features.get('days_since_activity', 999)} days since last activity)"
            )

        # Profile risk
        if features.get("profile_completion", 0) < 0.5:
            risk_factors.append(
                f"Incomplete profile ({features.get('profile_completion', 0):.1%} complete)"
            )

        # Social isolation
        if features.get("social_score", 0) < 0.2:
            risk_factors.append(
                f"Limited social connections ({features.get('connections', 0)} connections)"
            )

        # Return top 3 factors
        return risk_factors[:3] if risk_factors else ["Monitoring recommended"]

    @staticmethod
    def get_strengths(features: Dict[str, Any]) -> List[str]:
        """
        Identify student strengths

        Returns:
            List of strength descriptions
        """
        strengths = []

        # Academic strength
        if features.get("academic_score", 0) > 0.75:
            strengths.append(
                f"Strong academic performance (CGPA: {features.get('cgpa', 0):.2f})"
            )

        # Engagement strength
        if features.get("engagement_score", 0) > 0.6:
            strengths.append(
                f"Good engagement ({features.get('events_attended', 0)} events attended)"
            )

        # Activity strength
        if features.get("days_since_activity", 999) < 7:
            strengths.append("Active participant")

        # Social strength
        if features.get("social_score", 0) > 0.6:
            strengths.append(
                f"Strong social connections ({features.get('connections', 0)} connections)"
            )

        # Profile strength
        if features.get("profile_completion", 0) > 0.8:
            strengths.append("Well-defined profile")

        # Return top 2 strengths
        return strengths[:2] if strengths else ["Potential for growth"]

    @staticmethod
    def get_recommendations(
        features: Dict[str, Any], risk_factors: List[str]
    ) -> List[str]:
        """
        Generate personalized recommendations

        Args:
            features: Student features
            risk_factors: Identified risk factors

        Returns:
            List of actionable recommendations
        """
        recommendations = []

        # Academic support
        if features.get("academic_score", 0) < 0.5:
            recommendations.append("Enroll in academic support program")

        # Engagement support
        if features.get("engagement_score", 0) < 0.3:
            recommendations.append(
                "Explore interest-based events and clubs to boost engagement"
            )

        # Activity boost
        if features.get("days_since_activity", 999) > 14:
            recommendations.append("Schedule regular campus activities and check-ins")

        # Profile completion
        if features.get("profile_completion", 0) < 0.5:
            recommendations.append("Complete profile to improve visibility and opportunities")

        # Social development
        if features.get("social_score", 0) < 0.3:
            recommendations.append("Join group activities to build social connections")

        # Return top 3 recommendations
        return recommendations[:3] if recommendations else ["Continue current activities"]

    @staticmethod
    def calculate_performance_metrics(features: Dict[str, Any]) -> Dict[str, Any]:
        """
        Calculate comprehensive performance metrics

        Returns:
            Dictionary with performance breakdown
        """
        return {
            "academic": {
                "score": features.get("academic_score", 0),
                "cgpa": features.get("cgpa", 0),
                "level": FeatureEngineer._get_performance_level(
                    features.get("academic_score", 0)
                ),
            },
            "engagement": {
                "score": features.get("engagement_score", 0),
                "events": features.get("events_attended", 0),
                "level": FeatureEngineer._get_performance_level(
                    features.get("engagement_score", 0)
                ),
            },
            "activity": {
                "trend": features.get("activity_trend", 0),
                "days_since": features.get("days_since_activity", 999),
                "level": "Active" if features.get("activity_trend", 0) > 0.6 else "Inactive",
            },
            "profile": {
                "completion": features.get("profile_completion", 0),
                "level": FeatureEngineer._get_performance_level(
                    features.get("profile_completion", 0)
                ),
            },
            "social": {
                "score": features.get("social_score", 0),
                "connections": features.get("connections", 0),
                "level": FeatureEngineer._get_performance_level(
                    features.get("social_score", 0)
                ),
            },
        }

    @staticmethod
    def _get_performance_level(score: float) -> str:
        """Convert score to performance level"""
        thresholds = MLConfig.PERFORMANCE_THRESHOLDS
        if score > thresholds["excellent"]:
            return "Excellent"
        elif score > thresholds["good"]:
            return "Good"
        elif score > thresholds["satisfactory"]:
            return "Satisfactory"
        else:
            return "Needs Improvement"

    @staticmethod
    def identify_trend(
        current_features: Dict[str, Any],
        previous_features: Dict[str, Any] = None,
    ) -> Dict[str, str]:
        """
        Identify trends in student performance

        Args:
            current_features: Current student metrics
            previous_features: Previous period metrics (optional)

        Returns:
            Trend analysis dictionary
        """
        trends = {}

        if previous_features:
            # Academic trend
            current_academic = current_features.get("academic_score", 0)
            previous_academic = previous_features.get("academic_score", 0)
            academic_change = current_academic - previous_academic

            if academic_change > 0.05:
                trends["academic"] = "📈 Improving"
            elif academic_change < -0.05:
                trends["academic"] = "📉 Declining"
            else:
                trends["academic"] = "➡️ Stable"

            # Engagement trend
            current_engagement = current_features.get("engagement_score", 0)
            previous_engagement = previous_features.get("engagement_score", 0)
            engagement_change = current_engagement - previous_engagement

            if engagement_change > 0.05:
                trends["engagement"] = "📈 Improving"
            elif engagement_change < -0.05:
                trends["engagement"] = "📉 Declining"
            else:
                trends["engagement"] = "➡️ Stable"
        else:
            # No previous data, show current status
            trends["academic"] = (
                "✅ Good" if current_features.get("academic_score", 0) > 0.5 else "⚠️ Needs attention"
            )
            trends["engagement"] = (
                "✅ Good" if current_features.get("engagement_score", 0) > 0.5 else "⚠️ Needs attention"
            )

        return trends

    @staticmethod
    def generate_summary(
        student_id: str,
        features: Dict[str, Any],
        risk_score: float,
        risk_factors: List[str],
        strengths: List[str],
        recommendations: List[str],
    ) -> Dict[str, Any]:
        """
        Generate complete ML analysis summary

        Returns:
            Comprehensive analysis dictionary
        """
        risk_level = MLConfig.get_risk_level(risk_score)
        emoji = MLConfig.get_risk_emoji(risk_level)

        return {
            "student_id": student_id,
            "risk_score": round(risk_score, 3),
            "risk_level": risk_level,
            "risk_emoji": emoji,
            "risk_factors": risk_factors,
            "strengths": strengths,
            "recommendations": recommendations,
            "performance_metrics": FeatureEngineer.calculate_performance_metrics(
                features
            ),
            "confidence": min(0.85, 0.7 + (features.get("profile_completion", 0) * 0.15)),
            "generated_at": "now",
        }
