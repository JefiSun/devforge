# Devforge Per-Feature Sub-Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand EXECUTING phase to run build → review → scoped-test → commit per feature before the global test/review phases.

**Architecture:** Two markdown files edited — `SKILL.md` gets an expanded per-feature loop and a TESTING reset block; `test-runner.md` gets a new FEATURE mode section for scoped unit tests. No code, no tests — verification is reading changed sections.

**Tech Stack:** Markdown skill files. Git for commit verification.

---

### Task 1: Update state JSON in SKILL.md

**Files:**
- Modify: `SKILL.md` — state JSON block (lines ~53, ~44)

- [ ] **Step 1: Add `featureTest` to retries block**

Find:
```
  "retries": { "test": 0 },
```

Replace with:
```
  "retries": { "test": 0, "featureTest": {} },
```

- [ ] **Step 2: Add `featureTestResults` to artifacts block**

Find:
```
    "testResults": ".pipeline/test-results.json",
```

Replace with:
```
    "featureTestResults": ".pipeline/test-results-{featId}.json",
    "testResults": ".pipeline/test-results.json",
```

- [ ] **Step 3: Verify**

State JSON block contains both `featureTest: {}` in retries and `featureTestResults` pattern in artifacts. All other fields intact.

---

### Task 2: Expand EXECUTING per-feature loop in SKILL.md

**Files:**
- Modify: `SKILL.md` — EXECUTING section

- [ ] **Step 1: Replace the EXECUTING loop body**

Find this entire block (from `Read` through end of numbered list before `After all features`):
```
Read `.pipeline/feature-specs/`. Process all feature specs in order.

Check `state.features[featId].status` — skip features already `DONE`.

For each feature (in order):
1. Set `state.features[featId].status = "BUILDING"` → write state
2. **Autopilot model selection** — read `autopilot` block from `agents/dev-executor.md` frontmatter. Apply its rules against the feature spec to pick a model. Never select a model listed under `never`.
3. Spawn `agents/dev-executor.md` with selected model. Pass: feature spec path, `.pipeline/clarifications.json`, `.pipeline/instincts/dev-executor.md` (if exists)
4. Confirm build exits 0
5. If build fails → fix inline → retry once → if still fails → set status = `"BLOCKED"`, `phase = BLOCKED_EXECUTING` → report to user → stop
6. On success → set `state.features[featId].status = "DONE"`, `builtAt = now` → write state
7. **Proactive feature review:** spawn `agents/reviewer.md` in `FEATURE_REVIEW` mode. Pass: feature spec path (so reviewer knows which files to check). Report findings immediately — CRITICAL blocks pipeline, WARN reported but continues.
```

Replace with:
```
Read `.pipeline/feature-specs/`. Process all feature specs in order.

Check `state.features[featId].status` — skip features already `DONE`.

For each feature (in order):
1. Set `state.features[featId].status = "BUILDING"` → initialize `state.retries.featureTest[featId] = 0` → write state
2. **Autopilot model selection** — read `autopilot` block from `agents/dev-executor.md` frontmatter. Apply its rules against the feature spec to pick a model. Never select a model listed under `never`.
3. Spawn `agents/dev-executor.md` with selected model. Pass: feature spec path, `.pipeline/clarifications.json`, `.pipeline/instincts/dev-executor.md` (if exists)
4. Confirm build exits 0
5. If build fails → fix inline → retry once → if still fails → set status = `"BLOCKED"`, `phase = BLOCKED_EXECUTING` → report to user → stop
6. **Proactive feature review:** spawn `agents/reviewer.md` in `FEATURE_REVIEW` mode. Pass: feature spec path. CRITICAL → block pipeline. WARN → report and continue.
7. **Feature-scoped test:** spawn `agents/test-runner.md` in `FEATURE` mode. Pass: feature spec path, feat ID. Writes `.pipeline/test-results-{featId}.json`.
8. If feature tests fail:
   - If `state.retries.featureTest[featId] < 1` → spawn `agents/dev-executor.md` in FIX mode. Pass: `.pipeline/test-results-{featId}.json`. Increment `state.retries.featureTest[featId]` → write state. Re-run step 7.
   - If `state.retries.featureTest[featId] >= 1` → set status = `"BLOCKED"`, `phase = BLOCKED_EXECUTING` → report to user → stop.
9. If feature tests pass → git commit (stage files listed in the feature spec as created/modified) → set `state.features[featId].status = "DONE"`, `builtAt = now` → write state.
```

- [ ] **Step 2: Verify**

EXECUTING section has 9 steps per feature. Steps 7–9 are new (feature test, retry logic, commit). Step 6 is the proactive review (was step 7). Step 6 no longer sets status = DONE directly.

---

### Task 3: Add reset block to TESTING phase in SKILL.md

**Files:**
- Modify: `SKILL.md` — TESTING section

- [ ] **Step 1: Add reset before test-runner spawn**

Find:
```
Spawn `agents/test-runner.md`. Pass: project root.
```

