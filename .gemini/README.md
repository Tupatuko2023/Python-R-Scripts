# Gemini CLI Configuration for Fear-of-Falling

This directory contains the project-specific configuration for the Gemini CLI agent.

## `settings.json`

Defines the project baseline:

- **Context**: Always reads `GEMINI.md` first.
- **Auto-accept**: Safe tools (reading files, listing dirs) and specific "safe"
  shell commands (`Rscript`, `pytest`, `git status`) are auto-accepted to reduce
  noise.
- **Checkpointing**: Enabled for `/restore` capability.

## `policies/fof-policy.example.toml`

Defines the security guardrails (ported from Claude Code). Since policies are user-specific, you must install this manually.

### Installation

1. Copy the template to your global Gemini policies directory:

   ```bash
   # Windows (PowerShell)
   mkdir -Force ~/.gemini/policies
   copy .gemini/policies/fof-policy.example.toml ~/.gemini/policies/fof-policy.toml
   ```

   ```bash
   # macOS/Linux
   mkdir -p ~/.gemini/policies
   cp .gemini/policies/fof-policy.example.toml ~/.gemini/policies/fof-policy.toml
   ```

2. Verify active settings in the CLI:

   ```text
   /settings
   ```

### Behavior

- **Denied**: Reading `.env`, `secrets/`, SSH keys.
- **Ask User**: `git push`, `rm -rf`, `docker`, `curl`, etc.
- **Allowed**: Standard analysis commands (`Rscript`, `python`, `ls`, etc.).

## Troubleshooting

If you need to edit or allow a specific risky command for one session, use
`gemini --approval-mode auto_edit` or approve the specific action in the CLI
prompt.
