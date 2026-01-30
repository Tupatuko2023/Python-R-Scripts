# TASK: Verify MCP Setup (Windows)

**Status**: 01-ready
**Assigned**: Gemini
**Created**: 2026-01-30

## OBJECTIVE

Verifioi, että MCP-palvelimet (filesystem ja docker) toimivat odotetusti konfiguraatiokorjauksen ja uudelleenkäynnistyksen jälkeen.

## INPUTS

* `config/mcp_windows_fix.json` (applied to settings)
* `README.md` (target for read test)

## STEPS

1. **Tool Discovery**: Listaa agentin käytettävissä olevat työkalut. Varmista, että listassa näkyy `read_file` (filesystem) ja docker-työkalut.
2. **Filesystem Test**: Lue projektin `README.md` käyttäen MCP-työkalua.
3. **Docker Test**: Listaa kontit käyttäen MCP-työkalua (jos Docker päällä).

## ACCEPTANCE CRITERIA

* [ ] Agentti listaa työkalut ilman virheitä.
* [ ] `README.md` sisältö saadaan luettua.
* [ ] MCP-yhteys on stabiili (ei "Connection closed" -virheitä).
