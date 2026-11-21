# SKILLS.md — Agent Operating Protocol (Single Source of Truth)

## Rule of precedence (MUST)

- `SKILLS.md` on ylin kanoninen ohje **hallinnollisessa työnkulussa**: tehtäväjonon ja elinkaaren hallinnassa, tehtäväkohtaisessa kirjoitus- ja toimitusrajauksessa, GitHub-autentikoinnissa, PR- ja katselmointimenettelyssä, riippumattomassa ihmishyväksyntänäytössä, `main`-toimituksessa, teknisessä `04-done`-sulussa ja siivouksessa.
- Ennen mitään `gh`-komentoja, PR-työtä tai mergeä: lue tämä tiedosto ensin ja noudata kirjaimellisesti.
- **MANDATORY:** Ennen mitään kontribuutiota (Issue/Branch/Commit/PR), konsultoi ja noudata ohjeita tiedostossa `.codex/skills/make-repo-contribution/SKILL.md`.
- Tämä kontribuutiosääntö koskee koko repoa ja kaikkia agent-entrypointteja/orchestratoreita/wrappereita, jotka voivat käynnistää kontribuutiotoimia.
- Hallinnollisen työnkulun ristiriidoissa `SKILLS.md` voittaa. Tämä hallinnollinen etusija **ei koskaan syrjäytä tai heikennä** aliprojektien tiukempia tutkimusmenetelmä-, tietosuoja- (esim. Option B, `DATA_ROOT`, `AUTH_SOURCE`, aggregaattien kaksiosainen valtuutus ja `n < 5` -suojaus), QC- (esim. `K18/QC`) tai ajo-/ympäristövaatimuksia. Jos ohjeiden välillä ilmenee ratkaisematon ristiriita, se **pysäyttää riippuvan toimenpiteen** (`STOP` ja koottu täsmennyspyyntö), eikä koskaan anna lupaa valita heikompaa suojausta tai sääntöä.

---

## TODO System (Agent-First Task Queue) — MUST

Pakollinen työjono ja toimintalogiikka:

- **Selection rule & tehtäväjono (`<queue-root>`):** jokaisella tehtäväkortilla on oma kiinteä tehtäväjono — joko päärepon `tasks/` tai aliprojektin oma `<aliprojekti>/tasks/` (esim. `Fear-of-Falling/tasks/`, `Quantify-FOF-Utilization-Costs/tasks/`). Valitse uusi toteutustehtävä vain asianomaisen jonon `<queue-root>/01-ready/`-kansiosta. Jos jono on tyhjä: STOP ja pyydä ihmiseltä tehtävää. Ihmisen erikseen hyväksymän, jo `<queue-root>/03-review/`-tilassa olevan tehtävän tekninen sulkeminen ei ole uuden tehtävän valinta.
- **Transitions:** agentti siirtää tehtäväkorttia aina sen **omassa tehtäväjonossa** `<queue-root>/01-ready → <queue-root>/02-in-progress → <queue-root>/03-review` (aliprojektin kortti ei koskaan siirry päärepon `tasks/`-jonoon eikä päinvastoin). Jos tehtävä on linkitetty nimettyyn `docs/governance/project_registry/PRJ-*.md`-tietueeseen, päivitä tietueen tehtävätaulukon polku samassa elinkaarimuutoksessa. Owner tai muu tehtävälle määrätty ihminen tekee hyväksymispäätöksen; agentti ei saa hyväksyä omaa työtään. Vasta kirjatun hyväksynnän jälkeen agentti saa siirtää saman tehtävän teknisesti `<queue-root>/03-review → <queue-root>/04-done`, kirjata hyväksynnän provenance-tiedot, päivittää mahdollisen linkitetyn `PRJ-*.md`-tietueen tehtäväpolun (tarkistaen erikseen projektin omat valmistumiskriteerit ennen projektin tilan muuttamista), validoida muutoksen ja avata lifecycle-PR:n. Ihminen arvioi ja mergeää PR:n erikseen. Alla rajattu komponenttitoimitus voi käyttää yhden PR:n menettelyä.
- **Approval evidence (MUST):** ennen teknistä sulkua tarkista agentin omasta
  task-lokista riippumaton ja pysyvä ihmishyväksyntä. Näytöksi kelpaa tehtävälle
  määrätyn hyväksyjän GitHub PR-/issue-kommentti tai hänen tekemänsä hyväksytyn
  työn PR:n merge, kun PR:n diff sisältää saman review-tehtävän. Todennettavia
  tietoja ovat hyväksyjän tunnus, päätöksen aika, kohdetehtävä, hyväksytyn työn
  PR- tai commit-rajaus sekä pysyvä URL ja tarvittaessa merge-commit. Agentti saa
  kirjata nämä viitteet taskiin mutta ei saa itse tehdä näyttönä käytettyä
  mergeä tai hyväksyntäkommenttia. Agentin kirjoittama task-merkintä, PR-kuvaus
  tai kommentti ei kelpaa ainoaksi näytöksi.
  Jos hyväksyjä, kohde tai rajaus ei ole todennettavissa, STOP ja pyydä ihmistä
  täydentämään hyväksyntänäyttöä ennen siirtoa.
