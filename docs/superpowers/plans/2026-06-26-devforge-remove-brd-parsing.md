# Devforge: Remove BRD Parsing Phase — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove BRD_PARSING and FEATURE_SELECTION phases from devforge pipeline so it flows INIT → PLANNED → EXECUTING → ...

**Architecture:** Single file change (SKILL.md). Seven sequential edits — each scoped to one logical section. Architect agent absorbs feature extraction work previously done by brd-parser.

**Tech Stack:** Markdown skill file — no code, no tests. Verification is manual read of the changed sections.

---

### Task 1: Update frontmatter description

**Files:**
- Modify: `SKILL.md:3`

- [ ] **Step 1: Edit frontmatter `description` field**

Find this exact text on line 3:
```
description: "End-to-end web development pipeline. Use this skill whenever: a .docx BRD is provided with a build request, user says \"build from BRD / implement this spec / run the pipeline / develop this feature / enhance / enhance: [description] / re-run feat-X\", or a multi-phase web development workflow is needed. Stack-agnostic — supports nextjs14, react-vite, and more via stack files. Works for both new and existing repos."
```

Replace with:
```
description: "End-to-end web development pipeline. Use this skill whenever: user says \"build / implement this spec / run the pipeline / develop this feature / enhance / enhance: [description] / re-run feat-X\", provides requirements inline or as a docx path, or a multi-phase web development workflow is needed. Stack-agnostic — supports nextjs14, react-vite, and more via stack files. Works for both new and existing repos."
```

- [ ] **Step 2: Verify**

Confirm line 3 no longer mentions `.docx BRD is provided` or `build from BRD`.

---

### Task 2: Update phase sequence list

**Files:**
- Modify: `SKILL.md:64-65`

- [ ] **Step 1: Edit the Phases block**

Find:
```
- **max** (default): `INIT → BRD_PARSING → FEATURE_SELECTION → PLANNED → EXECUTING → TESTING → REVIEWING → DOCUMENTING → DONE → LEARNING`
- **standard**: `INIT → BRD_PARSING → FEATURE_SELECTION → PLANNED → EXECUTING → TESTING → DONE → LEARNING`
```

Replace with:
```
- **max** (default): `INIT → PLANNED → EXECUTING → TESTING → REVIEWING → DOCUMENTING → DONE → LEARNING`
- **standard**: `INIT → PLANNED → EXECUTING → TESTING → DONE → LEARNING`
```

- [ ] **Step 2: Verify**

Neither line contains `BRD_PARSING` or `FEATURE_SELECTION`.

---

### Task 3: Remove `selectedFeatures` and `brdParsed` from state JSON

**Files:**
- Modify: `SKILL.md` — state JSON block (~lines 24-57)

- [ ] **Step 1: Remove `selectedFeatures` line from state JSON**

Find:
```
  "selectedFeatures": [],
```

Delete that line entirely.

- [ ] **Step 2: Remove `brdParsed` artifact from state JSON**

Find:
```
    "brdParsed": ".pipeline/brd-parsed.json",
```

Delete that line entirely.

- [ ] **Step 3: Verify**

State JSON block no longer contains `selectedFeatures` or `brdParsed`. All other fields intact.

---

### Task 4: Update INIT phase transition

**Files:**
- Modify: `SKILL.md:132`

- [ ] **Step 1: Change phase transition at end of INIT section**

Find:
```
Update `state.project` → set `phase = BRD_PARSING` → write state.
```

Replace with:
```
Update `state.project` → set `phase = PLANNED` → write state.
```

- [ ] **Step 2: Verify**

End of INIT section now transitions to `PLANNED`, not `BRD_PARSING`.

---

### Task 5: Remove BRD_PARSING and FEATURE_SELECTION sections

**Files:**
- Modify: `SKILL.md` — lines ~136–210

- [ ] **Step 1: Delete the entire BRD_PARSING section**

Find and delete everything from:
```
### BRD_PARSING
```
through to (but not including):
```
### FEATURE_SELECTION
```

