
## Conflict Resolution Protocol

1. **Always Diff**: Before resolving conflicts, explicitly show the difference (lines added/removed) between local and remote versions.
2. **No Data Loss**: Never silently discard remote changes without explicit justification. Prefer UNION (merge) operations for data files.
3. **Schema Adaptation**: If schemas differ, map remote columns to the local schema rather than overwriting the file.
