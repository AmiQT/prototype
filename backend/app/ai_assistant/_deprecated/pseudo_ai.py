"""Pseudo-AI engine based on template & rule-based logic."""

from __future__ import annotations

import random
from typing import Any

from .schemas import AICommandResponse, AISource, AICommandStep
from . import templates


DEPARTMENTS = [
    "Computer Science",
    "Information Technology",
    "Software Engineering",
    "Artificial Intelligence",
    "Data Science",
    "Information Security",
]


MALE_NAMES = [
    "Ahmad Hafiz",
    "Muhammad Iqbal",
    "Syafiq Hakim",
    "Nuruddin Akmal",
    "Amirul Faris",
]


FEMALE_NAMES = [
    "Nurul Aisyah",
    "Siti Khadijah",
    "Aina Sofea",
    "Farah Nabilah",
    "Balqis Huda",
]


def _generate_student_profile(department: str, year: int) -> dict[str, Any]:
    """Generate simple student record."""

    gender = random.choice(["male", "female"])
    name = random.choice(MALE_NAMES if gender == "male" else FEMALE_NAMES)
    matric_suffix = random.randint(1000, 9999)
    matric = f"FSKTM{year}{matric_suffix}"

    email_name = name.lower().replace(" ", ".")
    email = f"{email_name}.{matric_suffix}@student.uthm.edu.my"

    return {
        "name": name,
        "gender": gender,
        "department": department,
        "year": year,
        "student_id": matric,
        "email": email,
        "status": "pending_activation",
    }


def parse_basic_command(command: str) -> dict[str, Any]:
    """Parse command untuk detect intent simple."""

    text = command.lower().strip()

    if text.startswith("create") and "student" in text:
        # Cari jumlah
        count = 10
        for token in text.split():
            if token.isdigit():
                count = min(int(token), 100)
                break

        # Cari department
        department = next((dept for dept in DEPARTMENTS if dept.lower() in text), DEPARTMENTS[0])

        # Tahun intake
        year = 2025
        for token in text.split():
            if len(token) == 4 and token.isdigit() and token.startswith("20"):
                year = int(token)
                break

        return {
            "action": "create_students",
            "count": count,
            "department": department,
            "year": year,
        }

    if text.startswith("find") or "search" in text:
        return {
            "action": "search",
            "query": command,
        }

    if "report" in text or "laporan" in text:
        return {
            "action": "report",
            "query": command,
        }

    return {"action": "fallback", "query": command}


def execute_parsed_command(parsed: dict[str, Any], *, context: dict[str, Any] | None = None) -> AICommandResponse:
    """Execute pseudo AI logic bagi parsed command."""

    action = parsed.get("action")

    if action == "create_students":
        count = parsed["count"]
        department = parsed["department"]
        year = parsed["year"]
        students = [_generate_student_profile(department, year) for _ in range(count)]
        summary = templates.generate_user_creation_summary(students)

        steps = [
            AICommandStep(label="Command parsed", detail=str(parsed)),
            AICommandStep(label="Profiles generated", detail=f"Generated {count} student profiles"),
            AICommandStep(label="Summary prepared", detail="Distribution by department calculated"),
        ]

        if context:
            steps.append(AICommandStep(label="Context received", detail=str(context)))

        return AICommandResponse(
            success=True,
            message=f"Generated {count} student profiles for {department} ({year} intake).",
            source=AISource.PSEUDO,
            data={"students": students, "summary": summary, "action": action},
            steps=steps,
        )

    if action == "search":
        placeholder = templates.generate_search_placeholder(parsed["query"])
        placeholder["action"] = action
        steps = [
            AICommandStep(label="Command parsed", detail="Search intent detected"),
            AICommandStep(label="Placeholder generated", detail="Real search integration pending"),
        ]
        return AICommandResponse(
            success=True,
            message="Search command received (pseudo AI placeholder)",
            source=AISource.PSEUDO,
            data=placeholder,
            steps=steps,
        )

    if action == "report":
        summary = templates.generate_student_report_summary({"query": parsed.get("query"), "context": context})
        steps = [
            AICommandStep(label="Command parsed", detail="Report intent detected"),
            AICommandStep(label="Summary generated", detail="Template report data prepared"),
        ]
        return AICommandResponse(
            success=True,
            message="Report generation placeholder (pseudo AI).",
            source=AISource.PSEUDO,
            data={"report": summary, "action": action},
            steps=steps,
        )

    return AICommandResponse(
        success=False,
        message="Command forwarded to Gemini for deeper reasoning.",
        source=AISource.PSEUDO,
        data={"parsed": parsed, "action": action},
        fallback_used=True,
    )


def handle_command(command: str) -> AICommandResponse:
    """Handle command guna rule-based pseudo AI."""

    parsed = parse_basic_command(command)
    return execute_parsed_command(parsed)

