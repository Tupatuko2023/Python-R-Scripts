# Final Risk Surface Summary

- Project: `Quantify-FOF-Utilization-Costs`
- Scope: `scripts/` + CLI execution paths
- Status: Post-PR #87 hardening complete
- Note: this document reflects a point-in-time posture as of PR #87 (and the subsequent hardening commit); future changes may introduce drift.

## 1. Threat Model Scope

Assessed risk surface focused on:

1. Path traversal (relative / absolute)
2. Uncontrolled filesystem writes (CLI `--out`)
3. `DATA_ROOT` containment
4. Archive / document extraction
5. Base directory leakage in error messages
6. Duplicate validation logic (inconsistent enforcement)

Not covered in this audit:

- Deserialization attacks (pickle, unsafe YAML)
- Remote code execution
- Dependency CVEs

## 2. Path Traversal Control Status

Canonical enforcement:

- All filesystem containment routes through `safe_join_path(base_dir, user_path)`.

Security properties:

- Denies absolute paths (`rel.is_absolute()`).
- Denies traversal via `..`.
- Uses `resolve(strict=False)`.
- Enforces containment via `relative_to(base)`.
- Raises `ValueError("Security Violation: Path traversal detected")`.
- Error message does not leak base directory.

Status (as of PR #87): Enforced and covered by `tests/security/test_path_traversal.py`.

Security tests:

- `tests/security/test_path_traversal.py`

## 3. CLI Output Path Hardening

Previously:

- `out_path = Path(args.out)`

Now:

- `out_path = safe_join_path(output_base, args.out)`

Applied to:

- `scripts/20_extract_pdf_pptx.py`
- `scripts/40_build_knowledge_package.py`
- `scripts/50_build_report.py`

Security impact:

- Prevents writing to arbitrary absolute paths.
- Prevents traversal outside output base.
- Keeps CLI defaults functional (relative filenames).

Status (as of PR #87): Hardened.

Behavior change:

- Absolute `--out` paths are no longer accepted (intentional hardening).

## 4. DATA_ROOT and Input Handling

Observed patterns:

- No direct `open(user_input)` usage found.
- Manifest-driven paths already pass through `safe_join_path`.
- No ZipSlip (`extractall`) patterns found in `20_extract_pdf_pptx.py`.

Observation (as of PR #87 audit): no direct `open(user_input)` patterns or archive extraction (`extractall`) usage found in `scripts/`.

Residual consideration:

- Ensure all future joins use `safe_join_path` instead of `os.path.join(data_root, ...)`.

## 5. Duplicate Validation Logic Risk

Before:

- Potential dual implementations of path validation.

Now:

- Single canonical implementation in `scripts/_io_utils.py`.
- `scripts/path_resolver.py` delegates via relative-first import with fallback.

Security benefit:

- Eliminates drift between validators.
- Guarantees consistent error semantics.

Status (as of PR #87): Resolved.

## 6. Error Message Leakage

Invariant enforced:

- No base directory exposure in raised exceptions.
- Fixed error string required by tests.

Status (as of PR #87): Verified by unit tests.

## 7. Archive / Extraction Surface

Checked:

- No `zipfile.extractall`.
- No `tarfile.extractall`.
- No unsafe member extraction patterns.

PDF handling:

- Uses file reads only.
- No path-based extraction.

Status (as of PR #87): No ZipSlip-class risk detected.

## 8. Remaining Risk Surface (Low)

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Developer forgets to use `safe_join_path` in future scripts | Medium | Medium | Add developer guideline |
| External absolute path expectations broken | Low | Low | Document CLI hardening |
| `DATA_ROOT` misuse via manual `os.path.join` | Low | Medium | Code review checklist |

Overall residual risk: Low.

## 9. Security Posture Assessment

Before PR #87:

- Output path writes were unconstrained.
- Path validation duplication possible.
- Traversal control correct but not globally enforced.

After PR #87 plus hardening:

- Centralized containment.
- CLI writes sandboxed.
- Traversal invariant tested.
- No detected bypasses in scripts layer.

Overall rating:

- Low Risk / Strong Containment Model.

## 10. Recommended Ongoing Controls

Optional but recommended:

1. Add developer rule: "All filesystem joins involving external input MUST use `safe_join_path`."
2. Add a lightweight CI check focused on `--out` handling: require CLI output paths to resolve via `safe_join_path(output_base, args.out)` (or a centralized helper enforcing equivalent behavior). Prefer tests or static checks over brittle text grep.
3. Add optional CLI test: `--out /tmp/x` raises `ValueError`.

## Final Assessment

The filesystem attack surface of `Quantify-FOF-Utilization-Costs/scripts` is now:

- Deterministic
- Centrally validated
- Containment-enforced
- Test-backed
- Non-leaky
- Review-consistent

No active path traversal or uncontrolled write vectors were identified after hardening.

## 11. ISO 27001 Control Mapping (As of PR #87/#89)

| Control | Requirement | Project Control | Evidence | Control Effectiveness (Preventive / Detective) | Residual Risk |
|---|---|---|---|---|---|
| A.8.12 Secure coding | Secure coding practices prevent common implementation vulnerabilities. | Centralized safe_join_path(base_dir, user_path) enforces filesystem containment and deterministic failure behavior. | scripts/_io_utils.py; tests/security/test_path_traversal.py | Preventive | Low |
| A.8.20 Input validation | External input is validated prior to processing or filesystem use. | CLI-provided output paths resolved via safe_join_path against defined output bases; absolute and traversal paths rejected. | scripts/20_extract_pdf_pptx.py; scripts/40_build_knowledge_package.py; scripts/50_build_report.py; PR #87 hardening commit | Preventive | Low |
| A.8.28 Secure architecture | Security controls are embedded in system design and reused consistently. | Single canonical path-containment function reused across scripts; duplicate validation logic removed/delegated. | scripts/path_resolver.py; scripts/_io_utils.py; PR #87 | Preventive | Low |
| A.8.9 Configuration management | Configuration-driven resources are handled in a controlled and consistent manner. | DATA_ROOT-derived path joins constrained through containment model for protected path construction. | scripts/path_resolver.py; docs/security.md (as of PR #87/#89) | Preventive | Low |
| A.5.1 Information security policies | Security controls are documented and maintained. | Time-bound security posture documented for filesystem attack surface and invariants. | docs/security.md; PR #89 | Detective | Low |
| A.5.8 Information security in project management | Security integrated into change management lifecycle. | Security fix (#87) and documentation refinement (#89) delivered via traceable, reviewable PR workflow. | PR #87; PR #89; repository PR history | Detective | Low |
