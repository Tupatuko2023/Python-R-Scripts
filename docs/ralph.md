# Ralph (snarktank/ralph) – asennus tähän repoosi

Tässä repossa Ralph on vendoroitu hakemistoon `scripts/ralph/`.

## Esivaatimukset

- `jq`
- Amp CLI **tai** Claude Code (`npm install -g @anthropic-ai/claude-code`)

## Käyttö (yleinen idea)

1. Tee/tuo PRD `prd.json`-muotoon (voit aloittaa `prd.json.example`-pohjasta).
2. Päätä käytätkö Ampia vai Claude Codea:
   - Amp: käytä `scripts/ralph/prompt.md`
   - Claude Code: käytä `scripts/ralph/CLAUDE.md`
3. Aja Ralph:
   - Varmista että olet projektin juuressa
   - Suorita: `./scripts/ralph/ralph.sh`

## Missä “muisti” elää?

- Git-historiassa, `progress.txt`-tiedostossa ja `prd.json`-tiedostossa.
