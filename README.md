# DevForge

End-to-end web development pipeline for Claude Code. Give it a BRD file or paste requirements directly — get a built, tested, reviewed, and documented web app.

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

### Claude Code

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 | iex
```

### GitHub Copilot CLI

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --copilot
```

**Windows (PowerShell):**
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1))) -Copilot
```

> Install for both: pass `--both` / `-Both`. Uninstall: add `--uninstall` / `-Uninstall`. See [install.md](install.md) for full details.

---

## Usage

Two ways to start the pipeline:

### Option 1 — BRD File (`.docx`)

Have a Word document with requirements? Point DevForge at it:

```
/devforge path/to/my-project.docx
```

Or in plain language:
```
build from BRD: path/to/my-project.docx
run the pipeline with specs/labdesk-brd.docx
```

DevForge extracts text via pandoc or python-docx, parses features, then runs the full pipeline.

**Requirements:** `pandoc` (preferred) or `python3 + python-docx` — see [Requirements](#requirements).

---

### Option 2 — Inline Requirements (chat)

No docx? Just type your requirements directly:

```
run the pipeline

Requirements:
- Build a task management app
- Users can create, edit, delete tasks
- Tasks have title, description, due date, priority (high/medium/low)
- Dashboard shows tasks grouped by status (todo/in-progress/done)
- Filter tasks by priority and due date
```

Or trigger naturally:
```
implement this spec:
[paste requirements here]
```

DevForge writes your text to `.pipeline/brd-raw.md`, skips docx extraction, and parses it as-is. No file needed — useful for quick builds, prototypes, or when requirements live in a doc you can copy-paste.

**Tip:** More detail = better feature specs. Include acceptance criteria when you have them.

---

### Special Commands

| Command | Action |
|---------|--------|
| `resume` | Resume from last saved phase |
| `re-run feat-002` | Rebuild a specific feature + full regression |
| `review feat-003` | Feature review only, no phase change |
| `BRD updated, re-parse` | Re-parse BRD, diff changes, flag stale clarifications |
| `clarification for feat-002 changed: {answer}` | Update clarification, warn dependents, optionally re-run |
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
| DONE | orchestrator | Summary report, optional WARN resolution |
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
  project-scanner.md
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
  brd-raw.md                ← extracted/inline requirements text
  brd-parsed.json
  project-context.md        ← existing projects only (from project-scanner)
  clarifications.json
  impl-plan.md
  feature-specs/
  test-results.json
  review-report.md
  open-warnings.md          ← created if WARNs deferred at DONE
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

- Claude Code (latest) **or** GitHub Copilot CLI (latest)
- Node.js 18+
- For BRD **file** mode only: `pandoc` (preferred) or `python3` with `python-docx`. Not needed for inline mode.
