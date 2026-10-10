# TASK-OUTBOUND-V2-STAGING-ISOLATION — v2:n oma staging-binding

## Context

Outbound-v2:n (`FOF_ARTIFACT_HANDOFF/2`) vastaanotin `receive_artifact_bundle.ps1`
käyttää oletuksena `$env:WINDOWS_STAGING_DIR`iä (`param([string]$StagingDir =
$env:WINDOWS_STAGING_DIR, …)`), koska v2-sovitin (`fof_v2_ssh_adapter.py`) ei antanut
`-StagingDir`-argumenttia. Nykyinen `WINDOWS_STAGING_DIR` (User-scope) osoittaa
Google Driven G:-asemaan (FAT32; pilvisynkronoitu virtuaaliasema), joka ei tarjoa
vaadittua paikallista NTFS-suojaa. Sama muuttuja kuuluu LEGACY/1:lle, joten
protokollat sekoittuisivat samaan juureen.

## Objective

V2 saa oman, eksplisiittisesti sidotun staging-valinnan, joka välitetään
vastaanottimelle `-StagingDir`-argumentilla; puuttuva/virheellinen valinta pysähtyy
ennen payloadia. Ei fallbackia `WINDOWS_STAGING_DIR`-muuttujaan. LEGACY/1 säilyy
ennallaan.

## Scope (katselmoitava korjauspaketti)

- `Fear-of-Falling/scripts/termux/fof_v2_ssh_adapter.py`
- `Fear-of-Falling/tests/test_v2_ssh_adapter.py`
- `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md`
- tämä tehtäväkortti

## Requirements

1. `FOF_V2_STAGING_DIR` (uusi) = v2:n oma absoluuttinen Windows-polku (`X:/…`,
   `/`-erottimet, sama rajattu sopimus kuin receiver-polulla).
2. Arvo välitetään receiverille eksplisiittisesti:
   `& '<receiver>' -StagingDir '<staging>' -TransferId '<id>'`.
3. Puuttuva tai virheellinen arvo → `ValueError` → sovitin palauttaa 255 **ennen**
   stdin/payloadin lukua (fail-closed; ei fallbackia `WINDOWS_STAGING_DIR`iin).
4. `--check` varmistaa lisäksi, että staging-hakemisto on olemassa Windowsilla.
5. LEGACY/1 ja `WINDOWS_STAGING_DIR` ennallaan; ei muutoksia pull-kanavaan,
   sijoitustyökaluun, ACL:iin, palveluihin tai runtime-asetuksiin.
6. Runtime-polku ei kuulu portable-profiiliin eikä Gitiin.

## Validation (kohdennetut testit)

- v2:n staging välittyy täsmälleen receiverille (`-StagingDir '<value>'`);
- puuttuva/virheellinen arvo hylätään ennen payloadia (255, stdin lukematon);
- välilyöntejä sisältävä sallittu polku välittyy oikein;
- LEGACY/1:n nykyinen toiminta säilyy (olemassa olevat testit).

## Proposals (ei toteutettu)

- Paikallinen NTFS-stagingjuuri (täsmällinen polku ja luonti-/ACL-skripti: Gitin
  ulkopuolinen evidenssi). Vaatimukset:
  - varmennettu paikallinen NTFS ja turvallinen esi-isäketju (ei reparsea);
  - kohde ei saa olla olemassa: olemassa oleva kohde **pysäyttää** luonnin
    (ei `-Force`-ylikirjoitusta);
  - ACL-toimet kohdistuvat vain tässä vaiheessa luotuihin hakemistoihin;
  - omistaja varmennetaan erikseen luonnin jälkeen;
  - ei yhteisten juurten oikeusmuutoksia.
- Runtime-käyttöönotto (`FOF_V2_STAGING_DIR` Termux-puolella) ja yksi synteettinen
  v2-verkkotesti: ehdotus Gitin ulkopuolisessa evidenssissä.

## Diagnostiikka (2026-10-10) — oma rajattu korjaus

