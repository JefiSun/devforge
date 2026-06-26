---
name: devforge
description: End-to-end web development pipeline. Use this skill whenever: a .docx BRD is provided with a build request, user says "build from BRD / implement this spec / run the pipeline / develop this feature / re-run feat-X", or a multi-phase web development workflow is needed. Stack-agnostic — supports nextjs14, react-vite, and more via stack files. Works for both new and existing repos.
---

# Web Dev Pipeline

Orchestrates an 8-phase build pipeline. All state in `.pipeline/state.json` — resumable at any phase.

## Stack
- Next.js 14 App Router · TypeScript strict · Tailwind CSS · shadcn/ui
- Unit: Vitest + Testing Library · E2E: Playwright
- Models:
  - claude-sonnet-4-6: orchestrator, architect, dev-executor, reviewer, doc-generator, learning-extractor
  - claude-haiku-4-5:  brd-parser, project-scanner, test-runner

---

## State File

Read `.pipeline/state.json` first on every invocation. Write it after every phase.

```json
{
  "phase": "INIT",
  "project": {
    "name": "",
    "root": ".",
    "brdPath": "",
    "brdMode": "file",
    "isNewProject": true
  },
  "stack": "",
  "stackFilePath": "",
  "mode": "max",
  "selectedFeatures": [],
  "features": {
    "feat-001": { "status": "PENDING", "builtAt": null },
    "feat-002": { "status": "DONE", "builtAt": "2026-06-26T10:00:00Z" }
  },
  "artifacts": {
    "brdParsed": ".pipeline/brd-parsed.json",
    "implPlan": ".pipeline/impl-plan.md",
    "featureSpecs": ".pipeline/feature-specs/",
    "clarifications": ".pipeline/clarifications.json",
    "testResults": ".pipeline/test-results.json",
    "reviewReport": ".pipeline/review-report.md",
    "instincts": ".pipeline/instincts/"
  },
  "gates": {
    "planApproved": false,
    "testsPassed": false,
    "reviewPassed": false
  },
  "retries": { "test": 0 },
  "testFailureSignatures": []
}
```

Feature statuses: `PENDING → BUILDING → DONE → BLOCKED`
`selectedFeatures`: feat IDs to build. Empty = build all.

Phases:
- **max** (default): `INIT → BRD_PARSING → FEATURE_SELECTION → PLANNED → EXECUTING → TESTING → REVIEWING → DOCUMENTING → DONE → LEARNING`
- **standard**: `INIT → BRD_PARSING → FEATURE_SELECTION → PLANNED → EXECUTING → TESTING → DONE → LEARNING`
Any phase can become `BLOCKED_{PHASE}` on gate failure.

---

## How to Start

1. Check for `.pipeline/state.json` → if exists, resume from `state.phase`
2. If missing: determine input mode:
   - **File mode** — user provides a `.docx` path → set `state.project.brdPath`, `state.project.brdMode = "file"`
   - **Inline mode** — user types requirements as chat text (no docx) → write the text verbatim to `.pipeline/brd-raw.md` → set `state.project.brdPath = ""`, `state.project.brdMode = "inline"`
   - If unclear which mode → ask: `"BRD file path, or type your requirements here?"`
3. Ask: new or existing project → initialise state → create `.pipeline/` and `.pipeline/feature-specs/` dirs → set `phase = INIT`

---

## Phases

### INIT

**Select stack:**

For existing projects, read `package.json` to detect:
- Has `"next"` in dependencies → `nextjs14`
- Has `"nuxt"` in dependencies → `nuxt3`
- Has `"@vitejs/plugin-react"` and not `"next"` → `react-vite`
- Unrecognised → ask user

For new projects, ask:
```
Which stack?
  1. nextjs14   — Next.js 14 · TypeScript · Tailwind · shadcn/ui
  2. react-vite — React + Vite · TypeScript · Tailwind
  (more stacks: ~/.claude/skills/web-dev-pipeline/stacks/)
```

