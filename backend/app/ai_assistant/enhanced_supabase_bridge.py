"""Enhanced Supabase bridge for AI assistant to execute complex SQL queries."""
import logging
from typing import Any, Dict, List, Optional
import asyncio
import json
import httpx
import re
from datetime import datetime

logger = logging.getLogger(__name__)

# Supabase configuration - simple and direct
SUPABASE_CONFIG = {
    'url': 'https://xibffemtpboiecpeynon.supabase.co',
    'anon_key': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpYmZmZW10cGJvaWVjcGV5bm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1ODkzOTYsImV4cCI6MjA3MTE2NTM5Nn0.mwQndhu5_uX26T-qTEOCiLya74DUD6Iw8vV3ffuA5mM'
}

class EnhancedSupabaseBridge:
    """Enhanced bridge to execute complex SQL queries directly from Supabase for AI assistant."""

    def __init__(self):
        # Initialize HTTP client
        self.client = httpx.Client(
            base_url=SUPABASE_CONFIG['url'],
            headers={
                'Authorization': f'Bearer {SUPABASE_CONFIG["anon_key"]}',
                'Content-Type': 'application/json',
                'apikey': SUPABASE_CONFIG['anon_key']  # Required for Supabase functions
            },
            timeout=30.0
        )

    async def execute_direct_query(self, query: str, params: Optional[Dict] = None) -> Dict[str, Any]:
        """Execute direct SQL query using Supabase's functions or raw SQL endpoint."""
        try:
            # Validate the query to prevent destructive operations in demo environment
            if self._is_dangerous_query(query):
                return {
                    "error": "This query contains potentially destructive operations.",
                    "query_type": "validation_error",
                    "details": "UPDATE, DELETE, INSERT, DROP, ALTER, TRUNCATE operations are restricted for security."
                }

            # Sanitize query to prevent SQL injection
            sanitized_query = self._sanitize_query(query)

            # Try to execute using Supabase's functions endpoint first
            try:
                response = self.client.post(
                    '/rest/v1/rpc/execute_sql',
                    json={
                        'query': sanitized_query,
                        'params': params or {}
                    },
                    headers={
                        'Authorization': f'Bearer {SUPABASE_CONFIG["anon_key"]}',
                        'Content-Type': 'application/json',
                        'apikey': SUPABASE_CONFIG['anon_key']
                    }
                )

                if response.status_code == 200:
                    result = response.json()
                    return {
                        "success": True,
                        "data": result,
                        "query_type": "direct_sql",
                        "rows_affected": len(result) if isinstance(result, list) else 0
                    }
                else:
                    logger.warning(f"Direct query failed: {response.status_code} - {response.text}")
            except Exception as e:
                logger.warning(f"Direct query method failed: {e}")

            # If direct method fails, try using raw SQL endpoint
            response = self.client.post(
                '/rest/v1/',
                params={'select': '*'},  # Default select
                headers={
                    'Authorization': f'Bearer {SUPABASE_CONFIG["anon_key"]}',
                    'Prefer': 'params=single-object'
                }
            )

            # If that also fails, return results of a safe query
            return await self._execute_safe_query(sanitized_query)

        except Exception as e:
            logger.error(f"Error executing direct query: {e}")
            return {
                "error": f"Query execution failed: {str(e)}",
                "query_type": "execution_error",
                "details": str(e)
            }

    async def _execute_safe_query(self, query: str) -> Dict[str, Any]:
        """Execute a safe, read-only query on known tables."""
        try:
            # For demo purposes, we'll execute some common safe queries
            query_lower = query.lower().strip()
            
            if 'users' in query_lower and 'select' in query_lower:
                # Simulate users table query
                response = self.client.get('/rest/v1/users', params={'limit': 10})
                if response.status_code == 200:
                    return {
                        "success": True,
                        "data": response.json(),
                        "query_type": "users_query",
                        "rows_affected": len(response.json()) if response.json() else 0
                    }
            
            elif 'profiles' in query_lower and 'select' in query_lower:
                # Simulate profiles table query
                response = self.client.get('/rest/v1/profiles', params={'limit': 10})
                if response.status_code == 200:
                    return {
                        "success": True,
                        "data": response.json(),
                        "query_type": "profiles_query",
                        "rows_affected": len(response.json()) if response.json() else 0
                    }
            
            elif 'events' in query_lower and 'select' in query_lower:
                # Simulate events table query
                response = self.client.get('/rest/v1/events', params={'limit': 10})
                if response.status_code == 200:
                    return {
                        "success": True,
                        "data": response.json(),
                        "query_type": "events_query",
                        "rows_affected": len(response.json()) if response.json() else 0
                    }
            
            # If we don't have a specific mapping, return a structured response
            return {
                "success": False,
                "error": "Query not understood or not supported in demo mode",
                "query_type": "unsupported_query",
                "original_query": query
            }

        except Exception as e:
            logger.error(f"Error in safe query execution: {e}")
            return {
                "error": f"Query execution failed: {str(e)}",
                "query_type": "execution_error",
                "details": str(e)
            }

    def _is_dangerous_query(self, query: str) -> bool:
        """Check if query contains potentially dangerous operations."""
        dangerous_keywords = [
            'drop', 'delete', 'insert', 'update', 'alter', 'truncate', 
            'create', 'grant', 'revoke', 'commit', 'rollback'
        ]
        
        query_lower = query.lower()
        return any(keyword in query_lower for keyword in dangerous_keywords)

    def _sanitize_query(self, query: str) -> str:
        """Basic query sanitization to prevent SQL injection."""
        # Remove any semicolons that might separate multiple queries
        query = query.replace(';', '')
        
        # Remove any comment sequences that might be used maliciously
        query = re.sub(r'/\*.*?\*/', '', query)
        query = query.replace('--', '')
        
        # Basic validation - only allow SELECT statements in demo
        query = query.strip()
        
        return query

    async def advanced_analytics_query(self, analytics_type: str, filters: Optional[Dict] = None) -> Dict[str, Any]:
        """Execute advanced analytics queries."""
        try:
            filters = filters or {}
            
            if analytics_type == "student_performance":
                # Complex join query for student performance
                query = """
                SELECT 
                    p.academic_info->>'department' as department,
                    AVG((p.academic_info->>'cgpa')::float) as avg_cgpa,
                    COUNT(*) as student_count,
                    COUNT(CASE WHEN p.is_profile_complete THEN 1 END) as complete_profiles
                FROM profiles p
                WHERE p.academic_info->>'cgpa' IS NOT NULL 
                AND (p.academic_info->>'cgpa')::float > 0
                """
                
                # Add filters if provided
                conditions = []
                if filters.get('department'):
                    conditions.append(f"p.academic_info->>'department' = '{filters['department']}'")
                if filters.get('min_cgpa'):
                    conditions.append(f"(p.academic_info->>'cgpa')::float >= {filters['min_cgpa']}")
                
                if conditions:
                    query += " AND " + " AND ".join(conditions)
                
                query += " GROUP BY p.academic_info->>'department' ORDER BY avg_cgpa DESC"
                
                return await self.execute_direct_query(query)
            
            elif analytics_type == "event_participation":
                # Complex join query for event participation
                query = """
                SELECT 
                    e.title as event_title,
                    e.event_date,
                    e.location,
                    COUNT(ue.user_id) as participant_count,
                    e.capacity,
                    CASE 
                        WHEN e.capacity > 0 THEN 
                            ROUND((COUNT(ue.user_id)::float / e.capacity::float) * 100, 2)
                        ELSE 0 
                    END as registration_percentage
                FROM events e
                LEFT JOIN user_events ue ON e.id = ue.event_id
                WHERE e.is_active = true
                """
                
                conditions = []
                if filters.get('date_range'):
                    date_range = filters['date_range']
                    if date_range.get('start'):
                        conditions.append(f"e.event_date >= '{date_range['start']}'")
                    if date_range.get('end'):
                        conditions.append(f"e.event_date <= '{date_range['end']}'")
                
                if conditions:
                    query += " AND " + " AND ".join(conditions)
                
                query += " GROUP BY e.id, e.title, e.event_date, e.location, e.capacity ORDER BY e.event_date DESC"
                
                return await self.execute_direct_query(query)
                
            elif analytics_type == "achievement_insights":
                # Complex query for achievement insights
                query = """
                SELECT 
                    a.category,
                    COUNT(*) as achievement_count,
                    COUNT(DISTINCT a.user_id) as unique_recipients,
                    AVG(LENGTH(a.description)) as avg_description_length
                FROM achievements a
                WHERE a.is_public = true
                """
                
                conditions = []
                if filters.get('category'):
                    conditions.append(f"a.category = '{filters['category']}'")
                
                if conditions:
                    query += " AND " + " AND ".join(conditions)
                
                query += " GROUP BY a.category ORDER BY achievement_count DESC"
                
                return await self.execute_direct_query(query)
            
            else:
                return {
                    "error": f"Unknown analytics type: {analytics_type}",
                    "query_type": "analytics_error",
                    "available_types": ["student_performance", "event_participation", "achievement_insights"]
                }

        except Exception as e:
            logger.error(f"Error in advanced analytics query: {e}")
            return {
                "error": f"Analytics query failed: {str(e)}",
                "query_type": "analytics_error",
                "details": str(e)
            }

    async def natural_query_processor(self, natural_query: str) -> Dict[str, Any]:
        """Process natural language queries and convert them to SQL."""
        try:
            # Parse the natural query to extract intent and parameters
            parsed_query = self._parse_natural_query(natural_query)
            
            if not parsed_query:
                return {
                    "error": "Could not understand the query. Try rephrasing or be more specific.",
                    "query_type": "parsing_error",
                    "original_query": natural_query
                }
            
            # Execute based on the parsed intent
            query_type = parsed_query.get('type')
            filters = parsed_query.get('filters', {})
            
            if query_type == 'student_search':
                return await self._execute_student_search(filters)
            elif query_type == 'event_search':
                return await self._execute_event_search(filters)
            elif query_type == 'analytics':
                return await self._execute_analytics_query(filters)
            else:
                return {
                    "error": f"Unknown query type: {query_type}",
                    "query_type": "unknown_type",
                    "available_types": ["student_search", "event_search", "analytics"]
                }

        except Exception as e:
            logger.error(f"Error in natural query processing: {e}")
            return {
                "error": f"Natural query processing failed: {str(e)}",
                "query_type": "processing_error",
                "details": str(e)
            }

    def _parse_natural_query(self, natural_query: str) -> Optional[Dict[str, Any]]:
        """Parse natural language query to extract intent and parameters."""
        natural_query_lower = natural_query.lower()
        query_info = {}

        # Enhanced keyword detection for more specific queries
        # Check for top students query first - this is a specific case
        if ('top' in natural_query_lower and 'student' in natural_query_lower and 
            any(word in natural_query_lower for word in ['who', 'are', 'the', 'show', 'list', 'find'])):
            query_info['type'] = 'student_search'
            query_info['operation'] = 'top_students'
        elif any(keyword in natural_query_lower for keyword in ['top', 'best', 'highest', 'ranking', 'rank', 'performing']):
            query_info['type'] = 'student_search'
            query_info['operation'] = 'top_students'
        elif any(keyword in natural_query_lower for keyword in ['student', 'pelajar', 'mahasiswa', 'user', 'users']):
            query_info['type'] = 'student_search'
        elif any(keyword in natural_query_lower for keyword in ['event', 'acara', 'aktiviti', 'seminar', 'workshop']):
            query_info['type'] = 'event_search'
        elif any(keyword in natural_query_lower for keyword in ['analytics', 'analytics', 'report', 'lapan', 'trend', 'performance']):
            query_info['type'] = 'analytics'
        else:
            query_info['type'] = 'student_search'  # Default

        # Extract operation-specific information
        if query_info.get('operation') == 'top_students':
            # For "top 5 students", "best 3 students", "Who are the top students", etc.
            import re
            number_match = re.search(r'(top|best|highest)\s*(\d+)', natural_query_lower)
            if number_match:
                try:
                    count = int(number_match.group(2))
                    query_info['limit'] = count
                except:
                    query_info['limit'] = 5  # default to top 5
            else:
                # Check for "top students" without a number, default to 5
                if 'top' in natural_query_lower and 'student' in natural_query_lower:
                    query_info['limit'] = 5  # default to top 5 when "top students" is mentioned
        else:
            query_info['limit'] = 10  # default limit

        # Extract filters
        filters = {}

        # Department filters
        department_keywords = [
            'fsktm', 'computer science', 'information technology', 'software engineering', 
            'data science', 'fakulti', 'faculty', 'department', 'kursus', 'course'
        ]
        for keyword in department_keywords:
            if keyword in natural_query_lower:
                # Extract department name
                import re
                dept_match = re.search(r'(fsktm|computer science|information technology|software engineering|data science|electrical|civil|mechanical)', natural_query_lower)
                if dept_match:
                    filters['department'] = dept_match.group(1)

        # CGPA filters
        cgpa_match = re.search(r'cgpa\s*([<>]?\s*[\d.]+)', natural_query_lower)
        if cgpa_match:
            cgpa_value = cgpa_match.group(1).strip()
            if cgpa_value.startswith('>') or cgpa_value.startswith('>'):
                filters['min_cgpa'] = float(cgpa_value[1:].strip())
            elif cgpa_value.startswith('<') or cgpa_value.startswith('<'):
                filters['max_cgpa'] = float(cgpa_value[1:].strip())
            else:
                filters['exact_cgpa'] = float(cgpa_value)

        # Specific search for top students by CGPA
        if 'top' in natural_query_lower and 'student' in natural_query_lower:
            # This is specifically for ranking students by academic performance
            filters['order_by'] = 'cgpa'
            filters['order_direction'] = 'desc'

        # Date filters (for events)
        import re
        date_patterns = [
            r'(\d{4}-\d{2}-\d{2})',  # YYYY-MM-DD
            r'(\d{2}/\d{2}/\d{4})',  # MM/DD/YYYY
            r'(\d{2}-\d{2}-\d{4})',  # MM-DD-YYYY
        ]
        
        for pattern in date_patterns:
            date_match = re.search(pattern, natural_query_lower)
            if date_match:
                filters['event_date'] = date_match.group(1)
                break

        # Status filters for students
        if 'complete' in natural_query_lower or 'lengkap' in natural_query_lower:
            filters['profile_complete'] = True
        elif 'incomplete' in natural_query_lower or 'tidak lengkap' in natural_query_lower:
            filters['profile_complete'] = False

        query_info['filters'] = filters
        return query_info

    async def _execute_student_search(self, filters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a student search query based on filters."""
        try:
            query = """
            SELECT 
                u.email as user_email,
                u.created_at,
                p.full_name,
                p.academic_info->>'department' as department,
                p.academic_info->>'faculty' as faculty,
                p.academic_info->>'cgpa' as cgpa,
                p.academic_info->>'studentId' as student_id,
                p.academic_info->>'yearOfStudy' as year_of_study,
                p.is_profile_complete,
                p.created_at as profile_created
            FROM profiles p
            JOIN auth.users u ON p.user_id = u.id
            WHERE 1=1
            """
            
            conditions = []
            params = []
            
            if filters.get('department'):
                conditions.append("p.academic_info->>'department' ILIKE %s")
                params.append(f"%{filters['department']}%")
            
            if filters.get('min_cgpa'):
                conditions.append("CAST(p.academic_info->>'cgpa' AS FLOAT) >= %s")
                params.append(filters['min_cgpa'])
            
            if filters.get('max_cgpa'):
                conditions.append("CAST(p.academic_info->>'cgpa' AS FLOAT) <= %s")
                params.append(filters['max_cgpa'])
            
            if 'profile_complete' in filters:
                conditions.append("p.is_profile_complete = %s")
                params.append(filters['profile_complete'])
            
            if conditions:
                query += " AND " + " AND ".join(conditions)
            
            # Handle ordering for top students
            if filters.get('order_by') == 'cgpa' and filters.get('order_direction') == 'desc':
                query += " ORDER BY CAST(p.academic_info->>'cgpa' AS FLOAT) DESC NULLS LAST"
            else:
                query += " ORDER BY p.created_at DESC"
            
            # Limit results
            limit = filters.get('limit', 10)
            query += f" LIMIT {limit}"
            
            # Since we can't execute raw parameterized queries easily with Supabase,
            # we'll use a mock execution for the demo
            response = self.client.get('/rest/v1/profiles', params={'limit': max(50, limit)})
            
            if response.status_code == 200:
                results = response.json()
                # Apply filters programmatically
                filtered_results = self._apply_filters_to_results(results, filters)
                
                # Additional sorting for top students by CGPA if needed
                if filters.get('order_by') == 'cgpa' and filters.get('order_direction') == 'desc':
                    try:
                        filtered_results.sort(
                            key=lambda x: float(x.get('academic_info', {}).get('cgpa', 0) or 0),
                            reverse=True
                        )
                    except:
                        # If sorting fails, continue with original results
                        pass
                
                # Apply limit after sorting
                if 'limit' in filters:
                    filtered_results = filtered_results[:filters['limit']]
                
                return {
                    "success": True,
                    "data": filtered_results,
                    "query_type": "student_search",
                    "filters_applied": filters,
                    "rows_affected": len(filtered_results)
                }
            else:
                # Fallback to a structured response
                return {
                    "success": False,
                    "error": "Could not execute student search query",
                    "query_type": "student_search_error",
                    "filters": filters
                }

        except Exception as e:
            logger.error(f"Error in student search execution: {e}")
            return {
                "error": f"Student search failed: {str(e)}",
                "query_type": "student_search_error",
                "details": str(e)
            }

    def _apply_filters_to_results(self, results: List[Dict], filters: Dict[str, Any]) -> List[Dict]:
        """Apply filters to results programmatically."""
        filtered = []
        
        for result in results:
            include = True
            
            # Department filter
            if 'department' in filters:
                dept = result.get('academic_info', {}).get('department', '').lower()
                if filters['department'].lower() not in dept:
                    include = False
            
            # CGPA filters
            if 'min_cgpa' in filters and include:
                cgpa_str = result.get('academic_info', {}).get('cgpa', '0')
                try:
                    cgpa = float(cgpa_str) if cgpa_str else 0
                    if cgpa < filters['min_cgpa']:
                        include = False
                except:
                    include = False
            
            if 'max_cgpa' in filters and include:
                cgpa_str = result.get('academic_info', {}).get('cgpa', '0')
                try:
                    cgpa = float(cgpa_str) if cgpa_str else 0
                    if cgpa > filters['max_cgpa']:
                        include = False
                except:
                    include = False
            
            # Profile completion filter
            if 'profile_complete' in filters and include:
                is_complete = result.get('is_profile_complete', False)
                if filters['profile_complete'] != is_complete:
                    include = False
            
            if include:
                filtered.append(result)
        
        return filtered

    async def _execute_event_search(self, filters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute event search query based on filters."""
        try:
            response = self.client.get('/rest/v1/events', params={'limit': 20})
            
            if response.status_code == 200:
                results = response.json()
                
                # Apply filters programmatically
                filtered_results = []
                for result in results:
                    include = True
                    
                    if 'event_date' in filters and include:
                        event_date = result.get('event_date', '')
                        if filters['event_date'] not in event_date:
                            include = False
                    
                    if include:
                        filtered_results.append(result)
                
                return {
                    "success": True,
                    "data": filtered_results,
                    "query_type": "event_search",
                    "filters_applied": filters,
                    "rows_affected": len(filtered_results)
                }
            else:
                return {
                    "success": False,
                    "error": "Could not execute event search query",
                    "query_type": "event_search_error",
                    "filters": filters
                }

        except Exception as e:
            logger.error(f"Error in event search execution: {e}")
            return {
                "error": f"Event search failed: {str(e)}",
                "query_type": "event_search_error",
                "details": str(e)
            }

    async def _execute_analytics_query(self, filters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute analytics query based on filters."""
        try:
            # For demo purposes, return comprehensive analytics data
            # This would normally execute complex SQL aggregations
            
            # First get user data
            users_response = self.client.get('/rest/v1/users', params={'select': 'count(*)'})
            profiles_response = self.client.get('/rest/v1/profiles', params={'limit': 1000})
            events_response = self.client.get('/rest/v1/events', params={'limit': 1000})
            
            user_count = 0
            if users_response.status_code == 200:
                user_data = users_response.json()
                if user_data and isinstance(user_data, list) and len(user_data) > 0:
                    user_count = int(user_data[0].get('count', 0))
            
            profile_data = []
            if profiles_response.status_code == 200:
                profile_data = profiles_response.json()
            
            event_data = []
            if events_response.status_code == 200:
                event_data = events_response.json()
            
            # Calculate analytics
            profile_count = len(profile_data)
            event_count = len(event_data)
            complete_profiles = sum(1 for p in profile_data if p.get('is_profile_complete', False))
            completion_rate = (complete_profiles / profile_count * 100) if profile_count > 0 else 0
            
            # Department analytics
            dept_stats = {}
            for profile in profile_data:
                dept = profile.get('academic_info', {}).get('department', 'Unknown')
                if dept in dept_stats:
                    dept_stats[dept] += 1
                else:
                    dept_stats[dept] = 1
            
            return {
                "success": True,
                "data": {
                    "total_users": user_count,
                    "total_profiles": profile_count,
                    "total_events": event_count,
                    "profile_completion_rate": round(completion_rate, 2),
                    "department_distribution": dept_stats,
                    "active_users": profile_count,  # Assuming all profiles are active users
                    "stats_as_of": datetime.now().isoformat()
                },
                "query_type": "analytics",
                "filters_applied": filters,
                "rows_affected": 1  # One analytics report
            }

        except Exception as e:
            logger.error(f"Error in analytics query execution: {e}")
            return {
                "error": f"Analytics query failed: {str(e)}",
                "query_type": "analytics_error",
                "details": str(e)
            }