This removes: the BRD_PARSING heading, both brdMode branches (file/inline spawn of brd-parser), existing project reconciliation block, and the "On BRD re-parse" special command block.

- [ ] **Step 2: Delete the entire FEATURE_SELECTION section**

Find and delete everything from:
```
### FEATURE_SELECTION
```
through to (but not including):
```
### PLANNED
```

This removes: feature list display format, INCOMPLETE gate, `all` vs ID selection logic, dependency check logic, and the `state.selectedFeatures` write.

- [ ] **Step 3: Verify**

No `### BRD_PARSING` or `### FEATURE_SELECTION` headings remain. `### PLANNED` follows directly after the INIT section separator.

---

### Task 6: Update PLANNED section

**Files:**
- Modify: `SKILL.md` — PLANNED section (~lines 212–236 after prior deletions)

- [ ] **Step 1: Remove the Filter block**

Find and delete:
```
**Filter:** if `selectedFeatures` non-empty, extract only those features from `brd-parsed.json` into a filtered list. Pass filtered list to architect — not the full brd-parsed.json.
```

- [ ] **Step 2: Replace architect spawn line**

Find:
```
Spawn `agents/architect.md`. Pass: filtered feature list, project root, `isNewProject`, `.pipeline/instincts/architect.md` (if exists).
```

Replace with:
```
Spawn `agents/architect.md`. Pass: input source (docx path if `brdMode = "file"`, or `.pipeline/brd-raw.md` if `brdMode = "inline"`), project root, `isNewProject`, `.pipeline/instincts/architect.md` (if exists).

Architect must:
1. Extract features from raw input
2. Initialize `state.features` with extracted feat IDs (all status = `PENDING`) — write state after this step
3. Write feature specs to `.pipeline/feature-specs/`
4. Run clarification loop (see below)
5. Write `.pipeline/impl-plan.md`
```

- [ ] **Step 3: Verify**

PLANNED section no longer references `brd-parsed.json`, `selectedFeatures`, or `filtered feature list`. Architect spawn line includes input source routing logic.

---

### Task 7: Update Enhance command and agents list

**Files:**
- Modify: `SKILL.md` — Enhance section and Agents section

- [ ] **Step 1: Update Enhance phase transition**

Find (in Enhance section):
```
3. Set `phase = BRD_PARSING` → write state
```

Replace with:
```
3. Set `phase = PLANNED` → write state
```

- [ ] **Step 2: Update Enhance resume sequence**

Find:
```
4. Resume pipeline from BRD_PARSING → FEATURE_SELECTION → PLANNED → EXECUTING → TESTING → REVIEWING → DOCUMENTING → DONE
```

Replace with:
```
4. Resume pipeline from PLANNED → EXECUTING → TESTING → REVIEWING → DOCUMENTING → DONE
```

- [ ] **Step 3: Remove brd-parser from agents list**

Find:
```
- `agents/brd-parser.md` — DOCX → brd-parsed.json
```

Delete that line entirely.

- [ ] **Step 4: Verify**

Enhance section sets `phase = PLANNED`. Agents list has no `brd-parser.md` entry.

---

### Task 8: Final review and commit

- [ ] **Step 1: Read through SKILL.md top to bottom**

Check for any remaining references to:
- `BRD_PARSING`
- `FEATURE_SELECTION`
- `brd-parsed.json`
- `brdParsed`
- `selectedFeatures`
- `brd-parser`

If any found, delete or update them.

- [ ] **Step 2: Verify phase sequences are consistent**

Confirm these three locations all show the same sequence (no BRD_PARSING, no FEATURE_SELECTION):
- Frontmatter (line 3, implicit in description)
- Phase list block (max and standard lines)
- INIT section end (transitions to PLANNED)
- Enhance section (resumes from PLANNED)

- [ ] **Step 3: Commit**

```bash
git add SKILL.md
git commit -m "feat(devforge): remove BRD_PARSING and FEATURE_SELECTION phases, architect reads raw input directly"
```
