# Fear-of-Falling: hook-pariteetti ja audit trail

Fear-of-Falling -aliprojektissa working directory on aina:
`Python-R-Scripts/Fear-of-Falling/`. (Katso AGENTS.md)

## Miksi analyysiajo ei ole git-hook

Analyysit voivat olla hitaita ja ymparistoriippuvaisia. Siksi "before analysis run"
tehdaan eksplisiittisella wrapperilla:

```bash
cd Python-R-Scripts
tools/run-gates.sh --mode analysis --project Fear-of-Falling \
  --rscript "R-scripts/K05/K05.WIDE_ANCOVA.V1_main.R"
```

Wrapper tuottaa audit trailin `manifest/`-kansioon ennen Rscript-ajoa.
`--rscript` on suositeltu: ilman sita wrapper tekee vain metadata-ajon.
Polku voi olla project-relatiivinen tai repo-root-relatiivinen.

## Konventiot

Kxx-skriptit kayttavat `init_paths()` + `append_manifest()` -mallia useissa
refaktoroiduissa skripteissa, jolloin output discipline ja manifest paivittyvat
deterministisesti.
