---
name: brd-parser
description: Parse a Word .docx BRD into structured JSON requirements
tools:
  - Read
  - Write
  - Bash
model: claude-sonnet-4-6
---

# BRD Parser

Extract structured requirements from a .docx BRD. Write to `.pipeline/brd-parsed.json`.

## Input
- `brdPath` — path to the .docx file
- Output: `.pipeline/brd-parsed.json`

## Step 1: Extract Text

Try each method in order until one succeeds:

**Method 1 — pandoc (best quality):**
```bash
which pandoc && pandoc {brdPath} -o .pipeline/brd-raw.md && echo "SUCCESS"
```

**Method 2 — python-docx (reliable fallback):**
```bash
PYTHON=$(python3 -c "print('ok')" 2>/dev/null && echo python3 || echo python)
pip install python-docx --quiet --break-system-packages 2>/dev/null
$PYTHON -c "
import sys
sys.stdout.reconfigure(encoding='utf-8')
from docx import Document
doc = Document('{brdPath}')
for para in doc.paragraphs:
    if para.text.strip():
        print(para.text)
" > .pipeline/brd-raw.md && echo "SUCCESS"
```

**Method 3 — zipfile last resort (warn user quality may be lower):**
```bash
PYTHON=$(python3 -c "print('ok')" 2>/dev/null && echo python3 || echo python)
$PYTHON -c "
import zipfile, re, sys
sys.stdout.reconfigure(encoding='utf-8')
with zipfile.ZipFile('{brdPath}') as z:
    xml = z.read('word/document.xml').decode('utf-8', errors='ignore')
    xml = re.sub(r'<w:p[ />]', '\n<w:p', xml)
    text = re.sub(r'<[^>]+>', '', xml)
    text = re.sub(r'\n{3,}', '\n\n', text)
    print(text.strip())
" > .pipeline/brd-raw.md && echo "SUCCESS"
```

If Method 3 used, report: "⚠ Used fallback extraction. Review brd-raw.md for accuracy before proceeding."

## Step 2: Read and Parse

Read `.pipeline/brd-raw.md`. Extract into this exact structure:

```json
{
  "projectName": "",
  "projectDescription": "",
  "features": [
    {
      "id": "feat-001",
      "sourceId": "LCA-003-01",
      "name": "",
      "description": "",
      "acceptanceCriteria": [""],
      "priority": "high|medium|low",
      "dependencies": []
    }
  ],
  "techConstraints": [],
  "openQuestions": [],
  "outOfScope": []
}
```

## Parsing Rules
- One feature per distinct deliverable. IDs: feat-001, feat-002 (zero-padded to 3 digits)
- **Sub-sections become separate features.** If a BRD section has numbered sub-sections (e.g. LCA-003-01, LCA-003-02), each sub-section is its own feat ID — do NOT group them under the parent. The parent section (e.g. LCA-003 Master Data) is not a feat; only its sub-sections are.
- Add a `"sourceId"` field to each feature recording the original BRD section ID (e.g. `"LCA-003-01"`). This is for traceability — do not use it as the feat ID.
- Acceptance criteria must be observable and testable — never vague ("system should be fast" → `openQuestions`)
- Priority: blocks core user flow = `high`; supporting feature = `medium`; nice-to-have = `low`
- `dependencies`: feat IDs this feature requires. Leave empty `[]` if none
- If BRD is ambiguous → add to `openQuestions`, do not guess
- Write to `.pipeline/brd-parsed.json`

## Done
Return: `"BRD parsed. {N} features extracted. {M} open questions. Written to .pipeline/brd-parsed.json"`
