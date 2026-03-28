#!/usr/bin/env bash
# kindling-bootstrap — add Claude Code best-practice kit to a Kind-ling repo
# Usage: ./bootstrap.sh <repo-name> <product-description> <reviewer-security-focus>
# Example: ./bootstrap.sh flint "Moltbook social growth engine" "no fake accounts, no spam, no auto-upvotes"

set -euo pipefail

REPO="${1:?Usage: bootstrap.sh <repo-name> <product-description> <reviewer-security-focus>}"
PRODUCT_DESC="${2:?provide a product description}"
REVIEWER_FOCUS="${3:?provide reviewer security focus}"
PAT="${KINDLING_PAT:?set KINDLING_PAT env var}"
ORG="Kind-ling"
GIT_EMAIL="b1e55ed@permanentupperclass.com"
GIT_NAME="b1e55ed"

echo "→ Bootstrapping $ORG/$REPO..."

# Clone
WORKDIR="/tmp/kindling-bootstrap-$REPO"
rm -rf "$WORKDIR"
git clone "https://x-token:$PAT@github.com/$ORG/$REPO.git" "$WORKDIR"
cd "$WORKDIR"
git config user.email "$GIT_EMAIL"
git config user.name "$GIT_NAME"

# Directory structure
mkdir -p .claude/agents .claude/commands specs

# Slash commands (identical across all repos)
cat > .claude/commands/plan.md << 'EOF'
# Plan a feature or task

Read CLAUDE.md for project conventions.
Read MISTAKES.md for known pitfalls.

I'm going to describe what I want to build. Your job:

1. **Restate my intent** in your own words so I can confirm you understand.
2. **Identify the files** that need to be created or modified.
3. **List the steps** in numbered order, with estimated complexity (S/M/L) per step.
4. **Flag risks** — what could go wrong? What's ambiguous in my spec?
5. **Propose acceptance criteria** — how will we verify this works without reading the code?

**Do NOT write any code.** Plan only. I will review and iterate on the plan before giving the green light to execute.

If anything in my description contradicts CLAUDE.md conventions, flag it immediately.
EOF

cat > .claude/commands/execute.md << 'EOF'
# Execute an approved plan

Read CLAUDE.md for project conventions.
Read the plan we just agreed on.

The plan has been approved. Now execute it:

1. **Follow the plan exactly.** Do not deviate, add features, or "improve" things that weren't in the plan.
2. **If you discover the plan needs changes**, STOP immediately and explain. Do not improvise.
3. **Write all code in one pass** if the plan is simple. For complex plans, implement step by step and confirm after each step.
4. **Run tests** after implementation. Report results.
5. **Report what you did:**
   - Files created
   - Files modified
   - Tests passing/failing
   - Anything that surprised you

**Constraints:**
- Named exports only (no default exports)
- No `any` types
- No `console.log` (use structured logger)
- Tests in `tests/` directory, not `src/__tests__/`
- Conventional commits for any git operations
EOF

cat > .claude/commands/review.md << 'EOF'
# Review code against spec

Read CLAUDE.md for project conventions.
Read MISTAKES.md for known pitfalls.

Review the code that was just written. Check against:

