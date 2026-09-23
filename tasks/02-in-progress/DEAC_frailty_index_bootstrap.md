# DEAC-Frailty-Index-aliprojektin minimaalinen bootstrap

## Tila

- State: `02-in-progress`
- Scope: vain DEAC-aliprojektin rakenne ja hyväksytyn handoverin kopio
- Owner authorization: 2026-09-23

## Tausta

Read-only repository preflight vahvisti `DEAC-Frailty-Index/`-nimen ja
`docs/DEAC_HANDOVER.md`-kohteen. Tieteellinen auktoriteetti on väitöskirjan
ihmisomistajalla; kanoninen tila on yksityisen dissertation-repon
`METHODS_AND_SCORING.md` §3.1. Analyysirepo toteuttaa ja validoi myöhemmin.

## Syöte

- Hyväksytty yksityisen repon handover: `DEAC_FIRA1_HANDOVER_20260923.md`.
- Odotettu SHA256: `6A7F99ECC63D7D77CB45B082FB6B8AFD87B7BD71B49A4AF2973A6A9C2DA37222`.
- Lähdettä saa vain lukea tätä kopiointia varten; sitä ei saa muuttaa.

## Tuotokset

Luo täsmälleen nämä viisi projektitiedostoa:

1. `DEAC-Frailty-Index/README.md`
2. `DEAC-Frailty-Index/AGENTS.md`
3. `DEAC-Frailty-Index/.gitignore`
4. `DEAC-Frailty-Index/config/.env.example`
5. `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md`

Handover kopioidaan muuttamatta tieteellistä sisältöä. README ja AGENTS
kuvaavat auktoriteettihierarkian ja FIRA1:n ensimmäisen myöhemmän tehtävän:
handover review + implementation feasibility audit.

## Definition of Done

- [x] Ennen muutoksia kirjataan repojuuri, haara, HEAD ja likaisen työpuun lähtötila.
- [x] Lähdehandoverin SHA256 täsmää odotettuun ja kohteissa ei ole törmäyksiä.
- [x] Viisi projektitiedostoa on luotu; handoverin sisältö ja provenance säilyvät.
- [x] `.env.example` sisältää vain placeholderin; paikallinen `.env` ja DATA_ROOT jäävät koskematta.
- [x] Projektin paikallinen `.gitignore` suojaa arkaluontoiset ja tuotetut tiedostot sekä sallii mallikonfiguraation versionhallinnan.
- [x] Ei DEAC-koodia, testejä, manifesteja, outputteja, derived-dataa tai lokitiedostoja.
- [x] Ennestään likaiset työpuun polut ovat muuttumattomat; tarkastuksen omat muutokset rajautuvat tähän taskiin ja viiteen projektitiedostoon.
- [x] Vain read-only-validointi; gate-ympäristön virhe raportoidaan erikseen eikä gate-skriptejä korjata tässä tehtävässä.
- [x] Ei commitia, pushia eikä mergeä.

## Rajoitteet

- `config/steering.md`: enintään viisi muutettua tiedostoa per ajo. Vaiheessa 1
  taskin lifecycle-siirto ja neljä projektitiedostoa täyttivät rajan.
  Vaiheessa 2 lisättiin viides projektitiedosto ja päivitettiin tätä taskia.
- Osallistujatason DATA_ROOT-dataa ei avata eikä yksityistä repoa kirjoiteta.
- FI22/KAAOS/EFI-legacy-koodi ei määritä DEAC:n tieteellisiä sääntöjä.

## Log

- 2026-09-23T13:16:19+03:00 Ownerin hyväksymä tehtävä otettu `01-ready`-jonoon. Lähdehandoverin SHA256 tarkistettu; se täsmää odotettuun. Kohdehakemistoa ei ole. Bootstrap-tiedostoja ei luotu admission-ajossa.
- 2026-09-23T13:50:13+03:00 Tehtävä valittu `01-ready`-jonosta ja siirretty `02-in-progress`-tilaan. Repojuuri, haara, HEAD, lähtötilan likaiset polut, kohteen puuttuminen ja lähdehandoverin SHA256 tarkistettu. Viiden tiedoston raja kattaa myös task-siirron; bootstrap toteutetaan kahdessa vaiheessa.
- 2026-09-23T13:51:41+03:00 Luotu README.md, AGENTS.md ja .gitignore sekä kopioitu hyväksytty handover byte-for-byte kohteeseen docs/DEAC_HANDOVER.md. Lähde- ja kohdehash täsmäävät. Gitignore-suoja tarkistettu; neljä projektitiedostoa ja task-siirto täyttävät tämän ajon viiden tiedoston rajan. `config/.env.example` ja review-siirto jäävät seuraavaan vaiheeseen.
- 2026-09-23T14:24:59+03:00 Phase 2: luotu `config/.env.example`, jonka ainoa sisältö on `DATA_ROOT=`. Viiden tiedoston rakennetarkistus ja aliprojektin juuresta ajettu Python `-B` -smoke läpäisivät. Handoverin lähde- ja kohdehash ovat samat; gitignore-suoja ja ennestään muokattujen analyysisuunnitelmien hashit tarkistettu. `run-gates.ps1 --help` pysähtyi ennen Bash-skriptin suoritusta Win32 error 5 -virheeseen. Repojuuren `AGENTS.md` vaatii varmistamaan gate-skriptin ajon; siksi task jää `02-in-progress`-tilaan eikä sitä siirretä review'hun.
- 2026-09-23T18:57:11+03:00 DEAC-bootstrapin viisi projektitiedostoa siirretty puhtaaseen `origin/main`-pohjaiseen feature-worktreehen rajattua Termux-handoffia varten. Tämä task säilyy `02-in-progress`-tilassa; pakollinen gate-validointi Termux/Linux-ympäristössä on vielä tekemättä.

## Blockers

- `GATE_ENVIRONMENT_BLOCKER`: repojuuren `AGENTS.md` TODO-järjestelmän MUST-sääntö vaatii varmistamaan, että `tools/run-gates.sh` on ajettu. `tools/run-gates.ps1 --help` epäonnistui Windowsissa ennen shell-skriptin suoritusta Git Bash -virheeseen `couldn't create signal pipe, Win32 error 5`. Onnistunutta gate-ajoa ei voi vielä todentaa. Aja gate Termux/Linux-ympäristössä ennen `03-review`-siirtoa; jos sekin epäonnistuu, kirjaa todellinen virhe ja tee erillinen tooling-selvitys. Gatea ei korjata tässä taskissa.
- Termux/Linux-gate-validointi on pending. Jatka tätä samaa taskia feature-haarassa; älä aloita uutta bootstrapia tai siirrä taskia `03-review`-tilaan ennen onnistunutta validointia.