- Sender (`export_artifacts_to_windows.sh`) kirjoittaa `FOF_V2_DIAG_ROOT`-juureen
  rajatun `FOF_V2_DIAGNOSTIC/1`-tietueen per ajo (`<run_id>.json`, ei overwritea):
  tulos, adapterin exit, timeout-tieto, vastauksen luokka (NOT_RUN/TIMEOUT/
  ADAPTER_START_FAILED/OVERSIZED/INVALID_JSON/NON_CORRELATED/CORRELATED_FAILED/
  CORRELATED_VERIFIED), tavumäärä ja sallitut kentät (status, error_code,
  content_digest, run_correlation_digest, file_count).
- `error_code` tallennetaan vain **täsmällisestä tunnetusta listasta**
  (sender+adapter+receiver); tuntematon koodi → `error_code_class=UNKNOWN`
  ilman alkuperäistä arvoa. Ei raakaa stdout/stderr-tekstiä eikä payloadia.
- Juuri on **valmisteltava erikseen etukäteen** käyttäjän omistamaksi
  yksityiseksi (0700), repository-ulkoiseksi, linkittömäksi hakemistoksi;
  kirjoittaja **ei luo** sitä (`os.makedirs` poistettu; puuttuva/ei-yksityinen →
  `NOT_WRITTEN`). Kirjoitus sidotaan varmennettuun hakemistokahvaan (ankkurista
  alkava O_NOFOLLOW-kävely), joten esi-isän vaihto ei ohjaa kirjoitusta toiseen
  kohteeseen; ankkuri ei ole `/`. Ei symlinkin seurausta.
- Best-effort: kirjoitusvirhe ei muuta FAILED/UNKNOWN_REMOTE_STATE-tulkintaa;
  senderi raportoi erikseen `V2 DIAGNOSTIC: WRITTEN/NOT_WRITTEN`. Timeout (60 s)
  ja retry-kielto säilyvät.
- Kohdennetut testit: korreloitu FAILED; tunnettu vs. tuntematon koodi
  (salaisuustestimerkki error_code-kentässä); ei-korreloitu/virheellinen vastaus;
  timeout; ylisuuri vastaus; sama run_id ei ylikirjoitu; linkki-; epäyksityinen
  juuri-; esi-isän vaihto-; kilpailutilanne (esi-isän vaihto tarkastuksen ja
  kirjoituksen välillä); repository-ulkoisuus (git-juuri); kirjoitusvirhe.

## Erillinen löydös: SmokeTest/SmokeSession-ristiriita

- Sovitin (`fof_v2_ssh_adapter.py`) lisää `-SmokeTest -SmokeSession '<sid>'`, kun
  `FOF_V2_SMOKE_SESSION` on asetettu, mutta vastaanottimen `param(`-lohko **ei**
  esittele näitä parametreja → PowerShell-parametrisidonta epäonnistuisi eikä
  vastaanotin käynnistyisi. Kysymys: kumpi puoli on auktoritatiivinen? **Ei
  korjata tässä**; kirjataan erillisenä löydöksenä.

## Log

- 2026-10-10: Valmisteltu eristetyssä korjaustyötilassa (base
  `43398dd81d5f669051e379ff263b4642cbbc9568`). Paikalliset runtime-/worktree-arvot
  pidetään Gitin ulkopuolisessa evidenssissä. Ei ACL-/runtime-muutoksia; ei oikeaa aineistoa.
- Tämä on **katselmoitava valmistelupaketti**; käyttöönotto ja Git-toimitus
  hyväksytään erikseen.

## Blockers

- v2:n paikallinen NTFS-stagingjuuri: **RATKAISTU 2026-10-10** (luotu; ks. Sulkeminen).

## Sulkeminen (2026-10-10)

