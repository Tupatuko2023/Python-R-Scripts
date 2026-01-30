# TASK: Verify GitHub MCP Connection (Windows)

**Status**: 01-ready
**Assigned**: Gemini
**Created**: 2026-01-30

## OBJECTIVE

Varmista, että GitHub-työkalut ovat käytettävissä ja että Agentti saa yhteyden GitHub APIin (Token validointi).

## INPUTS

* `GITHUB_PERSONAL_ACCESS_TOKEN` (Environment Variable)
* Agent restart (to apply settings)

## STEPS

1. **Tool Discovery**: Listaa työkalut. Etsi GitHub-spesifejä työkaluja (esim. `github_search_repositories`, `github_get_issue` jne. riippuen serverin versiosta).
2. **Connectivity Test**: Suorita kevyt hakukomento, esim. etsi tämän repon nimi tai julkinen repo "modelcontextprotocol".
    * *Huom: Älä tee kirjoitusoperaatioita (issue/PR) testin aikana.*

## ACCEPTANCE CRITERIA

* [ ] GitHub-työkalut näkyvät työkalulistassa.
* [ ] Hakukomento palauttaa tuloksia (ei 401/403 virheitä).
