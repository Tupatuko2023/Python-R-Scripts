import sys
import subprocess
import json
import os

class CodexMCPServer:
    """
    A wrapper to run the Codex CLI as an MCP server over stdio.
    Use this class to integrate Codex into the Agent workflow.
    """
    def __init__(self, codex_path="npx"):
        self.codex_path = codex_path
        self.process = None

    def start(self):
        """
        Starts the Codex CLI in MCP mode.
        """
        # Assuming 'codex server' or similar command starts the MCP mode
        # Adjust command based on actual Codex CLI usage
        command = [self.codex_path, "codex", "mcp-server"]

        try:
            self.process = subprocess.Popen(
                command,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=sys.stderr,
                text=True,
                bufsize=0
            )
            print(f"Codex MCP Server started (PID: {self.process.pid})")
        except FileNotFoundError:
            print(f"Error: Codex binary not found at '{self.codex_path}'. Please install it or check path.")
            raise

    def send_request(self, request: dict):
        if not self.process:
            raise RuntimeError("Server not started")

        json_line = json.dumps(request) + "\n"
        self.process.stdin.write(json_line)
        self.process.stdin.flush()

        # Read response
        response_line = self.process.stdout.readline()
        if not response_line:
            raise RuntimeError("Server closed connection")

        return json.loads(response_line)

    def stop(self):
        if self.process:
            self.process.terminate()
            self.process.wait()
            print("Codex MCP Server stopped")

class FakeCodexMCPServer:
    """
    A fast, deterministic stub for CI/smoke runs.
    """
    def __init__(self):
        self.started = False

    def start(self):
        self.started = True
        print("Fake Codex MCP Server started")

    def send_request(self, request: dict):
        if not self.started:
            raise RuntimeError("Server not started")
        return {
            "jsonrpc": "2.0",
            "id": request.get("id"),
            "result": {"content": [{"type": "text", "text": "stub-ok"}]}
        }

    def stop(self):
        if self.started:
            self.started = False
            print("Fake Codex MCP Server stopped")

def has_codex_secrets() -> bool:
    keys = [
        "OPENAI_API_KEY",
        "OPENAI_BASE_URL",
        "OPENAI_ORG_ID",
        "CODEX_API_KEY",
        "CODEX_AUTH_TOKEN"
    ]
    return any(os.environ.get(key) for key in keys)

def get_codex_mcp_server(use_real: bool):
    if use_real:
        return CodexMCPServer()
    return FakeCodexMCPServer()

if __name__ == "__main__":
    # Example usage / Test
    server = CodexMCPServer()
    try:
        # verifying it fails gracefully if npx/codex is missing
        server.start()
    except Exception as e:
        print(f"Test run failed (expected if codex not installed): {e}")
