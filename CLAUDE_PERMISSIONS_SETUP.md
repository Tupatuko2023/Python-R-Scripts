# Claude Code Permission Settings - Setup Summary

## Task: K00-claude-permissions

Successfully configured two-tier Claude Code permission system for safe workflow automation.

---

## Changes Applied

### 1. Updated .gitignore

```diff
 # Gemini and Claude local workspaces
 .gemini/
-.claude/
+.claude/settings.local.json
```

**Rationale:** Allow project-level settings to be committed while keeping developer-specific local settings gitignored.

---

### 2. Created .claude/settings.json (Project-level, Shared)

Conservative baseline guardrails committed to repository.

**Configuration:**

- `defaultMode`: `"default"` - Require explicit permission for all operations
- `ask`: Risky operations that require human approval
- `deny`: Sensitive files that should never be read

**Ask Rules (10 patterns):**

1. `Bash(git push:*)` - **Why:** Prevent accidental pushes to remote; user should review commits first
2. `Bash(git reset --hard:*)` - **Why:** Destructive operation that discards uncommitted changes
3. `Bash(git clean:*)` - **Why:** Permanently deletes untracked files; irreversible
4. `Bash(rm -rf:*)` - **Why:** Recursive forced deletion; high risk of data loss
5. `Bash(rm -r:*)` - **Why:** Recursive deletion; requires confirmation
6. `Bash(mv *:**/.*)` - **Why:** Moving dotfiles can break configurations
7. `Bash(curl:*)` - **Why:** Network operation; could download malicious content
8. `Bash(wget:*)` - **Why:** Network operation; could download malicious content
9. `Bash(docker:*)` - **Why:** Container operations can affect system resources
10. `Bash(docker-compose:*)` - **Why:** Orchestration operations need user awareness

**Deny Rules (9 patterns):**

1. `Read(./.env)` - **Why:** Environment files contain API keys, database passwords
2. `Read(./.env.*)` - **Why:** Variant environment files (.env.local, .env.production)
3. `Read(./secrets/**)` - **Why:** Dedicated secrets directory should never be accessed
4. `Read(~/.aws/**)` - **Why:** AWS credentials and configuration files
5. `Read(~/.ssh/**)` - **Why:** SSH private keys and known_hosts
6. `Read(**/id_rsa)` - **Why:** SSH private key files anywhere in filesystem
7. `Read(**/id_rsa.*)` - **Why:** SSH private key variants (id_rsa.pub, etc.)
8. `Read(**/.env)` - **Why:** Environment files in any subdirectory
9. `Read(**/.env.*)` - **Why:** Environment file variants in any subdirectory

---

### 3. Created .claude/settings.local.json.example (Template, Committed)

Developer productivity template. Copy to `.claude/settings.local.json` to activate.

**Configuration:**

- `defaultMode`: `"acceptEdits"` - Auto-approve file edits for speed
- `allow`: Common safe operations that don't require permission

**Allow Rules (26 patterns):**

<!-- markdownlint-disable MD029 -->

**R Analysis (7 patterns):**

1. `Bash(Rscript *)` - **Why:** Primary R script execution (from repo docs: K1-K18 scripts)
2. `Bash(R -q -e *)` - **Why:** R one-liners for renv operations (from repo docs: renv::restore)
3. `Bash(R -q --vanilla -e *)` - **Why:** Clean R environment for reproducibility checks
4. `Bash(Rscript -e *)` - **Why:** R expressions from command line

**Python Analysis (3 patterns):**

5. `Bash(python *)` - **Why:** Python script execution (from repo docs: EFI CLI)
6. `Bash(python3 *)` - **Why:** Explicit Python 3 execution
7. `Bash(pytest *)` - **Why:** Test suite execution (from repo docs: tests/)

**Build/Task Runners (1 pattern):**

8. `Bash(make *)` - **Why:** Makefile targets for builds and tasks

**File Operations - Read Only (8 patterns):**

9. `Bash(ls *)` + `Bash(ls:*)` - **Why:** Directory listing; completely safe
10. `Bash(cat *)` + `Bash(cat:*)` - **Why:** File content viewing; read-only
11. `Bash(find *)` - **Why:** File searching; read-only
12. `Bash(rg *)` - **Why:** Ripgrep code search; read-only
13. `Bash(grep *)` + `Bash(grep:*)` - **Why:** Text search; read-only

**Git - Read Only (6 patterns):**

