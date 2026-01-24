import sys
import json
import logging
import difflib
import subprocess
import os
from pathlib import Path
from datetime import datetime

# Import Guard
try:
    # Try relative import if running as module
    from .filesystem_guard import FileSystemGuard, SecurityError
except ImportError:
    # Try direct import if running script directly
    from filesystem_guard import FileSystemGuard, SecurityError

# Setup Logging
LOG_DIR = Path("artifacts/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    filename=LOG_DIR / "repo_tools.jsonl",
    level=logging.INFO,
    format='{"timestamp": "%(asctime)s", "level": "%(levelname)s", "message": %(message)s}',
    datefmt='%Y-%m-%dT%H:%M:%S'
)

class RepoToolsServer:
    def __init__(self):
        self.guard = FileSystemGuard(
            config_path="configs/tool_scopes.json",
            repo_root="."
        )

    def log_request(self, tool_name, args, result=None, error=None):
        entry = {
            "tool": tool_name,
            "args": args,
            "result": str(result)[:200] + "..." if result else None,
            "error": str(error) if error else None
        }
        logging.info(json.dumps(entry))

    def read_file(self, path: str, role: str) -> str:
        try:
            abs_path = self.guard.validate_path(path, role, "read")
            with open(abs_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            raise e

    def write_file(self, path: str, content: str, role: str) -> str:
        try:
            # Check write permission
            abs_path = self.guard.validate_path(path, role, "write")

            # Read existing content for diff
            old_content = ""
            if os.path.exists(abs_path):
                with open(abs_path, 'r', encoding='utf-8') as f:
                    old_content = f.read()

            # Write new content
            with open(abs_path, 'w', encoding='utf-8') as f:
                f.write(content)

            # Generate diff
            diff = difflib.unified_diff(
                old_content.splitlines(keepends=True),
                content.splitlines(keepends=True),
                fromfile=f"a/{path}",
                tofile=f"b/{path}"
            )
            return "".join(diff)
        except Exception as e:
            raise e

    def list_files(self, path: str, role: str) -> str:
        try:
            # Listing is a read operation on the directory
            abs_path = self.guard.validate_path(path, role, "read")

            if not os.path.isdir(abs_path):
                return f"Error: {path} is not a directory."

            files = []
            for item in os.listdir(abs_path):
                # Filter out obvious ignores if needed, or rely on agent
                files.append(item + ("/" if os.path.isdir(os.path.join(abs_path, item)) else ""))
            files.sort()
            return "\n".join(files)
        except Exception as e:
            raise e

    def run_git(self, args: list, role: str) -> str:
        try:
            self.guard.validate_git_command(args, role)

            # Run git command
            result = subprocess.run(
                ["git"] + args,
                cwd=str(self.guard.repo_root),
                capture_output=True,
                text=True
            )

            if result.returncode != 0:
                return f"Git Error: {result.stderr}"
            return result.stdout
        except Exception as e:
            raise e

    def handle_request(self, line):
        try:
            request = json.loads(line)
            method = request.get("method")
            params = request.get("params", {})
            id_ = request.get("id")

            if method == "tools/list":
                # Return tool definitions
                response = {
                    "jsonrpc": "2.0",
                    "id": id_,
                    "result": {
                        "tools": [
                            {
                                "name": "read_file",
                                "description": "Reads a file from the repository.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "path": {"type": "string"},
                                        "role": {"type": "string"}
                                    },
                                    "required": ["path", "role"]
                                }
                            },
                            {
                                "name": "write_file",
                                "description": "Writes to a file and returns a diff.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "path": {"type": "string"},
                                        "content": {"type": "string"},
                                        "role": {"type": "string"}
                                    },
                                    "required": ["path", "content", "role"]
                                }
                            },
                            {
                                "name": "list_files",
                                "description": "Lists files in a directory.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "path": {"type": "string"},
                                        "role": {"type": "string"}
                                    },
                                    "required": ["path", "role"]
                                }
                            },
                            {
                                "name": "run_git",
                                "description": "Runs allowed git commands.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "args": {"type": "array", "items": {"type": "string"}},
                                        "role": {"type": "string"}
                                    },
                                    "required": ["args", "role"]
                                }
                            }
                        ]
                    }
                }
            elif method == "tools/call":
                name = params.get("name")
                args = params.get("arguments", {})

                result = None
                error = None

                try:
                    if name == "read_file":
                        result = self.read_file(args["path"], args["role"])
                    elif name == "write_file":
                        result = self.write_file(args["path"], args["content"], args["role"])
                    elif name == "list_files":
                        result = self.list_files(args["path"], args["role"])
                    elif name == "run_git":
                        result = self.run_git(args["args"], args["role"])
                    else:
                        raise ValueError(f"Unknown tool: {name}")

                    response = {
                        "jsonrpc": "2.0",
                        "id": id_,
                        "result": {
                            "content": [{"type": "text", "text": str(result)}]
                        }
                    }
                    self.log_request(name, args, result=result)

                except Exception as e:
                    error_msg = str(e)
                    response = {
                        "jsonrpc": "2.0",
                        "id": id_,
                        "error": {"code": -32000, "message": error_msg}
                    }
                    self.log_request(name, args, error=error_msg)
            else:
                 response = {
                        "jsonrpc": "2.0",
                        "id": id_,
                        "error": {"code": -32601, "message": "Method not found"}
                    }

            print(json.dumps(response))
            sys.stdout.flush()

        except Exception as e:
             # Malformed JSON or other critical error
             logging.error(f"Critical error: {e}")

if __name__ == "__main__":
    server = RepoToolsServer()
    # Basic STDIO Loop
    for line in sys.stdin:
        server.handle_request(line)
