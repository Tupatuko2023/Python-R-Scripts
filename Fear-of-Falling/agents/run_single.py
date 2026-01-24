import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from agents.agent_types import Agent

def run_security_test():
    print("=== Running Security Smoke Test ===")

    integrator = Agent("Iggy", "integrator", "", ["write_file"])
    architect = Agent("Archie", "architect", "", ["write_file"]) # Architect shouldn't even have this, but if they try...

    # Test 1: Integrator write to allowed path
    print("\nTest 1: Integrator write to 'R-scripts/smoke.txt'")
    try:
        res = integrator.run("Write file", [{"tool": "write_file", "args": {"path": "R-scripts/smoke.txt", "content": "Smoke"}}])
        print("PASS: Allowed write succeeded.")
    except Exception as e:
        print(f"FAIL: Allowed write failed: {e}")

    # Test 2: Integrator write to denied path
    print("\nTest 2: Integrator write to 'data/secret.csv'")
    try:
        res = integrator.run("Write file", [{"tool": "write_file", "args": {"path": "data/secret.csv", "content": "Secret"}}])
        if "Access denied" in res or "failed" in res:
             print("PASS: Denied write failed as expected.")
        else:
             print("FAIL: Denied write succeeded?!")
    except Exception as e:
        print(f"PASS: Denied write raised exception: {e}")

    # Test 3: Architect write attempt
    print("\nTest 3: Architect write attempt")
    try:
        # Note: Architect usually doesn't have write_file in allowed_tools list in proper setup,
        # but here we force the call to test the Server-side guard.
        # We temporarily add it to allowed tools to bypass client-side check
        architect.allowed_tools.append("write_file")
        res = architect.run("Write file", [{"tool": "write_file", "args": {"path": "R-scripts/plan.txt", "content": "Plan"}}])
        print("FAIL: Architect write succeeded?!")
    except Exception as e:
         print(f"PASS: Architect write blocked: {e}")

if __name__ == "__main__":
    run_security_test()
