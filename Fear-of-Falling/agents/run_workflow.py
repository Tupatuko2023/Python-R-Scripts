import sys
import os
import argparse
from datetime import datetime, timezone

# Ensure we can import modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from agents.agent_types import Agent

def write_trace(trace_dir: str, role: str, content: str):
    os.makedirs(trace_dir, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    filename = f"{timestamp}_{role}.txt"
    path = os.path.join(trace_dir, filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    return path

def run_workflow_demo(do_commit: bool, approve: bool, allow_commit: bool):
    print("=== Starting Option A Architecture Demo ===")
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    trace_dir = os.path.join(repo_root, "artifacts", "traces")

    if approve:
        os.environ["FOF_QA_APPROVED"] = "1"
    if allow_commit:
        os.environ["FOF_ALLOW_COMMIT"] = "1"

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
    write_trace(trace_dir, "architect", plan)

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
    write_trace(trace_dir, "integrator", execution)

    # --- Step 3: Quality Gate Verification ---
    print("\n--- Step 3: Quality Gate Verification ---")
    verification = quality_gate.run(
        "Verify the new file exists and content is correct.",
        tool_calls=[
            {"tool": "read_file", "args": {"path": "R-scripts/smoke_test_hello.R"}},
            {"tool": "run_git", "args": {"args": ["diff"]}} # Checking what changed
        ]
    )
    write_trace(trace_dir, "quality_gate", verification)

    if do_commit:
        print("\n--- Step 4: Commit (if approved) ---")
        commit_run = integrator.run(
            "Stage and commit the smoke test file.",
            tool_calls=[
                {"tool": "run_git", "args": {"args": ["add", "R-scripts/smoke_test_hello.R"]}},
                {"tool": "run_git", "args": {"args": ["commit", "-m", "Add Option A smoke test script"]}}
            ]
        )
        write_trace(trace_dir, "integrator_commit", commit_run)

    print("\n=== Workflow Complete ===")

def main():
    parser = argparse.ArgumentParser(description="Run the Option A workflow demo.")
    parser.add_argument("--smoke", action="store_true", help="Run the workflow smoke demo.")
    parser.add_argument("--no-commit", action="store_true", help="Do not attempt to commit changes.")
    parser.add_argument("--commit", action="store_true", help="Attempt to commit after quality gate.")
    parser.add_argument("--approve", action="store_true", help="Set Quality Gate approval for commit.")
    parser.add_argument("--allow-commit", action="store_true", help="Override commit gate for debugging.")
    args = parser.parse_args()

    do_commit = args.commit and not args.no_commit
    run_workflow_demo(do_commit=do_commit, approve=args.approve, allow_commit=args.allow_commit)

if __name__ == "__main__":
    main()
