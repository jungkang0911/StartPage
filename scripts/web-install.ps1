# One-line installer for StartPage (Windows PowerShell 5.1+):
#   irm https://raw.githubusercontent.com/jungkang0911/StartPage/main/scripts/web-install.ps1 | iex
# Custom folder:
#   $env:STARTPAGE_TARGET = 'D:\StartPage'; irm https://raw.githubusercontent.com/jungkang0911/StartPage/main/scripts/web-install.ps1 | iex
# Downloads the latest source zip from GitHub, then runs scripts\install.ps1. Re-run to update; personal files are kept.
& {
  $ErrorActionPreference = 'Stop'
  $repo = if ($env:STARTPAGE_REPO) { $env:STARTPAGE_REPO } else { 'jungkang0911/StartPage' }
  $branch = if ($env:STARTPAGE_BRANCH) { $env:STARTPAGE_BRANCH } else { 'main' }
  $target = if ($env:STARTPAGE_TARGET) { $env:STARTPAGE_TARGET } else { Join-Path $env:USERPROFILE 'StartPage' }

  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $tmp = Join-Path $env:TEMP ('startpage-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
  New-Item -ItemType Directory -Force $tmp | Out-Null
  try {
    $zip = Join-Path $tmp 'src.zip'
    Write-Host "Downloading $repo ($branch)..."
    Invoke-WebRequest "https://codeload.github.com/$repo/zip/refs/heads/$branch" -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath $tmp -Force
    $src = Get-ChildItem $tmp -Directory | Select-Object -First 1
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $src.FullName 'scripts\install.ps1') -Target $target
  } finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