- **Rajattu yhden PR:n menettely uusille DEAC-komponenttitoimituksille:**
  Käytä tätä menettelyä vain, kun se on nimetty hyväksytyssä tehtäväkortissa
  ja toteutuksen, soveltuvan testinäytön, kortin ja nimetyn projektitietueen
  voi katselmoida yhdessä. Valitse kortti normaalisti `01-ready`-jonosta,
  siirrä se `02-in-progress`-jonoon ja kirjaa tekninen valmistuminen ja DoD
  `03-review`-vaiheessa. Valmistele samassa toimitushaarassa ja samassa PR:ssä
  kortin lopullinen `04-done`-polku sekä projektitietueen vastaava viite.
  Ennen yhdistämistä polku on PR:ssä ehdotettu lopputila. Merkitse korttiin
  tekninen valmistuminen ja se, että hyväksyntä ja main-toimitus odottavat
  PR:n avaushetkellä. Kirjaa toteutuneet testit, ratkaisemattomat esteet ja
  varmennetut rekisterihavainnot. Tarkista rekisterin kirjoitussuoja, kortin
  ja rekisteriviitteen vastaavuus sekä soveltuva CSV-vienti kuten muissa
  projektirekisterin muutoksissa.
  Toimituspäivä, toimituscommit ja siivoustila perustuvat havaintoihin.
  Ihmisomistaja hyväksyy PR-kommentissa lopullisen HEADin koko diffin,
  myös tehtävä- ja rekisterikirjaukset.
  Samassa kommentissa voi valtuuttaa yhdistämisen sekä jäljempänä kuvatun
  nimetyn siivouksen. Uusi HEAD vaatii uuden täsmähyväksynnän.
  Kun pakolliset portit ja hyväksyntä on tarkistettu, PR voidaan yhdistää
  HEAD-lukittuna valtuutuksen rajoissa. Kortin `04-done` tulee voimaan vasta
  main-toimituksessa. Varmenna toimitus `origin/main`ista ja kirjaa samaan
  PR:ään omistajan hyväksynnän URL, hyväksytty HEAD, toimituscommit, aika
  ja tehtäväpolku sekä erillinen siivoustulos. Kommentti on toimitus- ja
  siivousnäyttö. Omistajan kommentti on hyväksyntänäyttö. Tätä menettelyä
  käyttävässä toimitus-PR:ssä katselmoidaan myös elinkaarisiirto.
  Muiden sekä jo aiemmalla menettelyllä aloitettujen tehtävien säännöt säilyvät.
- **Log:** lisää tehtävätiedostoon aikaleimallinen lokimerkintä (ISO-8601; local time ok) jokaisesta merkittävästä toimesta.
- **DoD gate (tehtävän luonteen mukaiset tarkistukset):**
  - _Soveltuvat toimitus- ja dokumentaatiotarkistukset ovat aina pakollisia:_ aja muutokseen soveltuvat repojuuren toimitusportit (esim. `tools/run-gates.sh --mode pre-push --smoke` tai `tools/run-gates.ps1 --mode pre-push --smoke`), Markdown-/muotoilutarkistukset ja mahdolliset projektirekisteritarkistukset.
  - _Analyysikoodi-, datajohdannais- ja ympäristömuutokset:_ tee vähintään yksi aliprojektin ohjeiden mukainen smoke-run (`Rscript`/`python`) aliprojektin työjuuresta, aja soveltuva QC-portti (esim. `Fear-of-Falling/agent_workflow.md`:n `K18/QC Applicability Decision Gate`) ja jos `renv/` on käytössä, varmista `renv`-yhteensopivuus sekä kirjaa tarvittaessa `sessionInfo()`/`renv::diagnostics()`.
  - _Puhdas hallinto- tai dokumentaatiomuutos:_ ei itsessään valtuuta tai käynnistä tutkimusajoa, analyysiputkea eikä suojatun aineiston (`DATA_ROOT`/`AUTH_SOURCE`) lukua; soveltumattomat analyysi- ja QC-ajot merkitään perustellusti `NOT APPLICABLE`.
