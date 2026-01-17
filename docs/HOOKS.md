# Repo hooks (deterministiset gates)

Tavoite: pakottaa kevyet, deterministiset tarkistukset ennen commit/push,
ja tarjota yksi "before analysis run" -gate, joka tuottaa audit trailin.

Lyhyt malli:
- git commit -> pre-commit
- git push -> pre-push
- analysis -> tools/run-gates.sh

## Asennus (per klooni)

```bash
git config core.hooksPath .githooks
```

Hookit ovat versionoituja ja ajavat `tools/*`-gateskriptit.

## Pre-commit (kevyt)

Ajaa:
- Guardrails: ei vahingossa dataa/outputs/arkistoja staged-settiin
- renv.lock sanity (ei `renv::restore` hookissa)
- R: `parse()` staged .R tiedostoille
- Python: `py_compile` staged .py tiedostoille (vain jos Python-indikaattorit löytyvät)

## Pre-push (minimal CI parity)

Ajaa:
- Guardrails + renv + smoke-tason syntax checks
- Jos `tools/run-gates.sh` löytyy: `--smoke`

## Ennen analyysiajoa (suositus)

Tämä EI ole git-hook, vaan eksplisiittinen komento:

```bash
tools/run-gates.sh --mode analysis --project Fear-of-Falling \
  --rscript "R-scripts/K05/K05.WIDE_ANCOVA.V1_main.R"
```

Tämä kirjoittaa:
- `Fear-of-Falling/manifest/run_meta_*.txt`
- `Fear-of-Falling/manifest/sessionInfo_*.txt`
- `Fear-of-Falling/manifest/renv_diagnostics_*.txt`

`--rscript` on suositeltu: jos se annetaan, skripti ajetaan. Jos ei anneta,
wrapper vain kirjaa audit-metadatan. Polku voi olla:
- project-relatiivinen (esim. `R-scripts/K05/...`, suhteessa `Fear-of-Falling/`)
- repo-root-relatiivinen (esim. `Fear-of-Falling/R-scripts/K05/...`)

## Hätäohitus (vain commit-hook)

Jos on pakko ohittaa (esim. ympäristö rikki), käytä:

```bash
SKIP=1 git commit -m "..."
```

Kirjaa syy commit-viestiin.

## Termux + PRoot Debian (deterministiset komennot)

```bash
cd ~/Python-R-Scripts
git config core.hooksPath .githooks
tools/run-gates.sh --help
tools/run-gates.sh --mode pre-push --smoke
proot-distro login debian --termux-home -- bash -lc \
  "cd ~/Python-R-Scripts/Fear-of-Falling && Rscript -q -e 'cat(capture.output(sessionInfo()), sep=\"\n\")' | head -n 20"
```
