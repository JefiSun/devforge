$ErrorActionPreference = "Stop"

param(
    [switch]$Copilot,
    [switch]$Both,
    [switch]$Uninstall
)

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

function Uninstall-DevForge($skillDir, $agentDir, $label) {
    Write-Host "Uninstalling DevForge from $label..."
    if (Test-Path $skillDir) { Remove-Item -Recurse -Force $skillDir }
    foreach ($f in $agents) {
        $p = Join-Path $agentDir $f
        if (Test-Path $p) { Remove-Item -Force $p }
    }
    Write-Host "Done ($label)."
}

function Install-DevForge($skillDir, $agentDir, $label) {
    Write-Host "Installing DevForge for $label..."
    New-Item -ItemType Directory -Force -Path "$skillDir\stacks" | Out-Null
    New-Item -ItemType Directory -Force -Path $agentDir | Out-Null
    Invoke-WebRequest -Uri "$repo/SKILL.md" -OutFile "$skillDir\SKILL.md" -UseBasicParsing
    foreach ($f in $stacks) {
        Invoke-WebRequest -Uri "$repo/stacks/$f" -OutFile "$skillDir\stacks\$f" -UseBasicParsing
    }
    foreach ($f in $agents) {
        Invoke-WebRequest -Uri "$repo/$f" -OutFile "$agentDir\$f" -UseBasicParsing
    }
    Write-Host "Done ($label)."
}

if ($Uninstall) {
    if ($Both) {
        Uninstall-DevForge "$HOME\.claude\skills\devforge"  "$HOME\.claude\agents"  "Claude Code"
        Uninstall-DevForge "$HOME\.copilot\skills\devforge" "$HOME\.copilot\agents" "GitHub Copilot"
    } elseif ($Copilot) {
        Uninstall-DevForge "$HOME\.copilot\skills\devforge" "$HOME\.copilot\agents" "GitHub Copilot"
    } else {
        Uninstall-DevForge "$HOME\.claude\skills\devforge"  "$HOME\.claude\agents"  "Claude Code"
    }
} elseif ($Both) {
    Install-DevForge "$HOME\.claude\skills\devforge"  "$HOME\.claude\agents"  "Claude Code"
    Install-DevForge "$HOME\.copilot\skills\devforge" "$HOME\.copilot\agents" "GitHub Copilot"
} elseif ($Copilot) {
    Install-DevForge "$HOME\.copilot\skills\devforge" "$HOME\.copilot\agents" "GitHub Copilot"
    Write-Host "Run /devforge in GitHub Copilot CLI to start."
} else {
    Install-DevForge "$HOME\.claude\skills\devforge"  "$HOME\.claude\agents"  "Claude Code"
    Write-Host "Run /devforge in Claude Code to start."
}