- **Blocker:** jos olet epävarma, luo blocker-merkintä tehtävään tai pyydä ihmiseltä täsmennys ennen jatkoa.

**Steering integration & tehtäväkohtainen kirjoitusrajaus (MUST, kanoninen sääntö):**
lue `config/steering.md` ennen työn aloitusta ja noudata tätä kanonista rajaussääntöä
(muut ohjeet viittaavat tähän osioon tai tiivistävät sen):

- **Tavoite, kirjoituspolut ja toimitusraja:** jokaisella toteutuksella on ennalta
  hyväksytty tavoite, yksilöidyt repojuureen suhteutetut kirjoituspolut (ml.
  tehtäväkortin elinkaaripolut, mahdollinen nimetty
  `docs/governance/project_registry/PRJ-*.md`-tietue ja tarpeelliset paikalliset
  gitignored-tulokset), hyväksytyt operaatiot sekä eksplisiittinen toimitusraja
  (esim. read-only, paikallinen commit tai PR-katselmointi). Muutosmäärä
  raportoidaan katselmointia varten; mekaanista ajokohtaista tiedostomäärärajaa ei
  ole.
- **Eteneminen ja session jatko ilman toistuvia lupapyyntöjä:** hyväksytyssä
  rajauksessa agentti etenee sovittuun toimitusrajaan asti (ml. yksi tai useampi
  looginen kohdistettu commit) pyytämättä samaa lupaa uudelleen tiedostomäärän,
  commitin, työkalukutsun tai keskusteluvuoron vuoksi. Saman tehtävän jatko
  keskeytyksen tai uuden session jälkeen käyttää kirjattua valtuutusta, kun
  nykytila ja tallennettu valtuutus on tarkistettu; tekninen session käynnistys ei
  ole uusi sisältöhyväksyntä, eikä puuttuvaa valtuutusnäyttöä keksitä.
- **Tarkistusvirheet ja pakolliset portit:** pakollisen portin tai tarkistuksen
  virheen saa korjata hyväksytyissä kirjoituspoluissa ja tavoitteen sisällä ilman
  uutta lupapyyntöä. Pakollista porttia ei saa koskaan ohittaa: ratkaisematon
  virhe estää toimituksen.
- **Uutta päätöstä vaativat laajennukset:** jos tavoite, kirjoituspolut,
  vaikutukset tai tarvittavat operaatiot laajenevat — tai jos ilmenee
  ratkaisematon ohjeristiriita tai riski muiden paikalliselle työlle — agentti
  pysähtyy ja esittää yhden kootun muutosesityksen perusteluineen.
- **Operaatioiden valtuutus ja erilliset portit:** etäoperaatiot (`git fetch`,
  `git pull`, `git push`, `gh issue`/`gh pr`), merge, `04-done`-sulku ja poistot
  eivät tule automaattisesti sallituiksi pelkän kirjoituspolkulistan perusteella.
  Operaatiot voidaan hyväksyä yhdessä tehtävän alussa osana kirjattua valtuutusta
  ja toimitusrajaa, jolloin lupaa ei kysytä uudelleen jokaisella käyttökerralla.
  Merge ja `04-done` vaativat nimenomaisen valtuutuksen ja riippumattoman
  ihmishyväksyntänäytön. Yhden PR:n menettelyssä sama täsmähyväksyntä ja
  yhdistämisvaltuutus kattavat PR:n mukana mainiin toimitettavan elinkaarisiirron.
- Safe mode: `true` → tiedostojen poistot vaativat hyväksynnän
- Approvals required: `docs/` tai `src/` poistot, uudet Python-riippuvuudet, `data/`-rakenteen muutokset
- Language policy: dokumentaatio suomeksi, koodi/muuttujat englanniksi
- Poikkeus: `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` saa säilyä englanniksi
  vain Ownerin hyväksymän tieteellisen lähdehandoverin muuttumattomana
  tavukopiona (SHA-256
  `B8527242BF9718ECBADDEE6514837B2AD4F1B77C99B55BD18DAF26ABE3A00890`).
  Poikkeus ei koske muuta dokumentaatiota; sisältömuutos edellyttää
  tieteellistä hyväksyntää ja uutta hashia.

