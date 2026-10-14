<#
  送一則通知到 StartPage 起始頁（取代 ntfy）
  起始頁每 10 秒讀一次同資料夾的 inbox.js，有新通知就跳 Windows 桌面通知並記到右上 🔔。
  用法：
    & "<StartPage 資料夾>\notify.ps1" "排程 XXX 跑完了"
    & "<StartPage 資料夾>\notify.ps1" "匯入失敗：連線逾時" -Title "夜間批次" -Priority high
    & "<StartPage 資料夾>\notify.ps1" "報表已產生" -Click "D:\Report\今日.xlsx" -Source "報表排程"
  -Priority：min / low（只記錄不跳通知）、default、high / urgent（通知不會自動消失）
  -Click：點通知要開的網址（本機路徑會自動轉 file:///）
  -Todo：改成加入起始頁待辦清單（不跳通知、不送 ntfy），-TodoList 指定待辦區塊標題（預設第一個待辦區塊）
    & "<StartPage 資料夾>\notify.ps1" "回覆週報" -Todo
  -Note：改成附加一行到起始頁筆記（同上不跳通知、不送 ntfy），-TodoList 同樣可指定筆記區塊標題
    & "<StartPage 資料夾>\notify.ps1" "會議紀錄：D:\Notes\meeting.md" -Note
  ntfy 同步推播：settings.json 填 ntfy.url（如 https://ntfy.sh/你的topic）就會同時送到 ntfy（手機也收得到）；
                 舊版的同資料夾 ntfy.txt 仍可用；-NoNtfy 這次不送；ntfy 失敗只會警告，不影響起始頁通知
#>
param(
  [Parameter(Mandatory, Position = 0)][string]$Message,
  [string]$Title = '',
  [ValidateSet('min', 'low', 'default', 'high', 'urgent')][string]$Priority = 'default',
  [string]$Click = '',
  [string]$Source = '',
  [string]$Dir = '',
  [int]$Keep = 100,
  [switch]$NoNtfy,
  [switch]$Todo,
  [switch]$Note,
  [string]$TodoList = ''
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
# PS 5.1 用 -File 執行時，param 預設值裡的 $PSScriptRoot 會是空的
if (-not $Dir) { $Dir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$inbox = Join-Path $Dir 'inbox.js'

if ($Click -match '^[A-Za-z]:\\|^\\\\') { $Click = ([Uri]$Click).AbsoluteUri }   # 本機路徑 → file:///

# 多個排程同時送時用 mutex 排隊，避免互相覆蓋
$mutex = New-Object System.Threading.Mutex($false, 'Global\StartPageInbox')
[void]$mutex.WaitOne(10000)
try {
  $old = @()
  if (Test-Path $inbox) {
    $m = [regex]::Match([IO.File]::ReadAllText($inbox, $utf8), '(?s)STARTPAGE_INBOX\((.*)\)\s*;?\s*$')
    # PS 5.1 的 ConvertFrom-Json 會把整個陣列當一個物件輸出，再過一次管線才會攤開
    if ($m.Success) { try { $parsed = $m.Groups[1].Value | ConvertFrom-Json; $old = @($parsed | ForEach-Object { $_ }) } catch { $old = @() } }
  }
  $item = [ordered]@{
    id       = [guid]::NewGuid().ToString('N').Substring(0, 12)
    ts       = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    title    = $Title
    message  = $Message
    priority = $Priority
    click    = $Click
    source   = $Source
  }
  if ($Todo) { $item.kind = 'todo'; $item.list = $TodoList }
  elseif ($Note) { $item.kind = 'note'; $item.list = $TodoList }
  $list = @($item) + @($old | Select-Object -First ($Keep - 1))
  $json = ConvertTo-Json -InputObject $list -Depth 4 -Compress
  $tmp = "$inbox.tmp"
  [IO.File]::WriteAllText($tmp, "window.STARTPAGE_INBOX && STARTPAGE_INBOX($json);`n", $utf8)
  Move-Item $tmp $inbox -Force
} finally { $mutex.ReleaseMutex() }

# 同步送 ntfy（用 JSON 發布，中文標題才不會亂碼）
$url = ''
$cfgFile = Join-Path $Dir 'settings.json'
if (Test-Path $cfgFile) { try { $url = [string]([IO.File]::ReadAllText($cfgFile, $utf8) | ConvertFrom-Json).ntfy.url } catch { Write-Warning "settings.json 格式錯誤：$($_.Exception.Message)" } }
$ntfyFile = Join-Path $Dir 'ntfy.txt'
if (-not $url -and (Test-Path $ntfyFile)) { $url = [string](Get-Content $ntfyFile -TotalCount 1) }
$url = $url.Trim()
if (-not $NoNtfy -and -not $Todo -and -not $Note -and $url) {
  if ($url -match '^(https?://[^/]+)/([\w-]+)$') {
    $body = [ordered]@{
      topic    = $Matches[2]
      message  = $Message
      priority = @{ min = 1; low = 2; default = 3; high = 4; urgent = 5 }[$Priority]
    }
    if ($Title) { $body.title = $Title }
    if ($Click -match '^https?://') { $body.click = $Click }   # 手機開不了本機檔，只帶網址
    try {
      Invoke-RestMethod -Method Post -Uri $Matches[1] -ContentType 'application/json; charset=utf-8' `
        -Body ([Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Compress))) -TimeoutSec 10 | Out-Null
    } catch { Write-Warning "ntfy 推播失敗（起始頁通知已送出）：$($_.Exception.Message)" }
  } else { Write-Warning "ntfy.txt 格式不正確，應為 https://伺服器/topic：$url" }
}
