# Global Agent Instructions

One canonical file. Home Manager links it to `~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md` and `~/.config/opencode/AGENTS.md`, so every agent reads
the same rules.

Keep this file short. It describes *behaviour*, not any particular codebase.
Anything project-specific belongs in that project's own `AGENTS.md`.

## Working style

- Inspect the repository before modifying code.
- Prefer existing project conventions over introducing new ones.
- Make the smallest complete change that solves the problem.
- Do not silently change unrelated files.
- When making technical decisions, do not give much weight to development cost.
  Prefer quality, simplicity, robustness, scalability and long term
  maintainability.
- For one-off or infrequent operational work, start with the simplest direct
  end-to-end path. Do not build wrappers, control planes, policy layers, custom
  verifiers or automation unless the direct path exposes a concrete blocker or a
  repeated need that justifies the machinery.

## Bug fixes

Always start by reproducing the bug end-to-end, as closely as possible to how a
real user hits it. That is what makes the fix address the actual defect rather
than a plausible-looking symptom.

## Git

- Never force-push.
- Never delete branches unless explicitly requested.
- Never rewrite published history.
- Review `git diff` before committing.
- Do not commit secrets.
- When writing commit messages, never auto-add your agent name as co-author.
- Never manually modify `CHANGELOG.md` or any file marked as auto-generated.

## Validation

After code changes:

1. run the relevant formatter;
2. run static analysis;
3. run affected tests;
4. run the build when practical.

Do not claim validation succeeded unless the command actually ran. Report the
command and its real output.

Hold the same bar for engineering hygiene generally: if you see a lint error, a
failing test or a flaky test, fix it even when it is not caused by the work in
front of you.

When end-to-end testing a product, be picky about the UI and obsessive about
pixel alignment. If something looks off, get it fixed along the way.

## Dependencies

Do not introduce new dependencies without explaining why an existing dependency
or a standard-library solution is insufficient.

## Security

Never print or commit:

- API keys
- passwords
- access tokens
- private keys
- cloud credentials
- `.env` secrets

## Expensive harness features

Before using dynamic workflows, ultra code, or any feature that immediately
spawns a large swarm of subagents, explain the tradeoffs and ask for explicit
approval.

## Style

Never use the em dash. Use a plain dash instead.

## Completion report

When finished, provide:

1. Summary
2. Files changed
3. Design decisions
4. Tests executed
5. Test results
6. Known limitations
7. Follow-up work

Keep it short. The point is that supervision is predictable, not that the report
is long.

## Repository instructions

Always read the repository's own `AGENTS.md` before making changes. Repository
instructions override this file wherever they conflict.
