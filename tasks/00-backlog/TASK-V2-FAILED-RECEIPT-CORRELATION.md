# TASK-V2-FAILED-RECEIPT-CORRELATION — senderin FAILED-vastauksen korrelaatio

## Context

Diagnostiikka ja säilytetyt ajot osoittivat: kun receiver hylkää ajon, sen FAILED-kuitti
(`receive_artifact_bundle.ps1` catch-lohko) sisältää `file_count = 0`, mutta senderin korreloitu-FAILED-polku
(`export_artifacts_to_windows.sh`) vaatii `receipt.file_count == len(manifest.files)`. Siksi aidosti
korreloiva receiver-FAILED luokitellaan `NON_CORRELATED` → `UNKNOWN_REMOTE_STATE` (esim. ajo
`20261010T145310Z-ecef2d96f4624264903979763e4925f3`, `error_code Path_escaped_run`; diagnostiikka
`response_class NON_CORRELATED`, `status FAILED`, `file_count 0`).

## Impact

- **Fail-safe-suunta:** ei koskaan väärää SUCCESSia — vain vian **tarkkuus** heikkenee (FAILED → UNKNOWN).
- Ei vaikuta receiverin polkukorjaukseen, exact-set-, koko- tai hash-tarkastuksiin eikä diagnostiikkaan.

## Objective

Sovita senderin korreloitu-FAILED-tunnistus receiverin FAILED-kuittisopimukseen siten, että aito
receiver-FAILED raportoidaan `FAILED`ina (ei UNKNOWNina) **hyväksymättä** aidosti korreloimatonta
vastausta (avainten `content_digest`/`run_correlation_digest`/`run_id`/`protocol_version` on edelleen
täsmättävä).

## Scope (ehdotus)

- `Fear-of-Falling/scripts/termux/export_artifacts_to_windows.sh` (+ sen testit).
- Ei muutoksia receiveriin, LEGACY/1:een, pull-kanavaan tai sijoitustyökaluun.

## Acceptance criteria (ehdotus)

- Korreloitu receiver-FAILED → `FAILED` (exit 1) ja `error_code` säilyy ennallaan.
- Ei-korreloitu / ylisuuri / virheellinen vastaus → edelleen `UNKNOWN_REMOTE_STATE`.
- Regressiotestit: korreloitu FAILED (`file_count=0`), ei-korreloitu, ylisuuri, virheellinen.
- Onnistumistulkinta (VERIFIED/SUCCESS) ei muutu.

## Notes

- Ei sender-korjausta PR #198:n toimituksessa; tämä on erillinen rajattu tehtävä.
- Metadata-only; ei toteutusta ilman erillistä valtuutusta.

## Log

- 2026-10-10: Kirjattu PR #198:n sulkemisen yhteydessä avoimena löydöksenä.
