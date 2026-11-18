# AGENTS.md — Quantify-FOF-Utilization-Costs

Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku ja siivous) noudatetaan
repojuuren ohjeita [../SKILLS.md](../SKILLS.md) ja [../AGENTS.md](../AGENTS.md)
sekä tämän aliprojektin [WORKFLOW.md](WORKFLOW.md)- ja
[agent_workflow.md](agent_workflow.md)-ohjeita säilyttäen oma tehtäväjono
(`Quantify-FOF-Utilization-Costs/tasks/`). Tutkimusaineistossa, Option B
-tietosuojassa (`DATA_ROOT`, `n < 5`) ja koodistandardeissa noudatetaan tiukasti
[GEMINI.md](GEMINI.md)- ja [CLAUDE.md](CLAUDE.md)-tiedostoja. Aliprojektin
analyysiskriptit ajetaan tästä hakemistosta ja päärepon portti-/rekisterikomennot
worktreen repojuuresta.

## Conflict Resolution Protocol

1. **Always Diff**: Before resolving conflicts, explicitly show the difference (lines added/removed) between local and remote versions.
2. **No Data Loss**: Never silently discard remote changes without explicit justification. Prefer UNION (merge) operations for data files.
3. **Schema Adaptation**: If schemas differ, map remote columns to the local schema rather than overwriting the file.