Set `state.stack = "{choice}"` and `state.stackFilePath = "~/.claude/skills/devforge/stacks/{choice}.md"` → write state.

**Select mode:**

```
Mode?
  1. max (default) — full pipeline: build → test → review → docs → learn
  2. standard      — build → test → learn  (skips review + docs)
```

If no answer → default `max`. Set `state.mode` → write state.

Read `state.stackFilePath`. From the stack file:

**New project:** run the `## Scaffold` command.

**Existing project:** confirm root path exists. Then ask:

```
How should I learn this project?
  1. instruction — I'll provide a file describing the project (faster, no codebase scan)
  2. scan        — auto-scan the codebase (slower, no prep needed)
```

- **instruction** → ask: `Path to your instruction file?` → spawn `agents/project-scanner.md` in INSTRUCTION mode. Pass: `instructionPath`.
- **scan** → spawn `agents/project-scanner.md` in SCAN mode. Pass: project root.

Both write `.pipeline/project-context.md`. All subsequent agents load this file instead of scanning independently.

**Both:** run the `## Dev Dependencies` commands, then run the `## Test Config` file writes.

Update `state.project` → set `phase = BRD_PARSING` → write state.

---

### BRD_PARSING

Check `state.project.brdMode`:
- `"file"` → spawn `agents/brd-parser.md`. Pass: `brdPath`, output path `.pipeline/brd-parsed.json`
- `"inline"` → spawn `agents/brd-parser.md` with `mode: INLINE`. Pass: output path `.pipeline/brd-parsed.json`. (`.pipeline/brd-raw.md` already written — brd-parser skips extraction and goes straight to Step 2)

On success → initialise `state.features` from parsed feature IDs (all status = PENDING) → set `phase = FEATURE_SELECTION` → write state.

**On BRD re-parse (user says "BRD updated, re-parse"):**
- Re-spawn brd-parser
- Diff new vs old `brd-parsed.json`
- For each changed feature, check `clarifications.json` — if clarification exists, ask:
  ```
  feat-002 changed in BRD. Previous clarification exists:
    Q: {question}
    A: {answer}
  Still valid? (yes / update)
  ```
- Report added/changed/removed features
- Ask which features to re-run (do not auto-decide)

---

### FEATURE_SELECTION

Read `.pipeline/brd-parsed.json`. Display feature list:

```
Features found in BRD:
  feat-001  [high]    Login
  feat-002  [high]    Master Data
  feat-003  [medium]  Transaction
  feat-004  [low]     Report      ⚠ INCOMPLETE
  feat-005  [low]     Logging

Build which features?
  Type: all  OR  feat IDs separated by commas (e.g. feat-002, feat-003)
```

Mark any feature with `"status": "incomplete"` with `⚠ INCOMPLETE` in the list.

**Before accepting input — INCOMPLETE gate:** if any features are marked INCOMPLETE, show:
```
⚠ {N} incomplete feature(s): feat-004 (Report)
  BRD section is too thin to build from. Options:
  a) Skip these features — exclude from this build
  b) Include anyway — architect will ask clarifying questions
```
Resolve per feature before proceeding. Set `status = "skipped"` in brd-parsed.json for skipped features.

**Accept only:**
- `all` → `selectedFeatures = []` (excludes skipped features automatically)
- Comma-separated IDs → `selectedFeatures = ["feat-002", "feat-003"]`
- If anything else typed → re-ask with the same prompt

**Dependency check:** for each selected feat, read its `dependencies` from brd-parsed.json. If a dependency is NOT selected:
```
⚠ feat-003 (Transaction) depends on feat-001 (Login) — not selected.
  a) Add feat-001 to this build
  b) Proceed anyway (feat-001 already exists in codebase)
  c) Cancel
```
Resolve all conflicts before continuing.

Save to `state.selectedFeatures` → set `phase = PLANNED` → write state.

---

### PLANNED

**Filter:** if `selectedFeatures` non-empty, extract only those features from `brd-parsed.json` into a filtered list. Pass filtered list to architect — not the full brd-parsed.json.

