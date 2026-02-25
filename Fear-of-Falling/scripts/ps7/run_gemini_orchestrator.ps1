<#
.SYNOPSIS
Fear-of-Falling Gemini CLI Orchestrator (PS7 Native)
.DESCRIPTION
Lukee järjestelmäkehotteen ja käyttäjän tehtävän, validoi ympäristön,
yhdistää syötteet ja putkittaa ne Gemini CLI -työkalulle.
Tallentaa ajolokin manifest/orchestrator_logs/ -kansioon.
.PARAMETER TaskFile
Polku tiedostoon, joka sisältää agentille annettavan tehtävän (Task Packet).
#>
param (
[Parameter(Mandatory=$true)]
[string]$TaskFile
)

$ErrorActionPreference = 'Stop'

# 1. Työhakemiston validointi (Fail-closed)

$currentPath = (Get-Location).Path
if (-not $currentPath.EndsWith("Fear-of-Falling")) {
Write-Error "Virhe: Skripti on ajettava Fear-of-Falling -hakemistosta. Nykyinen polku: $currentPath"
exit 1
}

# 2. Lokituksen (Transcript) alustus

$logDir = ".\manifest\orchestrator_logs"
if (-not (Test-Path $logDir)) {
New-Item -ItemType Directory -Path $logDir | Out-Null
}
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $logDir "run_${timestamp}.log"

Start-Transcript -Path $logPath -Append:$false

try {
Write-Host "=== FOF Gemini Orchestrator Pre-flight ==="

# 3. System Promptin lataus ja signaturen luonti
$sysPromptPath = ".\SYSTEM_PROMPT_POWERSHELL7_S-FOF.md"
if (-not (Test-Path $sysPromptPath)) {
    throw "Virhe: System prompt -tiedostoa ei löytynyt polusta $sysPromptPath"
}

$sysPromptContent = Get-Content -Raw -Path $sysPromptPath
$sysPromptHash = (Get-FileHash -Path $sysPromptPath -Algorithm SHA256).Hash
$sysPromptBanner = ($sysPromptContent -split "`r?`n")[0]

Write-Host "-> System Prompt ladattu."
Write-Host "   Banner: $sysPromptBanner"
Write-Host "   SHA256: $sysPromptHash"

# 4. Tehtävätiedoston lataus
if (-not (Test-Path $TaskFile)) {
    throw "Virhe: Tehtävätiedostoa ei löytynyt polusta $TaskFile"
}
$taskContent = Get-Content -Raw -Path $TaskFile
Write-Host "-> Tehtävä ladattu tiedostosta: $TaskFile"

# 5. Syötteen yhdistäminen
$fullPrompt = "$sysPromptContent`n`n--- BEGIN TASK ---`n`n$taskContent"

# 6. Gemini CLI:n suoritus
# HUOM: Säädä lippuja (-p jne.) Gemini CLI -työkalusi todellisen syntaksin mukaiseksi.
# Tämä on standardi tapa putkittaa pitkä teksti (stdin) komentorivityökalulle PS7:ssä.
Write-Host "=== Executing Gemini CLI ==="

$fullPrompt | gemini -p ""

Write-Host "=== Execution Completed ==="

}
catch {
Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
Stop-Transcript
Write-Host "Loki tallennettu: $logPath"
}
