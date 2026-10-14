<#
  抓 Exchange（Outlook）行事曆，寫成同資料夾的 calendar.js，給起始頁顯示「下一場會議」並在會前通知
  起始頁每 60 秒重讀 calendar.js；本腳本可掛工作排程器定時跑（見 -Install）。
  設定：同資料夾 settings.json 的 calendar.ewsUrl（必填）、calendar.days、calendar.ewsDll；參數優先於 settings.json
  用法：
    & "<StartPage 資料夾>\calendar-sync.ps1"                       # 今天起 7 天
    & "<StartPage 資料夾>\calendar-sync.ps1" -EwsUrl https://mail.example.com/EWS/Exchange.asmx
    & "<StartPage 資料夾>\calendar-sync.ps1" -Install -Minutes 10  # 建立工作排程（每 10 分鐘，登入時也跑一次）
  認證：用目前登入者的 Windows / AD session（UseDefaultCredentials），不存密碼；失敗時 calendar.js 會寫入錯誤訊息
  EWS DLL：找不到時自動從 NuGet 下載 Microsoft.Exchange.WebServices 2.2（MIT）到同資料夾 lib\
#>
param(
  [string]$EwsUrl = '',
  [int]$Days = 0,
  [string]$EwsDll = '',
  [string]$Dir = $PSScriptRoot,
  [switch]$Install,
  [int]$Minutes = 10
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$out = Join-Path $Dir 'calendar.js'

$cfgFile = Join-Path $Dir 'settings.json'
$cfg = if (Test-Path $cfgFile) { ([IO.File]::ReadAllText($cfgFile, $utf8) | ConvertFrom-Json).calendar }
if (-not $EwsUrl -and $cfg.ewsUrl) { $EwsUrl = $cfg.ewsUrl }
if (-not $Days) { $Days = if ($cfg.days) { [int]$cfg.days } else { 7 } }
if (-not $EwsDll -and $cfg.ewsDll) { $EwsDll = $cfg.ewsDll }

if ($Install) {
  # 其餘設定每次執行時從 settings.json 讀，改設定不用重建排程
  $argList = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argList
  $repeat = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes $Minutes)
  $logon  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
  $set    = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
  # 只在使用者登入時執行（Interactive），才能用目前登入者的 AD session 連 EWS
  $who    = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
  Register-ScheduledTask -TaskName 'StartPage Calendar' -Action $action -Trigger $repeat, $logon -Settings $set -Principal $who -Force | Out-Null
  Write-Output "已建立工作排程「StartPage Calendar」：每 $Minutes 分鐘、登入時各跑一次"
}

$base = [ordered]@{ ts = [DateTimeOffset]::Now.ToUnixTimeMilliseconds(); owa = ($EwsUrl -replace '/EWS/.*$', '/owa/#path=/calendar'); error = ''; items = @() }
try {
  if (-not $EwsUrl) { throw '尚未設定 EWS 網址：請在 settings.json 填 calendar.ewsUrl（例如 https://mail.example.com/EWS/Exchange.asmx）' }
  $dll = @($EwsDll, (Join-Path $Dir 'lib\Microsoft.Exchange.WebServices.dll')) |
         Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $dll) {
    # 第一次執行：從 NuGet 下載 EWS Managed API（.nupkg 是 zip）
    $lib = Join-Path $Dir 'lib'
    New-Item -ItemType Directory -Force $lib | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zip = Join-Path $env:TEMP 'ews-managed-api.zip'
    Invoke-WebRequest 'https://www.nuget.org/api/v2/package/Microsoft.Exchange.WebServices/2.2.0' -OutFile $zip -UseBasicParsing
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
      $z.Entries | Where-Object { $_.FullName -like 'lib/40/*.dll' } |
        ForEach-Object { [IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $lib $_.Name), $true) }
    } finally { $z.Dispose(); Remove-Item $zip -Force }
    $dll = Join-Path $lib 'Microsoft.Exchange.WebServices.dll'
    if (-not (Test-Path $dll)) { throw '下載 Microsoft.Exchange.WebServices.dll 失敗，請手動放到 lib\ 或在 settings.json 指定 calendar.ewsDll' }
  }
  Add-Type -Path $dll
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $svc = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1)
  $svc.Url = [Uri]$EwsUrl
  $svc.UseDefaultCredentials = $true
  $svc.Timeout = 60000

  $cal  = [Microsoft.Exchange.WebServices.Data.CalendarFolder]::Bind($svc, [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Calendar)
  $from = (Get-Date).Date
  $view = New-Object Microsoft.Exchange.WebServices.Data.CalendarView($from, $from.AddDays($Days))
  $view.MaxItemsReturned = 500
  $res  = $cal.FindAppointments($view)

  $toMs = { param($d) [DateTimeOffset]::new($d).ToUnixTimeMilliseconds() }
  $base.items = @($res.Items | Where-Object { -not $_.IsCancelled } | ForEach-Object {
    $a = $_
    # PS 5.1：hashtable 值不能直接寫 try，先算好
    $resp = ''; try { $resp = [string]$a.MyResponseType } catch {}
    $org  = ''; try { $org = $a.Organizer.Name } catch {}
    [ordered]@{
      id        = [string]$a.Id.UniqueId.GetHashCode() + '-' + (& $toMs $a.Start)
      subject   = $a.Subject
      start     = & $toMs $a.Start
      end       = & $toMs $a.End
      allDay    = [bool]$a.IsAllDayEvent
      location  = $a.Location
      organizer = $org
      status    = [string]$a.LegacyFreeBusyStatus   # Free / Tentative / Busy / OOF
      response  = $resp                             # Organizer / Accept / Tentative / NoResponseReceived …
    }
  })
} catch {
  $base.error = $_.Exception.Message
}
$json = ConvertTo-Json -InputObject $base -Depth 5 -Compress
[IO.File]::WriteAllText("$out.tmp", "window.STARTPAGE_CALENDAR && STARTPAGE_CALENDAR($json);`n", $utf8)
Move-Item "$out.tmp" $out -Force
if ($base.error) { Write-Warning $base.error } else { Write-Output "已寫入 $out：$($base.items.Count) 筆" }
