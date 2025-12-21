# MANIFEST.CSV STRUCTURE VERIFICATION REPORT

**Date:** 2025-12-21
**Status:** ⚠️ INCONSISTENT - Requires cleanup or migration

---

## FINDINGS

### Current Manifest Status

- **File:** `manifest/manifest.csv`
- **Total rows:** 428 data rows + 1 header (429 lines total)
- **Current header:**
  `script,filepath,description,timestamp,label,kind,path,n,notes`

### Expected Structure (from manifest_row() function)

**Source:** `R/functions/reporting.R:58-69`

**Function definition:**

```r
manifest_row <- function(script, label, path, kind,
                         n = NA_integer_, notes = NA_character_) {
  tibble::tibble(
    timestamp = as.character(Sys.time()),
    script    = script,
    label     = label,
    kind      = kind,
    path      = path,
    n         = n,
    notes     = notes
  )
}
```

**Expected columns (in order):**

1. `timestamp` - ISO 8601 timestamp string
2. `script` - Script ID (e.g., "K11", "K12")
3. `label` - Artifact label (e.g., "fit_primary_ancova", "sessioninfo")
4. `kind` - Artifact type (e.g., "table_csv", "table_html", "figure_png", "sessioninfo")
5. `path` - Full file path to artifact
6. `n` - Sample size (integer, NA if not applicable)
7. `notes` - Optional notes (character, NA if none)

---

## PROBLEMS IDENTIFIED

### 1. Column Order Mismatch

**Current header order:**
`script, filepath, description, timestamp, label, kind, path, n, notes`

**Expected order (from manifest_row()):**
`timestamp, script, label, kind, path, n, notes`

**Impact:** When `append_manifest()` binds rows, column order from `manifest_row()` doesn't
match existing header order, causing data to be written to wrong columns.

### 2. Extra Legacy Columns

**Unexpected columns in current header:**

- `filepath` (column 2) - Not used by `manifest_row()`
- `description` (column 3) - Not used by `manifest_row()`

**Impact:** These columns exist for backward compatibility with old scripts but cause
confusion and data misalignment.

### 3. Mixed Data Formats

**Three different format patterns found:**

**Format A (rows 2-7, K16 old):**

- Uses: `script, filepath, description, timestamp`
- Has NA for: `label, kind, path, n, notes`
- Example: K16 frailty outputs from 2025-12-12

**Format B (rows 8-41, K13/K11 old):**

- Uses: `script, kind(?), path(?), description(?)` - COLUMNS MISALIGNED
- Data appears in wrong columns due to column order mismatch
- Example: K13 interaction models, K11 frequency tables

**Format C (rows 42+, K12/K11 new - CORRECT):**

- Uses: `script, NA, NA, timestamp, label, kind, path, n, notes`
- Correctly follows manifest_row() structure
- Example: K12/K11 outputs from 2025-12-14 onwards

---

## COLUMN MAPPING ANALYSIS

### Current header positions

| Position | Column Name  | Used by manifest_row()? |
|----------|--------------|-------------------------|
| 1        | script       | ✅ Yes (position 2)     |
| 2        | filepath     | ❌ No (legacy)          |
| 3        | description  | ❌ No (legacy)          |
| 4        | timestamp    | ✅ Yes (position 1)     |
| 5        | label        | ✅ Yes (position 3)     |
| 6        | kind         | ✅ Yes (position 4)     |
| 7        | path         | ✅ Yes (position 5)     |
| 8        | n            | ✅ Yes (position 6)     |
| 9        | notes        | ✅ Yes (position 7)     |

### Correct order for manifest_row()

| Position | Column Name  | Description                        |
|----------|--------------|-------------------------------------|
| 1        | timestamp    | ISO 8601 timestamp                 |
| 2        | script       | Script ID (K11, K12, etc.)         |
| 3        | label        | Artifact label                     |
| 4        | kind         | Artifact type                      |
| 5        | path         | Full file path                     |
| 6        | n            | Sample size (integer or NA)        |
| 7        | notes        | Optional notes (character or NA)   |

