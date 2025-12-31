# GitHub CLI (gh) -asennuksen ja toimivuuden varmistus (Windows)

Tämä ohje auttaa varmistamaan, että GitHub CLI (`gh`) on asennettu oikein, löytyy `PATH`-ympäristömuuttujasta ja että kirjautuminen toimii.

## 1. Varmistus (avaa UUSI terminaali)

Aja komennot sen mukaan, käytätkö PowerShellia vai komentokehotetta (CMD).

### PowerShell
```powershell
gh --version
Get-Command gh
```
**Odotettu tulos:**
* `gh --version`: Tulostaa versionumeron (esim. `gh version 2.40.0 ...`).
* `Get-Command gh`: Tulostaa polun, jossa `gh.exe` sijaitsee (esim. `C:\Program Files\GitHub CLI\gh.exe`).

### CMD (Command Prompt)
```cmd
gh --version
where gh
```
**Odotettu tulos:**
* `gh --version`: Tulostaa versionumeron.
* `where gh`: Tulostaa `gh.exe`:n polun.

---

## 2. Jos komentoa ei löydy ("gh is not recognized")

Jos saat virheilmoituksen, `gh.exe` ei ole `PATH`:ssa. Älä arvaa. Selvitä tilanne diagnostiikkakomennoilla ennen korjausta.

### Diagnostiikka (ennen korjausta)
**PowerShell:**
```powershell
Get-Command gh
echo $env:Path
```
**CMD:**
```cmd
where gh
echo %PATH%
```
**Tulkinta:** Jos `Get-Command` tai `where` ei löydä mitään, tarkista `Path`-tulosteesta, puuttuuko GitHub CLI:n asennuskansio sieltä.

### Ratkaisu A: PATH-korjaus (jos tiedät asennuskansion)
1. Etsi kansio, jossa `gh.exe` sijaitsee.
2. Lisää kyseinen kansio Windowsin `Path`-ympäristömuuttujaan.
3. **Tärkeää:** Avaa uusi terminaali muutoksen jälkeen ja aja `gh --version` varmistaaksesi korjauksen.

### Ratkaisu B: Asenna uudelleen pakettimanagerilla
Jos et halua etsiä polkuja, asenna `gh` helposti pakettimanagerilla:

* **Winget:** `winget install --id GitHub.cli`
* **Chocolatey:** `choco install gh`
* **Scoop:** `scoop install gh`

---

## 3. Kirjautuminen

Kun `gh` toimii, kirjaudu sisään:

```bash
gh auth login
```
* Valitse `GitHub.com`.
* Valitse protokolla (HTTPS on yleensä helpoin).
* Kirjaudu selaimen kautta (default).

Tarkista kirjautumisen tila:
```bash
gh auth status
```
**Odotettu tulos:** Näet tekstin `Logged in to github.com as <username>`.

*(Valinnainen) Jos haluat käyttää gh:ta git-tunnusten hallintaan:*
```bash
gh auth setup-git
```

---

## 4. Smoke test (luku oikeus riittää)

Varmista toimivuus hakemalla julkista tietoa:

```bash
gh api user
# TAI
gh repo view cli/cli
```

**Yhteenveto:**
Jos `gh --version` palauttaa version, `gh auth status` näyttää käyttäjäsi ja `gh api user` palauttaa JSON-dataa, kaikki on kunnossa.