# Table 2 Technical Reproducibility Note

Taulukko 2 on rakennettu deterministisella, audit-ystavallisella putkella. Kuvatun analyysin nykyinen kohortti on FOF_No=144 ja FOF_Yes=330, kun kasikirjoituksessa raportoitiin 147/330. Erotus ei synny Table 2 -suodatuksista, vaan upstream-cohortin muodostuksesta (aim2_analysis snapshot). Taman vuoksi poikkeama on dokumentoitu metodologiassa eikaa analyysiputken sisalla.

Sairaalamittari on lukittu: “Treatment periods in hospital” vastaa diagnoositiedostosta (dxfile) johdettuja injury-hoitopaivia, jotka muodostetaan ICD-10 S/T -rajauksella (S00–S99 ja T00–T14), paivarajauksella (date-bounded merge) ja paivien interval-collapsella (paallekkaisyyksien poistaminen). Tama maaritelma tuottaa FOF_No-ryhmassa ~377.9 / 1000 PY, mika vastaa kasikirjoituksen mittakaavaa (~378.2 / 1000 PY).

Replikaatio on toistettavissa: ajot ovat ymparistomuuttujilla ohjattuja, aggregaattien tuotto on kaksinkertaisesti portitettu (ALLOW_AGGREGATES=1 ja INTEND_AGGREGATES=true), eika henkilokohtaisia tietoja tallenneta repoartefakteihin. Table 2 on versioitu tunnisteella `TABLE2_LOCKED_v2_collapsed_dx_days`.
