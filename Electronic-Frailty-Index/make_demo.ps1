param(
  [int]$Rows = 120,
  [string]$Python = "python",
  [string]$Rscript = "Rscript"
)

$ErrorActionPreference = "Stop"
$root = Get-Location
$demoDir = Join-Path $root "docs\SYNTHETIC_DEMO"
$csv = Join-Path $demoDir "demo_synthetic.csv"
$pyDemo = Join-Path $demoDir "demo_py.py"
$rDemo  = Join-Path $demoDir "demo_r.R"

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err ($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red }

New-Item -ItemType Directory -Force -Path $demoDir | Out-Null
if (-not (Test-Path $pyDemo)) { Write-Warn "Puuttuu: $pyDemo" }
if (-not (Test-Path $rDemo))  { Write-Warn "Puuttuu: $rDemo" }

Write-Info "Luodaan CSV: $csv (Rows=$Rows)"
$data = 1..$Rows | ForEach-Object {
  $age = Get-Random -Minimum 50 -Maximum 91
  $sex = Get-Random -Minimum 0 -Maximum 2
  $falls = Get-Random -Minimum 0 -Maximum 2
  $inco = Get-Random -Minimum 0 -Maximum 2
  $lone = Get-Random -Minimum 0 -Maximum 2
  $mob  = Get-Random -Minimum 0 -Maximum 2
  $event= Get-Random -Minimum 0 -Maximum 2
  $fu   = ([Math]::Round((Get-Random -Minimum 0 -Maximum 120)/10,1)).ToString([Globalization.CultureInfo]::InvariantCulture)
  [PSCustomObject]@{age=$age;sex=$sex;label_falls=$falls;label_incont=$inco;label_lonely=$lone;label_mobility=$mob;event_death=$event;followup_years=$fu}
}
$data | Export-Csv -NoTypeInformation -Encoding UTF8 $csv

$pyOut = $null; $pyOk = $false
try {
  Write-Info "Ajetaan Python-demo..."
  $pyOut = & $Python $pyDemo 2>&1
  if ($LASTEXITCODE -eq 0 -and ($pyOut -join "`n") -match "Samples=\d+") { $pyOk = $true }
} catch { $pyOut = $_ | Out-String }

$rOut = $null; $rOk = $false
try {
  Write-Info "Ajetaan R-demo..."
  $rOut = & $Rscript -e "source('docs/SYNTHETIC_DEMO/demo_r.R')" 2>&1
  if ($LASTEXITCODE -eq 0 -and ($rOut -join "`n") -match "Samples=\d+") { $rOk = $true }
} catch { $rOut = $_ | Out-String }

Write-Host ""
Write-Host "==== DEMO SUMMARY ====" -ForegroundColor Green
Write-Host "CSV: $csv"
Write-Host ""
Write-Host "Python output:" -ForegroundColor DarkCyan
$pyOut | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "R output:" -ForegroundColor DarkCyan
$rOut | ForEach-Object { Write-Host $_ }
Write-Host "=======================" -ForegroundColor Green

if ($pyOk -and $rOk) {
  Write-Info "Valmis. Molemmat demot tuottivat Samples-rivin."
  exit 0
} else {
  if (-not $pyOk) { Write-Err "Python-demo epäonnistui tai ei tuottanut odotettua tulostetta." }
  if (-not $rOk)  { Write-Err "R-demo epäonnistui tai ei tuottanut odotettua tulostetta." }
  exit 1
}