Spawn `agents/architect.md`. Pass: filtered feature list, project root, `isNewProject`, `.pipeline/instincts/architect.md` (if exists).

**Clarification loop (per feature, not all at once):**

Before writing any spec, architect reads each feature and checks if anything is unclear. For each feature with questions:
```
Questions for feat-002 (Master Data) — before I write the spec:
  1. What entities does this manage?
  2. Which operations: create / edit / delete / view?
  3. Role-based access required?

Answer these, then I'll move to the next feature.
```
Wait for answers. Save to `.pipeline/clarifications.json`. Continue to next feature. Only write specs after all features are clarified.

On success → show `impl-plan.md` → ask: **"Approve this plan? (yes / edit)"**
- **yes** → set `gates.planApproved = true`, `phase = EXECUTING` → write state
- **edit** → user edits `.pipeline/impl-plan.md` → re-ask
- Do not advance without explicit approval.

---

### EXECUTING

Read `.pipeline/feature-specs/`. If `selectedFeatures` non-empty, only process those IDs. Skip others.

Check `state.features[featId].status` — skip features already `DONE`.

For each feature (in order):
1. Set `state.features[featId].status = "BUILDING"` → write state
2. **Autopilot model selection** — read `autopilot` block from `agents/dev-executor.md` frontmatter. Apply its rules against the feature spec to pick a model. Never select a model listed under `never`.
3. Spawn `agents/dev-executor.md` with selected model. Pass: feature spec path, `.pipeline/clarifications.json`, `.pipeline/instincts/dev-executor.md` (if exists)
4. Confirm build exits 0
5. If build fails → fix inline → retry once → if still fails → set status = `"BLOCKED"`, `phase = BLOCKED_EXECUTING` → report to user → stop
6. On success → set `state.features[featId].status = "DONE"`, `builtAt = now` → write state
7. **Proactive feature review:** spawn `agents/reviewer.md` in `FEATURE_REVIEW` mode. Pass: feature spec path (so reviewer knows which files to check). Report findings immediately — CRITICAL blocks pipeline, WARN reported but continues.

After all features DONE → set `phase = TESTING` → write state.

---

### TESTING

Spawn `agents/test-runner.md`. Pass: project root, `.pipeline/brd-parsed.json`.

Read `.pipeline/test-results.json`:

**Pass:** `coveragePassed && unitTestsPassed && e2ePassed && i18nPassed` → set `gates.testsPassed = true` → write state.

Check `state.mode`:
- `max` → set `phase = REVIEWING`
- `standard` → set `phase = DONE` (skip REVIEWING + DOCUMENTING) → proceed directly to LEARNING

**Fail — stall detection before retry:**

Compute failure signature: for each failure, hash `"{testName}:{errorMessage}"`. Collect all hashes as a set.

