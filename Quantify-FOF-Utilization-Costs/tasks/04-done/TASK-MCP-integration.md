---
title: "MCP Double-Airlock Integration"
status: "done"
created: "2026-01-28"
tags: ["infrastructure", "security", "mcp"]
---

# Objective

Implement the "Double-Airlock" Model Context Protocol (MCP) architecture to securely separate public internet access (Zone 1) from private health data analysis (Zone 2) in the Quantify-FOF-Utilization-Costs project.

# Context

As defined in the security architecture for geriatric health data analysis:

- **Zone 1 (Public Gateway):** `healthcare-mcp-public`. Network allowed. NO filesystem access.
- **Zone 2 (Secure Enclave):** `secure-analysis-r`. Network BLOCKED. Read-only access to private data.
- **Goal:** Ensure sensitive health data is processed in a network-isolated environment while still allowing general agent capabilities.

# Subtasks

- [x] **Prerequisites**
  - [x] Verify Docker is installed and running.
  - [x] Create private data directory structure (e.g., `data/external/private`).

- [x] **Configuration**
  - [x] Set up `claude_desktop_config.json` with the two-zone architecture.
  - [x] Configure `healthcare-mcp-public` for general tasks.
  - [x] Configure `secure-analysis-r` for data tasks with network isolation.

- [ ] **Security Implementation & Tests**
  - [x] **Canary Token:** Create a file (e.g., `CONFIDENTIAL_CANARY.txt`) in the private data folder.
  - [x] **Test 1: Network Isolation:** specific prompt to `secure-analysis-r` to fetch a URL (MUST FAIL).
  - [x] **Test 2: Read-Only Access:** prompt to write a file to `/data` in `secure-analysis-r` (MUST FAIL).
  - [x] **Test 3: Canary Detection:** prompt to read the canary file (MUST TRIGGER STOP via system prompt).

# Acceptance Criteria

- [ ] Folder `tasks/01-ready` exists and contains this file.
- [ ] The "Double-Airlock" architecture is clearly documented.
- [ ] Security tests (Network Isolation, RO Access, Canary Detection) are defined.

# Definition of Done

- MCP "Double-Airlock" zones are configured and verified.
- All 3 security tests pass.
- Documentation in `docs/guides/mcp-setup.md` is accurate.
