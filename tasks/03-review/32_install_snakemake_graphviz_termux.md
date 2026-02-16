# Task: Install Snakemake and Graphviz on Termux (Android)

## Goal
- `dot -V` toimii
- `snakemake --version` toimii
- Demo workflow generoi `dag.png`

## Constraints
- Android + Termux
- No root
- `pkg/apt` ensisijainen
- `pip` fallback mahdollinen
- Polut `$PREFIX` tai `~/`

## Plan
1. Update + toolchain
2. Install Graphviz
3. Verify dot
4. Install Snakemake
5. Verify snakemake
6. Demo + DAG generation
7. Fallback only if needed
