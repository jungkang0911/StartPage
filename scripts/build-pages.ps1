<#
  產生 GitHub Pages 線上試用（docs/）：
    docs/index.html  ← assets/index.html 原樣複製（範本改了就重跑一次）
    docs/config.js   ← examples/default.json（首次開啟的虛構內容，並在首頁放一個 DevOps 區塊）
  docs/options.js、calendar.js、devops.js、inbox.js 是手寫的虛構資料，不會被覆蓋。
  Pages 設定：Settings → Pages → Deploy from a branch → main / docs
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$utf8 = New-Object System.Text.UTF8Encoding($false)
Copy-Item (Join-Path $root 'assets\index.html') (Join-Path $root 'docs\index.html') -Force
$cfg = [IO.File]::ReadAllText((Join-Path $root 'examples\default.json'), $utf8) | ConvertFrom-Json
$dev = [pscustomobject]@{ id = 'dev'; type = 'devops'; title = 'DevOps Task'; color = 'purple' }
$w = [System.Collections.ArrayList]@($cfg.pages[0].widgets); $w.Insert(2, $dev); $cfg.pages[0].widgets = $w.ToArray()
$json = $cfg | ConvertTo-Json -Depth 50
[IO.File]::WriteAllText((Join-Path $root 'docs\config.js'), "// GitHub Pages 線上試用的預設內容（由 scripts/build-pages.ps1 從 examples/default.json 產生）`nwindow.STARTPAGE_DEFAULT = $json;`n", $utf8)
Write-Host '已更新 docs/index.html 與 docs/config.js'
