# Legacy Figure 1 Assets

This directory archives historical Figure 1 assets that are no longer current
for Paper 01 Fear of Falling. They are retained for provenance and review only.
The canonical current family remains in `diagram/` root as
`paper_01_cohort_flow.wide_long.locomotor_capacity.*`.

## Archived Families

| Family | Original path | Legacy path | Producer | Limitation | Replacement | Task/commit | Usage status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Generic template | `diagram/paper_01_cohort_flow.dot` | `diagram/legacy/paper_01_cohort_flow.dot` | Historical shell renderer template | Parameterized helper source, not the current K50 producer | `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.dot` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `LEGACY_REFERENCE_ONLY` |
| Generic shell helper | `diagram/render_paper_01_cohort_flow.sh` | `diagram/legacy/render_paper_01_cohort_flow.sh` | Historical Graphviz shell renderer | Reads historical template and placeholders; not used by the current K50 producer | `R-scripts/K50/K50.FIG1_VISUAL_DUAL_BRANCH.V1_render.R` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `DO_NOT_RUN_FOR_CURRENT_FIGURE` |
| LONG-only resolved DOT | `diagram/paper_01_cohort_flow.long.locomotor_capacity.resolved.dot` | `diagram/legacy/paper_01_cohort_flow.long.locomotor_capacity.resolved.dot` | Historical shell renderer from generic template | LONG-only branch does not represent the current wide+long cohort flow | `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `DO_NOT_USE` |
| LONG-only SVG | `diagram/paper_01_cohort_flow.long.locomotor_capacity.svg` | `diagram/legacy/paper_01_cohort_flow.long.locomotor_capacity.svg` | Graphviz render from historical LONG resolved DOT | LONG-only branch does not represent the current wide+long cohort flow | `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.svg` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `DO_NOT_USE` |
| LONG-only PNG | `diagram/paper_01_cohort_flow.long.locomotor_capacity.png` | `diagram/legacy/paper_01_cohort_flow.long.locomotor_capacity.png` | Graphviz render from historical LONG resolved DOT | LONG-only branch does not represent the current wide+long cohort flow | `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.png` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `DO_NOT_USE` |
| WIDE-only resolved DOT | `diagram/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot` | `diagram/legacy/paper_01_cohort_flow.wide.locomotor_capacity.resolved.dot` | Historical shell renderer from generic template | WIDE-only branch is historical and is not the current Figure 1 | `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.resolved.dot` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `LEGACY_REFERENCE_ONLY` |
| WIDE-only SVG | `diagram/paper_01_cohort_flow.wide.locomotor_capacity.svg` | `diagram/legacy/paper_01_cohort_flow.wide.locomotor_capacity.svg` | Graphviz render from historical WIDE resolved DOT | Ignored/untracked local render at archive time; not a current publication asset | `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.svg` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `LEGACY_REFERENCE_ONLY_IF_PRESENT` |
| WIDE-only PNG | `diagram/paper_01_cohort_flow.wide.locomotor_capacity.png` | `diagram/legacy/paper_01_cohort_flow.wide.locomotor_capacity.png` | Graphviz render from historical WIDE resolved DOT | Ignored/untracked local render at archive time; not a current publication asset | `diagram/paper_01_cohort_flow.wide_long.locomotor_capacity.png` | `tasks/03-review/20260721_diagram_legacy_archive_and_downstream_usage_contract.md`; commit `chore(diagram): archive legacy Figure 1 assets` | `LEGACY_REFERENCE_ONLY_IF_PRESENT` |

## Usage Rule

Do not use these archived files for current manuscript integration. Current
downstream consumers must use the `wide_long` family in `diagram/` root through
the analysis repository submodule commit.
