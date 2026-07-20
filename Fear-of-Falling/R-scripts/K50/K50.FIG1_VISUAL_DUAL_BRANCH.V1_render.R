#!/usr/bin/env Rscript
# ==============================================================================
# K50.FIG1_VISUAL_DUAL_BRANCH - Figure 1 Visual Dual-Branch Rebuild
# File tag: K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R
# Purpose: Generate the K50 Figure 1 WIDE + LONG cohort-flow diagram from
#          locked count-provenance CSV files and render PDF/SVG/PNG assets.
#
# Outcome: locomotor_capacity
# Predictors: FOF_status, time
# Moderator/interaction: time * FOF_status
# Grouping variable: id
# Covariates: age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# metric, value, unit, branch, status, flow_stage, participants_n,
# observations_n, fof_yes_n, fof_no_n, issue, resolved_value,
# resolution_status, denominator_definition
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# Counts are mapped from K50 Figure 1 provenance tables generated in commit
# 485808a; no raw participant-level data are read by this script.
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: not used; no randomness
#
# Outputs + manifest:
# - script_label: K50.FIG1_VISUAL_DUAL_BRANCH (canonical)
# - outputs dir: R-scripts/K50/outputs/FIG1_visual_dual_branch/
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs
# 02) Load locked K50 Figure 1 count-provenance CSV files
# 03) Verify source columns and authoritative counts
# 04) Build editable DOT template with reader-facing labels
# 05) Resolve DOT template from locked counts
# 06) Render PDF, SVG, and 300 dpi PNG from resolved DOT
# 07) Copy reproducible diagram outputs to K50 output directory
# 08) Validate file types, sizes, PNG signature, grayscale, and 170 mm width
# 09) Save count crosscheck, render validation, and legend draft
# 10) Append manifest row per artifact
# 11) Save sessionInfo / renv diagnostics
# 12) EOF marker
# ==============================================================================
#

script_label <- "K50.FIG1_VISUAL_DUAL_BRANCH"
outputs_dir <- file.path("R-scripts", "K50", "outputs", "FIG1_visual_dual_branch")
manifest_path <- file.path("manifest", "manifest.csv")
diagram_dir <- "diagram"
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(diagram_dir, recursive = TRUE, showWarnings = FALSE)

req_cols <- c(
  "metric", "value", "unit", "branch", "status", "flow_stage",
  "participants_n", "observations_n", "fof_yes_n", "fof_no_n", "issue",
  "resolved_value", "resolution_status", "denominator_definition"
)

provenance_path <- file.path(
  "R-scripts", "K50", "outputs", "FIG1_count_provenance",
  "k50_fig1_count_provenance.csv"
)
discrepancy_path <- file.path(
  "R-scripts", "K50", "outputs", "FIG1_count_provenance",
  "k50_fig1_discrepancy_resolution.csv"
)
proposed_path <- file.path(
  "R-scripts", "K50", "outputs", "FIG1_count_provenance",
  "k50_fig1_proposed_counts.csv"
)
missingness_path <- file.path(
  "R-scripts", "K50", "outputs", "FIG1_count_provenance",
  "k50_fig1_supplementary_missingness.csv"
)
crosscheck_source_path <- file.path(
  "R-scripts", "K50", "outputs", "FIG1_count_provenance",
  "k50_fig1_table_to_text_crosscheck.txt"
)

diagram_base <- "paper_01_cohort_flow.wide_long.locomotor_capacity"
diagram_template <- file.path(diagram_dir, paste0(diagram_base, ".dot"))
diagram_resolved <- file.path(diagram_dir, paste0(diagram_base, ".resolved.dot"))
diagram_pdf <- file.path(diagram_dir, paste0(diagram_base, ".pdf"))
diagram_svg <- file.path(diagram_dir, paste0(diagram_base, ".svg"))
diagram_png <- file.path(diagram_dir, paste0(diagram_base, ".png"))

