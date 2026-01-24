from typing import List, Dict, Any, Callable
import json
import sys
import os

# Add parent dir to path to import mcp_servers
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from mcp_servers.repo_tools_server import RepoToolsServer

class Agent:
    def __init__(self, name: str, role: str, instructions: str, allowed_tools: List[str]):
        self.name = name
        self.role = role
        self.instructions = instructions
        self.allowed_tools = allowed_tools

        # Instantiate the server directly for this mock implementation
        # In a real scenario, this would be an MCP Client connecting to the process
        self.server = RepoToolsServer()

    def call_tool(self, tool_name: str, **kwargs) -> Any:
        if tool_name not in self.allowed_tools:
            raise PermissionError(f"Agent '{self.name}' is not allowed to use tool '{tool_name}'")

        # Add role to kwargs automatically
        kwargs['role'] = self.role

        # Direct method call for simulation
        if tool_name == "read_file":
            return self.server.read_file(kwargs['path'], kwargs['role'])
        elif tool_name == "write_file":
            return self.server.write_file(kwargs['path'], kwargs['content'], kwargs['role'])
        elif tool_name == "replace_in_file":
            return self.server.replace_in_file(kwargs['path'], kwargs['search'], kwargs['replace'], kwargs['role'])
        elif tool_name == "list_files":
            return self.server.list_files(kwargs['path'], kwargs['role'])
        elif tool_name == "run_git":
            return self.server.run_git(kwargs['args'], kwargs['role'])
        else:
            raise ValueError(f"Unknown tool {tool_name}")

    def run(self, input_message: str, tool_calls: List[Dict] = None) -> str:
        """
        Simulates an agent run.
        In a real LLM agent, this would generate tool calls.
        Here, we accept a list of 'planned' tool calls to execute for the smoke test.
        """
        print(f"\n[{self.role.upper()}]: Processing: {input_message}")

        response = f"Processed: {input_message}\n"

        if tool_calls:
            for call in tool_calls:
                tool = call['tool']
                args = call['args']
                print(f"  -> Calling {tool} with {args}")
                try:
                    result = self.call_tool(tool, **args)
                    print(f"  -> Result: {str(result)[:50]}...")
                    response += f"Tool {tool} output: {result}\n"
                except Exception as e:
                    print(f"  -> Error: {e}")
                    response += f"Tool {tool} failed: {e}\n"

        return response