---

## Orchestration exceptions (MUST)

Nämä poikkeukset ohittavat TODO-valintasäännön vain orkestroijan
eksplisiittisellä käskyllä:

1. **PR+merge gate precedence**
   - Jos orkestroija käskee hoitaa PR:n (ja/tai merge) ensin, agentti ei
     aloita uuden tehtävän etsimistä tai luomista ennen kuin:
     a) PR on mergetty (oletus), TAI
     b) orkestroija eksplisiittisesti ohittaa merge-ehdon.
   - Agentti saa tehdä PR:n validointeja, mutta ei siirry uuteen tehtävään.

2. **Orkestroijan ohjaama tehtävän luonti**
   - Jos orkestroija käskee luomaan uuden tehtävän `tasks/01-ready/`-kansioon,
     agentti luo sen itse (metadata-only, Option B -turvarajat).
   - Ei raakadataa, ei absoluuttisia polkuja, ei salaisuuksia, ei outputteja.

---

## Repository conventions (MUST)

- Kaikki analyysi-R-skriptit ovat omissa kansioissaan `R/`-hakemiston alla.
- Jokaisella skriptillä on omat `outputs/` ja `logs/` -alihakemistot.
- Outputit ovat aina gitignored ja skriptikohtaisia.
- Yhteisiä `outputs/`-hakemistoja ei käytetä.
- Kun tehtävä nimeää projektitietueen (`docs/governance/project_registry/PRJ-*.md`),
  noudata [projektirekisterin käyttöohjetta](docs/governance/project_registry/README.md):
  päivitä vain tehtävän hyväksyttyihin kirjoituspolkuihin kuuluvaa tietuetta
  Git-suojan (`--verify-guard`) kautta lukittua lähdekuvausta muuttamatta,
  päivitä tehtävätaulukon polku samassa muutoksessa kortin elinkaarisiirron kanssa,
  säilytä tehtäväkortit omissa jonoissaan ja erota yksittäisen tehtävän `04-done`-sulku
  projektin `closed`/`delivered`-päätöksestä.

## GitHub Auth (Non-Interactive) — Termux-safe

Supported auth models (automatic, no prompts):

1. Preferred: GitHub CLI is already authenticated on this device.
   - Check: `gh auth status`
   - If not authenticated: STOP and report that device auth is required.

2. Alternative: token via environment variable (non-interactive).
   - Supported env vars (precedence): `GH_TOKEN`, then `GITHUB_TOKEN`
   - Tokens must be provided by the environment (Termux export, CI secrets).
   - Never prompt for tokens; do not assume a TTY exists.

### Important clarification (env empty is OK)

Empty `GH_TOKEN` / `GITHUB_TOKEN` does not mean "no token". The preferred default is
persistent gh login stored locally in Termux under `~/.config/gh/hosts.yml` (or
`hosts.yaml`). Treat gh itself as the source of truth:

```bash
gh auth status -h github.com
gh api user -q .login
```

### Auth modes (priority order)

1. Persistent login: `~/.config/gh/hosts.yml|hosts.yaml`
2. Env override (headless): `GH_TOKEN` (preferred) or `GITHUB_TOKEN`
3. Secrets-file fallback (headless, no persistent env export):
   - Store token locally: `~/.secrets/github_fine_grained_pat` (chmod 600, never commit)
   - Use per-command injection:

```bash
GH_TOKEN="$(cat ~/.secrets/github_fine_grained_pat)" gh api user -q .login
```

### Agent decision rule

- If `gh api user -q .login` succeeds: proceed (even if env vars are empty).
- If it fails AND no env/secrets-file override is available: STOP and request operator re-auth.

### Required reporting

- Include one line in every PR report: `Auth mode: persistent-login | env-token | secrets-file`.

### Authoritative MCP Test Protocol

- Operational note: Codex MCP config should use `bearer_token_env_var = "GH_TOKEN"` (not `GITHUB_PAT_TOKEN`).

Path A (preferred):

- Use persistent gh login in `~/.config/gh/hosts.yml|hosts.yaml`.
- Env tokens may be empty; this is OK.
- Works check: `gh api user -q .login`.
- Do not run curl/SSE by default.

Path B (manual validation only):

- Use per-command token injection from a secrets file (no export, no prompts).
- Example:

```bash
ENDPOINT="https://api.githubcopilot.com/mcp/"
GH_TOKEN="$(cat ~/.secrets/github_fine_grained_pat)" \
curl -sS -D /tmp/mcp_headers_auth.txt -o /dev/null \
  -H "Accept: text/event-stream" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  "$ENDPOINT"
```

Do NOT:

- Use `read -s` or any prompt-based token entry in automation.
- Persist token exports in shell profiles.
- Write tokens into repo files.

Sanity checks (must be non-interactive):

```bash
gh --version
gh auth status || true
gh repo view --json nameWithOwner -q .nameWithOwner
```

Prohibited (breaks automation):

- Do not use interactive auth (e.g., `gh auth login` prompts).
- Do not read tokens from stdin/TTY.
- Do not use `read -s` or any prompt-based token entry in automation; if env is missing, STOP and request the operator to set it in the shell environment.

---

## PR Protocol / Definition of Done (Mechanical Checklist)

Branch naming:

- Use a deterministic name: `docs/<topic>` or `chore/<topic>`.

Required steps (report each as Done/Not done/Stop reason):

1. Sync & create isolated task worktree (säilytä päächeckout ja muiden paikallinen työ)

- Älä koskaan vaihda jaetun päächeckoutin haaraa (`git switch`), älä tyhjennä
  tai siirrä sen paikallisia muutoksia äläkä aja rinnakkaisia tehtäviä samassa
  työpuussa. Jokainen tehtävä käyttää omaa eristettyä tehtäväworktreetä.
- Aja valtuutettu `git fetch origin main`, ota talteen ja varmenna lähtöpisteen
  täysi muuttumaton commit-SHA (`BASE_SHA`) ja luo eristetty tehtäväworktree sekä
  tehtävähaara suoraan tästä varmennetusta täydestä SHA:sta:

```bash
git status --porcelain # vain havainnointi; päächeckoutin haaraan tai muutoksiin ei kosketa
git fetch origin main
BASE_SHA="$(git rev-parse --verify origin/main^{commit})"
printf 'Verified base SHA: %s\n' "$BASE_SHA"
git worktree add -b docs/<topic> tmp/<task-id> "$BASE_SHA"
cd tmp/<task-id>
```

1. Make changes (minimal diffs)

- Avoid reformatting unrelated content.
- Never touch `data/raw/**` or `data/processed/**`.
- Never edit submodule contents under `analysis/modules/**`.

1. Local checks (run what is feasible)

```bash
git submodule update --init --recursive
```

Optional (only if environment supports it):

```bash
proot-distro login debian --termux-home -- bash -lc "cd <ABS_REPO_ROOT> && bash analysis/pipelines/run_all.sh"
proot-distro login debian --termux-home -- bash -lc "cd <ABS_REPO_ROOT> && quarto render"
```

1. Commit (one logical change per commit, targeted staging only)

- Stageaa aina vain tehtävän hyväksytyt kirjoituspolut. Älä käytä `git add -A`
  -komentoa, jotta muiden paikalliset tai seuraamattomat tiedostot säilyvät
  koskemattomina.

```bash
git add -- <approved-paths>
git diff --cached --name-status
git commit -m "docs: enforce non-interactive gh auth protocol"
```

1. Push and open PR (non-interactive; vain kun sisältyy hyväksyttyyn toimitusrajaan)

```bash
git push -u origin HEAD
gh pr create --fill
```

1. Merge tai auto-merge (vain erillisellä merge-valtuutuksella ja riippumattoman ihmishyväksynnän jälkeen)

- PR-katselmointiin rajattu toimitusvaltuutus päättyy PR:n luontiin/päivittämiseen
  ja tarkistusten raportointiin. Älä aja `gh pr merge` -komentoa tai kytke
  auto-mergeä päälle ilman nimenomaista merge-valtuutusta ja tämän tiedoston
  mukaista riippumatonta ihmishyväksyntänäyttöä.

```bash
# Vain kun erillinen merge-valtuutus ja riippumaton ihmishyväksyntä on varmennettu:
gh pr merge --auto --squash
```

1. Post-merge cleanup (erillään main-toimituksesta; vain erillisellä nimetyllä siivousvaltuutuksella)

- Työn valmistuminen (`03-review`), hyväksytty `main`-toimitus / tekninen
  `04-done`-sulku sekä työpuiden ja haarojen siivous ovat kolme eri vaihetta.
  Oletus toimituksen jälkeen on työpuun ja haarojen säilytys (`retained`).
