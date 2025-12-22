"""Demo for testing integrated Agentic AI features."""

import asyncio
from typing import Dict, Any
from app.ai_assistant.plan_generator import PlanGenerator
from app.ai_assistant.intent_classifier import IntentClassifier
from app.ai_assistant.clarification_system import ClarificationSystem
from app.ai_assistant.tool_selector import ToolSelector

class AgenticAIDemo:
    """Demo class to test integrated agentic AI features."""
    
    def __init__(self):
        self.plan_generator = PlanGenerator()
        self.intent_classifier = IntentClassifier()
        self.clarification_system = ClarificationSystem()
        self.tool_selector = ToolSelector()
    
    def process_command(self, command: str) -> Dict[str, Any]:
        """Process a command through all the agentic AI components."""
        print(f"\n{'='*60}")
        print(f"Processing command: {command}")
        print(f"{'='*60}")
        
        # Step 1: Intent Classification
        print("\n1. Intent Classification:")
        intent_result = self.intent_classifier.classify_intent(command)
        print(f"   Intent: {intent_result.intent_type.value}")
        print(f"   Confidence: {intent_result.confidence:.2f}")
        print(f"   Entities: {intent_result.detected_entities}")
        print(f"   Clarification needed: {intent_result.clarification_needed}")
        
        # Step 2: Clarification (if needed)
        clarification_response = None
        if intent_result.clarification_needed:
            print("\n2. Clarification System:")
            clarification_response = self.clarification_system.generate_clarification_response(
                command, intent_result.detected_entities, intent_result.intent_type.value
            )
            if clarification_response:
                print(f"   Needs clarification: {clarification_response['needs_clarification']}")
                for i, question in enumerate(clarification_response['questions'], 1):
                    print(f"   Question {i}: {question}")
                for i, suggestion in enumerate(clarification_response['suggestions'], 1):
                    print(f"   Suggestion {i}: {suggestion}")
            else:
                print("   No specific clarifications generated")
        else:
            print("\n2. Clarification System: No clarification needed")
        
        # Step 3: Tool Selection
        print("\n3. Tool Selection:")
        selected_tools = self.tool_selector.select_tools(
            intent_result.intent_type.value, 
            intent_result.detected_entities
        )
        print(f"   Selected tools: {selected_tools}")
        
        # Show ranked tools
        ranked_tools = self.tool_selector.rank_tools_by_relevance(
            intent_result.intent_type.value,
            intent_result.detected_entities
        )
        print(f"   Top ranked tools: {ranked_tools[:3]}")
        
        # Step 4: Plan Generation
        print("\n4. Plan Generation:")
        plan = self.plan_generator.generate_plan(command)
        print(f"   Plan intent: {plan.intent}")
        print(f"   Number of steps: {len(plan.steps)}")
        for i, step in enumerate(plan.steps, 1):
            print(f"   Step {i}: {step.task_type.value}")
            print(f"     Description: {step.description}")
            print(f"     Parameters: {step.parameters}")
            print(f"     Tools needed: {step.tools_needed}")
        
        # Step 5: Execution Plan
        print("\n5. Tool Execution Plan:")
        execution_plan = self.tool_selector.get_tool_execution_plan(
            selected_tools, 
            intent_result.intent_type.value, 
            intent_result.detected_entities
        )
        for i, step in enumerate(execution_plan, 1):
            print(f"   Execution Step {i}:")
            print(f"     Tool: {step['tool_name']}")
            print(f"     Purpose: {step['purpose']}")
            print(f"     Parameters: {step['parameters']}")
            print(f"     Execution Order: {step['execution_order']}")
        
        # Return result summary
        return {
            "command": command,
            "intent": intent_result.intent_type.value,
            "confidence": intent_result.confidence,
            "entities": intent_result.detected_entities,
            "clarification_needed": intent_result.clarification_needed,
            "clarification_response": clarification_response,
            "selected_tools": selected_tools,
            "plan_steps": len(plan.steps),
            "plan_details": [
                {
                    "step_id": step.step_id,
                    "task_type": step.task_type.value,
                    "description": step.description,
                    "tools_needed": step.tools_needed
                } for step in plan.steps
            ]
        }


def run_demo():
    """Run a comprehensive demo of the agentic AI features."""
    demo = AgenticAIDemo()
    
    # Test commands of varying complexity
    test_commands = [
        "Show me the top 5 students in Computer Science",
        "Find students with CGPA above 3.5 and email them",
        "List all upcoming events for this month",
        "Generate a report on student achievement statistics",
        "Show me top students and then their achievements",
        "Send notification about the event to participants",
        "Update student status to active"
    ]
    
    results = []
    
    for command in test_commands:
        result = demo.process_command(command)
        results.append(result)
    
    # Summary
    print(f"\n{'='*60}")
    print("DEMO SUMMARY")
    print(f"{'='*60}")
    
    intent_counts = {}
    tool_counts = {}
    
    for result in results:
        intent = result['intent']
        intent_counts[intent] = intent_counts.get(intent, 0) + 1
        
        for tool in result['selected_tools']:
            tool_counts[tool] = tool_counts.get(tool, 0) + 1
    
    print(f"\nIntent Distribution:")
    for intent, count in intent_counts.items():
        print(f"  {intent}: {count}")
    
    print(f"\nTool Usage:")
    for tool, count in tool_counts.items():
        print(f"  {tool}: {count}")
    
    print(f"\nCommands requiring clarification: {sum(1 for r in results if r['clarification_needed'])}/{len(results)}")


if __name__ == "__main__":
    run_demo()