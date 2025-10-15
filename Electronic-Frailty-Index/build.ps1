param(
  [ValidateSet("html","pdf","all","lint","clean")]
  [string]$Target = "all"
)

function Build-Html { quarto render report\efi_2024_progress.md --to html --output-dir report }
function Build-Pdf  { quarto render report\efi_2024_progress.md --to pdf  --output-dir report }
function Run-Lint   {
  if (Get-Command markdownlint -ErrorAction SilentlyContinue) {
    markdownlint .
  } else {
    Write-Host "markdownlint CLI ei asennettu. Asenna: winget install OpenJS.NodeJS.LTS; npm i -g markdownlint-cli"
  }
}
function Clean-Out  {
  Remove-Item -Recurse -Force .\_site, .\.quarto, .\*.log -ErrorAction SilentlyContinue
  # Puhdista juuresta vahingossa syntyneet raporttitiedostot
  Get-ChildItem -File -Filter "efi_2024_progress.*" | Remove-Item -Force -ErrorAction SilentlyContinue
}

switch ($Target) {
  "html"  { Build-Html }
  "pdf"   { Build-Pdf }
  "lint"  { Run-Lint }
  "clean" { Clean-Out }
  "all"   { Build-Html; Build-Pdf }
}
