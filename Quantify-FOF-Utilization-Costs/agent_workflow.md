# Agent Execution Protocol

Standard operating procedure for Gemini Agents gpa1qf-gpa4qf:

1. **Discovery**: 'git pull' to stay in sync with other agents.
2. **Work**: Move task to '02-in-progress', execute changes.
3. **Validation**: Run smoke tests and QC.
4. **Synchronization**: 'git push' changes to origin.
5. **Completion**: Move task to '04-done' ONLY after step 4 is confirmed.
