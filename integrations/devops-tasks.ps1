<#
  抓 Azure DevOps 上指派給我的未結工作項，寫成同資料夾的 devops.js，給起始頁「DevOps Task」區塊顯示
  起始頁每 60 秒重讀 devops.js；本腳本可掛工作排程器定時跑（見 -Install）。
  設定：同資料夾 settings.json 的 devops.org（必填）、devops.project、devops.types；參數優先於 settings.json
  用法：
    & "<StartPage 資料夾>\devops-tasks.ps1"                                  # 依 settings.json
    & "<StartPage 資料夾>\devops-tasks.ps1" -Org https://dev.azure.com/my-org
    & "<StartPage 資料夾>\devops-tasks.ps1" -Project MyProject -Types Task,Bug
    & "<StartPage 資料夾>\devops-tasks.ps1" -Install -Minutes 30             # 建立工作排程（每 30 分鐘，登入時也跑一次）
  認證：用 Azure CLI（az login）的 token，不存密碼；未登入時 devops.js 會寫入錯誤訊息，起始頁會顯示「請執行 az login」
#>
param(
  [string]$Org = '',
  [string]$Project = '',
  [string[]]$Types = @(),
  [string]$Dir = $PSScriptRoot,
  [switch]$Install,
  [int]$Minutes = 30
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$out = Join-Path $Dir 'devops.js'

$cfgFile = Join-Path $Dir 'settings.json'
$cfg = if (Test-Path $cfgFile) { ([IO.File]::ReadAllText($cfgFile, $utf8) | ConvertFrom-Json).devops }
if (-not $Org -and $cfg.org) { $Org = $cfg.org }
$Org = $Org.TrimEnd('/')
if (-not $Project -and $cfg.project) { $Project = $cfg.project }
if (-not $Types.Count) { $Types = if ($cfg.types) { @($cfg.types) } else { @('Task') } }

if ($Install) {
  # 其餘設定每次執行時從 settings.json 讀，改設定不用重建排程
  $argList = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  $action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argList
  $repeat  = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes $Minutes)
  $logon   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
  $set     = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
  Register-ScheduledTask -TaskName 'StartPage DevOps Tasks' -Action $action -Trigger $repeat, $logon -Settings $set -Force | Out-Null
  Write-Output "已建立工作排程「StartPage DevOps Tasks」：每 $Minutes 分鐘、登入時各跑一次"
}

function Write-Result($obj) {
  $json = ConvertTo-Json -InputObject $obj -Depth 5 -Compress
  $tmp = "$out.tmp"
  [IO.File]::WriteAllText($tmp, "window.STARTPAGE_DEVOPS && STARTPAGE_DEVOPS($json);`n", $utf8)
  Move-Item $tmp $out -Force
}

$base = [ordered]@{ ts = [DateTimeOffset]::Now.ToUnixTimeMilliseconds(); org = $Org; project = $Project; error = ''; items = @() }
try {
  if (-not $Org) { throw '尚未設定組織：請在 settings.json 填 devops.org（例如 https://dev.azure.com/my-org）' }
  $token = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $token) { throw 'NOT_LOGGED_IN: 請在終端機執行 az login' }
  $h = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json; charset=utf-8' }

  $typeList = ($Types | ForEach-Object { "'$_'" }) -join ','
  $projFilter = if ($Project) { " AND [System.TeamProject] = '$Project'" } else { '' }
  $wiql = "SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] IN ($typeList) AND [System.AssignedTo] = @Me" +
          " AND [System.State] NOT IN ('Closed','Done','Removed','Resolved')$projFilter ORDER BY [System.ChangedDate] DESC"
  $wiqlUrl = if ($Project) { "$Org/$Project/_apis/wit/wiql?api-version=7.0" } else { "$Org/_apis/wit/wiql?api-version=7.0" }
  $q = Invoke-RestMethod -Method Post -Headers $h -Body ([Text.Encoding]::UTF8.GetBytes((@{ query = $wiql } | ConvertTo-Json))) $wiqlUrl

  $ids = @($q.workItems.id | Where-Object { $_ })   # PS 5.1：空陣列取 .id 會變成 @($null)
  $items = @()
  $fields = 'System.Id,System.Title,System.State,System.WorkItemType,System.TeamProject,System.Parent,System.ChangedDate,Microsoft.VSTS.Scheduling.RemainingWork,Microsoft.VSTS.Scheduling.TargetDate,Microsoft.VSTS.Scheduling.DueDate'
  for ($i = 0; $i -lt $ids.Count; $i += 200) {
    $batch = ($ids[$i..([Math]::Min($i + 199, $ids.Count - 1))]) -join ','
    $items += (Invoke-RestMethod -Headers $h "$Org/_apis/wit/workitems?ids=$batch&fields=$fields&errorPolicy=omit&api-version=7.0").value | Where-Object { $_ }
  }

  # 上層 User Story / PBI 標題
  $parentIds = @($items | ForEach-Object { $_.fields.'System.Parent' } | Where-Object { $_ } | Select-Object -Unique)
  $parents = @{}
  for ($i = 0; $i -lt $parentIds.Count; $i += 200) {
    $batch = ($parentIds[$i..([Math]::Min($i + 199, $parentIds.Count - 1))]) -join ','
    (Invoke-RestMethod -Headers $h "$Org/_apis/wit/workitems?ids=$batch&fields=System.Id,System.Title&errorPolicy=omit&api-version=7.0").value |
      Where-Object { $_ } | ForEach-Object { $parents[[int]$_.id] = $_.fields.'System.Title' }
  }

  $base.items = @($items | ForEach-Object {
    $f = $_.fields
    $due = if ($f.'Microsoft.VSTS.Scheduling.DueDate') { $f.'Microsoft.VSTS.Scheduling.DueDate' } else { $f.'Microsoft.VSTS.Scheduling.TargetDate' }
    [ordered]@{
      id          = $_.id
      title       = $f.'System.Title'
      state       = $f.'System.State'
      type        = $f.'System.WorkItemType'
      project     = $f.'System.TeamProject'
      parentId    = $f.'System.Parent'
      parentTitle = if ($f.'System.Parent') { $parents[[int]$f.'System.Parent'] } else { '' }
      changed     = ([datetime]$f.'System.ChangedDate').ToString('yyyy-MM-dd')
      due         = if ($due) { ([datetime]$due).ToString('yyyy-MM-dd') } else { '' }
      remaining   = $f.'Microsoft.VSTS.Scheduling.RemainingWork'
      url         = "$Org/$([Uri]::EscapeDataString($f.'System.TeamProject'))/_workitems/edit/$($_.id)"
    }
  })
} catch {
  $base.error = $_.Exception.Message
}
Write-Result $base
if ($base.error) { Write-Warning $base.error } else { Write-Output "已寫入 $out：$($base.items.Count) 筆" }
