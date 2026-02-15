# TASK: Standardize script paths in Snakefile (RDIR/PYDIR) + spaces-safe shell template

## STATUS
- State: 02-in-progress

## OBJECTIVE
- Add RDIR/PYDIR path variables based on workflow.basedir.
- Update models-rule to reference R scripts via RDIR.
- Apply consistent quoting/log redirection pattern to shell commands (spaces-safe).

## DEFINITION OF DONE
- Snakefile has BASE/PROJ/RDIR/PYDIR variables (no absolute path printing).
- models-rule uses RDIR.
- Shell lines use consistent quoting for paths/OUTPUT_DIR/logs.
- Rebase + push + remote verify.
- Task moved to 03-review (not 04-done).

## LOG
- 2026-02-15T14:46:24.9718445+02:00 Created task and moved to 02-in-progress.
- 2026-02-15T14:47:24.0492204+02:00 Added BASE/PROJ/RDIR/PYDIR path variables and standardized shell script-path usage in Snakefile.
