# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root, or
- **`GLOSSARY-MAP.md`** at the repo root if it exists. It points at one `GLOSSARY.md` per context. Read each one that is relevant to the topic.
- **`docs/adr/`**: read ADRs that touch the area of the work.

If these files do not exist, **proceed silently**. Do not flag the absence. Do not suggest creating them upfront. The `/domain-modeling` skill creates them when terms or decisions get resolved. `/domain-modeling` is reached via `/grill-with-docs` and `/improve-codebase-architecture`.

## File structure

This repo is single-context:

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── 0001-example-decision.md
│   └── 0002-example-decision.md
├── models/        ← dbt models: staging → intermediate → marts
├── seeds/
└── tests/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Do not drift to synonyms the glossary explicitly avoids.

If the concept is not in the glossary yet, that is a signal. Either you invent language the project does not use (reconsider), or there is a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly. Do not override it silently.

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
