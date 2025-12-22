"""
AI Action Plan Generator

Uses Gemini AI to generate personalized action plans for students
based on their academic-kokurikulum balance analysis.
"""

from typing import Dict, Any, List, Optional
import google.generativeai as genai
import logging
import json
import os

from .config import MLConfig
from .balance_analyzer import BalanceAnalyzer, BalanceMetrics, BalanceStatus

logger = logging.getLogger(__name__)


class AIActionPlanGenerator:
    """
    Generates personalized action plans using Gemini AI.
    
    Combines rule-based analysis with AI-generated recommendations
    for more contextual and personalized student guidance.
    """
    
    def __init__(self):
        self.config = MLConfig
        self.balance_analyzer = BalanceAnalyzer()
        self._init_gemini()
    
    def _init_gemini(self):
        """Initialize Gemini API."""
        if self.config.GEMINI_API_KEY:
            genai.configure(api_key=self.config.GEMINI_API_KEY)
            self.model = genai.GenerativeModel(self.config.GEMINI_MODEL)
            self.ai_enabled = True
            logger.info("AI Action Plan Generator initialized with Gemini")
        else:
            self.ai_enabled = False
            logger.warning("Gemini API key not configured. Using rule-based plans only.")
    
    async def generate_action_plan(
        self, 
        student_data: Dict[str, Any],
        include_ai_insights: bool = True
    ) -> Dict[str, Any]:
        """
        Generate comprehensive action plan for a student.
        
        Args:
            student_data: Student profile data
            include_ai_insights: Whether to include AI-generated insights
            
        Returns:
            Complete analysis with action plan
        """
        # First, get rule-based analysis
        analysis = self.balance_analyzer.analyze_student(student_data)
        
        # If AI is enabled and requested, enhance with AI insights
        if include_ai_insights and self.ai_enabled:
            try:
                ai_plan = await self._generate_ai_plan(student_data, analysis)
                analysis["ai_action_plan"] = ai_plan
                analysis["ai_enhanced"] = True
            except Exception as e:
                logger.error(f"AI plan generation failed: {e}")
                analysis["ai_enhanced"] = False
                analysis["ai_error"] = str(e)
        else:
            analysis["ai_enhanced"] = False
        
        return analysis
    
    async def _generate_ai_plan(
        self, 
        student_data: Dict[str, Any],
        analysis: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate AI-powered action plan using Gemini."""
        
        metrics = analysis["metrics"]
        issues = analysis["issues"]
        
        prompt = self._build_prompt(student_data, metrics, issues)
        
        try:
            response = await self.model.generate_content_async(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=0.7,
                    max_output_tokens=2000,
                )
            )
            
            # Parse the response
            return self._parse_ai_response(response.text)
            
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise
    
    def _build_prompt(
        self, 
        student_data: Dict[str, Any],
        metrics: Dict[str, Any],
        issues: List[Dict[str, Any]]
    ) -> str:
        """Build prompt for Gemini."""
        
        student_name = student_data.get("full_name", "Pelajar")
        department = student_data.get("department", "Tidak dinyatakan")
        cgpa = student_data.get("cgpa", "N/A")
        koku_activities = student_data.get("kokurikulum_activities", [])
        
        # Handle koku_activities that might be list of dicts or strings
        if koku_activities:
            activities_list = []
            for act in koku_activities:
                if isinstance(act, dict):
                    # Extract name/title from dict
                    act_name = act.get("name") or act.get("title") or act.get("activity") or str(act)
                    activities_list.append(str(act_name))
                else:
                    activities_list.append(str(act))
            activities_text = ', '.join(activities_list)
        else:
            activities_text = 'Tiada rekod'
        
        issues_text = "\n".join([
            f"- [{i['severity'].upper()}] {i['description']}"
            for i in issues
        ]) if issues else "Tiada isu kritikal."
        
        prompt = f"""Anda adalah penasihat akademik universiti Malaysia. Beri pelan tindakan ringkas untuk pelajar ini.

PELAJAR: {student_name}
JABATAN: {department}
CGPA: {cgpa}
KOKURIKULUM: {activities_text}
SKOR AKADEMIK: {metrics['academic_score']:.0f}%
SKOR KOKU: {metrics['kokurikulum_score']:.0f}%
STATUS: {metrics['status']}
GAP: {metrics['gap']:.0f}%

ISU: {issues_text}

ARAHAN PENTING:
1. Respons MESTI dalam format JSON yang valid
2. JANGAN guna markdown code block
3. Beri HANYA 2 tindakan sahaja
4. Pastikan JSON lengkap dengan semua closing brackets

Format JSON (ikut TEPAT):
{{"ringkasan":"[1-2 ayat]","pelan":[{{"tindakan":"[apa]","sebab":"[kenapa]","tempoh":"[bila]"}}],"motivasi":"[1 ayat]","jumpa_pa":false}}"""

        return prompt
    
    def _parse_ai_response(self, response_text: str) -> Dict[str, Any]:
        """Parse Gemini response to structured format."""
        
        # Try to extract JSON from response
        try:
            # Remove markdown code block markers if present
            clean_text = response_text.strip()
            
            # Handle ```json ... ``` format
            if clean_text.startswith("```"):
                # Find the end of the opening marker
                first_newline = clean_text.find('\n')
                if first_newline > 0:
                    clean_text = clean_text[first_newline + 1:]
                # Remove closing ```
                if clean_text.endswith("```"):
                    clean_text = clean_text[:-3].strip()
            
            # Find JSON in response
            json_start = clean_text.find('{')
            json_end = clean_text.rfind('}') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = clean_text[json_start:json_end]
                parsed = json.loads(json_str)
                logger.info("Successfully parsed AI response as JSON")
                return parsed
                
        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse AI response as JSON: {e}")
        
        # Fallback: return as plain text
        return {
            "ringkasan": response_text[:500] if len(response_text) > 500 else response_text,
            "pelan_tindakan": [],
            "tips_motivasi": "",
            "rujukan_pa": False,
            "parse_error": True
        }
    
    async def generate_batch_report(
        self,
        students: List[Dict[str, Any]],
        include_ai: bool = False
    ) -> Dict[str, Any]:
        """
        Generate report for multiple students.
        
        Args:
            students: List of student data
            include_ai: Include AI insights (slower, uses more API calls)
            
        Returns:
            Batch report with statistics
        """
        # Get batch analysis from balance analyzer
        batch_analysis = self.balance_analyzer.analyze_batch(students)
        
        # Categorize students by priority
        high_priority = []
        medium_priority = []
        low_priority = []
        
        for result in batch_analysis["individual_results"]:
            status = result["metrics"]["status"]
            
            if status == "kedua_rendah":
                high_priority.append(result)
            elif status in ["fokus_akademik", "fokus_kokurikulum"]:
                medium_priority.append(result)
            else:
                low_priority.append(result)
        
        batch_analysis["priority_groups"] = {
            "high": {
                "count": len(high_priority),
                "students": [s["student_name"] for s in high_priority],
                "action_required": "Intervensi segera - jumpa PA dalam 1 minggu"
            },
            "medium": {
                "count": len(medium_priority),
                "students": [s["student_name"] for s in medium_priority],
                "action_required": "Pantauan - semak semula dalam 2 minggu"
            },
            "low": {
                "count": len(low_priority),
                "students": [s["student_name"] for s in low_priority],
                "action_required": "Tiada tindakan segera diperlukan"
            }
        }
        
        # Generate AI summary for the batch if requested
        if include_ai and self.ai_enabled:
            try:
                batch_analysis["ai_summary"] = await self._generate_batch_ai_summary(
                    batch_analysis["statistics"],
                    batch_analysis["priority_groups"]
                )
            except Exception as e:
                logger.error(f"Batch AI summary failed: {e}")
                batch_analysis["ai_summary"] = None
        
        return batch_analysis
    
    async def _generate_batch_ai_summary(
        self,
        statistics: Dict[str, Any],
        priority_groups: Dict[str, Any]
    ) -> str:
        """Generate AI summary for batch analysis."""
        
        prompt = f"""Anda adalah dekan fakulti universiti Malaysia. Berikan ringkasan eksekutif berdasarkan data berikut:

## Statistik Keseluruhan
- Purata Skor Akademik: {statistics['average_academic_score']}%
- Purata Skor Kokurikulum: {statistics['average_kokurikulum_score']}%
- Pelajar Memerlukan Perhatian: {statistics['students_needing_attention']}

## Kumpulan Keutamaan
- Keutamaan Tinggi: {priority_groups['high']['count']} pelajar
- Keutamaan Sederhana: {priority_groups['medium']['count']} pelajar
- Tiada Isu: {priority_groups['low']['count']} pelajar

Berikan ringkasan eksekutif dalam 3-4 ayat sahaja. Fokus pada insight utama dan cadangan tindakan untuk fakulti."""

        try:
            response = await self.model.generate_content_async(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=0.5,
                    max_output_tokens=300,
                )
            )
            return response.text
        except Exception as e:
            logger.error(f"Batch summary generation failed: {e}")
            return None