---

## RECOMMENDATIONS

### Option 1: Clean Migration (RECOMMENDED)

**Action:** Create new manifest with correct structure, archive old one.

**Steps:**

1. Backup current manifest:

   ```bash
   cp manifest/manifest.csv manifest/manifest_backup_20251221.csv
   ```

2. Create migration script to extract rows 42+ (correct format) to new manifest
3. Update header to correct column order: `timestamp,script,label,kind,path,n,notes`
4. Remove legacy columns: `filepath`, `description`
5. Archive rows 1-41 (legacy formats) to `manifest/manifest_legacy.csv`
6. Document migration in manifest/MIGRATION_LOG.md

**Pros:**

- Clean structure going forward
- All new scripts work correctly
- No code changes needed

**Cons:**

- Lose access to legacy rows 1-41 in main manifest (but archived separately)
- Requires manual migration step

### Option 2: Backward-Compatible Header Update

**Action:** Keep current header but reorder columns, update manifest_row() to match.

**Steps:**

1. Change manifest_row() to output columns in current header order
2. Map `label` → `description` or keep both
3. Map `path` → `filepath` or keep both
4. Accept redundant columns for backward compatibility

**Pros:**

- Preserves all historical data in main manifest
- No data loss

**Cons:**

- Perpetuates confusion with redundant columns
- Code becomes more complex
- Unclear which columns are authoritative

### Option 3: Fresh Start (SIMPLEST)

**Action:** Delete current manifest, start fresh with standardized K5-K16 runs.

**Steps:**

1. Archive entire current manifest to `manifest/manifest_archive_20251221.csv`
2. Delete `manifest/manifest.csv`
3. First script run will create new manifest with correct structure from manifest_row()
4. Re-run all K5-K16 scripts to populate new manifest

**Pros:**

- Cleanest solution
- Guaranteed correct structure
- No migration complexity

**Cons:**

- Lose all historical tracking (but archived)
- Requires re-running all analyses

---

## RECOMMENDED IMMEDIATE ACTION

**Use Option 1 (Clean Migration):**

1. Backup current manifest immediately
2. Extract rows 42-428 (correct format) to new clean manifest
3. Fix header to: `timestamp,script,label,kind,path,n,notes`
4. Remove columns 2-3 (filepath, description) from extracted data
5. Archive rows 1-41 as legacy reference
6. Document what was done

This preserves recent correct data while cleaning up the structure.

---

## VERIFICATION CHECKLIST

After fixing manifest structure, verify:

- ✅ Header matches manifest_row() output exactly
- ✅ Column order: timestamp, script, label, kind, path, n, notes
- ✅ No extra columns (filepath, description removed)
- ✅ All new appends from scripts work correctly
- ✅ Sample manifest row from K11 run matches expected format
- ✅ Old manifest archived with date stamp

---

## CURRENT STRUCTURE DOCUMENTATION (for reference)

**append_manifest() behavior:**

```r
append_manifest <- function(row, manifest_path) {
  stopifnot(is.data.frame(row))
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)

  if (!file.exists(manifest_path)) {
    readr::write_csv(row, manifest_path)  # Creates with manifest_row() column order
  } else {
    old <- suppressMessages(readr::read_csv(manifest_path, show_col_types = FALSE))
    out <- dplyr::bind_rows(old, row)  # Binds by column NAME, not position
    readr::write_csv(out, manifest_path)
  }
  invisible(manifest_path)
}
```

**Key insight:** `bind_rows()` matches columns by NAME, so mismatched order causes NAs
where column names don't match. This is why Format C has `NA, NA` in positions 2-3
(filepath, description don't exist in manifest_row() output).

---

## End of MANIFEST STRUCTURE REPORT
