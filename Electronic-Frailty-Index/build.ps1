param(
  [ValidateSet("html","pdf","all","lint")]
  [string]$Target = "all"
)

function Run-Lint {
  if (Get-Command markdownlint -ErrorAction SilentlyContinue) { markdownlint .. }
  else { Write-Host "Asenna markdownlint-cli: npm i -g markdownlint-cli" -ForegroundColor Yellow }
}

function Build-Html { quarto render .\docs\PHDSUM_efi_progress_2024_summary.md --to html --output-dir .\docs }
function Build-Pdf  { quarto render .\docs\PHDSUM_efi_progress_2024_summary.md --to pdf  --output-dir .\docs }

switch ($Target) {
  "lint" { Run-Lint }
  "html" { Build-Html }
  "pdf"  { Build-Pdf  }
  "all"  { Run-Lint; Build-Html; Build-Pdf }
}
