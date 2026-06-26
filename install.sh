#!/usr/bin/env bash
set -e

REPO="https://raw.githubusercontent.com/JefiSun/devforge/main"
TOOL="claude"  # default

for arg in "$@"; do
  case $arg in
    --copilot) TOOL="copilot" ;;
    --both)    TOOL="both" ;;
  esac
done

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

install_for() {
  local skill_dir="$1" agent_dir="$2" label="$3"
  echo "Installing DevForge for $label..."
  mkdir -p "$skill_dir/stacks"
  mkdir -p "$agent_dir"
  curl -fsSL "$REPO/SKILL.md" -o "$skill_dir/SKILL.md"
  for f in "${STACKS[@]}"; do
    curl -fsSL "$REPO/stacks/$f" -o "$skill_dir/stacks/$f"
  done
  for f in "${AGENTS[@]}"; do
    curl -fsSL "$REPO/$f" -o "$agent_dir/$f"
  done
  echo "Done ($label)."
}

case $TOOL in
  copilot) install_for "$HOME/.copilot/skills/devforge" "$HOME/.copilot/agents" "GitHub Copilot"
           echo "Run /devforge in GitHub Copilot CLI to start." ;;
  both)    install_for "$HOME/.claude/skills/devforge"  "$HOME/.claude/agents"  "Claude Code"
           install_for "$HOME/.copilot/skills/devforge" "$HOME/.copilot/agents" "GitHub Copilot" ;;
  *)       install_for "$HOME/.claude/skills/devforge"  "$HOME/.claude/agents"  "Claude Code"
           echo "Run /devforge in Claude Code to start." ;;
esac