- **Owner-hyväksyntä (näyttö):** PR #198 **MERGED** repositoryyn Tupatuko2023/Python-R-Scripts,
  merge-commit `91f4037ce8e0584dc13770441608ee5b3a3679d0`, merged 2026-10-10T17:23:45Z,
  `https://github.com/Tupatuko2023/Python-R-Scripts/pull/198`. Hyväksytty head
  `1423af3588b8b916f2e8fcb5fa6b8c6645be9b10`; merged main -sisältö vastaa hyväksyttyä headia
  (8/8 blob täsmää). Draft poistettu ja yhdistetty repositoryn sallimalla menetelmällä
  (squash; ei branch-protection-ohitusta). Lähdehaara säilyi.
- **Tulos:** v2:n staging-isolointi + turvallinen diagnostiikka + receiverin polkukorjaus ovat
  mergettyssä mainissa.
- **Näyttö:** synteettinen Termux → Windows v2 SSH -siirto PASS
  (`20261010T161103Z-80e6d6b64acd42a797dd6fb318bae634`): pysyvä `VERIFIED` (`status=VERIFIED`,
  `file_count=2`), `content_digest` `2fe4f1f933e947f5c499099698df1f4f42b8cb455b51533b9fd940f123535159`,
  `run_correlation_digest` `ffefb3ac93bf85322ddf2ababe038e0af5976962d3a3f8d3df8adfa82e0c4bd3`, payload
  exact-set `[binary.bin, text.txt]`, koot ja SHA-256 täsmäävät. Windowsin riippumaton read-only
  -vastaanottovarmennus PASS; A:n normaalikäytön ajokohtainen `--check` exit 0.
- **Käyttöönottoratkaisu:** korjattu receiver valitaan **eksplisiittisesti ajokohtaisella
  `FOF_V2_RECEIVER_SCRIPT`-arvolla**. Vanhaa/deployed-receiveriä **ei korvattu** eikä pysyviä
  shell-/ympäristöasetuksia muutettu.
- **Julkiset evidenssiviitteet:** `receive_artifact_bundle.ps1` (blob `74e5dbb746c8`),
  `fof_v2_ssh_adapter.py` (`53b835051d93`), sender (`db99e8286793`), testit (`f93422ae326f`,
  `14ab3b4e2709`), dokumentit (`16d294fa1f32`, `5e15ef5bb24b`). Tarkat paikalliset käyttöpolut ovat
  Gitin ulkopuolisessa käyttöönottokuittauksessa (ei julkisessa repositoryssa).
- **Avoin tehtävä (erillinen):** FAILED-vastauksen `file_count`/korrelaatioristiriita →
  `tasks/00-backlog/TASK-V2-FAILED-RECEIPT-CORRELATION.md`.
- **Tila (alkuperäinen sulkeminen):** DONE (Owner-merge-näytön perusteella).

## Palautus review-tilaan (2026-10-10)

- **Owner-käsky:** sulkeminen peruutetaan toistaiseksi ja tehtävä palautetaan
  `tasks/03-review/`-tilaan odottamaan worktree-siivousta. Peruste: `WORKFLOW.md`:n
  DONE-ehto edellyttää tehtävän kaikkien työtreiden poistoa kaikista käytetyistä
  ympäristöistä (mukaan lukien toimitus- ja varmennusworktreet) ja lopputilan
  varmennusta `git worktree list --porcelain`-komennolla.
- **Säilyy:** itse toteutus, Owner-merge-näyttö (PR #198 merge `91f4037c…`), PR #199
  (`9f1e7ae…`) sekä kaikki evidenssi. Vain lifecycle-tila palautetaan, kunnes
  molempien ympäristöjen (Windows + Termux) siivous ja varmennus on kirjattu.
- **Windows-inventaario (2026-10-10):** siivottavat worktreet
  `fof-main-9f1e7ae` (varmennus), `fof-closure-91f4037c` (toimitus),
  `fof-v2staging-43398dd` (testattu toimitushead). Säilytettävät: ensisijainen
  checkout (`prs-197-win-30286b0`) ja muun tehtävän worktree (`fof-usage-43398dd`).
- **Termux-inventaario:** odottaa (pyydetty Termux-agentilta).
- **Tila:** REVIEW — DONE odottaa molempien ympäristöjen varmennettua siivousta.
