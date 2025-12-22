"""
Balance Analyzer

Analyzes student balance between academic and co-curricular (kokurikulum) achievements.
Identifies imbalances and generates targeted action plans.
"""

from typing import Dict, Any, List, Optional, Literal
from dataclasses import dataclass
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class BalanceStatus(str, Enum):
    """Student balance status categories"""
    BALANCED = "seimbang"
    ACADEMIC_FOCUSED = "fokus_akademik"
    KOKU_FOCUSED = "fokus_kokurikulum"
    BOTH_LOW = "kedua_rendah"
    BOTH_HIGH = "kedua_cemerlang"


@dataclass
class BalanceMetrics:
    """Metrics for academic-kokurikulum balance"""
    academic_score: float  # 0-100
    kokurikulum_score: float  # 0-100
    balance_score: float  # 0-100 (100 = perfectly balanced)
    status: BalanceStatus
    gap: float  # Difference between academic and koku
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "academic_score": round(self.academic_score, 2),
            "kokurikulum_score": round(self.kokurikulum_score, 2),
            "balance_score": round(self.balance_score, 2),
            "status": self.status.value,
            "gap": round(self.gap, 2)
        }


class BalanceAnalyzer:
    """
    Analyzer for student academic-kokurikulum balance.
    
    Evaluates student performance in both areas and identifies
    imbalances that need attention.
    """
    
    # Thresholds for categorization
    EXCELLENT_THRESHOLD = 75.0  # Above this = excellent
    GOOD_THRESHOLD = 50.0  # Above this = good
    LOW_THRESHOLD = 30.0  # Below this = needs attention
    BALANCE_TOLERANCE = 15.0  # Difference within this = balanced
    
    def __init__(self):
        self.config = {
            "cgpa_max": 4.0,
            "koku_score_max": 100.0,
            "koku_credits_target": 50,  # Target credits for full score
        }
    
    def analyze_student(self, student_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze a student's academic-kokurikulum balance.
        
        Args:
            student_data: Student profile data from database
            
        Returns:
            Complete balance analysis with metrics and recommendations
        """
        # Extract and normalize scores
        metrics = self._calculate_metrics(student_data)
        
        # Identify specific issues
        issues = self._identify_issues(metrics, student_data)
        
        # Generate action plan
        action_plan = self._generate_action_plan(metrics, issues, student_data)
        
        # Build response
        return {
            "student_id": student_data.get("id"),
            "student_name": student_data.get("full_name", "Unknown"),
            "metrics": metrics.to_dict(),
            "issues": issues,
            "action_plan": action_plan,
            "summary": self._generate_summary(metrics, issues)
        }
    
    def _calculate_metrics(self, student_data: Dict[str, Any]) -> BalanceMetrics:
        """Calculate balance metrics from student data."""
        
        # Academic score (from CGPA)
        cgpa = self._extract_cgpa(student_data)
        academic_score = (cgpa / self.config["cgpa_max"]) * 100
        
        # Kokurikulum score (from kokurikulum_score or calculate from credits/activities)
        koku_score = self._extract_koku_score(student_data)
        
        # Calculate gap and balance
        gap = academic_score - koku_score
        abs_gap = abs(gap)
        
        # Balance score: 100 when perfectly balanced, decreases with gap
        balance_score = max(0, 100 - (abs_gap * 2))
        
        # Determine status
        status = self._determine_status(academic_score, koku_score, gap)
        
        return BalanceMetrics(
            academic_score=academic_score,
            kokurikulum_score=koku_score,
            balance_score=balance_score,
            status=status,
            gap=gap
        )
    
    def _extract_cgpa(self, student_data: Dict[str, Any]) -> float:
        """Extract CGPA from student data."""
        # Try direct field first
        cgpa = student_data.get("cgpa")
        
        # Try from academic_info if not found
        if not cgpa:
            academic_info = student_data.get("academic_info") or {}
            cgpa = academic_info.get("cgpa")
        
        # Convert and validate
        try:
            cgpa = float(cgpa) if cgpa else 0.0
            return min(max(cgpa, 0.0), 4.0)
        except (ValueError, TypeError):
            return 0.0
    
    def _extract_koku_score(self, student_data: Dict[str, Any]) -> float:
        """Extract or calculate kokurikulum score."""
        # Direct score if available
        koku_score = student_data.get("kokurikulum_score")
        if koku_score is not None:
            try:
                return float(koku_score)
            except (ValueError, TypeError):
                pass
        
        # Calculate from credits and activities if score not available
        credits = student_data.get("kokurikulum_credits", 0) or 0
        activities = student_data.get("kokurikulum_activities", []) or []
        
        # Score based on credits (50% weight)
        credits_score = min(credits / self.config["koku_credits_target"], 1.0) * 50
        
        # Score based on activities (50% weight) - assume 5 activities = full score
        activities_score = min(len(activities) / 5, 1.0) * 50
        
        return credits_score + activities_score
    
    def _determine_status(
        self, 
        academic: float, 
        koku: float, 
        gap: float
    ) -> BalanceStatus:
        """Determine balance status based on scores."""
        
        abs_gap = abs(gap)
        
        # Check if both are excellent
        if academic >= self.EXCELLENT_THRESHOLD and koku >= self.EXCELLENT_THRESHOLD:
            return BalanceStatus.BOTH_HIGH
        
        # Check if both are low
        if academic < self.LOW_THRESHOLD and koku < self.LOW_THRESHOLD:
            return BalanceStatus.BOTH_LOW
        
        # Check if balanced (within tolerance)
        if abs_gap <= self.BALANCE_TOLERANCE:
            return BalanceStatus.BALANCED
        
        # Check which area dominates
        if gap > 0:  # Academic higher
            return BalanceStatus.ACADEMIC_FOCUSED
        else:  # Koku higher
            return BalanceStatus.KOKU_FOCUSED
    
    def _identify_issues(
        self, 
        metrics: BalanceMetrics, 
        student_data: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Identify specific issues based on metrics."""
        issues = []
        
        # Academic issues
        if metrics.academic_score < self.LOW_THRESHOLD:
            issues.append({
                "area": "akademik",
                "severity": "tinggi",
                "description": "Prestasi akademik rendah (CGPA < 2.0)",
                "current_value": f"CGPA: {self._extract_cgpa(student_data):.2f}"
            })
        elif metrics.academic_score < self.GOOD_THRESHOLD:
            issues.append({
                "area": "akademik",
                "severity": "sederhana",
                "description": "Prestasi akademik perlu ditingkatkan",
                "current_value": f"CGPA: {self._extract_cgpa(student_data):.2f}"
            })
        
        # Kokurikulum issues
        if metrics.kokurikulum_score < self.LOW_THRESHOLD:
            issues.append({
                "area": "kokurikulum",
                "severity": "tinggi",
                "description": "Penglibatan kokurikulum sangat rendah",
                "current_value": f"Skor: {metrics.kokurikulum_score:.1f}%"
            })
        elif metrics.kokurikulum_score < self.GOOD_THRESHOLD:
            issues.append({
                "area": "kokurikulum",
                "severity": "sederhana",
                "description": "Penglibatan kokurikulum perlu ditingkatkan",
                "current_value": f"Skor: {metrics.kokurikulum_score:.1f}%"
            })
        
        # Balance issues
        if metrics.status == BalanceStatus.ACADEMIC_FOCUSED:
            issues.append({
                "area": "keseimbangan",
                "severity": "sederhana",
                "description": f"Terlalu fokus akademik, kurang kokurikulum (Gap: {metrics.gap:.1f}%)",
                "current_value": f"Akademik: {metrics.academic_score:.1f}%, Koku: {metrics.kokurikulum_score:.1f}%"
            })
        elif metrics.status == BalanceStatus.KOKU_FOCUSED:
            issues.append({
                "area": "keseimbangan",
                "severity": "sederhana",
                "description": f"Terlalu fokus kokurikulum, akademik perlu perhatian (Gap: {abs(metrics.gap):.1f}%)",
                "current_value": f"Akademik: {metrics.academic_score:.1f}%, Koku: {metrics.kokurikulum_score:.1f}%"
            })
        elif metrics.status == BalanceStatus.BOTH_LOW:
            issues.append({
                "area": "keseimbangan",
                "severity": "tinggi",
                "description": "Kedua-dua akademik dan kokurikulum memerlukan perhatian segera",
                "current_value": f"Akademik: {metrics.academic_score:.1f}%, Koku: {metrics.kokurikulum_score:.1f}%"
            })
        
        return issues
    
    def _generate_action_plan(
        self, 
        metrics: BalanceMetrics, 
        issues: List[Dict[str, Any]],
        student_data: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate specific action plan based on issues."""
        actions = []
        
        status = metrics.status
        
        if status == BalanceStatus.BOTH_HIGH:
            actions.append({
                "priority": 1,
                "category": "pengiktirafan",
                "action": "Kekalkan prestasi cemerlang",
                "details": "Pelajar menunjukkan keseimbangan yang baik antara akademik dan kokurikulum.",
                "timeline": "Berterusan",
                "target": "Kekalkan CGPA dan penglibatan kokurikulum"
            })
            actions.append({
                "priority": 2,
                "category": "pembangunan",
                "action": "Pertimbangkan untuk mentor rakan lain",
                "details": "Dengan prestasi cemerlang, pelajar boleh membantu rakan yang memerlukan bimbingan.",
                "timeline": "Semester ini",
                "target": "Bantu sekurang-kurangnya 2 rakan"
            })
        
        elif status == BalanceStatus.BOTH_LOW:
            actions.append({
                "priority": 1,
                "category": "intervensi_segera",
                "action": "Jumpa Penasihat Akademik (PA)",
                "details": "Bincang masalah akademik dan dapatkan bimbingan untuk pengurusan masa.",
                "timeline": "Dalam 1 minggu",
                "target": f"Tingkatkan CGPA dari {self._extract_cgpa(student_data):.2f} ke 2.5"
            })
            actions.append({
                "priority": 2,
                "category": "akademik",
                "action": "Sertai kelas tuisyen/tutorial",
                "details": "Fokus pada subjek yang lemah untuk meningkatkan CGPA.",
                "timeline": "Sepanjang semester",
                "target": "Hadiri sekurang-kurangnya 2 sesi tutorial seminggu"
            })
            actions.append({
                "priority": 3,
                "category": "kokurikulum",
                "action": "Sertai 1 aktiviti kokurikulum yang diminati",
                "details": "Pilih aktiviti yang tidak membebankan tetapi memberi kredit kokurikulum.",
                "timeline": "Dalam 2 minggu",
                "target": "Dapatkan sekurang-kurangnya 5 kredit kokurikulum"
            })
        
        elif status == BalanceStatus.ACADEMIC_FOCUSED:
            # High academic, low koku
            actions.append({
                "priority": 1,
                "category": "kokurikulum",
                "action": "Sertai kelab/persatuan akademik",
                "details": "Pilih kelab yang berkaitan dengan bidang pengajian untuk menggabungkan minat akademik dengan kokurikulum.",
                "timeline": "Dalam 2 minggu",
                "target": f"Tingkatkan skor kokurikulum dari {metrics.kokurikulum_score:.1f}% ke {min(metrics.kokurikulum_score + 20, 100):.1f}%"
            })
            actions.append({
                "priority": 2,
                "category": "kokurikulum",
                "action": "Sertai aktiviti sukan rekreasi",
                "details": "Sukan rekreasi membantu kesihatan mental dan fizikal tanpa terlalu membebankan.",
                "timeline": "Mingguan",
                "target": "Sekurang-kurangnya 2 jam aktiviti sukan seminggu"
            })
            actions.append({
                "priority": 3,
                "category": "sukarela",
                "action": "Sertai program sukarelawan",
                "details": "Program sukarelawan memberi kredit kokurikulum dan pengalaman kepimpinan.",
                "timeline": "Semester ini",
                "target": "Sertai sekurang-kurangnya 1 program komuniti"
            })
        
        elif status == BalanceStatus.KOKU_FOCUSED:
            # High koku, low academic
            actions.append({
                "priority": 1,
                "category": "akademik",
                "action": "Kurangkan komitmen kokurikulum sementara",
                "details": "Fokus pada akademik dahulu sehingga CGPA stabil.",
                "timeline": "Segera",
                "target": f"Tingkatkan CGPA dari {self._extract_cgpa(student_data):.2f} ke {min(self._extract_cgpa(student_data) + 0.5, 4.0):.2f}"
            })
            actions.append({
                "priority": 2,
                "category": "akademik",
                "action": "Buat jadual belajar yang konsisten",
                "details": "Peruntukkan masa khusus untuk belajar setiap hari.",
                "timeline": "Segera",
                "target": "Sekurang-kurangnya 3 jam belajar setiap hari"
            })
            actions.append({
                "priority": 3,
                "category": "akademik",
                "action": "Dapatkan bantuan tutor untuk subjek lemah",
                "details": "Kenal pasti subjek yang paling rendah dan dapatkan bantuan.",
                "timeline": "Dalam 1 minggu",
                "target": "Lulus semua subjek semester ini"
            })
        
        elif status == BalanceStatus.BALANCED:
            # Already balanced
            if metrics.academic_score >= self.GOOD_THRESHOLD:
                actions.append({
                    "priority": 1,
                    "category": "pengekalan",
                    "action": "Kekalkan keseimbangan semasa",
                    "details": "Prestasi anda seimbang. Teruskan usaha yang baik.",
                    "timeline": "Berterusan",
                    "target": "Kekalkan atau tingkatkan prestasi semasa"
                })
            else:
                actions.append({
                    "priority": 1,
                    "category": "peningkatan",
                    "action": "Tingkatkan kedua-dua aspek secara seimbang",
                    "details": "Walaupun seimbang, kedua-dua skor boleh ditingkatkan lagi.",
                    "timeline": "Semester ini",
                    "target": f"Tingkatkan kedua-dua skor ke {self.GOOD_THRESHOLD}%"
                })
        
        return actions
    
    def _generate_summary(
        self, 
        metrics: BalanceMetrics, 
        issues: List[Dict[str, Any]]
    ) -> str:
        """Generate human-readable summary in Bahasa Melayu."""
        
        status_messages = {
            BalanceStatus.BOTH_HIGH: 
                "🌟 Tahniah! Anda menunjukkan prestasi cemerlang dalam kedua-dua akademik dan kokurikulum. Teruskan usaha yang baik!",
            BalanceStatus.BALANCED: 
                "✅ Prestasi anda seimbang antara akademik dan kokurikulum. Ini adalah keadaan yang baik.",
            BalanceStatus.ACADEMIC_FOCUSED: 
                f"📚 Anda lebih fokus kepada akademik (Gap: {metrics.gap:.1f}%). Pertimbangkan untuk meningkatkan penglibatan kokurikulum.",
            BalanceStatus.KOKU_FOCUSED: 
                f"🏃 Anda lebih aktif dalam kokurikulum (Gap: {abs(metrics.gap):.1f}%). Perlu memberi perhatian lebih kepada akademik.",
            BalanceStatus.BOTH_LOW: 
                "⚠️ Kedua-dua akademik dan kokurikulum memerlukan perhatian. Sila jumpa Penasihat Akademik untuk bimbingan."
        }
        
        base_message = status_messages.get(metrics.status, "Analisis selesai.")
        
        # Add issue count
        high_severity = sum(1 for i in issues if i.get("severity") == "tinggi")
        if high_severity > 0:
            base_message += f"\n\n🔴 {high_severity} isu kritikal perlu perhatian segera."
        
        return base_message
    
    def analyze_batch(
        self, 
        students: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Analyze multiple students and provide aggregate statistics.
        
        Args:
            students: List of student data
            
        Returns:
            Batch analysis with individual results and statistics
        """
        results = []
        status_counts = {status.value: 0 for status in BalanceStatus}
        total_academic = 0.0
        total_koku = 0.0
        
        for student in students:
            analysis = self.analyze_student(student)
            results.append(analysis)
            
            metrics = analysis["metrics"]
            status_counts[metrics["status"]] += 1
            total_academic += metrics["academic_score"]
            total_koku += metrics["kokurikulum_score"]
        
        count = len(students)
        
        return {
            "total_students": count,
            "individual_results": results,
            "statistics": {
                "average_academic_score": round(total_academic / count, 2) if count else 0,
                "average_kokurikulum_score": round(total_koku / count, 2) if count else 0,
                "status_distribution": status_counts,
                "students_needing_attention": status_counts.get("kedua_rendah", 0) + 
                    status_counts.get("fokus_akademik", 0) + 
                    status_counts.get("fokus_kokurikulum", 0)
            }
        }
