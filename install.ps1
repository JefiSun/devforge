$ErrorActionPreference = "Stop"

$repo = "https://raw.githubusercontent.com/JefiSun/devforge/main"

$agents = @(
    "brd-parser.md"
    "architect.md"
    "dev-executor.md"
    "test-runner.md"
    "reviewer.md"
    "doc-generator.md"
    "learning-extractor.md"
    "project-scanner.md"
)

$stacks = @(
    "nextjs14.md"
)

Write-Host "Installing DevForge..."

$skillDir = "$HOME\.claude\skills\devforge\stacks"
$agentDir = "$HOME\.claude\agents"

New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
New-Item -ItemType Directory -Force -Path $agentDir | Out-Null

Invoke-WebRequest -Uri "$repo/SKILL.md" -OutFile "$HOME\.claude\skills\devforge\SKILL.md" -UseBasicParsing

foreach ($f in $stacks) {
    Invoke-WebRequest -Uri "$repo/stacks/$f" -OutFile "$skillDir\$f" -UseBasicParsing
}

foreach ($f in $agents) {
    Invoke-WebRequest -Uri "$repo/$f" -OutFile "$agentDir\$f" -UseBasicParsing
}

Write-Host "Done. Run /devforge in Claude Code to start."
