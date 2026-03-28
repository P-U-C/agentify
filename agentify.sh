#!/usr/bin/env bash
# agentify — bootstrap any repo to code like the Anthropic team
# Usage: ./agentify.sh <owner/repo> "<product description>" "<reviewer security focus>"
# Requires: AGENTIFY_PAT env var (GitHub PAT with repo write access)

set -euo pipefail

REPO_FULL="${1:?Usage: agentify.sh <owner/repo> <product-description> <reviewer-security-focus>}"
PRODUCT_DESC="${2:?provide a product description}"
REVIEWER_FOCUS="${3:?provide reviewer security focus}"
PAT="${AGENTIFY_PAT:?set AGENTIFY_PAT env var to a GitHub PAT with repo write access}"

OWNER="${REPO_FULL%%/*}"
REPO="${REPO_FULL##*/}"
GIT_EMAIL="${AGENTIFY_GIT_EMAIL:-agent@agentify.dev}"
GIT_NAME="${AGENTIFY_GIT_NAME:-agentify}"

echo "→ Agentifying $OWNER/$REPO..."

WORKDIR="/tmp/agentify-$REPO-$$"
rm -rf "$WORKDIR"
git clone "https://x-token:$PAT@github.com/$OWNER/$REPO.git" "$WORKDIR"
cd "$WORKDIR"
git config user.email "$GIT_EMAIL"
git config user.name "$GIT_NAME"

mkdir -p .claude/agents .claude/commands specs

# ── Slash commands ────────────────────────────────────────────────────────────

cat > .claude/commands/spec.md << 'EOF'
# Write a task spec

Read CLAUDE.md for project conventions and current product state.

I'm going to describe a task in plain English. Convert it into a structured spec:

```markdown
## Task: [One-line description]

### Context
[Project state relevant to this task]

### Goal
[What "done" looks like in plain English]

### Acceptance Criteria
- [ ] [Specific, testable criterion]

### Constraints
- [Tech stack constraints from CLAUDE.md]
- [Things NOT to do — reference MISTAKES.md]

### Files to Touch
- [Files to create or modify]

### Verify By
- [How to check without reading the code]

### Model Routing
- [opus/sonnet/flash — and why]
```

Ask clarifying questions if my description is too vague. Don't fill gaps with assumptions.
EOF

cat > .claude/commands/plan.md << 'EOF'
# Plan a feature or task

Read CLAUDE.md for project conventions.
Read MISTAKES.md for known pitfalls.

I will describe what I want to build. Your job:

1. Restate my intent in your own words (confirm understanding)
2. Identify all files to create or modify
3. List steps in numbered order with complexity (S/M/L) per step
4. Flag risks — what could go wrong? What's ambiguous?
5. Propose acceptance criteria — how to verify without reading the code?

Do NOT write any code. Plan only.

Flag any contradictions with CLAUDE.md conventions immediately.
EOF

cat > .claude/commands/execute.md << 'EOF'
# Execute an approved plan

Read CLAUDE.md for project conventions.
Read the approved plan.

Execute it:
1. Follow the plan exactly. Do not deviate or add features.
2. If the plan needs changes, STOP and explain. Do not improvise.
3. Write all code in one pass for simple plans; step by step for complex ones.
4. Run tests after implementation.
5. Report: files created, files modified, tests passing/failing, anything surprising.

Hard constraints:
- Named exports only (no default exports)
- No `any` types
- No `console.log` in production code
- Tests in `tests/` mirroring `src/` structure
- Conventional commits
EOF

cat > .claude/commands/review.md << 'EOF'
# Review code against spec

Read CLAUDE.md for project conventions.
Read MISTAKES.md for known pitfalls.

Review the code just written. Check:
1. Spec/acceptance criteria — does it do what was asked?
2. CLAUDE.md conventions — named exports, no any, no console.log, correct test location
3. MISTAKES.md patterns — any known mistakes repeated?
4. Security — payment handling, auth, input validation, no hardcoded secrets
5. Edge cases — empty inputs, nulls, timeouts, rate limits, file corruption

