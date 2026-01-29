#!/usr/bin/env python3
import os
import sys
import csv
import hashlib
import re
import unicodedata
from pathlib import Path
from datetime import datetime, timezone
from collections import Counter, defaultdict

MAX_SAMPLE_ROWS = int(os.environ.get("DD_MAX_SAMPLE_ROWS", "2000"))
HEADER_SCAN_LINES = int(os.environ.get("DD_CSV_HEADER_SCAN_LINES", "20"))
SUPPORTED_EXTS = {".csv", ".tsv", ".parquet", ".feather", ".xlsx", ".xls"}


def eprint(*a, **k):
    print(*a, file=sys.stderr, **k)


def redact_root(_: Path) -> str:
    return "DATA_ROOT:<redacted>"


def sha256_prefix(path: Path, limit_bytes: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        h.update(f.read(limit_bytes))
    return h.hexdigest()


def list_files(root: Path):
    out = []
    for p in root.rglob("*"):
        if p.is_file() and (not p.name.startswith("~$")) and p.suffix.lower() in SUPPORTED_EXTS:
            out.append(p)
    return sorted(out)


def import_pandas():
    try:
        import pandas as pd
        return pd
    except Exception as ex:
        eprint(f"ERROR: pandas required: {ex}")
        sys.exit(2)

_num_re = re.compile(r"^\s*-?\d+(\.\d+)?\s*$")
_id_like_pat = re.compile(r"(sotullinen|henkilotunnus|hetu|[0-9]{6,})", re.IGNORECASE)


def is_identifier_like_name(s: str) -> bool:
    return bool(_id_like_pat.search(str(s) or ""))


def redact_relpath(rel: str):
    parts = str(rel).split("/")
    redacted_parts = []
    flag = 0
    for seg in parts:
        if is_identifier_like_name(seg):
            redacted_parts.append("[REDACTED_NAME]")
            flag = 1
        else:
            redacted_parts.append(seg)
    reason = "identifier_like_filename" if flag else ""
    return "/".join(redacted_parts), reason, flag


def redact_identifier_token(s: str) -> str:
    if is_identifier_like_name(s):
        return "[REDACTED_IDENTIFIER]"
    return str(s)


def detect_header_row_text(path: Path, sep: str) -> int:
    best_i = 0
    best_score = -1e9
    try:
        with path.open("r", encoding="utf-8", errors="replace") as f:
            reader = csv.reader(f, delimiter=sep)
            for i, row in enumerate(reader):
                if i >= HEADER_SCAN_LINES:
                    break
                if not row:
                    continue
                non_empty = sum(1 for p in row if str(p).strip())
                if non_empty <= 1:
                    continue
                numeric_like = sum(1 for p in row if _num_re.match(str(p).strip()))
                alpha_like = sum(1 for p in row if re.search(r"[A-Za-zÅÄÖåäö]", str(p)))
                score = (non_empty * 2.0) + (alpha_like * 1.0) - (numeric_like * 1.5)
                if score > best_score:
                    best_score = score
                    best_i = i
    except Exception:
        return 0
    return best_i


def load_sample(path: Path):
    pd = import_pandas()
    suf = path.suffix.lower()
    if suf in (".csv", ".tsv"):
        sep = "\t" if suf == ".tsv" else ","
        hdr = detect_header_row_text(path, sep)
        return pd.read_csv(path, sep=sep, header=hdr, nrows=MAX_SAMPLE_ROWS, low_memory=False)
    if suf == ".xlsx":
        return pd.read_excel(path, sheet_name=0, nrows=MAX_SAMPLE_ROWS)
    if suf == ".xls":
        return pd.read_excel(path, sheet_name=0, nrows=MAX_SAMPLE_ROWS, engine="xlrd")
    if suf == ".parquet":
        df = pd.read_parquet(path)
        return df.head(MAX_SAMPLE_ROWS) if len(df) > MAX_SAMPLE_ROWS else df
    if suf == ".feather":
        df = pd.read_feather(path)
        return df.head(MAX_SAMPLE_ROWS) if len(df) > MAX_SAMPLE_ROWS else df
    raise ValueError("unsupported")


def safe_nunique(series):
    try:
        return int(series.nunique(dropna=True))
    except Exception:
        return ""


def role_guess(name: str) -> str:
    c = name.lower()
    if "henkilotunnus" in c or "hetu" in c:
        return "identifier"
    if c == "id" or c.endswith("_id") or "person_id" in c or "patient_id" in c:
        return "identifier"
    if "date" in c or c.endswith("_dt") or c.endswith("_date") or "pvm" in c or "paiv" in c:
        return "date"
    if "cost" in c or c.endswith("_eur") or c.endswith("euro") or "kustann" in c:
        return "cost"
    if "visit" in c or "inpatient" in c or "outpatient" in c or "emergency" in c or c.startswith("util") or "kaynt" in c:
        return "utilization"
    if c in ("sex", "gender", "age", "birth_year", "yob", "ika", "sukupuoli"):
        return "demographic"
    if "fof" in c or "fear" in c or "fall" in c or "kaatu" in c:
        return "fof"
    return ""


def normalize_ascii(s: str) -> str:
    s2 = unicodedata.normalize("NFKD", s)
    s2 = "".join(ch for ch in s2 if not unicodedata.combining(ch))
    return s2


def tokenize(name: str):
    n = normalize_ascii(name)
    n = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", n)
    n = re.sub(r"[^A-Za-z0-9_]+", "_", n)
    n = re.sub(r"_+", "_", n).strip("_").lower()
    if not n:
        return []
    return [t for t in n.split("_") if t]


_FI_EN = {
    "henkilotunnus": "personal_identity_code",
    "hetu": "personal_identity_code",
    "ika": "age",
    "vuosi": "year",
    "vuodet": "years",
    "synt": "birth",
    "syntym": "birth",
    "sukupuoli": "sex",
    "mies": "male",
    "nainen": "female",
    "pvm": "date",
    "paiva": "date",
    "paivamaara": "date",
    "kaynti": "visit",
    "kaynt": "visit",
    "kayntipvm": "visit_date",
    "kuolin": "death",
    "kuolinpvm": "death_date",
    "alku": "start",
    "loppu": "end",
    "kustannus": "cost",
    "kustannukset": "costs",
    "euro": "eur",
    "eur": "eur",
    "kaynti": "visit",
    "kaynnit": "visits",
    "hoito": "care",
    "osasto": "inpatient",
    "poliklinikka": "outpatient",
    "diagnoosi": "diagnosis",
    "icd": "icd",
    "toimenpide": "procedure",
    "verrokki": "control",
    "tutkimus": "study",
    "henkilo": "person",
    "potilas": "patient",
    "kaatuminen": "fall",
    "kaatumiset": "falls",
}


def translate_tokens_to_en(tokens):
    out = []
    for t in tokens:
        mapped = _FI_EN.get(t, t)
        out.extend(mapped.split("_"))
    return [t for t in out if t]


def make_variable_en(name: str) -> str:
    toks = translate_tokens_to_en(tokenize(name))
    if toks:
        return "_".join(toks)
    return normalize_ascii(name).strip().lower().replace(" ", "_")


def make_standard_name_en(name: str, role: str) -> str:
    base = make_variable_en(name)
    if not base:
        base = normalize_ascii(name).strip().lower().replace(" ", "_")
    if role == "date" and not base.endswith("_date"):
        if "date" not in base.split("_"):
            base = f"{base}_date"
    if role == "cost" and not base.endswith("_eur"):
        if "eur" not in base.split("_"):
            base = f"{base}_eur"
    return base


def infer_description_en(name: str, role: str) -> str:
    prefix = "Inferred from name/role: "
    v = name.lower()
    if name == "FILE_UNREADABLE" or "file_unreadable" in v:
        return prefix + "Source file could not be read; variable list unavailable."
    if "henkilotunnus" in v or "hetu" in v:
        return prefix + "Direct personal identity code (sensitive). Must be excluded from repo outputs; use pseudonymized linkage id instead."
    if role == "identifier":
        return prefix + "Pseudonymized person identifier used for linkage."
    if role == "date":
        return prefix + "Event or reference date."
    if role == "cost":
        return prefix + "Cost amount in euros for the defined period/component."
    if role == "utilization":
        return prefix + "Healthcare utilization metric (count/days/episodes) for the defined period."
    if role == "demographic":
        if "age" in v or "ika" in v:
            return prefix + "Age (years) at baseline/index date."
        if "sex" in v or "gender" in v or "sukupuoli" in v:
            return prefix + "Sex/gender category."
        return prefix + "Demographic attribute."
    if role == "fof":
        return prefix + "Fear of falling (FOF) measure or derived indicator."
    if "icd" in v or "diagno" in v:
        return prefix + "Diagnosis code (likely ICD) or derived comorbidity flag."
    if "proc" in v or "toimenpide" in v:
        return prefix + "Procedure code or derived indicator."
    return prefix + "Variable requiring domain confirmation."


def main():
    data_root = os.environ.get("DATA_ROOT", "")
    if not data_root:
        eprint("BLOCKED: DATA_ROOT missing.")
        sys.exit(2)
    root = Path(data_root)
    if not root.exists() or not root.is_dir():
        eprint(f"BLOCKED: DATA_ROOT invalid: {root}")
        sys.exit(2)

    files = list_files(root)
    if not files:
        eprint("ERROR: no supported files under DATA_ROOT.")
        sys.exit(3)

    rows = []
    unreadable = []
    for f in files:
        rel = str(f.relative_to(root))
        rel_redacted, red_reason, red_flag = redact_relpath(rel)
        sha_prefix = sha256_prefix(f)
        try:
            df = load_sample(f)
        except Exception as ex:
            tag = "UNREADABLE"
            if "kopio" in rel.lower():
                tag = "UNREADABLE/COPY/PASSWORD-PROTECTED"
            reason = f"{type(ex).__name__}: {ex}"
            unreadable.append({"rel": rel_redacted, "reason": reason, "tag": tag})
            rows.append({
                "source_dataset": rel_redacted,
                "source_dataset_redacted": rel_redacted,
                "source_name_redaction_reason": red_reason,
                "identifier_like_filename": red_flag,
                "source_file_sha256_prefix1mb": sha_prefix,
                "variable": "FILE_UNREADABLE",
                "dtype": "",
                "role_guess": "",
                "missing_rate_sample": "",
                "nunique_sample": "",
                "variable_en": "",
                "standard_name_en": "",
                "description_en": "Inferred from name/role: Source file could not be read; variable list unavailable.",
                "description_fi": "",
                "units": "",
                "coding": "",
                "notes": tag,
            })
            eprint(f"WARNING: cannot read {rel}: {ex}")
            continue
        n = len(df)
        for col in df.columns:
            s = df[col]
            col_raw = str(col)
            col_out = redact_identifier_token(col_raw)
            rg = role_guess(col_raw)
            var_en = make_variable_en(col_raw)
            std_en = make_standard_name_en(col_raw, rg)
            notes = ""
            if "henkilotunnus" in col_raw.lower() or "hetu" in col_raw.lower():
                notes = "DIRECT_IDENTIFIER; must_not_be_used_in_repo_outputs"
            rows.append({
                "source_dataset": rel_redacted,
                "source_dataset_redacted": rel_redacted,
                "source_name_redaction_reason": red_reason,
                "identifier_like_filename": red_flag,
                "source_file_sha256_prefix1mb": sha_prefix,
                "variable": col_out,
                "dtype": str(getattr(s, "dtype", "")),
                "role_guess": rg,
                "missing_rate_sample": round(float(s.isna().mean()) if n else 0.0, 6),
                "nunique_sample": safe_nunique(s),
                "variable_en": var_en or normalize_ascii(col_raw).strip().lower().replace(" ", "_"),
                "standard_name_en": std_en or normalize_ascii(col_raw).strip().lower().replace(" ", "_"),
                "description_en": infer_description_en(col_raw, rg),
                "description_fi": "",
                "units": "",
                "coding": "",
                "notes": notes,
            })

    if not rows:
        eprint("ERROR: no readable schemas.")
        sys.exit(4)

    out_csv = Path("data/data_dictionary.csv")
    out_md = Path("data/Muuttujasanakirja.md")
    out_std_csv = Path("data/VARIABLE_STANDARDIZATION.csv")
    out_std_md = Path("data/VARIABLE_STANDARDIZATION.md")
    out_csv.parent.mkdir(parents=True, exist_ok=True)

    fieldnames = [
        "source_dataset",
        "source_dataset_redacted",
        "source_name_redaction_reason",
        "identifier_like_filename",
        "source_file_sha256_prefix1mb",
        "variable",
        "dtype",
        "role_guess",
        "missing_rate_sample",
        "nunique_sample",
        "variable_en",
        "standard_name_en",
        "description_en",
        "description_fi",
        "units",
        "coding",
        "notes",
    ]

    with out_csv.open("w", newline="", encoding="utf-8") as fp:
        w = csv.DictWriter(fp, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow(r)

    std_rows = []
    for r in rows:
        var_orig = r.get("variable", "")
        var_en = (r.get("variable_en", "") or normalize_ascii(var_orig).strip().lower().replace(" ", "_"))
        std_en = (r.get("standard_name_en", "") or var_en)
        desc_en = (r.get("description_en", "") or infer_description_en(var_orig, r.get("role_guess", "")))
        std_rows.append({
            "source_dataset": r["source_dataset"],
            "variable_original": var_orig,
            "variable_en": var_en,
            "standard_name_en": std_en,
            "role_guess": r.get("role_guess", ""),
            "dtype_example": r.get("dtype", ""),
            "description_en": desc_en,
            "notes": r.get("notes", ""),
        })

    with out_std_csv.open("w", newline="", encoding="utf-8") as fp:
        w = csv.DictWriter(fp, fieldnames=list(std_rows[0].keys()))
        w.writeheader()
        for r in std_rows:
            w.writerow(r)

    by_src = defaultdict(int)
    for r in rows:
        if r["variable"] != "FILE_UNREADABLE":
            by_src[r["source_dataset"]] += 1

    lines = []
    lines.append("# Muuttujasanakirja (DATA_ROOTista generoitu, metadata-only)")
    lines.append("")
    lines.append(f"**Lähde**: {redact_root(root)}")
    lines.append(f"**Generoitu**: {datetime.now(timezone.utc).isoformat()}")
    lines.append("")
    lines.append("## Option B -rajaus")
    lines.append("- Ei raakadataa, ei yksilötason arvoja repoon")
    lines.append("- Vain skeema + turvalliset aggregaatit (puuttuvuus% ja uniikit otoksesta)")
    lines.append("")
    lines.append("## Standardointi (englanti)")
    lines.append("- `data/VARIABLE_STANDARDIZATION.csv`: muuttujien englanninkieliset standardinimet + heuristiset selitteet")
    lines.append("- `data/VARIABLE_STANDARDIZATION.md`: standardisointisäännöt ja yhteenveto")
    lines.append("")
    lines.append("## DATA_ROOT tiedostot (redacted relpath + metadata)")
    for f in files:
        rel = str(f.relative_to(root))
        rel_redacted, red_reason, red_flag = redact_relpath(rel)
        try:
            st = f.stat()
            lines.append(
                f"- `{rel_redacted}` (bytes={st.st_size}, mtime_utc={datetime.fromtimestamp(st.st_mtime, timezone.utc).isoformat()}, "
                f"sha256_prefix1mb={sha256_prefix(f)}, identifier_like_filename={red_flag}, redaction_reason={red_reason})"
            )
        except Exception:
            lines.append(f"- `{rel_redacted}` (identifier_like_filename={red_flag}, redaction_reason={red_reason})")
    if unreadable:
        lines.append("")
        lines.append("## Lukukelvottomat tiedostot (metadata-only)")
        for item in unreadable:
            lines.append(f"- `{item['rel']}`: {item['tag']} ({item['reason']})")
    lines.append("")
    lines.append("## Tiivistelmä per lähdedatasetti")
    for src, cnt in sorted(by_src.items()):
        lines.append(f"### {src}")
        lines.append(f"- Muuttujia: {cnt}")
        lines.append(f"- Otos: enintään {MAX_SAMPLE_ROWS} riviä (vain puuttuvuus/uniikit)")
        lines.append("")
    out_md.write_text("\n".join(lines), encoding="utf-8")

    role_counts = Counter([r.get("role_guess", "") for r in std_rows if r.get("role_guess", "")])
    total_std = len(std_rows)

    md2 = []
    md2.append("# VARIABLE_STANDARDIZATION (metadata-only)")
    md2.append("")
    md2.append("## Purpose")
    md2.append("Provide an English-standard naming layer and short, safe, **heuristic** descriptions for variables discovered from DATA_ROOT (Option B).")
    md2.append("Descriptions are inferred from variable names and role_guess only; they must be confirmed by domain owners before publication.")
    md2.append("")
    md2.append("## Artifacts")
    md2.append("- `data/data_dictionary.csv`: per-source schema + safe aggregates + inferred English columns")
    md2.append("- `data/VARIABLE_STANDARDIZATION.csv`: mapping table (original -> English/standard) + inferred descriptions")
    md2.append("")
    md2.append("## Naming rules (English standard)")
    md2.append("- Use `snake_case`")
    md2.append("- Add units as suffix where obvious: `_eur`, `_days`, `_count`")
    md2.append("- Dates end with `_date` when role_guess indicates a date")
    md2.append("- Identifiers are treated as strings (pseudonymized)")
    md2.append("")
    md2.append("## Direct identifiers")
    md2.append("- Variables indicating direct personal identity codes are tagged in notes as DIRECT_IDENTIFIER and must not be used in repo outputs.")
    md2.append("")
    md2.append("## Filename redaction (Option B)")
    md2.append("- Source filenames containing identifier-like tokens are redacted in outputs.")
    md2.append("- `identifier_like_filename=1` marks redacted filenames; use sha256_prefix1mb for deterministic linkage.")
    md2.append("")
    md2.append("## Role summary (from role_guess heuristics)")
    md2.append(f"- Total variables in mapping: {total_std}")
    for k, v in sorted(role_counts.items()):
        md2.append(f"- {k}: {v}")
    md2.append("")
    if unreadable:
        md2.append("## Unreadable sources")
        md2.append("Some files could not be read (e.g., password-protected copies). These are recorded as `FILE_UNREADABLE` and excluded from variable-level mapping.")
        for item in unreadable:
            md2.append(f"- `{item['rel']}`: {item['tag']} ({item['reason']})")
        md2.append("")
    md2.append("## How to use")
    md2.append("1) Start from `VARIABLE_STANDARDIZATION.csv` to see the proposed English standard names and inferred descriptions.")
    md2.append("2) Confirm/replace `description_en` (and optionally fill `description_fi`) in a separate governance step if needed.")
    md2.append("3) Keep Option B: never add participant-level examples or raw values to repo artifacts.")
    md2.append("")
    out_std_md.write_text("\n".join(md2), encoding="utf-8")

    def report_csv(path: Path):
        with path.open("r", encoding="utf-8") as fp:
            header = fp.readline().strip()
            rows_count = sum(1 for _ in fp)
        print(f"WROTE: {path.resolve()} rows={rows_count} header={header}")

    def report_md(path: Path):
        print(f"WROTE: {path.resolve()}")

    report_csv(out_csv)
    report_csv(out_std_csv)
    report_md(out_md)
    report_md(out_std_md)


if __name__ == "__main__":
    main()