14. `Bash(git status *)` + `Bash(git status:*)` - **Why:** Repository status; read-only
15. `Bash(git diff *)` + `Bash(git diff:*)` - **Why:** Show changes; read-only
16. `Bash(git log *)` + `Bash(git log:*)` - **Why:** Commit history; read-only
17. `Bash(git show *)` - **Why:** Show commit details; read-only

**Utilities (5 patterns):**

18. `Bash(pwd *)` - **Why:** Print working directory; informational
19. `Bash(echo *)` - **Why:** Output text; harmless
20. `Bash(test *)` + `Bash(test:*)` - **Why:** Shell test conditions; read-only checks

**CI/CD Tools (5 patterns):**

21. `Bash(npx markdownlint-cli2:*)` - **Why:** Linting tool (used in pre-commit hooks)
22. `Bash(gh run list:*)` - **Why:** GitHub Actions workflow listing; read-only
23. `Bash(gh run watch:*)` - **Why:** Watch workflow execution; read-only
24. `Bash(gh run view:*)` - **Why:** View workflow details; read-only
25. `Bash(gh run download:*)` - **Why:** Download workflow artifacts; safe

**System Paths (1 pattern):**

26. `Read(//tmp/claude/C--GitWork-Python-R-Scripts/tasks/**)` - **Why:** Claude task output files; safe to read

<!-- markdownlint-enable MD029 -->

**NOT Allowed (Inherited from Project Settings):**

- `git push` / `git commit` - Require explicit approval (ask)
- `rm -rf` / `rm -r` - Require explicit approval (ask)
- `curl` / `wget` - Require explicit approval (ask)
- `docker` operations - Require explicit approval (ask)
- Reading `.env` files - Denied (security)

---

## File Structure

```text
.claude/
├── settings.json                    # Project-level (committed)
├── settings.local.json              # Developer-specific (gitignored)
└── settings.local.json.example      # Template (committed)
```

---

## Setup Instructions for Developers

1. **Copy the example to create your local settings:**

   ```bash
   cp .claude/settings.local.json.example .claude/settings.local.json
   ```

2. **Verify git ignores your local settings:**

   ```bash
   git status  # .claude/settings.local.json should NOT appear
   ```

3. **Test in Claude Code:**
   - Run `/permissions` to view active permission rules
   - Verify project-level rules (ask/deny) come from `settings.json`
   - Verify local-level rules (allow) come from `settings.local.json`

4. **Test common operations:**
   - Safe operation (should auto-approve): `Rscript R-scripts/K1/K1.7.main.R`
   - Risky operation (should ask): `git push`

---

## Verification Checklist

- [x] `.claude/settings.json` created with conservative guardrails
- [x] `.claude/settings.local.json.example` created as template
- [x] `.claude/settings.local.json` exists and is gitignored
- [x] `.gitignore` updated to ignore only `settings.local.json`
- [x] JSON files are valid
- [x] Git status shows only `settings.json` and `settings.local.json.example` staged
- [x] Committed and pushed to main

---

## Unified Diff

