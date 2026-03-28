# agentify

Bootstrap any repo to code like the Anthropic team.

One command turns a bare repo into a structured, agent-native coding environment:
- Persistent project memory (`CLAUDE.md`)
- Slash commands for every stage of the loop (`/spec /plan /execute /review /mistake`)
- Subagent role definitions (implementer + reviewer, model-routed)
- Error corpus (`MISTAKES.md`) that compounds over time
- Spec history (`specs/`)
- Model routing config (`.claude/settings.json`)

This is the Boris Cherny workflow — spec → plan → execute → review → commit → repeat — dropped into any project in seconds.

---

## Usage

```bash
export AGENTIFY_PAT="<YOUR_GITHUB_PAT>"

./agentify.sh <repo-owner/repo-name> "<product description>" "<reviewer security focus>"
```

### Examples

```bash
# A payment API
./agentify.sh myorg/payments-api \
  "x402 micropayment gating for REST APIs" \
  "no hardcoded wallet addresses; fail-open on chain writes; payment stubs return false"

# A data pipeline
./agentify.sh myorg/pipeline \
  "ETL pipeline for on-chain event data" \
  "no API keys in source; idempotent writes; no data loss on retry"

# An agent service
./agentify.sh myorg/agent-svc \
  "MCP tool server for web search and summarization" \
  "no prompt injection; rate limit enforced; no PII logged"
```

---

## What gets added

```
.claude/
  agents/
    implementer.md   ← sonnet — write code, follow plan exactly, no deviations
    reviewer.md      ← opus — read-only, structured 🟢/🟡/🔴 report
  commands/
    spec.md          ← /spec  — convert intent to structured spec
    plan.md          ← /plan  — architecture plan, no code
    execute.md       ← /execute — approved plan execution
    review.md        ← /review — spec + convention + security check
    mistake.md       ← /mistake — log to MISTAKES.md
  settings.json      ← model routing: opus for judgment, sonnet for implementation
CLAUDE.md            ← project memory (appended, not overwritten)
MISTAKES.md          ← error corpus — append-only, weekly promote to CLAUDE.md
specs/               ← spec history, one file per feature
```

---

## The loop

```
/spec   →  write structured spec from plain English
/plan   →  architecture plan, file list, risks, acceptance criteria
           iterate until right
/execute →  agent writes all code, runs tests, reports
/review →  second agent checks spec compliance + security + conventions
           fix all 🔴 items
commit  →  clean, tested, reviewed code
/mistake → log anything that went wrong → feeds CLAUDE.md rules
```

You never type code. You type intent. The agents do the rest.

---

## The error corpus system

The compounding advantage. Every mistake logged in `MISTAKES.md` makes the next session better. Patterns that repeat get promoted to `CLAUDE.md` as permanent rules. After a few weeks, the agents know your codebase better than most humans would.

---

## Requirements

- GitHub PAT with repo write access
- `git`, `curl`, `jq` installed

---

*Inspired by Boris Cherny's workflow at Anthropic. Generalised for any project.*
