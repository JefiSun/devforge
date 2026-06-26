# Devforge: Per-Feature Sub-Pipeline

**Date:** 2026-06-26
**Scope:** `SKILL.md` (EXECUTING section + state JSON), `agents/test-runner.md` (add FEATURE mode)

---

## Problem

Current pipeline runs all features through each phase globally:
```
Plan(A,B,C) → Execute(A,B,C) → Test(all) → Review(all) → Doc(all) → Done
```

A failure in testing blocks all features together. Commits happen globally, not per feature. Feedback loop is slow — a bug in feature A isn't caught until all features are built.

---

## New Flow

Per-feature sub-pipeline inside EXECUTING, global phases after:

```
Plan(A,B,C) →
  Feature A: build → review → test(scoped) → commit
  Feature B: build → review → test(scoped) → commit
  Feature C: build → review → test(scoped) → commit
→ Test(global, full) → Review(global) → Doc → Done → Learning
```

---

## EXECUTING Phase — New Per-Feature Loop

Each feature runs this sequence:

1. Set `state.features[featId].status = "BUILDING"` → write state
2. Autopilot model selection (read `autopilot` block from `agents/dev-executor.md` frontmatter)
3. Spawn `agents/dev-executor.md` with selected model. Pass: feature spec path, `.pipeline/clarifications.json`, `.pipeline/instincts/dev-executor.md` (if exists)
4. If build fails → fix inline → retry once → if still fails: set status = `"BLOCKED"`, `phase = BLOCKED_EXECUTING` → report to user → stop
5. Spawn `agents/reviewer.md` in `FEATURE_REVIEW` mode. Pass: feature spec path. CRITICAL → block pipeline. WARN → report and continue.
6. Spawn `agents/test-runner.md` in `FEATURE` mode. Pass: feature spec path, feat ID. Writes `.pipeline/test-results-{featId}.json`.
7. If feature tests fail → spawn `agents/dev-executor.md` in FIX mode. Pass: `.pipeline/test-results-{featId}.json`. Retry once. If still fails → set status = `"BLOCKED"`, `phase = BLOCKED_EXECUTING` → report to user → stop.
8. If feature tests pass → git commit (stage files listed in the feature spec as created/modified) → set `state.features[featId].status = "DONE"`, `builtAt = now` → write state.

After all features DONE → set `phase = TESTING` → write state.

---

## test-runner FEATURE Mode

`agents/test-runner.md` gains a `FEATURE` mode alongside the existing default (global) mode.

**Input:** `featureSpecPath`, `featId`

**Behavior:**
- Read feature spec → identify files created or modified by this feature
- Run unit tests scoped to those files only
- No E2E tests
- No coverage gate (coverage checked in global TESTING phase only)

**Output:** `.pipeline/test-results-{featId}.json`

Pass condition: all scoped unit tests green.

---

## State JSON Changes

**Add `featureTest` to retries block:**

```json
"retries": {
  "test": 0,
  "featureTest": {}
}
```

`featureTest` is a map of `featId → retry count`. Orchestrator sets `featureTest[featId] = 0` at start of each feature, increments on retry. Max 1 retry per feature (simpler than global's 2).

No stall detection per feature — retry once then block.

**Add per-feature test result pattern to artifacts:**

```json
"artifacts": {
  "implPlan": ".pipeline/impl-plan.md",
  "featureSpecs": ".pipeline/feature-specs/",
  "featureTestResults": ".pipeline/test-results-{featId}.json",
  "clarifications": ".pipeline/clarifications.json",
  "testResults": ".pipeline/test-results.json",
  "reviewReport": ".pipeline/review-report.md",
  "instincts": ".pipeline/instincts/"
}
```

`featureTestResults` is a pattern — orchestrator substitutes `{featId}` with the actual feat ID.

---

## TESTING Phase (Global) — Minor Change

Before spawning `test-runner.md` in default mode, reset:
- `state.retries.featureTest = {}` 
- `state.retries.test = 0`
- `state.testFailureSignatures = []`

Otherwise TESTING phase is unchanged: full unit + E2E + i18n + coverage gate.

---

## What Does Not Change

- PLANNED, REVIEWING, DOCUMENTING, DONE, LEARNING phases
- `agents/architect.md`, `agents/dev-executor.md`, `agents/reviewer.md`, `agents/doc-generator.md`, `agents/learning-extractor.md`
- Gate logic (plan approval, test pass, review pass)
- Enhance / re-run / review-only / update-clarification special commands
- Global TESTING stall detection logic