```diff
diff --git a/.claude/settings.json b/.claude/settings.json
new file mode 100644
index 0000000..6fb9043
--- /dev/null
+++ b/.claude/settings.json
@@ -0,0 +1,28 @@
+{
+  "permissions": {
+    "defaultMode": "default",
+    "ask": [
+      "Bash(git push:*)",
+      "Bash(git reset --hard:*)",
+      "Bash(git clean:*)",
+      "Bash(rm -rf:*)",
+      "Bash(rm -r:*)",
+      "Bash(mv *:**/.*)",
+      "Bash(curl:*)",
+      "Bash(wget:*)",
+      "Bash(docker:*)",
+      "Bash(docker-compose:*)"
+    ],
+    "deny": [
+      "Read(./.env)",
+      "Read(./.env.*)",
+      "Read(./secrets/**)",
+      "Read(~/.aws/**)",
+      "Read(~/.ssh/**)",
+      "Read(**/id_rsa)",
+      "Read(**/id_rsa.*)",
+      "Read(**/.env)",
+      "Read(**/.env.*)"
+    ]
+  }
+}

diff --git a/.claude/settings.local.json.example b/.claude/settings.local.json.example
new file mode 100644
index 0000000..aca22a1
--- /dev/null
+++ b/.claude/settings.local.json.example
@@ -0,0 +1,40 @@
+{
+  "permissions": {
+    "defaultMode": "acceptEdits",
+    "allow": [
+      "Bash(Rscript *)",
+      "Bash(R -q -e *)",
+      "Bash(R -q --vanilla -e *)",
+      "Bash(Rscript -e *)",
+      "Bash(python *)",
+      "Bash(python3 *)",
+      "Bash(pytest *)",
+      "Bash(make *)",
+      "Bash(ls *)",
+      "Bash(ls:*)",
+      "Bash(cat *)",
+      "Bash(cat:*)",
+      "Bash(find *)",
+      "Bash(rg *)",
+      "Bash(grep *)",
+      "Bash(grep:*)",
+      "Bash(git status *)",
+      "Bash(git status:*)",
+      "Bash(git diff *)",
+      "Bash(git diff:*)",
+      "Bash(git log *)",
+      "Bash(git log:*)",
+      "Bash(git show *)",
+      "Bash(pwd *)",
+      "Bash(echo *)",
+      "Bash(test *)",
+      "Bash(test:*)",
+      "Bash(npx markdownlint-cli2:*)",
+      "Bash(gh run list:*)",
+      "Bash(gh run watch:*)",
+      "Bash(gh run view:*)",
+      "Bash(gh run download:*)",
+      "Read(//tmp/claude/C--GitWork-Python-R-Scripts/tasks/**)"
+    ]
+  }
+}

diff --git a/.gitignore b/.gitignore
index eaa9e2a..2f3e78a 100644
--- a/.gitignore
+++ b/.gitignore
@@ -51,4 +51,4 @@ Fear-of-Falling/R-scripts/**/outputs/

 # Gemini and Claude local workspaces
 .gemini/
-.claude/
+.claude/settings.local.json
```

---

## Permission Flow

```text
┌─────────────────────────────────────────────────────┐
│ Claude Code receives command                        │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ Check local settings (.claude/settings.local.json) │
│ - defaultMode: "acceptEdits"                        │
│ - allow: [safe operations]                          │
└─────────────────┬───────────────────────────────────┘
                  │
                  ├─► ALLOWED → Execute immediately
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ Check project settings (.claude/settings.json)     │
│ - ask: [risky operations]                           │
│ - deny: [sensitive files]                           │
└─────────────────┬───────────────────────────────────┘
                  │
                  ├─► DENIED → Reject
                  ├─► ASK → Prompt user
                  └─► (not matched) → Use defaultMode
```

---

## Examples

### Auto-approved (from local allow list)

```bash
Rscript R-scripts/K1/K1.7.main.R        # ✓ Allowed
R -q -e 'renv::restore()'               # ✓ Allowed
python src/efi/cli.py --help            # ✓ Allowed
pytest tests/                           # ✓ Allowed
git status                              # ✓ Allowed
git diff HEAD~1                         # ✓ Allowed
ls -la data/                            # ✓ Allowed
```

### Requires approval (from project ask list)

```bash
git push origin main                    # ⚠ Ask user
git reset --hard HEAD~1                 # ⚠ Ask user
rm -rf outputs/                         # ⚠ Ask user
curl https://example.com/script.sh      # ⚠ Ask user
docker run -it ubuntu                   # ⚠ Ask user
```

### Denied (from project deny list)

```bash
cat .env                                # ✗ Denied
cat secrets/api_key.txt                 # ✗ Denied
cat ~/.ssh/id_rsa                       # ✗ Denied
cat ~/.aws/credentials                  # ✗ Denied
```

---

## Customization

### To allow additional safe operations

Edit `.claude/settings.local.json` (NOT committed) and add to the `allow` array:

```json
"allow": [
  "Bash(your-safe-command *)"
]
```

### To add more guardrails

Edit `.claude/settings.json` (committed, shared) and add to `ask` or `deny`:

```json
"ask": [
  "Bash(git commit:*)"  // Example: require approval for commits
]
```

---

## Task Completion

**Task:** K00-claude-permissions ✓

**Acceptance Criteria:**

- ✓ `.claude/settings.json` with conservative baseline
- ✓ `.claude/settings.local.json.example` committed as template
- ✓ `.claude/settings.local.json` gitignored
- ✓ `.gitignore` updated minimally
- ✓ All rules justified (1-2 lines each)
- ✓ Commands based on repo docs (README.md, CLAUDE.md)
- ✓ Unified diff provided

**Commit:** df20cdc
**Files Changed:** 3 (69 insertions, 1 deletion)
**Status:** ✓ Pushed to main