Compare with `state.testFailureSignatures` (previous attempt's hashes):
- **Identical signatures** → same errors, no progress → **STALL detected**
  - Set `phase = BLOCKED_TESTING`, reason = `"STALL — identical failures across attempts"`
  - Report to user: exact failing tests + error messages + "These failures did not change after fix attempt — manual intervention required"
  - Stop.
- **Different signatures** → genuine change, retry warranted
  - Save current signatures to `state.testFailureSignatures` → write state
  - Increment `retries.test`
  - If `retries.test < 2`:
    - Spawn `agents/dev-executor.md` in FIX mode with `claude-haiku-4-5`. Pass: `.pipeline/test-results.json`
    - Re-spawn `agents/test-runner.md`
  - If `retries.test >= 2` → set `phase = BLOCKED_TESTING`, reason = `"MAX_RETRIES"` → report to user → stop

---

### REVIEWING

Spawn `agents/reviewer.md` in `FULL_REVIEW` mode. Pass: project root, `.pipeline/test-results.json`.

Note: a11y, security, and code quality were already checked per-feature during EXECUTING. Full review focuses on: bundle performance, cross-feature consistency, and any global checks that need the full codebase.

Read `.pipeline/review-report.md`:
- Overall = `PASS` → set `gates.reviewPassed = true`, `phase = DOCUMENTING` → write state
- Overall = `CRITICAL_FAIL` → set `phase = BLOCKED_REVIEWING` → report CRITICAL findings to user → stop

WARN findings do not block. Report alongside success.

---

### DOCUMENTING

Spawn `agents/doc-generator.md`. Pass: project root, `.pipeline/impl-plan.md`, `.pipeline/brd-parsed.json`.

On success → set `phase = DONE` → write state.

---

### DONE

Report to user:
- Features built (list with status)
- Unit coverage %, E2E pass/fail
- Review WARN count
- Docs: README.md, docs/API.md, docs/DEPLOYMENT.md

**WARN resolution (only if review WARN count > 0):**

List each WARN with file:line and ask:
```
{N} warnings found. Resolve now before closing?
  1. yes — fix all WARNs now (spawns dev-executor in FIX mode per WARN, then re-runs reviewer on affected files)
  2. later — log to .pipeline/open-warnings.md and continue
  3. skip — ignore
```

- **yes** → for each WARN: spawn `agents/dev-executor.md` in FIX mode with the WARN as input. After all fixed, spawn `agents/reviewer.md` in FEATURE_REVIEW mode on affected files. Update review-report.md. Then proceed.
- **later** → write `.pipeline/open-warnings.md` listing all unresolved WARNs. Proceed.
- **skip** → proceed.

Set `phase = LEARNING` → write state.

---

### LEARNING

Spawn `agents/learning-extractor.md`. Pass: `.pipeline/clarifications.json`, `.pipeline/review-report.md`, `.pipeline/test-results.json`, `.pipeline/instincts/` dir path.

Agent extracts patterns, presents each for approval, then writes approved patterns directly into `.pipeline/instincts/{agent}.md` files as standing instructions. No separate JSON — instincts are markdown instructions agents read directly.

Set `phase = COMPLETE` → write state.

---

## Special Commands

### Re-run a feature
User says: `"re-run feat-001"` or `"re-run feat-001, feat-002"`

1. Check `state.features` — confirm features exist
2. Warn if dependents exist:
   ```
   feat-002 (Master Data) depends on feat-001.
   Re-run feat-002 as well? (yes / no)
   ```
3. Set affected features status = `PENDING`
4. Set `phase = EXECUTING` → write state → resume pipeline from EXECUTING
5. Always run full regression tests after re-run (not just affected feature)

### Review only
User says: `"review feat-003"`
→ spawn reviewer.md with that feature's files only → report findings → do not change phase

### Update clarification
User says: `"clarification for feat-002 changed: {new answer}"`
1. Update `.pipeline/clarifications.json` for that feature (preserve `previousAnswer`)
2. Check dependents — warn if other features reference it
3. Ask: re-run feat-002? (yes / no / decide later)

---

## Gate Summary

| Gate | Condition | On Failure |
|------|-----------|------------|
| Plan approval | Human says yes | Wait, re-ask after edits |
| Tests | coverage ≥ 80% + all E2E pass | dev-executor fixes → retry once → BLOCKED |
| Review | Zero CRITICAL findings | BLOCKED, report to human |

## Resuming After BLOCKED

Read `state.phase` → read `state.features` for per-feature status → skip DONE features → resume from exact failure point. Never restart from INIT unless explicitly requested.

## Agents
- `agents/brd-parser.md` — DOCX → brd-parsed.json
- `agents/project-scanner.md` — INSTRUCTION (read provided file) or SCAN (auto-scan) → .pipeline/project-context.md (INIT, existing projects only)
- `agents/architect.md` — plan + feature specs + clarifications
- `agents/dev-executor.md` — sequential Next.js build + test fixes
- `agents/test-runner.md` — unit + E2E + manual checklist (report only)
- `agents/reviewer.md` — FEATURE_REVIEW (per feature) + FULL_REVIEW (post-test)
- `agents/doc-generator.md` — README + API + deployment docs
- `agents/learning-extractor.md` — extract patterns → write instinct files
