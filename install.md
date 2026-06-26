# Install DevForge

## Requirements

- Claude Code (latest) **or** GitHub Copilot CLI (latest)
- Node.js 18+
- `pandoc` (preferred) or `python3` + `python-docx` for BRD parsing

---

## Quick Install

### Claude Code

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 | iex
```

---

### GitHub Copilot CLI

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --copilot
```

**Windows (PowerShell):**
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1))) -Copilot
```

---

### Both (Claude Code + GitHub Copilot CLI)

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --both
```

**Windows (PowerShell):**
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1))) -Both
```

---

## File Destinations

| Source | Claude Code | GitHub Copilot CLI |
|--------|-------------|---------------------|
| `SKILL.md` | `~/.claude/skills/devforge/SKILL.md` | `~/.copilot/skills/devforge/SKILL.md` |
| `stacks/*.md` | `~/.claude/skills/devforge/stacks/` | `~/.copilot/skills/devforge/stacks/` |
| `*.md` (agents) | `~/.claude/agents/` | `~/.copilot/agents/` |

---

## Verify

After install, confirm the skill loaded:

**Claude Code:** type `/devforge` in a session.

**GitHub Copilot CLI:**
```
/skills info devforge
```

Expected structure:
```
~/.copilot/                         # or ~/.claude/
  skills/
    devforge/
      SKILL.md
      stacks/
        nextjs14.md
  agents/
    brd-parser.md
    architect.md
    dev-executor.md
    test-runner.md
    reviewer.md
    doc-generator.md
    learning-extractor.md
    project-scanner.md
```

---

## Update

Re-run the install command — it overwrites existing files.

Existing `.pipeline/` state and `instincts/` in your projects are untouched.

---

## Add a Stack

Create `stacks/{id}.md` with required sections, then copy to the skills dir:

```bash
# Claude Code
cp stacks/mystack.md ~/.claude/skills/devforge/stacks/

# GitHub Copilot CLI
cp stacks/mystack.md ~/.copilot/skills/devforge/stacks/
```

See `README.md → Adding a Stack` for the required section template.

---

## Uninstall

**Claude Code:**
```bash
rm -rf ~/.claude/skills/devforge
rm ~/.claude/agents/brd-parser.md \
   ~/.claude/agents/architect.md \
   ~/.claude/agents/dev-executor.md \
   ~/.claude/agents/test-runner.md \
   ~/.claude/agents/reviewer.md \
   ~/.claude/agents/doc-generator.md \
   ~/.claude/agents/learning-extractor.md \
   ~/.claude/agents/project-scanner.md
```

**GitHub Copilot CLI:**
```bash
rm -rf ~/.copilot/skills/devforge
rm ~/.copilot/agents/brd-parser.md \
   ~/.copilot/agents/architect.md \
   ~/.copilot/agents/dev-executor.md \
   ~/.copilot/agents/test-runner.md \
   ~/.copilot/agents/reviewer.md \
   ~/.copilot/agents/doc-generator.md \
   ~/.copilot/agents/learning-extractor.md \
   ~/.copilot/agents/project-scanner.md
```
