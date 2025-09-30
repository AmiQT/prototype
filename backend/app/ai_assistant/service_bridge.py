"""Bridge helpers untuk interact dengan services/DB sedia ada."""

from __future__ import annotations

import logging
from typing import Any
from datetime import datetime
from sqlalchemy import func, text

from fastapi import Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.profile import Profile
from app.models.achievement import Achievement
from app.models.event import Event
# from app.models.showcase import ShowcasePost  # Skip - schema mismatch

logger = logging.getLogger(__name__)


class AssistantServiceBridge:
    """Helper untuk tindakan AI ke atas database & service lain."""

    def __init__(self, db: Session = Depends(get_db)) -> None:
        self.db = db

    # Example: real search (placeholder for now)
    def search_users(self, name_or_email: str, limit: int = 10) -> list[dict[str, Any]]:
        query = (self.db.query(User)
                 .outerjoin(Profile, Profile.userId == User.id)
                 .filter((User.name.ilike(f"%{name_or_email}%")) | (User.email.ilike(f"%{name_or_email}%")))
                 .limit(limit)
                 .all())

        results = []
        for user in query:
            results.append(
                {
                    "id": user.id,
                    "name": user.name,
                    "email": user.email,
                    "role": user.role.value,
                    "department": user.department,
                    "is_active": user.is_active,
                }
            )

        return results

    def get_system_stats(self) -> dict[str, Any]:
        """Get comprehensive system statistics."""
        try:
            # Test database connection first (with transaction pooler compatibility)  
            from sqlalchemy import text
            result = self.db.execute(text("SELECT 1")).scalar()
            logger.info(f"Database connection test successful: {result}")
            
            # Basic counts (use string values to match database exactly)
            total_students = self.db.query(User).filter(User.role == 'student').count()
            total_lecturers = self.db.query(User).filter(User.role == 'lecturer').count()  # Fix: 'lecturer' not 'staff'
            total_admins = self.db.query(User).filter(User.role == 'admin').count()
            total_users = self.db.query(User).count()
            
            # Profile stats - now with correct column name
            students_with_profiles = self.db.query(User).join(Profile, User.id == Profile.user_id)\
                                      .filter(User.role == 'student').count()
            
            # Activity stats - simplified to avoid schema issues
            total_achievements = 0  # Skip complex joins for now
            total_events = self.db.query(Event).count()
            total_showcases = 0  # Skip showcase count - model schema mismatch
            
            # Department distribution
            dept_stats = self.db.query(
                User.department,
                func.count(User.id).label('count')
            ).filter(
                User.role == 'student',
                User.department.isnot(None),
                User.department != ''
            ).group_by(User.department).all()
            
            return {
                "total_users": total_users,
                "user_breakdown": {
                    "students": total_students,
                    "lecturers": total_lecturers,  # Fixed: use correct variable name
                    "admins": total_admins
                },
                "profile_completion_rate": round((students_with_profiles / total_students * 100) if total_students > 0 else 0, 1),
                "activity_stats": {
                    "achievements": total_achievements,
                    "events": total_events,
                    "showcases": total_showcases
                },
                "department_distribution": {
                    dept: count for dept, count in dept_stats if dept
                }
            }
        except Exception as e:
            logger.error(f"Error getting system stats: {e}")
            return {
                "error": "Database connection failed",
                "details": str(e),
                "solution": "Check DATABASE_URL in .env file",
                "total_users": 0,
                "user_breakdown": {"students": 0, "lecturers": 0, "admins": 0},
                "profile_completion_rate": 0,
                "activity_stats": {"achievements": 0, "events": 0, "showcases": 0},
                "department_distribution": {}
            }

    def search_students_by_criteria(self, criteria: dict[str, Any]) -> list[dict[str, Any]]:
        """Search students based on various criteria."""
        try:
            query = self.db.query(User).filter(User.role == 'student')
            
            # Apply filters based on criteria
            if criteria.get("department"):
                query = query.filter(User.department.ilike(f"%{criteria['department']}%"))
            
            if criteria.get("name"):
                query = query.filter(User.name.ilike(f"%{criteria['name']}%"))
                
            if criteria.get("email"):
                query = query.filter(User.email.ilike(f"%{criteria['email']}%"))
            
            # Note: faculty, year_of_study, cgpa are in Profile.academic_info JSON
            # For now, skip JSON filtering in query (will filter in results)
            # This is simpler and works for moderate data sizes
            
            limit = criteria.get("limit", 20)
            students = query.limit(limit).all()
            
            results = []
            for user in students:
                # Get profile if exists  
                profile = self.db.query(Profile).filter(Profile.user_id == user.id).first()
                
                # Extract data from academic_info JSON
                academic_info = profile.academic_info if profile and profile.academic_info else {}
                faculty = academic_info.get('faculty') or academic_info.get('department')
                year_of_study = academic_info.get('year_of_study') or academic_info.get('year')
                cgpa = academic_info.get('cgpa') or academic_info.get('gpa')
                
                # Apply post-query filters if needed
                if criteria.get("faculty") and faculty:
                    if criteria["faculty"].lower() not in str(faculty).lower():
                        continue
                
                if criteria.get("year_of_study") and year_of_study:
                    if str(criteria["year_of_study"]) != str(year_of_study):
                        continue
                
                if criteria.get("cgpa_min") and cgpa:
                    try:
                        if float(cgpa) < float(criteria["cgpa_min"]):
                            continue
                    except (ValueError, TypeError):
                        pass
                
                # Get achievement count
                # Skip achievement count for now to avoid column issues
                achievement_count = 0  # TODO: Fix when Achievement model is confirmed
                
                results.append({
                    "id": user.id,
                    "name": user.name,
                    "email": user.email,
                    "department": user.department,
                    "student_id": user.student_id,
                    "full_name": profile.full_name if profile else user.name,
                    "faculty": faculty,
                    "year_of_study": year_of_study,
                    "cgpa": cgpa,
                    "achievement_count": achievement_count,
                    "is_active": user.is_active
                })
            
            return results
            
        except Exception as e:
            logger.error(f"Error searching students: {e}")
            return []

    def get_department_analytics(self, department: str = None) -> dict[str, Any]:
        """Get analytics for a specific department or all departments."""
        try:
            query = self.db.query(User).filter(User.role == 'student')
            
            if department:
                query = query.filter(User.department.ilike(f"%{department}%"))
            
            students = query.all()
            
            # Calculate metrics
            total_students = len(students)
            active_students = sum(1 for s in students if s.is_active)
            
            # Get profiles for completion rate
            profile_count = 0
            total_achievements = 0
            
            for student in students:
                profile = self.db.query(Profile).filter(Profile.user_id == student.id).first()
                if profile:
                    profile_count += 1
                
                # Skip achievement count for now to avoid column issues  
                achievements = 0  # TODO: Fix when Achievement model is confirmed
                total_achievements += achievements
            
            return {
                "department": department or "All Departments",
                "total_students": total_students,
                "active_students": active_students,
                "profile_completion_rate": round((profile_count / total_students * 100) if total_students > 0 else 0, 1),
                "total_achievements": total_achievements,
                "avg_achievements_per_student": round(total_achievements / total_students, 2) if total_students > 0 else 0
            }
            
        except Exception as e:
            logger.error(f"Error getting department analytics: {e}")
            return {"error": "Failed to retrieve department analytics"}

    def advanced_search(self, query_type: str, criteria: dict[str, Any]) -> dict[str, Any]:
        """Advanced agentic search across multiple tables."""
        try:
            results = {}
            
            if query_type == "students":
                # Search students with advanced criteria
                results = self._search_students_advanced(criteria)
            elif query_type == "events":
                # Search events with criteria  
                results = self._search_events_advanced(criteria)
            elif query_type == "cross_table":
                # Search across multiple tables
                results = self._search_cross_table(criteria)
            elif query_type == "analytics":
                # Analytical searches
                results = self._search_analytics(criteria)
            else:
                results = {"error": f"Unknown query type: {query_type}"}
                
            return {
                "query_type": query_type,
                "criteria": criteria,
                "results": results,
                "count": len(results) if isinstance(results, list) else results.get("count", 0),
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Advanced search error: {e}")
            return {
                "error": f"Search failed: {str(e)}",
                "query_type": query_type,
                "criteria": criteria
            }

    def _search_students_advanced(self, criteria: dict[str, Any]) -> list[dict[str, Any]]:
        """Search students with complex criteria."""
        query = self.db.query(User).filter(User.role == 'student')
        
        # Apply filters
        if criteria.get("department"):
            query = query.filter(User.department.ilike(f"%{criteria['department']}%"))
        if criteria.get("name"):
            query = query.filter(User.name.ilike(f"%{criteria['name']}%"))
        if criteria.get("email"):
            query = query.filter(User.email.ilike(f"%{criteria['email']}%"))
        if criteria.get("is_active") is not None:
            query = query.filter(User.is_active == criteria["is_active"])
        if criteria.get("profile_completed") is not None:
            query = query.filter(User.profile_completed == criteria["profile_completed"])
            
        students = query.limit(criteria.get("limit", 50)).all()
        
        results = []
        for student in students:
            profile = self.db.query(Profile).filter(Profile.user_id == student.id).first()
            results.append({
                "id": student.id,
                "name": student.name,
                "email": student.email,
                "department": student.department,
                "student_id": student.student_id,
                "is_active": student.is_active,
                "profile_completed": student.profile_completed,
                "created_at": student.created_at.isoformat() if student.created_at else None,
                "profile": {
                    "full_name": profile.full_name if profile else None,
                    "bio": profile.bio if profile else None,
                    "academic_info": profile.academic_info if profile else None,
                    "headline": profile.headline if profile else None,
                    "skills": profile.skills if profile else None,
                } if profile else None
            })
        
        return results

    def _search_events_advanced(self, criteria: dict[str, Any]) -> list[dict[str, Any]]:
        """Search events with complex criteria."""
        query = self.db.query(Event)
        
        # Apply filters
        if criteria.get("title"):
            query = query.filter(Event.title.ilike(f"%{criteria['title']}%"))
        if criteria.get("description"):
            query = query.filter(Event.description.ilike(f"%{criteria['description']}%"))
        if criteria.get("location"):
            query = query.filter(Event.location.ilike(f"%{criteria['location']}%"))
        if criteria.get("organizer_id"):
            query = query.filter(Event.organizer_id == criteria["organizer_id"])
        if criteria.get("is_active") is not None:
            query = query.filter(Event.is_active == criteria["is_active"])
        if criteria.get("date_from"):
            query = query.filter(Event.event_date >= criteria["date_from"])
        if criteria.get("date_to"):
            query = query.filter(Event.event_date <= criteria["date_to"])
            
        events = query.limit(criteria.get("limit", 50)).all()
        
        results = []
        for event in events:
            organizer = self.db.query(User).filter(User.id == event.organizer_id).first() if event.organizer_id else None
            results.append({
                "id": event.id,
                "title": event.title,
                "description": event.description,
                "event_date": event.event_date.isoformat() if event.event_date else None,
                "location": event.location,
                "is_active": event.is_active,
                "created_at": event.created_at.isoformat() if event.created_at else None,
                "organizer": {
                    "name": organizer.name if organizer else None,
                    "email": organizer.email if organizer else None,
                    "role": organizer.role if organizer else None
                } if organizer else None
            })
        
        return results

    def _search_cross_table(self, criteria: dict[str, Any]) -> dict[str, Any]:
        """Search across multiple tables for comprehensive results."""
        results = {}
        
        # Search students
        if criteria.get("include_students", True):
            student_criteria = {k: v for k, v in criteria.items() if k.startswith("student_")}
            student_criteria.update({k.replace("student_", ""): v for k, v in student_criteria.items()})
            results["students"] = self._search_students_advanced(student_criteria)
        
        # Search events  
        if criteria.get("include_events", True):
            event_criteria = {k: v for k, v in criteria.items() if k.startswith("event_")}
            event_criteria.update({k.replace("event_", ""): v for k, v in event_criteria.items()})
            results["events"] = self._search_events_advanced(event_criteria)
        
        # Cross-reference data
        if criteria.get("cross_reference"):
            results["cross_references"] = self._find_relationships(results)
            
        return results

    def _search_analytics(self, criteria: dict[str, Any]) -> dict[str, Any]:
        """Analytical search queries."""
        results = {}
        
        if criteria.get("type") == "department_performance":
            results = self._analyze_department_performance(criteria.get("department"))
        elif criteria.get("type") == "user_engagement":
            results = self._analyze_user_engagement(criteria)
        elif criteria.get("type") == "event_participation":
            results = self._analyze_event_participation(criteria)
        
        return results

    def _find_relationships(self, data: dict[str, Any]) -> list[dict[str, Any]]:
        """Find relationships between different data types."""
        relationships = []
        
        students = data.get("students", [])
        events = data.get("events", [])
        
        # Find students who organized events
        for student in students:
            organized_events = [e for e in events if e.get("organizer", {}).get("name") == student.get("name")]
            if organized_events:
                relationships.append({
                    "type": "student_organizer",
                    "student": student,
                    "organized_events": organized_events
                })
                
        return relationships

    def bulk_create_users(self, students: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Example stub untuk create users. Current: log sahaja."""

        logger.info("Pseudo bulk create called for %d students", len(students))
        # Future: integrate with Supabase/FastAPI user creation endpoint.
        return students

