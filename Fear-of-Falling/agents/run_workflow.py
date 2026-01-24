import sys
import os

# Ensure we can import modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from agents.agent_types import Agent

def run_workflow_demo():
    print("=== Starting Option A Architecture Demo ===")

    # 1. Define Agents
    architect = Agent(
        name="Archie",
        role="architect",
        instructions="Plan changes. Do not touch files.",
        allowed_tools=["read_file", "list_files"]
    )

    integrator = Agent(
        name="Iggy",
        role="integrator",
        instructions="Implement changes. Allowed to write to R-scripts.",
        allowed_tools=["read_file", "write_file", "list_files", "run_git"]
    )

    quality_gate = Agent(
        name="Quinn",
        role="quality_gate",
        instructions="Verify changes. Read only.",
        allowed_tools=["read_file", "list_files", "run_git"]
    )

    # 2. Scenario: Create a new analysis script
    task_goal = "Create a new R script 'R-scripts/smoke_test_hello.R' that prints Hello."

    # --- Step 1: Architect ---
    print("\n--- Step 1: Architect Planning ---")
    plan = architect.run(
        f"Analyze request: {task_goal}. Check existing files.",
        tool_calls=[
            {"tool": "list_files", "args": {"path": "R-scripts"}}
        ]
    )

    # --- Step 2: Integrator Execution ---
    print("\n--- Step 2: Integrator Implementation ---")
    # In a real system, the LLM would generate this call based on the Architect's plan.
    execution = integrator.run(
        f"Execute plan: {task_goal}",
        tool_calls=[
            {
                "tool": "write_file",
                "args": {
                    "path": "R-scripts/smoke_test_hello.R",
                    "content": "print('Hello Option A')\n"
                }
            },
             {
                "tool": "run_git",
                "args": {
                    "args": ["status"]
                }
            }
        ]
    )

    # --- Step 3: Quality Gate Verification ---
    print("\n--- Step 3: Quality Gate Verification ---")
    verification = quality_gate.run(
        "Verify the new file exists and content is correct.",
        tool_calls=[
            {"tool": "read_file", "args": {"path": "R-scripts/smoke_test_hello.R"}},
            {"tool": "run_git", "args": {"args": ["diff"]}} # Checking what changed
        ]
    )

    print("\n=== Workflow Complete ===")

if __name__ == "__main__":
    run_workflow_demo()
