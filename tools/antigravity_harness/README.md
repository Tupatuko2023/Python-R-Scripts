# Antigravity Harness — synteettinen tiedostopohjainen lähdehaku (`WP-HARNESS-SYNTH-FILE-SEARCH-01`)

Tämä paketti toteuttaa `PRJ-ANTIGRAVITY-HARNESS`-projektin ensimmäisen varsinaisen työpaketin (`WP-HARNESS-SYNTH-FILE-SEARCH-01`): toistettavan, täysin synteettisen tiedostopohjaisen lähdehakukokeen ja sen mekaanisen jälkiarvioijan ilman suojattua tutkimusaineistoa.

## Rakenne ja turvarajat

- `tools/antigravity_harness/synth_file_search_fixture.py`: luo deterministisen synteettisen työtilan repon ulkopuoliseen väliaikaishakemistoon (`--workspace-dir`) ja tallettaa ennakkoon lukitun vastausavaimen (`expected_answer_key.json`), lähtötason kehotteen (`prompt_baseline_b.txt`) sekä istuntokohtaisen lupamäärityksen (`cli_settings.json`) erilliseen arviointikansioon (`--eval-dir`). Kieltäytyy ajosta, jos kansiot menevät päällekkäin tai jos työtila osoittaa repon sisälle.
- `tools/antigravity_harness/tests/test_synth_file_search_fixture.py`: yksikkötestit deterministiselle generoinnille, hakemistoeristykselle, `cli_settings.json`-säännöille ja `stream-json`-arvioinnille.
- `tools/antigravity_harness/outputs/`: Git-ignoroitu (`**/outputs/`) tuloshakemisto ajokohtaisille vastausavaimille, `stream-json`-tapahtumavirroille ja arviointiraporteille.

## Toistettava ajo-ohje (toinen istunto)

Aja valmistelevat ja arvioivat Python-komennot repon työpuun juuresta ja itse `agy`-istunto repon ulkopuolisesta synteettisestä työtilasta. **Älä käytä `--dangerously-skip-permissions`-lippua**, sillä se ohittaa `cli_settings.json`-tiedoston `permissions.deny`-estot:

```bash
REPO_DIR="$(pwd)"
RUN_ID="synth_run_$(date -u +%Y%m%dT%H%M%SZ)"
WS_DIR="${TMPDIR:-/tmp}/wp_harness_ws_${RUN_ID}"
OUT_DIR="${REPO_DIR}/tools/antigravity_harness/outputs/${RUN_ID}"

# 1) Generoi synteettinen työtila (repon ulkopuolelle) ja lukitse vastausavain + cli_settings.json
python tools/antigravity_harness/synth_file_search_fixture.py materialize \
  --workspace-dir "${WS_DIR}" \
  --eval-dir "${OUT_DIR}/eval"

# 2) Aja tuore Antigravity CLI -istunto synteettisessä työtilassa vain luku-/hakutyökaluilla
PROMPT_TEXT="$(cat "${OUT_DIR}/eval/prompt_baseline_b.txt")"
(
  cd "${WS_DIR}" && \
  agy --model gemini-4-carbon-medium \
    --effort medium \
    --disable-slash-commands \
    --output-format stream-json \
    --settings="${OUT_DIR}/eval/cli_settings.json" \
    --print="${PROMPT_TEXT}" > "${OUT_DIR}/session_stream.jsonl"
)

# 3) Arvioi tapahtumavirta ja vastaus ennakkoon lukittua vastausavainta vasten
python tools/antigravity_harness/synth_file_search_fixture.py evaluate \
  --eval-dir "${OUT_DIR}/eval" \
  --stream-jsonl "${OUT_DIR}/session_stream.jsonl" \
  --report-json "${OUT_DIR}/evaluation_report.json" \
  --report-md "${OUT_DIR}/evaluation_report.md"
```

## Ensimmäisen vaiheen onnistumiskriteeri ja tunnetut rajoitteet

1. **Ensimmäinen onnistumiskriteeri (`primary_criterion_pass`):** tuore CLI-istunto lukee synteettisen työtilan tiedostoja (`workspace_read_count > 0`) ilman kiellettyjä työkaluja tai työtilan ulkopuolisia datapolkuja (`workspace_isolated == True`), erottaa oikean lähdetiedoston `runs/20261119_model_s2_primary/model_estimates.tsv` kolmesta harhautustiedostosta ja osoittaa kohderivin täsmällisellä viitteellä (`rivi 4` / `L4`, arvot `1.4204`, `1.1102`, `1.8173`, `0.0052`).
2. **Empiiriset alustarajoitteet (`agy` `1.5.14`):**
   - `agy` `1.5.14` ei sisällä natiivia hakemistolistaustyökalua, joten hakemistojen selaus sallitaan `cli_settings.json`-tiedostossa vain lukuoikeuksisille `mcp(filesystem/directory_tree|list_directory|search_files)`-kutsuille samalla kun `command(*)`, `write_file(*)`, `read_url(*)` ja kaikki muut MCP-palvelimet estetään teknisesti.
   - Lippu `--dangerously-skip-permissions` ohittaa `permissions.deny`-säännöt kokonaan, joten sitä ei saa käyttää eristetyissä ajoissa.
   - Empiirisen savutestin perusteella `read_file(<polku>/**)`-estosääntö `permissions.deny`-listassa **ei** estä natiivia `read_file`-työkalua lukemasta nimettyä paikallista polkua. Siksi vastausavain on pidettävä työtilan ulkopuolisessa, kehotteessa nimeämättömässä polussa, kokeessa ei saa olla suojattua tutkimusaineistoa samalla käyttäjätunnuksella ja jokainen `read_file`-kutsu on tarkistettava jälkikäteen `stream-json`-tapahtumavirrasta (`outside_workspace_paths == []`).
3. **Seuraava vaihe:** kun tämä tiedostopohjainen lähtötaso toimii ja toinen istunto pystyy toistamaan sen, saman synteettisen työtilan ja arvioijan päällä voidaan verrata B- ja B′-ohjeita (mekanismin lähteen vaatimus).
