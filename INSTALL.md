# Install DevForge

## Requirements

- Claude Code (latest)
- Node.js 18+
- `pandoc` (preferred) or `python3` + `python-docx` for BRD parsing

---

## Quick Install

```bash
git clone https://github.com/yourname/devforge
cd devforge

# Create target dirs
mkdir -p ~/.claude/skills/devforge/stacks
mkdir -p ~/.claude/agents

# Install orchestrator skill
cp SKILL.md ~/.claude/skills/devforge/

# Install stack configs
cp stacks/*.md ~/.claude/skills/devforge/stacks/

# Install agents
cp brd-parser.md \
   architect.md \
   dev-executor.md \
   test-runner.md \
   reviewer.md \
   doc-generator.md \
   learning-extractor.md \
   ~/.claude/agents/
```

---

## File Destinations

| Source | Destination | Purpose |
|--------|-------------|---------|
| `SKILL.md` | `~/.claude/skills/devforge/SKILL.md` | Orchestrator — triggers on `/devforge` |
| `stacks/*.md` | `~/.claude/skills/devforge/stacks/` | Stack configs loaded at runtime |
| `*.md` (agents) | `~/.claude/agents/` | Sub-agents spawned by orchestrator |

---

## Verify

After install, confirm structure:

```
~/.claude/
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
```

---

## Update

To update to a newer version:

```bash
git pull
cp SKILL.md ~/.claude/skills/devforge/
cp stacks/*.md ~/.claude/skills/devforge/stacks/
cp brd-parser.md architect.md dev-executor.md test-runner.md \
   reviewer.md doc-generator.md learning-extractor.md ~/.claude/agents/
```

Existing `.pipeline/` state and `instincts/` in your projects are untouched.

---

## Add a Stack

Create `stacks/{id}.md` with required sections, then copy to `~/.claude/skills/devforge/stacks/`:

```bash
cp stacks/mystack.md ~/.claude/skills/devforge/stacks/
```

See `README.md → Adding a Stack` for the required section template.

---

## Uninstall

```bash
rm -rf ~/.claude/skills/devforge
rm ~/.claude/agents/brd-parser.md \
   ~/.claude/agents/architect.md \
   ~/.claude/agents/dev-executor.md \
   ~/.claude/agents/test-runner.md \
   ~/.claude/agents/reviewer.md \
   ~/.claude/agents/doc-generator.md \
   ~/.claude/agents/learning-extractor.md
```
