# Tietoturvakäytäntö (Security Policy)

Tämä tietoturvakäytäntö koskee `Tupatuko2023/Python-R-Scripts` -monorepositoriota ja kaikkia sen aliprojekteja (mm. Fear-of-Falling, Electronic-Frailty-Index, Quantify-FOF-Utilization-Costs).

Käsittelemme tutkimuksessamme terveystietoja, ja siksi tietoturva ja yksityisyyden suoja ovat projektin korkeimpia prioriteetteja. Repositorioon ei saa missään olosuhteissa viedä henkilötietoja (PII) tai potilastietoja (PHI).

## Tuetut versiot

Tietoturvapäivityksiä ja valvontaa ylläpidetään aktiivisimmin repositoryn päähaarassa (`main` / `master`). Mahdolliset tietoturvakorjaukset kohdistetaan aina uusimpaan kehitysversioon.

## Haavoittuvuuksien ja tietovuotojen raportointi

**KRIITTISTÄ: ÄLÄ avaa julkista GitHub Issue -tikettiä, jos epäilet tietoturvahaavoittuvuutta tai huomaat repositoriossa arkaluontoista dataa (esim. potilasdataa, API-avaimia tai salasanoja).**

Jos havaitset tietoturvaongelman tai datavuodon, pyydämme raportoimaan sen välittömästi GitHubin turvallisen ja yksityisen raportointityökalun kautta:

1. Siirry repositorion **Security**-välilehdelle.
2. Valitse vasemmasta sivuvalikosta kohdasta *Vulnerability alerts* vaihtoehto **Advisories**.
3. Klikkaa painiketta **Report a vulnerability**.
4. Sisällytä raporttiin seuraavat tiedot:
   - Ongelman tarkka kuvaus (esim. "Tiedostossa X on vahingossa julkaistu raakadataa" tai "Skriptissä Y on polunläpäisyhaavoittuvuus").
   - Tarkka tiedostopolku ja commit-hash, jossa ongelma esiintyy.
   - Mahdolliset askeleet ongelman todentamiseksi.

Pyrimme vastaamaan kaikkiin tietoturvailmoituksiin 48 tunnin kuluessa ja ryhtymään tarvittaviin toimenpiteisiin (kuten git-historian siivoamiseen) viipymättä. Tämä kanava on täysin luottamuksellinen.

## Tekninen tietoturvadokumentaatio

Projektin sisäiset tekniset riskikartoitukset ja tietoturva-auditoinnit on dokumentoitu erikseen (esim. `Quantify-FOF-Utilization-Costs/docs/security.md` sisältää riskiarviot polunläpäisyhaavoittuvuuksista ja tiedostojärjestelmän hallinnasta). Nämä dokumentit on tarkoitettu koodin kehittäjille ja ne kuvaavat järjestelmän sisäisiä kontrolleja.
