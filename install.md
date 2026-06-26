# Install DevForge

One install. Works for Claude Code and GitHub Copilot CLI.

Run the one-liner for your tool. Want to know what gets touched, scroll down.

---

## One-liner

### Claude Code

**macOS / Linux / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash
```

**Windows (PowerShell 5.1+):**
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 -OutFile "$env:TEMP\devforge.ps1"; & "$env:TEMP\devforge.ps1"
```

---

### GitHub Copilot CLI

**macOS / Linux / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --copilot
```

**Windows (PowerShell 5.1+):**
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 -OutFile "$env:TEMP\devforge.ps1"; & "$env:TEMP\devforge.ps1" --copilot
```

---

### Both tools at once

**macOS / Linux / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --both
```

**Windows (PowerShell 5.1+):**
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 -OutFile "$env:TEMP\devforge.ps1"; & "$env:TEMP\devforge.ps1" --both
```

---

## What gets installed

| File | Claude Code | GitHub Copilot CLI |
|------|-------------|---------------------|
| `SKILL.md` | `~/.claude/skills/devforge/SKILL.md` | `~/.copilot/skills/devforge/SKILL.md` |
| `stacks/*.md` | `~/.claude/skills/devforge/stacks/` | `~/.copilot/skills/devforge/stacks/` |
| Agent `*.md` files | `~/.claude/agents/` | `~/.copilot/agents/` |

Safe to re-run — overwrites existing files. `.pipeline/` state and `instincts/` in your projects are never touched.

---

## Requirements

- Claude Code (latest) **or** GitHub Copilot CLI (latest)
- Node.js 18+
- BRD **file** mode only: `pandoc` (preferred) or `python3` + `python-docx`. Not needed for inline mode.

---

## Verify

**Claude Code** — open a session and type:
```
/devforge
```

**GitHub Copilot CLI** — open a session and run:
```
/skills info devforge
```

You should see the skill name, description, and file path. If missing, run `/skills reload` and check again.

---

## Update

Re-run the install one-liner. Overwrites existing files, leaves project state untouched.

---

## Uninstall

**Claude Code:**

macOS / Linux / WSL:
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --uninstall
```

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 -OutFile "$env:TEMP\devforge.ps1"; & "$env:TEMP\devforge.ps1" --uninstall
```

**GitHub Copilot CLI:**

macOS / Linux / WSL:
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --copilot --uninstall
```

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 -OutFile "$env:TEMP\devforge.ps1"; & "$env:TEMP\devforge.ps1" --copilot --uninstall
```

**Both:**

macOS / Linux / WSL:
```bash
curl -fsSL https://raw.githubusercontent.com/JefiSun/devforge/main/install.sh | bash -s -- --both --uninstall
```

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/JefiSun/devforge/main/install.ps1 -OutFile "$env:TEMP\devforge.ps1"; & "$env:TEMP\devforge.ps1" --both --uninstall
```

What uninstall removes:
- `~/.claude/skills/devforge/` or `~/.copilot/skills/devforge/` (the skill + stacks)
- Each agent `.md` file from `~/.claude/agents/` or `~/.copilot/agents/`

What it does **not** remove:
- `.pipeline/` directories in your projects (state, specs, instincts)

---

## Add a stack

Create `stacks/{id}.md` with required sections (see `README.md → Adding a Stack`), then copy to the skills dir:

```bash
# Claude Code
cp stacks/mystack.md ~/.claude/skills/devforge/stacks/

# GitHub Copilot CLI
cp stacks/mystack.md ~/.copilot/skills/devforge/stacks/
```
