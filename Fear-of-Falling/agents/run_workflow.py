import sys
import os
import argparse
from pathlib import Path

# Ensure we can import modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from agents.agent_types import Agent

def run_workflow_demo(use_codex=False, smoke=False):
    print("=== Starting Option A Architecture Demo ===")
    if use_codex:
        print("(Note: Real Codex MCP integration requested via --use-codex, but currently running in simulated demo mode for this artifact)")
    else:
        print("(Running in stubbed/fast mode)")

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
    # Use a temporary file name that is easy to clean up
    test_file = "R-scripts/smoke_test_hello.R"
    task_goal = f"Create a new R script '{test_file}' that prints Hello."

    try:
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
                        "path": test_file,
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
                {"tool": "read_file", "args": {"path": test_file}},
                {"tool": "run_git", "args": {"args": ["diff"]}} # Checking what changed
            ]
        )

    finally:
        # Cleanup if smoke test
        if smoke:
            print(f"\n[Cleanup] Removing temporary file {test_file}")
            # Use mcp server (via agent or directly) or os to clean up
            # Using OS directly for reliability in cleanup block
            try:
                # We need to resolve relative to repo root, assuming CWD is repo root or script dir
                # The script assumes running from repo root usually, let's try to handle it.
                repo_root = Path(".").resolve()
                # Check if we are inside agents/ or root
                if (repo_root / "Fear-of-Falling").exists():
                     file_path = repo_root / "Fear-of-Falling" / test_file
                else:
                     file_path = repo_root / test_file

                if file_path.exists():
                    os.remove(file_path)
                    print("Cleanup successful.")
                else:
                    # Try fallback relative path if logic above missed
                    if os.path.exists(test_file):
                        os.remove(test_file)
                        print("Cleanup successful (relative).")
            except Exception as e:
                print(f"Cleanup failed: {e}")

    print("\n=== Workflow Complete ===")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run Option A Workflow Demo")
    parser.add_argument("--smoke", action="store_true", help="Run as smoke test (cleanup artifacts)")
    parser.add_argument("--no-commit", action="store_true", help="Do not commit changes (implied by this demo script)")
    parser.add_argument("--smoke-fast", "--ci", dest="smoke_fast", action="store_true", help="Force stubbed execution (default)")
    parser.add_argument("--use-codex", action="store_true", help="Use real Codex MCP (mocked in this demo)")

    args = parser.parse_args()

    # Logic: smoke_fast is default, use_codex overrides if implemented
    run_workflow_demo(use_codex=args.use_codex, smoke=args.smoke)
