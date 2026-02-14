#!/usr/bin/env python3
"""Minimal Kimi CLI for NVIDIA OpenAI-compatible chat completions."""

import argparse
import json
import os
import socket
import sys
from typing import Optional
import urllib.error
import urllib.request


DEFAULT_MODEL = "moonshotai/kimi-k2-instruct"
ENDPOINT = "https://integrate.api.nvidia.com/v1/chat/completions"


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Kimi CLI for NVIDIA NIM serverless.")
    parser.add_argument("prompt", nargs="?", help="User prompt. If omitted, reads from stdin.")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Model name (default: {DEFAULT_MODEL}).")
    parser.add_argument("--system", default="", help="Optional system message.")
    parser.add_argument("--temperature", type=float, default=0.2, help="Sampling temperature.")
    parser.add_argument("--max-tokens", type=int, default=None, help="Optional max output tokens.")
    parser.add_argument("--json", action="store_true", help="Print full JSON response.")
    parser.add_argument("--timeout", type=int, default=60, help="HTTP timeout in seconds.")
    return parser


def _resolve_prompt(arg_prompt: Optional[str]) -> str:
    if arg_prompt is not None and arg_prompt.strip():
        return arg_prompt.strip()
    if not sys.stdin.isatty():
        stdin_prompt = sys.stdin.read().strip()
        if stdin_prompt:
            return stdin_prompt
    print("Error: prompt is required via argument or stdin.", file=sys.stderr)
    raise SystemExit(2)


def _request(payload: dict, api_key: str, timeout: int) -> dict:
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        ENDPOINT,
        data=data,
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = response.read()
    except urllib.error.HTTPError as error:
        print(
            f"Error: request failed (HTTP {getattr(error, 'code', 'unknown')}).",
            file=sys.stderr,
        )
        raise SystemExit(1)
    except (urllib.error.URLError, socket.timeout, TimeoutError):
        print("Error: request failed.", file=sys.stderr)
        raise SystemExit(1)

    try:
        decoded = body.decode("utf-8")
        return json.loads(decoded)
    except (UnicodeDecodeError, json.JSONDecodeError):
        print("Error: invalid JSON response.", file=sys.stderr)
        raise SystemExit(1)


def _extract_content(response_json: dict) -> str:
    try:
        content = response_json["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        print("Error: unexpected response format.", file=sys.stderr)
        raise SystemExit(2)

    if not isinstance(content, str):
        print("Error: unexpected response format.", file=sys.stderr)
        raise SystemExit(2)

    return content


def main() -> int:
    args = _build_parser().parse_args()
    api_key = os.environ.get("NVIDIA_API_KEY", "")
    if not api_key:
        print("Error: NVIDIA_API_KEY not set.", file=sys.stderr)
        return 1

    prompt = _resolve_prompt(args.prompt)
    messages = []
    if args.system:
        messages.append({"role": "system", "content": args.system})
    messages.append({"role": "user", "content": prompt})

    payload = {
        "model": args.model,
        "messages": messages,
        "temperature": args.temperature,
    }
    if args.max_tokens is not None:
        payload["max_tokens"] = args.max_tokens

    response_json = _request(payload, api_key=api_key, timeout=args.timeout)

    if args.json:
        print(json.dumps(response_json, ensure_ascii=False, indent=2))
        return 0

    print(_extract_content(response_json))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
