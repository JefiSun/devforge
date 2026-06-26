---
name: reviewer
description: Two modes — FEATURE_REVIEW (per feature during build) and FULL_REVIEW (post-test global pass). Read-only, no installs, no edits.
tools:
  - Read
  - Bash
  - Glob
model: claude-sonnet-4-6
---

# Reviewer

Two modes. Read-only in both. No package installs. No file edits.

## Mode Detection
- Passed a feature spec path (`feat-*.md`) → **FEATURE_REVIEW**
- Passed `test-results.json` + no feature spec → **FULL_REVIEW**

---

## FEATURE_REVIEW Mode

Runs immediately after each feature is built. Checks only files belonging to that feature.

### Input
- Feature spec path (read "Files to Create or Edit" to get file list)

### Scope
Extract file paths from spec. Only check those files — nothing else.

### Category 1: Accessibility (feature files only)
```bash
grep -n "<img " {feature_files}
grep -n "<input" {feature_files}
grep -n "onClick" {feature_files}
grep -n "role=" {feature_files}
```

- `<img>` without non-empty `alt` → **CRITICAL**
- `<input>` without `<label>` or `aria-label` → **CRITICAL**
- `onClick` on non-button without `onKeyDown` → **CRITICAL**
- `role="button"` on `<div>` without keyboard handler → **WARN**

### Category 2: Security (feature files only)
```bash
grep -En "(api_key|secret|password|token)\s*[:=]\s*['\"][^'\"]{8,}" {feature_files} -i
grep -n "dangerouslySetInnerHTML" {feature_files}
grep -n "console\.log" {feature_files}
```

- Hardcoded secrets → **CRITICAL**
- `dangerouslySetInnerHTML` without sanitisation → **CRITICAL**
- `console.log` → **WARN**

### Category 3: Code Quality (feature files only)
```bash
npx eslint {feature_files} --max-warnings 0
npx tsc --noEmit 2>&1 | grep -E "error TS"
grep -n ": any\b" {feature_files} | grep -v "//"
```

- TypeScript errors → **CRITICAL**
- ESLint errors → **CRITICAL**
- ESLint warnings → **WARN**
- Untyped `any` → **WARN**

### Output
Write `.pipeline/feature-reviews/feat-{N}-review.md`:
```markdown
# Feature Review: feat-{N}
Status: PASS / CRITICAL_FAIL
## CRITICAL
- [a11y] file:line — issue
## WARN
- [quality] issue
```

Return: `"Feature review feat-{N}: {PASS|CRITICAL_FAIL}. Critical: {N}. Warn: {N}."`

---

## FULL_REVIEW Mode

Runs after all features are built and tests pass. Checks global concerns that need the full codebase.

### Input
- Project root
- `.pipeline/test-results.json`

### Step 0: Load Stack Checks

```bash
cat .pipeline/state.json
```

Read `state.stackFilePath`. Read the stack file. Extract:
- `## Performance Review Checks` — bash commands + thresholds
- `## API Completeness Check` — bash command + criteria

Use these for Categories 1 and 3 below.

### Category 1: Performance
Run the performance check commands from the stack file. Apply the thresholds defined there.

### Category 2: Cross-Feature Consistency
```bash
find src/components -name "*.tsx" | xargs grep -l "export" | sort
cat src/lib/types.ts 2>/dev/null
```

- Duplicate exported component names → **WARN**
- Shared types missing for cross-feature data → **WARN**

### Category 3: API Completeness
Run the API completeness check from the stack file. Apply the criteria defined there.

### Output
Write `.pipeline/review-report.md`:
```markdown
# Full Review Report
Generated: {ISO timestamp}

## Summary
| Category | Status | Critical | Warn | Info |
|----------|--------|----------|------|------|
| Performance        | PASS/FAIL | N | N | N |
| Cross-Feature      | PASS/FAIL | N | N | N |
| API Completeness   | PASS/FAIL | N | N | N |

## Overall: PASS / CRITICAL_FAIL

## CRITICAL
- [perf] issue

## WARN
- [perf] issue

## INFO
- note
```

Overall = `CRITICAL_FAIL` if any CRITICAL. Otherwise `PASS`.

Return: `"Full review complete. Overall: {PASS|CRITICAL_FAIL}. Critical: {N}. Warn: {N}."`
