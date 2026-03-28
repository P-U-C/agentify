# kindling-bootstrap

Adds the Claude Code best-practice kit to any Kind-ling repo in one command.

## Usage

```bash
export KINDLING_PAT="<YOUR_KINDLING_PAT>"

./bootstrap.sh <repo-name> "<product description>" "<reviewer security focus>"
```

## Examples

```bash
./bootstrap.sh twig \
  "MCP description optimizer — score and rewrite tool descriptions for agent discoverability" \
  "payment verification must not accept arbitrary tx hashes; wallet addresses never hardcoded"

./bootstrap.sh heat \
  "Reputation oracle — dual-graph scoring via Moltbook social + x402 economic graph" \
  "graph manipulation resistance; x402 payment verification; wallet address handling"

./bootstrap.sh flint \
  "Moltbook social growth engine — analyze, optimize, schedule agent posts" \
  "no fake accounts; no auto-upvotes; no spam; no impersonation"
```

## What gets added

```
.claude/
  agents/
    implementer.md   ← sonnet, product-scoped, code only
    reviewer.md      ← opus, product-scoped security focus, read-only
  commands/
    plan.md          ← /plan
    execute.md       ← /execute
    review.md        ← /review
    mistake.md       ← /mistake
    spec.md          ← /spec
  settings.json      ← model routing table
MISTAKES.md          ← error corpus (with known patterns from twig pre-seeded)
specs/               ← created, ready for SPEC_001.md
CLAUDE.md            ← agent kit section appended
```

## New repo checklist

1. Create repo on GitHub
2. Push initial code
3. Run `./bootstrap.sh <repo> "<desc>" "<security focus>"`
4. Write `specs/<PRODUCT>_SPEC_001.md`
5. Start first session: "Read CLAUDE.md. Open specs/SPEC_001.md and run /plan."
