# DevForge

End-to-end web development pipeline for Claude Code. Feed it a BRD, get a built, tested, reviewed, and documented web app.

---

## What It Does

DevForge orchestrates sequential phases using specialised sub-agents. Two modes:

| Mode | Pipeline | Use when |
|------|----------|----------|
| **max** (default) | Parse → Select → Plan → Build → Test → Review → Docs → Learn | Production-ready output |
| **standard** | Parse → Select → Plan → Build → Test → Learn | Fast iteration, internal builds |

Each phase writes to `.pipeline/state.json` — the pipeline is fully resumable at any point.

---

## Installation

```bash
# Clone
git clone https://github.com/yourname/devforge
cd devforge

# Install
mkdir -p ~/.claude/skills/devforge/stacks
mkdir -p ~/.claude/agents

cp SKILL.md ~/.claude/skills/devforge/
cp stacks/*.md ~/.claude/skills/devforge/stacks/
cp brd-parser.md architect.md dev-executor.md test-runner.md \
   reviewer.md doc-generator.md learning-extractor.md ~/.claude/agents/
```

---

## Usage

In any Claude Code session:

```
/devforge my-project.docx
```

Or trigger phrases: `"build from BRD"`, `"run the pipeline"`, `"implement this spec"`

### Special Commands

| Command | Action |
|---------|--------|
| `resume` | Resume from last saved phase |
| `re-run feat-002` | Rebuild a specific feature + full regression |
| `review feat-003` | Feature review only, no phase change |
| `BRD updated, re-parse` | Re-parse BRD, diff changes, flag stale clarifications |
| `what phase is the pipeline in?` | Report current state |

---

## Pipeline Phases

| Phase | Agent | Output |
|-------|-------|--------|
| INIT | orchestrator | Project scaffolded, deps installed |
| BRD_PARSING | brd-parser | `.pipeline/brd-parsed.json` |
| FEATURE_SELECTION | orchestrator | Feature scope confirmed |
| PLANNED | architect | `impl-plan.md` + `feature-specs/feat-N.md` |
| EXECUTING | dev-executor + reviewer | Built features, per-feature reviews |
| TESTING | test-runner | `test-results.json`, manual checklist |
| REVIEWING | reviewer | `review-report.md` |
| DOCUMENTING | doc-generator | README, API docs, deployment guide |
| LEARNING | learning-extractor | `.pipeline/instincts/` updated |

### Gates (what blocks the pipeline)

| Gate | Condition |
|------|-----------|
| Plan approval | Human says "yes" |
| Feature review | Zero CRITICAL findings |
| Test coverage | ≥ 80% unit coverage + all E2E pass |
| Full review | Zero CRITICAL findings |

---

## Supported Stacks

| Stack ID | Description |
|----------|-------------|
| `nextjs14` | Next.js 14 · TypeScript · Tailwind · shadcn/ui |

### Adding a Stack

Create `stacks/{id}.md` with these sections:

```markdown
---
stack: {id}
label: "..."
---

## Scaffold        ← new project command
## Dev Dependencies
## Test Config
## Commands        ← build, typecheck, lint, dev, unit-test, e2e-test
## Dev Server Port
## File Structure
## Component Library
## Code Conventions
## Unit Test Pattern
## Performance Review Checks
## API Completeness Check
```

No agent edits needed — stack file is loaded at runtime via `state.stackFilePath`.

---

## File Structure

```
devforge/
  SKILL.md                  ← orchestrator (install to ~/.claude/skills/devforge/)
  stacks/
    nextjs14.md             ← stack config (install to ~/.claude/skills/devforge/stacks/)
  brd-parser.md             ← agents (install to ~/.claude/agents/)
  architect.md
  dev-executor.md
  test-runner.md
  reviewer.md
  doc-generator.md
  learning-extractor.md
```

### Runtime artifacts (generated per project)

```
.pipeline/
  state.json                ← resume point
  brd-parsed.json
  clarifications.json
  impl-plan.md
  feature-specs/
  feature-reviews/
  test-results.json
  manual-checklist.md
  review-report.md
  instincts/                ← learned patterns, grow over time
    architect.md
    dev-executor.md
    test-runner.md
```

---

## Learning System

After each completed pipeline run, `learning-extractor` analyses:
- Clarification patterns (recurring questions across features)
- Review findings (recurring WARNs = convention gaps)
- Test failure patterns

Presents each as a candidate for approval, then appends approved patterns to `.pipeline/instincts/`. Agents read these as standing instructions on the next run — the pipeline gets smarter with use.

---

## Requirements

- Claude Code (latest)
- Node.js 18+
- For BRD parsing: `pandoc` (preferred) or `python3` with `python-docx`
