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

- v2:n paikallinen NTFS-stagingjuuri puuttuu; ehdotus valmisteltu, ei luotu.
