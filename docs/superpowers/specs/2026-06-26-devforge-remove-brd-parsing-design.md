# Devforge: Remove BRD Parsing Phase

**Date:** 2026-06-26
**Scope:** SKILL.md — devforge pipeline

---

## Problem

Current pipeline starts with a dedicated BRD_PARSING phase (brd-parser agent → brd-parsed.json) and a FEATURE_SELECTION phase before planning. This adds overhead and an intermediate JSON artifact that the architect re-reads anyway. The pipeline should go straight from INIT to PLANNED.

---

## New Phase Sequence

**Before:** `INIT → BRD_PARSING → FEATURE_SELECTION → PLANNED → EXECUTING → TESTING → REVIEWING → DOCUMENTING → DONE → LEARNING`

**After:** `INIT → PLANNED → EXECUTING → TESTING → REVIEWING → DOCUMENTING → DONE → LEARNING`

Same for both `max` and `standard` modes.

---

## Input Modes (unchanged)

Two modes remain, both determined in INIT:

- **File mode** — user provides `.docx` path → stored in `state.project.brdPath`, `brdMode = "file"`
- **Inline mode** — user types requirements in chat → written to `.pipeline/brd-raw.md`, `brdMode = "inline"`

No unification. Architect handles both.

---

## INIT Changes

- Determine input mode and set state as before
- Change final transition: set `phase = PLANNED` (was `phase = BRD_PARSING`)
- No other changes

---

## PLANNED Changes

Architect reads raw input directly:
- File mode: reads docx at `state.project.brdPath`
- Inline mode: reads `.pipeline/brd-raw.md`

Architect responsibilities (expanded from before):
1. Extract features from raw input
2. Initialize `state.features` with extracted feat IDs (all `PENDING`) — previously done by brd-parser
3. Write feature specs to `.pipeline/feature-specs/`
4. Run clarification loop per feature
5. Write `.pipeline/impl-plan.md`
6. Show plan → await approval gate (`gates.planApproved`)

Rest of PLANNED logic unchanged.

---

## State JSON Changes

Remove:
- `artifacts.brdParsed`
- `selectedFeatures`

Keep:
- `features` — now populated by architect instead of brd-parser
- `brdPath`, `brdMode` — still needed for input routing in PLANNED

---

## Removed

- `BRD_PARSING` phase section
- `FEATURE_SELECTION` phase section
- "On BRD re-parse" special command (no parser = no re-parse concept)
- `agents/brd-parser.md` from agents list
- `artifacts.brdParsed` from state

---

## Enhance Command Changes

Before: wrote `brd-raw.md` → set `phase = BRD_PARSING`
After: wrote `brd-raw.md` → set `phase = PLANNED`

No other changes to Enhance logic.

---

## Frontmatter Description Update

Remove BRD docx mention. New trigger: user provides a plan, types requirements inline, or invokes enhance.

---

## What Does Not Change

- EXECUTING, TESTING, REVIEWING, DOCUMENTING, DONE, LEARNING phases — unchanged
- Feature status tracking (`PENDING → BUILDING → DONE → BLOCKED`) — unchanged
- Gate logic — unchanged
- All other agents — unchanged
- Re-run / review-only / update-clarification special commands — unchanged
