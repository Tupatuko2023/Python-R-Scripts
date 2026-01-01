Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

trap {
  Write-Host ("unexpected_error={0}" -f $_.Exception.Message)
  exit 1
}

# Exit codes:
# 0  = OK (offline or online success)
# 10 = network disabled indicators present
# 20 = DNS/TLS failure detected during opt-in tests
$E_OK = 0
$E_NET_DISABLED = 10
$E_NET_FAIL = 20

Write-Host "== diag_network_github =="
Write-Host ("timestamp: {0}" -f ([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")))
Write-Host ("cwd: {0}" -f (Get-Location))

function Is-SensitiveName {
  param([string]$Name)
  return $Name -match '(?i)(TOKEN|SECRET|KEY|PASS|PASSWORD|AUTH|COOKIE|CRED|SESSION)'
}

Write-Host ""
Write-Host "== env var names (no values; sensitive names redacted) =="
Get-ChildItem Env: | ForEach-Object {
  if (Is-SensitiveName $_.Name) { 'REDACTED_ENV_NAME' } else { $_.Name }
} | Sort-Object -Unique | ForEach-Object { Write-Host $_ }

Write-Host ""
Write-Host "== proxy vars (values redacted) =="
foreach ($v in @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY')) {
  $val = [Environment]::GetEnvironmentVariable($v)
  if ([string]::IsNullOrEmpty($val)) {
    Write-Host ("{0}=EMPTY" -f $v)
  } elseif ($val -match '@') {
    Write-Host ("{0}=SET (redacted)" -f $v)
  } else {
    Write-Host ("{0}=SET" -f $v)
  }
}

Write-Host ""
Write-Host "== tool availability =="
foreach ($cmd in @('curl','openssl','nslookup','Resolve-DnsName','Test-NetConnection','gh')) {
  $found = Get-Command $cmd -ErrorAction SilentlyContinue
  if ($null -ne $found) {
    Write-Host ("{0}=present" -f $cmd)
  } else {
    Write-Host ("{0}=missing" -f $cmd)
  }
}

$netDisabled = $false
if (Get-ChildItem Env: | Where-Object { $_.Name -eq 'CODEX_SANDBOX_NETWORK_DISABLED' }) { $netDisabled = $true }
if (Get-ChildItem Env: | Where-Object { $_.Name -eq 'SBX_NONET_ACTIVE' }) { $netDisabled = $true }

if ($netDisabled) {
  Write-Host ""
  Write-Host "== network policy =="
  Write-Host "network_disabled=1 (CODEX_SANDBOX_NETWORK_DISABLED or SBX_NONET_ACTIVE present)"
}

function Invoke-Head {
  param([string]$Url)
  try {
    $resp = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 6 -MaximumRedirection 0
    Write-Host ("http_ok url={0} status={1}" -f $Url, $resp.StatusCode)
  } catch {
    $msg = $_.Exception.Message
    Write-Host ("http_error url={0} err={1}" -f $Url, $msg)
  }
}

if ($env:RUN_NETWORK_TESTS -ne '1') {
  Write-Host ""
  Write-Host "== network tests skipped =="
  Write-Host "set RUN_NETWORK_TESTS=1 to run DNS/TCP/HTTP checks"
  if ($netDisabled) { exit $E_NET_DISABLED }
  exit $E_OK
}

$dnsFail = $false
$tlsFail = $false

Write-Host ""
Write-Host "== DNS test (opt-in) =="
if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
  try {
    Resolve-DnsName -Name api.github.com | Out-Null
  } catch {
    $dnsFail = $true
  }
} elseif (Get-Command nslookup -ErrorAction SilentlyContinue) {
  try {
    nslookup api.github.com | Out-Null
  } catch {
    $dnsFail = $true
  }
} else {
  Write-Host "dns_tool=missing"
}

Write-Host ""
Write-Host "== connectivity smoke tests (no auth, opt-in) =="
@(
  'https://example.com',
  'https://example.org',
  'https://example.net',
  'https://httpbin.org/get',
  'https://ifconfig.me',
  'https://api.github.com',
  'https://github.com',
  'https://raw.githubusercontent.com',
  'https://objects.githubusercontent.com',
  'https://uploads.githubusercontent.com',
  'https://api.github.com/rate_limit',
  'https://api.github.com/octocat'
) | ForEach-Object { Invoke-Head $_ }

Write-Host ""
Write-Host "== optional repo-scoped Actions API check (no auth by default) =="
if ($env:GITHUB_REPO) {
  Invoke-Head ("https://api.github.com/repos/{0}/actions/runs?per_page=1" -f $env:GITHUB_REPO)
  Write-Host "note: set GITHUB_REPO=owner/repo to enable"
} else {
  Write-Host "GITHUB_REPO not set; skipping repo-scoped check"
}

Write-Host ""
Write-Host "== TLS/TCP 443 check (opt-in) =="
if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
  try {
    $ok = Test-NetConnection -ComputerName api.github.com -Port 443 -InformationLevel Quiet
    if (-not $ok) { $tlsFail = $true }
  } catch {
    $tlsFail = $true
  }
} else {
  Write-Host "Test-NetConnection=missing"
}

if ($netDisabled) { exit $E_NET_DISABLED }
if ($dnsFail -or $tlsFail) { exit $E_NET_FAIL }
exit $E_OK
