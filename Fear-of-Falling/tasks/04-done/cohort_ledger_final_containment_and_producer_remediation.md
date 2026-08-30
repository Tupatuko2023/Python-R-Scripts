# Cohort ledgerin lopullinen containment ja tuottajakorjaus

## Tavoite

- Säilytä osallistujatason ledger vain varmennetussa `DATA_ROOT/derived`-
  sijainnissa.
- Estä restricted ledgerin kirjoittaminen Git-työpuuhun.
- Säilytä tieteellinen kohorttilogiikka ja outputin sisältösemantiikka.

## Definition of Done

- [x] Molemmat auditoidut checkout-ledgerit on siirretty ulkoiseen sijaintiin.
- [x] Tuottaja ratkaisee ledger-polun `DATA_ROOT/derived`-sopimuksesta.
- [x] Tuottaja ja testit käyttävät samaa live security-helperiä.
- [x] Eri sisältö aiheuttaa collision-helperissä FAIL_CLOSED.
- [x] Todellinen restricted-write-polku on atominen ja idempotentti, tarkistaa
  kaikki filesystem-paluuarvot ja käyttää `0600`-oikeutta temp-vaiheesta asti.
- [x] Testit kattavat epäselvän Git-virheen, symlink-ohituksen sekä todellisen
  absent/identical/different/forced-failure publication-polun ilman PASSiksi
  laskettuja SKIP-tuloksia.
- [x] R parse, FOF preflight ja pre-push smoke läpäisevät nykyisen esitilan.
- [x] Tieteelliseen kohorttilogiikkaan ei ole tehty muutoksia.
- [x] Tehtävä siirretään `03-review`-tilaan vasta koko DoD:n täytyttyä.

## Loki

- 2026-08-30 — CONTAINMENT PASS: molemmat aidot ledgerit siirrettiin
  varmennettuun `DATA_ROOT/derived`-luokkaan ennen checkout-kopioiden poistoa.
- 2026-08-30 — Ensimmäinen hardening lisäsi shared-helperin, DATA_ROOT-
  reitityksen, worktree-ancestor-guardin ja collision-helperin.
- 2026-08-30 — INDEPENDENT REVIEW NEEDS_FIXES: 23/23 sisälsi yhden SKIPin;
  epäselvän Git-virheen ja symlinkin testit puuttuivat; todellista publication-
  polkua ei testattu; identtinen kohde jatkoi korvaavaan renameen; renamen
  tulosta ja tempin eksplisiittistä `0600`-oikeutta ei tarkistettu.
- 2026-08-30 — ROUND2 HARDENING PASS (prompt 26): Toinen hardening-passi toteutettu.
- 2026-08-30 — PERMISSION HARDENING PASS (prompt 28): Kolme oikeusdefektiä korjattu.
- 2026-08-30 — FINAL PERMISSION & EDITING FIX PASS (prompt 30): Bitwise `is_exact_mode_0600()` toteutettu.
- 2026-08-30 — CHMOD NON-TRUE & CANONICAL 0400 SURGICAL FIX (prompt 33):
  (1) `chmod_tmp_res` ja `chmod_final_res` edellyttävät nyt yksiselitteistä `!isTRUE(...)` epäonnistumisen tarkistusta (`TRUE` vaaditaan), jolloin `FALSE`, `NA`, `NULL` ja `logical(0)` laukaisevat `FAIL_CLOSED_CHMOD_FAILED`.
  (2) `test_output_routing.R`:ssä on eksplisiittiset kontrollitilaukset väliaikaisen ja lopullisen `chmod`-palautteen arvoille: `TRUE` (succeeds), `FALSE` (fail-closed), `NA` (fail-closed).
  (3) Kanoninen `0400`-testi tallentaa ja todentaa itsenäisesti tiedostojärjestelmän todellisen `0400`-bitti-tilan ennen kuin virheenkäsittelyn cleanup (`unlink`) poistaa kelvottoman julkaisutiedoston.
  (4) 45/45 synteettistä testiä PASS (0 FAIL, 0 SKIP). R parse OK kaikille tiedostoille. Tieteelliset vakiot säilyivät ennallaan.
