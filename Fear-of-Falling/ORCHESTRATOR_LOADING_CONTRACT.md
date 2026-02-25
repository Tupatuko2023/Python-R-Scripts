# Orchestrator Loading Contract (S-FOF)

Tämä dokumentti määrittelee, miten Gemini CLI -agentin ohjeistus ("System Prompt") päivittyy ja miten se todennetaan Fear-of-Falling -projektin PowerShell 7 -orkestroinnissa.

## 1. Mitä "päivittyminen" tarkoittaa?

Gemini CLI -työkalulla ei ole pysyvää muistia ajojen välillä. Mallin ohjeistusta **ei voi päivittää pysyvästi taustalle**.

Päivitys tarkoittaa yksinomaan sitä, että `SYSTEM_PROMPT_POWERSHELL7_S-FOF.md` -tiedoston sisältöä muutetaan projektin repossa. Uusi ohjeistus astuu voimaan **vasta kun seuraava ajo käynnistetään** `run_gemini_orchestrator.ps1` -skriptillä. Skripti lukee tiedoston dynaamisesti ja injektoi sen osaksi mallille lähetettävää kontekstia jokaisessa yksittäisessä suorituksessa.

## 2. Miten päivitys todennetaan (Signature Validation)?

Jotta käyttäjä voi luottaa siihen, että malli käyttää oikeaa ja ajantasaista ohjeistusta, orkestrointiskripti noudattaa tiukkaa lataussopimusta (Loading Contract):

Ennen kuin kutsu lähetetään mallille, skripti tulostaa konsoliin ja transkriptio-lokiin kaksi varmistetta (Signature):

1. **Banner:** Tiedoston `SYSTEM_PROMPT_POWERSHELL7_S-FOF.md` ensimmäinen rivi (esim. `# GEMINI AGENT CONTEXT: Gemini PowerShell 7 Orchestrator GPT (S-FOF)`).
2. **SHA256 Hash:** Koko tiedoston kryptografinen tiiviste.

**Esimerkki lokitulosteesta:**

```text
-> System Prompt ladattu.
   Banner: # GEMINI AGENT CONTEXT: Gemini PowerShell 7 Orchestrator GPT (S-FOF)
   SHA256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855

```

*Tarkistamalla lokin SHA256-tiivisteen käyttäjä voi aukottomasti todentaa, että tehty muutos `SYSTEM_PROMPT_POWERSHELL7_S-FOF.md` -tiedostoon on siirtynyt agentin kontekstiin.*

## 3. Rajoitteet (Mikä EI ole mahdollista)

* Et voi pyytää agenttia "muistamaan" sääntöjä tästä hetkestä eteenpäin pelkällä chat-komennolla. Kaikki pysyvät säännöt on kirjattava `SYSTEM_PROMPT_POWERSHELL7_S-FOF.md` -tiedostoon.
* Agentti ei pysty päivittämään System Promptiaan itse lennosta siten, että se vaikuttaisi meneillään olevaan CLI-istuntoon ilman skriptin uudelleenkäynnistystä.