Output:
- 🟢 Pass: [what's correct]
- 🟡 Warning: [works but could be better — non-blocking]
- 🔴 Fail: [wrong, must be fixed]

For each 🔴: file path, exact problem, exact fix.
Do NOT fix anything. Review only.
EOF

cat > .claude/commands/mistake.md << 'EOF'
# Log a mistake to MISTAKES.md

Something went wrong. Describe what happened.

Add an entry to MISTAKES.md:
- Today's date
- What happened
- What was expected
- How it was fixed
- Root cause (vague spec? missing convention? model limitation?)
- Rule candidate: YES/NO — if YES, draft the CLAUDE.md rule

If this pattern already exists in MISTAKES.md, note it's a repeat and escalate to a CLAUDE.md rule.
EOF

# ── MISTAKES.md ───────────────────────────────────────────────────────────────

cat > MISTAKES.md << 'EOF'
# MISTAKES.md — Error Corpus

> Append-only during the day. Review weekly.
> Patterns that repeat get promoted to CLAUDE.md as permanent rules.
> Format: date → what happened → fix → root cause → rule candidate

## Template

```
### [Short description]
- **Date:** YYYY-MM-DD
- **What happened:** [What the agent did wrong]
- **Expected:** [What should have happened]
- **Fix:** [How it was corrected]
- **Root cause:** [vague spec? missing convention? model limitation?]
- **Rule candidate:** YES/NO — [draft rule if YES]
```

## Log

*No entries yet.*
EOF

# ── settings.json ─────────────────────────────────────────────────────────────

cat > .claude/settings.json << 'EOF'
{
  "model": "claude-sonnet-4-5",
  "agents": {
    "implementer": {
      "model": "claude-sonnet-4-5",
      "description": "Implementation — mechanical, well-specified code"
    },
    "reviewer": {
      "model": "claude-opus-4-5",
      "description": "Security review, spec compliance, payment code"
    }
  },
  "modelRouting": {
    "architecture_decisions": "opus",
    "implementation": "sonnet",
    "tests": "sonnet",
    "security_review": "opus",
    "documentation": "sonnet",
    "data_research": "flash"
  },
  "permissions": {
    "allow": [
      "Bash(npm test)",
      "Bash(npm run build)",
      "Bash(npm run typecheck)",
      "Bash(pytest)",
      "Bash(git status)",
      "Bash(git log*)",
      "Bash(git diff*)"
    ]
  }
}
EOF

# ── Product-specific agents ───────────────────────────────────────────────────

cat > .claude/agents/implementer.md << EOF
---
name: implementer
description: Executes approved implementation plans. Scope: $PRODUCT_DESC. Follows the plan exactly — no architectural decisions.
model: claude-sonnet-4-5
tools: Read, Write, Edit, Bash
---

# Implementer

You write code. You do not make architectural decisions.

## Before you start
1. Read \`CLAUDE.md\` — follow every convention without exception
2. Read \`MISTAKES.md\` — do not repeat any logged mistake
3. Read the spec — this is your source of truth

## Scope
$PRODUCT_DESC

## Hard rules
- Follow CLAUDE.md conventions exactly
- Named exports only — no default exports
- No \`any\` type — use \`unknown\` and narrow
- No \`console.log\` in production code
- Tests mirror \`src/\` structure in \`tests/\`
- Never hardcode secrets, API keys, or credentials
- Zero new dependencies unless the plan explicitly calls for one

## Stop conditions
- Tests fail → do NOT commit, report what failed
- Plan requires an undocumented architectural decision → STOP and ask
- Security issue not covered by the plan → STOP and flag it
EOF

cat > .claude/agents/reviewer.md << EOF
---
name: reviewer
description: Reviews code for $REPO. Read-only. Security focus: $REVIEWER_FOCUS
model: claude-opus-4-5
tools: Read, Bash
---

# Reviewer

You find problems. You do not fix them.

## Before you start
1. Read \`CLAUDE.md\` — this is your review rubric
2. Read \`MISTAKES.md\` — check for repeated patterns
3. Read the original spec

## Security focus for this project
$REVIEWER_FOCUS

## Standard checklist
1. Spec compliance — every acceptance criterion met?
2. CLAUDE.md conventions — naming, exports, error handling, test location
3. Security — hardcoded secrets, input validation, error leakage, fail-open logic
4. Edge cases — empty inputs, nulls, timeouts, file corruption, rate limits
5. MISTAKES.md — any known patterns repeated?

## Output format
🟢 Pass: [correct]
🟡 Warning: [non-blocking, could be better]
🔴 Fail: [must fix before merge]

For each 🔴: file path, exact problem, exact fix.
Do NOT fix anything.
EOF

# ── Append to CLAUDE.md ───────────────────────────────────────────────────────

if [ -f CLAUDE.md ]; then
  cat >> CLAUDE.md << 'EOF'

## Agent Workflow (agentify)

Loop: `/spec` → `/plan` → iterate → `/execute` → `/review` → commit → `/mistake`

| File | Purpose |
|------|---------|
| `.claude/agents/implementer.md` | sonnet — write code, follow plan exactly |
| `.claude/agents/reviewer.md` | opus — read-only, structured 🟢/🟡/🔴 |
| `.claude/commands/spec.md` | /spec — intent → structured spec |
| `.claude/commands/plan.md` | /plan — architecture plan, no code |
| `.claude/commands/execute.md` | /execute — approved plan execution |
| `.claude/commands/review.md` | /review — spec + security + conventions |
| `.claude/commands/mistake.md` | /mistake — log error, feed corpus |
| `MISTAKES.md` | Error corpus — append-only, weekly → CLAUDE.md |
| `specs/` | Spec history |
EOF
else
  cat > CLAUDE.md << EOF
# CLAUDE.md — Project Memory

> Read this at the start of every session.

## Project
$PRODUCT_DESC

## Agent Workflow (agentify)

Loop: \`/spec\` → \`/plan\` → iterate → \`/execute\` → \`/review\` → commit → \`/mistake\`

| File | Purpose |
|------|---------|
| \`.claude/agents/implementer.md\` | sonnet — write code, follow plan exactly |
| \`.claude/agents/reviewer.md\` | opus — read-only, structured 🟢/🟡/🔴 |
| \`.claude/commands/\` | /spec /plan /execute /review /mistake |
| \`MISTAKES.md\` | Error corpus — append-only, weekly → CLAUDE.md |
| \`specs/\` | Spec history |

## Conventions
- Named exports only
- No \`any\` type
- No \`console.log\` in production code
- Tests in \`tests/\` mirroring \`src/\`
- Conventional commits

## Mistakes Log Reference
See \`MISTAKES.md\`. Patterns that repeat become rules here.
EOF
fi

# ── Commit and push ───────────────────────────────────────────────────────────

git add -A
git commit -m "chore: agentify — add Claude Code best-practice kit"
git push
echo "✅ $OWNER/$REPO agentified"