Replace with:
```
Reset state before global run: set `state.retries.featureTest = {}`, `state.retries.test = 0`, `state.testFailureSignatures = []` → write state.

Spawn `agents/test-runner.md`. Pass: project root.
```

- [ ] **Step 2: Verify**

TESTING section now resets featureTest, test retry counter, and failure signatures before spawning test-runner. All other TESTING logic unchanged.

---

### Task 4: Add FEATURE mode to test-runner.md

**Files:**
- Modify: `test-runner.md`

- [ ] **Step 1: Update Input section to document both modes**

Find:
```
## Input
- Project root
- `.pipeline/brd-parsed.json` (for manual checklist)
```

Replace with:
```
## Input

**Global mode (default):**
- Project root

**FEATURE mode:**
- `featureSpecPath` — path to the feature spec file
- `featId` — feature ID (e.g. `feat-001`)
```

- [ ] **Step 2: Add mode routing check after Input section**

Find:
```
---

## Step 0: Load Stack Commands
```

Replace with:
```
---

**Mode routing:** If invoked with `featureSpecPath` and `featId`, run [FEATURE Mode](#feature-mode) below. Otherwise run Steps 0–4 (global mode).

---

## Step 0: Load Stack Commands
```

- [ ] **Step 3: Add FEATURE mode section at end of file**

Find:
```
## Done
Return: `"Tests complete. Unit: {passed}/{total} ({coverage}% coverage, {failed} failing). E2E: {passed}/{total}. i18n: {OK|MISSING {N} keys}. Gate: {PASS|FAIL}."`

If FAIL, list each failure name and error — orchestrator passes this to dev-executor.
```

Replace with:
```
## Done
Return: `"Tests complete. Unit: {passed}/{total} ({coverage}% coverage, {failed} failing). E2E: {passed}/{total}. i18n: {OK|MISSING {N} keys}. Gate: {PASS|FAIL}."`

If FAIL, list each failure name and error — orchestrator passes this to dev-executor.

---

## FEATURE Mode

Run scoped unit tests for a single feature. No E2E. No coverage gate. No manual checklist.

### Step F0: Load Stack Commands

```bash
cat .pipeline/state.json
```

Read `state.stackFilePath`. Read stack file. Extract unit test command.

### Step F1: Identify Feature Files

Read `{featureSpecPath}`. Extract the list of files this feature creates or modifies. These are the files whose tests will be scoped.

If the feature spec does not list files explicitly, look for a `## Files` or `## Implementation` section. If still unclear, run all unit tests (treat as global unit run, skip E2E).

### Step F2: Run Scoped Unit Tests

Run the unit test command from the stack file, scoped to the feature's files.

For Vitest (Next.js / React-Vite stack):
```bash
npx vitest run --reporter=verbose {file1} {file2} ...
```
Where `{file1}`, `{file2}` are the test files corresponding to the feature's source files (look for `*.test.ts`, `*.spec.ts`, `*.test.tsx`, `*.spec.tsx` alongside or in `__tests__/` near each source file).

If no test files found for this feature's files, report: `"No unit tests found for {featId} files — unitTestsPassed = true (no tests to fail)."` Write results and return PASS.

Parse output for:
- Total tests, passed, failed
- Failed test names and exact error messages

### Step F3: Write Feature Test Results

Write `.pipeline/test-results-{featId}.json`:

```json
{
  "timestamp": "{ISO timestamp}",
  "featId": "{featId}",
  "mode": "FEATURE",
  "unit": {
    "total": 0,
    "passed": 0,
    "failed": 0,
    "failures": [
      { "name": "test name", "error": "exact error message" }
    ]
  },
  "unitTestsPassed": false
}
```

`unitTestsPassed = unit.failed === 0`

### Done (FEATURE mode)

Return: `"Feature tests complete for {featId}. Unit: {passed}/{total} ({failed} failing). Gate: {PASS|FAIL}."`

If FAIL, list each failure name and error — orchestrator passes this to dev-executor FIX mode.
```

- [ ] **Step 4: Verify**

`test-runner.md` has updated Input section (both modes documented), mode routing line after Input, and new `## FEATURE Mode` section at bottom with steps F0–F3 and FEATURE Done block.

---

### Task 5: Final scan and commit

- [ ] **Step 1: Scan SKILL.md for consistency**

Check:
- EXECUTING step 1 initializes `state.retries.featureTest[featId] = 0`
- EXECUTING steps 7–9 reference `FEATURE` mode and `.pipeline/test-results-{featId}.json`
- TESTING phase has reset block before test-runner spawn
- State JSON has `featureTest: {}` in retries and `featureTestResults` in artifacts

- [ ] **Step 2: Scan test-runner.md for consistency**

Check:
- Input section documents both modes
- Mode routing line present after Input
- FEATURE mode section exists at bottom
- FEATURE mode output file is `.pipeline/test-results-{featId}.json` (matches SKILL.md reference)
- FEATURE mode Done return string mentions `{featId}`

- [ ] **Step 3: Commit both files**

```bash
git add SKILL.md test-runner.md
git commit -m "feat(devforge): add per-feature sub-pipeline with scoped tests and per-feature commits"
```