- **Yhden PR:n komponenttitoimitus:** sama täsmähyväksyntäkommentti voi sisältää
  kohdassa 1 vaaditun nimetyn siivousvaltuutuksen. Yksilöi työpuu, paikallinen
  haara, etähaara ja niiden odotetut OID-arvot. Varmenna säilytettävän aineiston
  kopiot ja tarvittaessa haarakärjen palautettavuus ennen poistamista.
  Tarkista squash-toimituksen sisältö ja haaran historian yhdistyminen erikseen.
  Sido etäpoisto atomisesti tarkistettuun OID-arvoon paikallisten vaiheiden
  jälkeen. Jos normaali poisto, turvallinen OID-ehto tai muu edellytys estyy,
  säilytä kohde ja siitä riippuvat kohteet. Kirjaa `retained` ja syy saman
  yhdistetyn PR:n kommenttiin. Tämä päättää siivouksen kyseisiltä osin.
- Älä suorita sokeaa komentosarjaa. Siivous on sallittu vain, kun jokainen
  seuraavista ehdoista tarkistetaan ja täyttyy järjestyksessä (mikä tahansa
  epäonnistuminen pysäyttää ketjun välittömästi ennen seuraavaa poistoa):
  1. **Erillinen nimetty siivousvaltuutus:** ihmisomistaja on antanut nimenomaisen,
     poistettavan worktreen ja/tai haaran yksilöivän siivousvaltuutuksen (pelkkä
     merge- tai `04-done`-valtuutus ei riitä).
  2. **Toimituksen varmennus (myös squash-mergelle):** `git fetch origin main`
     on ajettu ja sekä PR:n tila (`MERGED`, kohde `main`, `mergeCommit`) että
     `origin/main`-historia vahvistavat toimituksen. Koska squash-mergessä
     tehtävähaaran yksittäiset commitit eivät ole suoraan `origin/main`in
     esivanhempia, tarkista squash-mergen `mergeCommit` `origin/main`ista ja
     varmista, ettei tehtävähaarassa ole yhtään hyväksytyn PR-`HEAD`in jälkeistä
     julkaisematonta committia; jos tarkistus epäonnistuu tai PR ei ole
     yhdistetty, **STOP**.
  3. **Sisällön ja aktiivisen käytön tarkistus:** tarkista kohdeworktreen
     tracked-, staged-, untracked- ja `gitignored`-sisältö (`git status --porcelain --ignored`)
     sekä varmista, ettei mikään prosessi, terminaali tai rinnakkainen agentti
     käytä kohdetta eikä nykyinen työhakemisto ole sen sisällä. Päächeckoutia tai
     tallennettavaa paikallista sisältöä sisältävää työpuuta ei koskaan poisteta.
  4. **Suoritusjärjestys ja välitön pysäytys virheessä:** siirry ensin pois
     kohdeworktreestä -> poista eristetty tehtäväworktree (`git worktree remove <path>`) ->
     poista paikallinen haara turvallisella tarkistuksella (`git branch -d <branch>`;
     jos `git branch -d` estyy esim. squash-mergen vuoksi, jätä haara `retained`-tilaan
     tai pyydä ihmistä tarkistamaan — älä jatka sokeasti) -> poista etähaara
     (`git push origin --delete <branch>`) vasta, kun valtuutetut edeltävät
     tarkistukset ja paikalliset vaiheet ovat onnistuneet ilman virheitä.
  5. **Ehdottomat kiellot:** älä koskaan käytä `--force`-, `git branch -D`- tai
     virheiden ohitusmenettelyä (`|| true` tms.). Raportoi poistot ja säilytetyt
     (`retained`) kohteet aina erillään `main`-toimituksesta.

Required report format:

```text
Auth model used: (gh-authenticated device) OR (GH_TOKEN/GITHUB_TOKEN env)
Checklist:
Sync & isolated worktree: Done/Not done/Stop reason
Checks: Done/Not done/Stop reason
PR created: Done/Not done/Stop reason
Auto-merge: Done/Not done/Stop reason
Cleanup: Done/Not done/Stop reason
```

---

## Skills directory index

The skills location has moved to the `skills/` directory (general) and `.codex/skills/` (Codex-specific):

- Index: `skills/README.md`
- GitHub PAT skill: `skills/github-pat/skill.md`
- Make Repo Contribution skill: `.codex/skills/make-repo-contribution/SKILL.md`