1. **Original spec/acceptance criteria** — does it do what was asked?
2. **CLAUDE.md conventions** — does it follow all project rules?
3. **MISTAKES.md patterns** — does it repeat any known mistakes?
4. **Security** — especially around:
   - Payment handling (x402, wallet addresses)
   - Auth/authorization
   - Input validation
   - Error leakage (don't expose internals)
5. **Edge cases** — what happens with empty inputs, nulls, timeouts, rate limits?

**Output format:**
- 🟢 **Pass:** [thing that's correct]
- 🟡 **Warning:** [thing that works but could be better]
- 🔴 **Fail:** [thing that's wrong and must be fixed]

For each 🔴, provide the file, the problem, and the fix.

**Do NOT fix anything.** Review only. I'll route fixes to the appropriate agent.
EOF

cat > .claude/commands/mistake.md << 'EOF'
# Log a mistake to MISTAKES.md

Something went wrong. I'm going to describe what happened.

Your job:
1. Add an entry to MISTAKES.md with today's date
2. Use the standard format (date, what happened, expected, fix, root cause, rule candidate)
3. If this pattern already exists in MISTAKES.md, note that it's a repeat
4. If it's a repeat, draft the CLAUDE.md rule and suggest I promote it

**Be honest about root cause.** Was it:
- A vague spec? (my fault — I need to be more specific)
- A missing convention? (CLAUDE.md needs a new rule)
- A model limitation? (route to a different model next time)
- An edge case? (add to acceptance criteria template)
EOF

cat > .claude/commands/spec.md << 'EOF'
# Write a task spec

Read CLAUDE.md for project conventions and current product state.

I'm going to describe a task in plain English. Convert it into a structured spec using this exact format:

```markdown
## Task: [One-line description]

### Context
[What needs to be known about the project state]

### Goal
[What "done" looks like in plain English]

### Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]

### Constraints
- [Tech stack constraints from CLAUDE.md]
- [Patterns to follow]
- [Things NOT to do — reference MISTAKES.md]

### Files to Touch
- [Files to create or modify]

### Verify By
- [How to check without reading the code]
- [Tests, endpoints, UI checks]

### Model Routing
- [Suggested model: opus/sonnet/codex/flash]
- [Reason for routing choice]
```

Ask me clarifying questions if my description is too vague to write a good spec. Don't fill in gaps with assumptions — surface them as questions.
EOF

# MISTAKES.md template
cat > MISTAKES.md << 'EOF'
# MISTAKES.md — Error Corpus

> Append-only during the day. Review weekly.
> Patterns that repeat get promoted to CLAUDE.md as permanent rules.

## Template

```
### [Short description]
- **Date:** YYYY-MM-DD
- **What happened:** [What the agent did wrong]
- **Expected:** [What should have happened]
- **Fix:** [How it was corrected]
- **Root cause:** [vague spec? missing convention? model limitation?]
- **Rule candidate:** YES/NO — [draft rule for CLAUDE.md]
```

## Known patterns (promoted from twig — apply here too)

- JSON.parse on files from disk must always be in try/catch → return safe empty value + structured stderr warning
- Payment verification stubs must return `false` by default — fail-open in the gate, not in the verifier
- Define all type union variants before implementation begins — don't reuse variants for semantically different states
- After implementation, grep for variables assigned but never read (dead code = plan/implementation diverged silently)

## Log

*No entries yet.*
EOF

# settings.json
cat > .claude/settings.json << 'EOF'
{
  "model": "claude-sonnet-4-5",
  "agents": {
    "implementer": {
      "model": "claude-sonnet-4-5",
      "description": "Implementation tasks — well-specified, mechanical code"
    },
    "reviewer": {
      "model": "claude-opus-4-5",
      "description": "Security review, spec compliance, payment code audit"
    }
  },
  "modelRouting": {
    "architecture": "opus — design decisions, scoring rubric, taste",
    "implementation": "sonnet — pure functions, well-specified behavior",
    "tests": "sonnet — mechanical, well-specified",
    "security_review": "opus — payment handling, auth, fail-open logic",
    "documentation": "sonnet — spec-driven output"
  },
  "permissions": {
    "allow": [
      "Bash(npm test)",
      "Bash(npm run build)",
      "Bash(npm run typecheck)",
      "Bash(git status)",
      "Bash(git log*)",
      "Bash(git diff*)"
    ]
  }
}
EOF

# Product-specific agents
cat > .claude/agents/implementer.md << EOF
---
name: implementer
description: Executes approved implementation plans for $REPO. Scope: $PRODUCT_DESC. Does NOT make architectural decisions — follows the plan exactly.
model: claude-sonnet-4-5
tools: Read, Write, Edit, Bash
---

# Implementer — $REPO

You write code. You do not make architectural decisions.

## Before you start
1. Read \`CLAUDE.md\` — follow every convention without exception
2. Read \`MISTAKES.md\` — do not repeat any logged mistake
3. Read the spec file — this is your source of truth

## Scope
$PRODUCT_DESC

## Hard rules
- Named exports only — no default exports
- No \`any\` type — use \`unknown\` and narrow
- No \`console.log\` in \`src/\` — use \`process.stderr.write\` with structured JSON
- Tests use injected temp directories — never hardcode home paths
- Never hardcode wallet addresses or payment amounts — always parameterize
- Zero new dependencies unless the plan explicitly calls for one

## When to stop
- \`npm test\` fails → do NOT commit, report what failed
- Plan requires an architectural decision → STOP and ask
- Security issue the plan didn't address → STOP and flag it
EOF

cat > .claude/agents/reviewer.md << EOF
---
name: reviewer
description: Reviews code for $REPO against specs, conventions, and security. Read-only — does NOT write or fix code.
model: claude-opus-4-5
tools: Read, Bash
---

# Reviewer — $REPO

You find problems. You do not fix them.

## Before you start
1. Read \`CLAUDE.md\` — this is your review rubric
2. Read \`MISTAKES.md\` — check for repeated patterns
3. Read the original spec

## Product-specific security focus
$REVIEWER_FOCUS

## Standard checklist
1. Spec compliance — every acceptance criterion met?
2. CLAUDE.md conventions — named exports, no any, no console.log, tests in tests/
3. Security — no hardcoded addresses, fail-open intentional and visible, JSON.parse guarded, input validated
4. Edge cases — empty inputs, nulls, timeouts, file corruption
5. MISTAKES.md — any known patterns repeated?

## Output
🟢 Pass / 🟡 Warning / 🔴 Fail

For each 🔴: file, problem, exact fix. Do NOT fix anything.
EOF

# Append agent kit section to CLAUDE.md if it exists
if [ -f CLAUDE.md ]; then
  cat >> CLAUDE.md << 'EOF'

## Agent Kit

| File | Purpose |
|------|---------|
| `.claude/agents/implementer.md` | sonnet — write code, follow plan exactly |
| `.claude/agents/reviewer.md` | opus — read-only, structured pass/warn/fail |
| `.claude/commands/plan.md` | `/plan` — architecture plan, no code |
| `.claude/commands/execute.md` | `/execute` — approved plan execution |
| `.claude/commands/review.md` | `/review` — structured code review |
| `.claude/commands/mistake.md` | `/mistake` — log to MISTAKES.md |
| `.claude/commands/spec.md` | `/spec` — convert intent to structured spec |
| `MISTAKES.md` | Error corpus — append-only, feeds CLAUDE.md rules |
| `specs/` | Spec history |

Loop: `/spec` → `/plan` → iterate → `/execute` → `/review` → commit → `/mistake` (if needed)
EOF
fi

# Commit and push
git add -A
git commit -m "chore(infra): add Claude Code best-practice kit — agents, commands, settings, spec stub"
git push
echo "✅ $REPO bootstrapped"