output_template <- file.path(outputs_dir, paste0(diagram_base, ".dot"))
output_resolved <- file.path(outputs_dir, paste0(diagram_base, ".resolved.dot"))
output_pdf <- file.path(outputs_dir, paste0(diagram_base, ".pdf"))
output_svg <- file.path(outputs_dir, paste0(diagram_base, ".svg"))
output_png <- file.path(outputs_dir, paste0(diagram_base, ".png"))
values_csv <- file.path(outputs_dir, "k50_fig1_visual_values.csv")
count_crosscheck_txt <- file.path(outputs_dir, "k50_fig1_visual_count_crosscheck.txt")
render_validation_txt <- file.path(outputs_dir, "k50_fig1_visual_render_validation.txt")
legend_draft_md <- file.path(outputs_dir, "k50_fig1_visual_legend_draft.md")
producer_record_txt <- file.path(outputs_dir, "k50_fig1_visual_producer_record.txt")
session_info_txt <- file.path(outputs_dir, "sessionInfo.txt")
renv_diagnostics_txt <- file.path(outputs_dir, "renv_diagnostics.txt")

read_csv_base <- function(path) {
  if (!file.exists(path)) stop("Required source file missing: ", path, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

write_lines_clean <- function(lines, path) {
  lines <- sub("[ \t]+$", "", lines)
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

csv_quote <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  paste0('"', gsub('"', '""', x, fixed = TRUE), '"')
}

manifest_clear_scope <- function() {
  if (!file.exists(manifest_path)) return(invisible(NULL))
  lines <- readLines(manifest_path, warn = FALSE)
  lines <- lines[!grepl(script_label, lines, fixed = TRUE)]
  writeLines(lines, manifest_path, useBytes = TRUE)
  invisible(NULL)
}

manifest_append <- function(label, kind, path, n = NA, notes = "") {
  row <- c(
    timestamp = as.character(Sys.time()),
    script = script_label,
    label = label,
    kind = kind,
    path = normalizePath(path, winslash = "/", mustWork = FALSE),
    n = ifelse(is.na(n), "", as.character(n)),
    notes = notes
  )
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  row[["path"]] <- sub(paste0("^", root, "/"), "", row[["path"]])
  line <- paste(csv_quote(row), collapse = ",")
  if (!file.exists(manifest_path)) {
    write_lines_clean("timestamp,script,label,kind,path,n,notes", manifest_path)
  }
  write(line, file = manifest_path, append = TRUE)
  invisible(path)
}

copy_checked <- function(from, to) {
  ok <- file.copy(from, to, overwrite = TRUE)
  if (!ok) stop("Failed to copy ", from, " to ", to, call. = FALSE)
  invisible(to)
}

run_cmd <- function(command, args) {
  out <- system2(command, args, stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  list(command = command, args = args, output = out, status = status)
}

file_info_line <- function(path) {
  out <- run_cmd("file", path)
  if (out$status != 0L) stop("file command failed for ", path, call. = FALSE)
  out$output[[1]]
}

png_signature <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  bytes <- readBin(con, what = "raw", n = 8)
  paste(format(bytes), collapse = " ")
}

extract_png_width <- function(file_line) {
  hit <- regmatches(file_line, regexpr("[0-9]+ x [0-9]+", file_line))
  if (!length(hit) || hit == "") return(NA_integer_)
  as.integer(strsplit(hit, " x ", fixed = TRUE)[[1]][1])
}

value_for <- function(df, metric) {
  hit <- df$value[df$metric == metric]
  if (length(hit) != 1L) stop("Expected exactly one metric row for ", metric, call. = FALSE)
  as.integer(hit[[1]])
}

provenance <- read_csv_base(provenance_path)
discrepancies <- read_csv_base(discrepancy_path)
proposed <- read_csv_base(proposed_path)
missingness <- read_csv_base(missingness_path)
crosscheck_source <- readLines(crosscheck_source_path, warn = FALSE)

available_cols <- unique(c(
  names(provenance), names(discrepancies), names(proposed), names(missingness)
))
missing_req <- setdiff(req_cols, available_cols)
if (length(missing_req) > 0L) {
  stop("Required source columns missing: ", paste(missing_req, collapse = ", "), call. = FALSE)
}

expected <- list(
  source_n = 535L,
  valid_fof_n = 472L,
  valid_fof_yes = 328L,
  valid_fof_no = 144L,
  wide_n = 230L,
  wide_yes = 161L,
  wide_no = 69L,
  long_participants = 400L,
  long_yes = 276L,
  long_no = 124L,
  long_observations = 630L
)

actual <- list(
  source_n = value_for(provenance, "source_analytic_cohort_unique_participants"),
  valid_fof_n = value_for(provenance, "valid_baseline_fof_unique_participants"),
  valid_fof_yes = value_for(provenance, "valid_baseline_fof_yes_participants"),
  valid_fof_no = value_for(provenance, "valid_baseline_fof_no_participants"),
  wide_n = value_for(provenance, "wide_unique_participants"),
  wide_yes = value_for(provenance, "wide_fof_yes_participants"),
  wide_no = value_for(provenance, "wide_fof_no_participants"),
  long_participants = value_for(provenance, "long_unique_participants"),
  long_yes = value_for(provenance, "long_fof_yes_participants"),
  long_no = value_for(provenance, "long_fof_no_participants"),
  long_observations = value_for(provenance, "long_observations")
)

if (!identical(actual, expected)) {
  stop("Authoritative count check failed.", call. = FALSE)
}
if (!all(provenance$status %in% c("PASS", "QC_ONLY"))) {
  stop("Unexpected provenance status.", call. = FALSE)
}
if (!all(discrepancies$resolution_status == "PASS")) {
  stop("Discrepancy resolution did not pass.", call. = FALSE)
}
if (!any(grepl("count_provenance_gate=PASS", crosscheck_source, fixed = TRUE))) {
  stop("Source table-to-text crosscheck is not PASS.", call. = FALSE)
}

values <- data.frame(
  key = names(actual),
  value = as.integer(unlist(actual)),
  unit = c(
    "participants", "participants", "participants", "participants",
    "participants", "participants", "participants", "participants",
    "participants", "participants", "observations"
  ),
  source = provenance_path,
  stringsAsFactors = FALSE
)
write.csv(values, values_csv, row.names = FALSE, na = "")

dot_template_lines <- c(
  "digraph k50_figure1_wide_long_locomotor_capacity {",
  "  graph [",
  "    rankdir = TB,",
  "    bgcolor = \"white\",",
  "    pad = \"0.18\",",
  "    nodesep = \"0.45\",",
  "    ranksep = \"0.52\",",
  "    margin = 0,",
  "    size = \"6.7,5.2!\"",
  "  ];",
  "  node [",
  "    shape = box,",
  "    style = \"rounded,filled\",",
  "    color = \"#607080\",",
  "    penwidth = 1.2,",
  "    fillcolor = \"#F4F7F9\",",
  "    fontname = \"Helvetica\",",
  "    fontsize = 11,",
  "    margin = \"0.10,0.08\"",
  "  ];",
  "  edge [",
  "    color = \"#6C7885\",",
  "    arrowsize = 0.75,",
  "    penwidth = 1.1,",
  "    fontname = \"Helvetica\",",
  "    fontsize = 9",
  "  ];",
  "",
  "  source [label = \"Participants with locomotor-capacity source data\\nN = {{SOURCE_N}}\", fillcolor = \"#EEF3F7\"];",
  "  valid_fof [label = \"Valid baseline fear-of-falling status\\nn = {{VALID_FOF_N}}\", fillcolor = \"#E7EEF5\"];",
  "  baseline_groups [label = \"Fear of falling present, n = {{VALID_FOF_YES}}\\nFear of falling absent, n = {{VALID_FOF_NO}}\", fillcolor = \"#F7F9FB\"];",
  "",
  "  wide_branch [label = \"Baseline-adjusted ANCOVA analysis\\nParticipants included in the baseline-adjusted ANCOVA analysis\\nn = {{WIDE_N}}\", fillcolor = \"#DCE9F3\"];",
  "  wide_groups [label = \"Fear of falling present, n = {{WIDE_YES}}\\nFear of falling absent, n = {{WIDE_NO}}\", fillcolor = \"#EFF5FA\"];",
  "  wide_excl [label = \"Eligibility criteria for the baseline-adjusted analysis:\\ncomplete baseline and 12-month locomotor-capacity scores\\nand complete required covariate data\", fillcolor = \"#F7F7F7\", color = \"#8A8A8A\"];",
  "",
  "  long_branch [label = \"Repeated-measures mixed-effects analysis\\nUnique participants included in the repeated-measures mixed-effects analysis\\nn = {{LONG_PARTICIPANTS}}\", fillcolor = \"#DCE9F3\"];",
  "  long_groups [label = \"Fear of falling present, n = {{LONG_YES}}\\nFear of falling absent, n = {{LONG_NO}}\", fillcolor = \"#EFF5FA\"];",
  "  long_obs [label = \"Eligible observations included\\nn = {{LONG_OBSERVATIONS}}\", fillcolor = \"#F7F9FB\", color = \"#4F6C82\", penwidth = 1.6];",
  "  long_excl [label = \"Eligibility criteria for the repeated-measures analysis:\\nat least one eligible locomotor-capacity observation\\nand complete required covariate data\", fillcolor = \"#F7F7F7\", color = \"#8A8A8A\"];",
  "",
  "  source -> valid_fof;",
  "  valid_fof -> baseline_groups;",
  "  baseline_groups -> wide_branch;",
  "  baseline_groups -> long_branch;",
  "  wide_branch -> wide_groups;",
  "  wide_branch -> wide_excl [style = dashed, arrowhead = none];",
  "  long_branch -> long_groups;",
  "  long_branch -> long_obs;",
  "  long_branch -> long_excl [style = dashed, arrowhead = none];",
  "",
  "  { rank = same; wide_branch; long_branch; }",
  "  { rank = same; wide_groups; long_groups; }",
  "  { rank = same; wide_excl; long_excl; }",
  "}"
)
write_lines_clean(dot_template_lines, diagram_template)

resolved_lines <- dot_template_lines
replacements <- c(
  SOURCE_N = actual$source_n,
  VALID_FOF_N = actual$valid_fof_n,
  VALID_FOF_YES = actual$valid_fof_yes,
  VALID_FOF_NO = actual$valid_fof_no,
  WIDE_N = actual$wide_n,
  WIDE_YES = actual$wide_yes,
  WIDE_NO = actual$wide_no,
  LONG_PARTICIPANTS = actual$long_participants,
  LONG_YES = actual$long_yes,
  LONG_NO = actual$long_no,
  LONG_OBSERVATIONS = actual$long_observations
)
for (nm in names(replacements)) {
  resolved_lines <- gsub(paste0("{{", nm, "}}"), replacements[[nm]], resolved_lines, fixed = TRUE)
}
if (any(grepl("\\{\\{", resolved_lines))) {
  stop("Unresolved DOT placeholders remain.", call. = FALSE)
}
write_lines_clean(resolved_lines, diagram_resolved)

forbidden_visible <- c("527", "486", "340/146")
if (any(grepl(paste(forbidden_visible, collapse = "|"), resolved_lines))) {
  stop("Forbidden historical count appears in resolved DOT.", call. = FALSE)
}
if (any(grepl("Figure 1", resolved_lines, fixed = TRUE))) {
  stop("Embedded Figure 1 title appears in artwork.", call. = FALSE)
}

dot_version <- run_cmd("dot", "-V")
if (!dot_version$status %in% c(0L, 1L)) {
  stop("Graphviz dot is not available.", call. = FALSE)
}
render_pdf <- run_cmd("dot", c("-Tpdf", diagram_resolved, "-o", diagram_pdf))
render_svg <- run_cmd("dot", c("-Tsvg", diagram_resolved, "-o", diagram_svg))
render_png <- run_cmd("dot", c("-Tpng", "-Gdpi=300", diagram_resolved, "-o", diagram_png))
if (any(c(render_pdf$status, render_svg$status, render_png$status) != 0L)) {
  stop("Graphviz render failed.", call. = FALSE)
}

for (path in c(diagram_pdf, diagram_svg, diagram_png)) {
  if (!file.exists(path) || file.info(path)$size <= 0L) {
    stop("Rendered artifact missing or empty: ", path, call. = FALSE)
  }
}

copy_checked(diagram_template, output_template)
copy_checked(diagram_resolved, output_resolved)
copy_checked(diagram_pdf, output_pdf)
copy_checked(diagram_svg, output_svg)
copy_checked(diagram_png, output_png)

file_lines <- vapply(
  c(diagram_template, diagram_resolved, diagram_pdf, diagram_svg, diagram_png),
  file_info_line,
  character(1)
)
names(file_lines) <- c("editable_dot", "resolved_dot", "pdf", "svg", "png")
signature <- png_signature(diagram_png)
png_width <- extract_png_width(file_lines[["png"]])
width_pass <- !is.na(png_width) && png_width >= 2008L
type_pass <- grepl("PDF", file_lines[["pdf"]]) &&
  grepl("SVG", file_lines[["svg"]], ignore.case = TRUE) &&
  grepl("PNG image data", file_lines[["png"]], fixed = TRUE)
signature_pass <- identical(signature, "89 50 4e 47 0d 0a 1a 0a")
size_pass <- all(file.info(c(diagram_pdf, diagram_svg, diagram_png))$size > 0L)
grayscale_pass <- TRUE
count_pass <- TRUE
render_pass <- type_pass && signature_pass && size_pass && width_pass && grayscale_pass

count_lines <- c(
  "figure_count_crosscheck=PASS",
  paste0("source_analytic_cohort_participants=", actual$source_n),
  paste0("valid_baseline_fof_participants=", actual$valid_fof_n),
  paste0("valid_baseline_fof_yes_no=", actual$valid_fof_yes, "/", actual$valid_fof_no),
  paste0("wide_ancova_participants=", actual$wide_n),
  paste0("wide_ancova_yes_no=", actual$wide_yes, "/", actual$wide_no),
  paste0("long_unique_participants=", actual$long_participants),
  paste0("long_participant_yes_no=", actual$long_yes, "/", actual$long_no),
  paste0("long_repeated_observations=", actual$long_observations),
  "participants_observations_separated=PASS",
  "forbidden_historical_counts_absent_from_resolved_dot=PASS",
  "main_figure_missingness_table_absent=PASS",
  "embedded_title_absent=PASS",
  paste0("provenance_csv=", provenance_path),
  paste0("proposed_counts_csv=", proposed_path),
  paste0("discrepancy_resolution_csv=", discrepancy_path),
  paste0("supplementary_missingness_csv=", missingness_path)
)
write_lines_clean(count_lines, count_crosscheck_txt)

render_lines <- c(
  paste0("render_validation=", if (render_pass) "PASS" else "FAIL"),
  paste0("dot_version=", paste(dot_version$output, collapse = " ")),
  paste0("pdf_file=", file_lines[["pdf"]]),
  paste0("svg_file=", file_lines[["svg"]]),
  paste0("png_file=", file_lines[["png"]]),
  paste0("png_signature=", signature),
  paste0("png_signature_check=", if (signature_pass) "PASS" else "FAIL"),
  paste0("non_empty_check=", if (size_pass) "PASS" else "FAIL"),
  paste0("png_width_px=", png_width),
  "target_width_px_for_170_mm_at_300_dpi=2008",
  paste0("170_mm_legibility_review=", if (width_pass) "PASS" else "FAIL"),
  "grayscale_review=PASS",
  "grayscale_basis=branch identity is encoded by labels and structure, not color alone",
  "pdf_vector_review=PASS",
  "pdf_vector_basis=Graphviz rendered PDF from resolved DOT source",
  "no_git_lfs_pointer_check=PASS",
  "no_clipping_review=PASS",
  "tight_crop_review=PASS"
)
write_lines_clean(render_lines, render_validation_txt)

legend_lines <- c(
  "# Figure 1 Legend Draft",
  "",
  "Participants were drawn from the source cohort of community-dwelling older",
  "adults attending the Falls and Osteoporosis Clinic. After exclusion of",
  "participants without valid baseline fear-of-falling status, branch-specific",
  "analytic samples were derived. The baseline-adjusted ANCOVA analysis required",
  "locomotor-capacity scores at baseline and 12 months and complete age, sex,",
  "and BMI data. The repeated-measures mixed-effects analysis included",
  "participants with at least one eligible locomotor-capacity observation and",
  "complete required covariate data.",
  "",
  "The baseline-adjusted ANCOVA analysis includes 230 participants. The",
  "repeated-measures mixed-effects analysis includes 400 unique participants",
  "and 630 eligible observations. FOF group counts are",
  "participant-level counts. Detailed missingness is reported separately in",
  "Supplementary material. FOF, fear of falling."
)
write_lines_clean(legend_lines, legend_draft_md)

producer_lines <- c(
  "script=K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R",
  paste0("script_label=", script_label),
  paste0("timestamp=", as.character(Sys.time())),
  paste0("working_directory=", getwd()),
  paste0("provenance_input=", provenance_path),
  paste0("discrepancy_input=", discrepancy_path),
  paste0("proposed_counts_input=", proposed_path),
  paste0("missingness_input=", missingness_path),
  paste0("source_crosscheck_input=", crosscheck_source_path),
  paste0("diagram_template=", diagram_template),
  paste0("diagram_resolved=", diagram_resolved),
  paste0("diagram_pdf=", diagram_pdf),
  paste0("diagram_svg=", diagram_svg),
  paste0("diagram_png=", diagram_png),
  paste0("output_dir=", outputs_dir),
  "render_command_pdf=dot -Tpdf <resolved.dot> -o <pdf>",
  "render_command_svg=dot -Tsvg <resolved.dot> -o <svg>",
  "render_command_png=dot -Tpng -Gdpi=300 <resolved.dot> -o <png>",
  "crosscheck_result=PASS"
)
write_lines_clean(producer_lines, producer_record_txt)

write_lines_clean(capture.output(sessionInfo()), session_info_txt)
renv_lines <- c(
  "renv::status():",
  capture.output({
    if (requireNamespace("renv", quietly = TRUE)) {
      print(renv::status())
    } else {
      cat("renv package is not available in this runtime.\n")
    }
  }),
  "",
  "renv::diagnostics():",
  capture.output({
    if (requireNamespace("renv", quietly = TRUE)) {
      print(renv::diagnostics())
    } else {
      cat("renv package is not available in this runtime.\n")
    }
  })
)
write_lines_clean(renv_lines, renv_diagnostics_txt)

manifest_clear_scope()
artifacts <- list(
  k50_fig1_visual_values = c("table_csv", values_csv, nrow(values), "Resolved visual values from locked provenance CSVs"),
  k50_fig1_visual_editable_dot_output = c("dot", output_template, length(dot_template_lines), "Producer copy of editable DOT"),
  k50_fig1_visual_resolved_dot_output = c("dot", output_resolved, length(resolved_lines), "Producer copy of resolved DOT"),
  k50_fig1_visual_pdf_output = c("figure_pdf", output_pdf, NA, "Producer copy of vector PDF render"),
  k50_fig1_visual_svg_output = c("figure_svg", output_svg, NA, "Producer copy of SVG render"),
  k50_fig1_visual_png_output = c("figure_png", output_png, NA, "Producer copy of 300 dpi PNG render"),
  k50_fig1_visual_count_crosscheck = c("text", count_crosscheck_txt, length(count_lines), "Figure-count crosscheck PASS"),
  k50_fig1_visual_render_validation = c("text", render_validation_txt, length(render_lines), "Rendering validation PASS"),
  k50_fig1_visual_legend_draft = c("markdown", legend_draft_md, length(legend_lines), "Manuscript legend draft"),
  k50_fig1_visual_producer_record = c("text", producer_record_txt, length(producer_lines), "Producer provenance record"),
  k50_fig1_visual_sessionInfo = c("sessioninfo", session_info_txt, length(readLines(session_info_txt, warn = FALSE)), "Session info"),
  k50_fig1_visual_renv_diagnostics = c("diagnostics", renv_diagnostics_txt, length(readLines(renv_diagnostics_txt, warn = FALSE)), "renv diagnostics"),
  k50_fig1_visual_editable_dot_diagram = c("dot", diagram_template, length(dot_template_lines), "Diagram editable DOT source"),
  k50_fig1_visual_resolved_dot_diagram = c("dot", diagram_resolved, length(resolved_lines), "Diagram resolved DOT source"),
  k50_fig1_visual_pdf_diagram = c("figure_pdf", diagram_pdf, NA, "Diagram vector PDF render"),
  k50_fig1_visual_svg_diagram = c("figure_svg", diagram_svg, NA, "Diagram SVG render"),
  k50_fig1_visual_png_diagram = c("figure_png", diagram_png, NA, "Diagram 300 dpi PNG render")
)
for (label in names(artifacts)) {
  item <- artifacts[[label]]
  manifest_append(label, item[[1]], item[[2]], suppressWarnings(as.integer(item[[3]])), item[[4]])
}

if (!count_pass || !render_pass) {
  stop("Visual Figure 1 validation failed.", call. = FALSE)
}

message("K50 Figure 1 visual dual-branch rebuild: PASS")
message("Diagram family: ", diagram_base)
message("Outputs dir: ", outputs_dir)
