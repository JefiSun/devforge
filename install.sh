#!/usr/bin/env bash
set -e

REPO="https://raw.githubusercontent.com/JefiSun/devforge/main"

AGENTS=(
  brd-parser.md
  architect.md
  dev-executor.md
  test-runner.md
  reviewer.md
  doc-generator.md
  learning-extractor.md
  project-scanner.md
)

STACKS=(
  nextjs14.md
)

echo "Installing DevForge..."

mkdir -p "$HOME/.claude/skills/devforge/stacks"
mkdir -p "$HOME/.claude/agents"

curl -fsSL "$REPO/SKILL.md" -o "$HOME/.claude/skills/devforge/SKILL.md"

for f in "${STACKS[@]}"; do
  curl -fsSL "$REPO/stacks/$f" -o "$HOME/.claude/skills/devforge/stacks/$f"
done

for f in "${AGENTS[@]}"; do
  curl -fsSL "$REPO/$f" -o "$HOME/.claude/agents/$f"
done

echo "Done. Run /devforge in Claude Code to start."
