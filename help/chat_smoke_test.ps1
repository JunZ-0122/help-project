$ErrorActionPreference = 'Stop'

$backendDir = 'C:\Users\22789\Desktop\endProject\help'
$backendJar = Join-Path $backendDir 'target\help-0.0.1-SNAPSHOT.jar'
$baseUrl = 'http://localhost:8080/api'

$requestId = 'req005'
$helpSeekerPhone = '13800138002'
$volunteerPhone = '13800138005'
$password = '123456'
$dbName = 'help'
$dbUser = 'root'
$dbPassword = '123456'

$helpSeekerText = $null
$volunteerText = $null

function Wait-ForServer {
  param (
    [string]$Url,
    [int]$TimeoutSeconds = 40
  )

  for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
    Start-Sleep -Seconds 1
    try {
      Invoke-RestMethod -Uri $Url -Method Post -ContentType 'application/json' -Body '{"phone":"13800138002","password":"123456"}' | Out-Null
      return $true
    } catch {
      continue
    }
  }

  return $false
}

function Login-User {
  param (
    [string]$Phone,
    [string]$PasswordText
  )

  $body = @{
    phone = $Phone
    password = $PasswordText
  } | ConvertTo-Json

  $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType 'application/json' -Body $body
  if ($response.code -ne 200 -or -not $response.data.token) {
    throw "Login failed for $Phone"
  }

  return $response.data
}

function Invoke-Api {
  param (
    [string]$Method,
    [string]$Path,
    [string]$Token,
    [object]$Body = $null
  )

  $headers = @{
    Authorization = "Bearer $Token"
  }

  $params = @{
    Uri = "$baseUrl$Path"
    Method = $Method
    Headers = $headers
  }

  if ($Body -ne $null) {
    $params.ContentType = 'application/json'
    $params.Body = ($Body | ConvertTo-Json -Depth 10)
  }

  return Invoke-RestMethod @params
}

function Get-FieldValue {
  param (
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }

  if ($Object -is [System.Collections.IDictionary]) {
    return $Object[$Name]
  }

  $property = $Object.PSObject.Properties[$Name]
  if ($property) {
    return $property.Value
  }

  return $null
}

function Get-ChatHistory {
  param (
    [string]$RequestId,
    [string]$Token
  )

  $headers = @{
    Authorization = "Bearer $Token"
  }

  $response = Invoke-RestMethod -Uri "$baseUrl/chat/$($RequestId)?page=1&pageSize=50" -Method Get -Headers $headers
  return [ordered]@{
    response = $response
    items = @($response.data.items)
    total = $response.data.total
  }
}

function Get-MySqlExecutable {
  $candidates = @(
    'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  $command = Get-Command mysql.exe -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  return $null
}

function Cleanup-SmokeMessages {
  param (
    [string[]]$Texts
  )

  $validTexts = @($Texts | Where-Object { $_ })
  if ($validTexts.Count -eq 0) {
    return
  }

  $mysqlExe = Get-MySqlExecutable
  if (-not $mysqlExe) {
    return
  }

  $quotedTexts = $validTexts | ForEach-Object { "'$($_)'" }
  $sql = "DELETE FROM chat_messages WHERE text IN ({0});" -f ($quotedTexts -join ',')
  & $mysqlExe "-u$dbUser" "-p$dbPassword" -D $dbName -e $sql | Out-Null
}

$serverProcess = $null

try {
  if (-not (Test-Path $backendJar)) {
    throw "Backend jar not found: $backendJar"
  }

  $serverProcess = Start-Process -FilePath 'java' -ArgumentList '-jar', $backendJar -WorkingDirectory $backendDir -PassThru

  if (-not (Wait-ForServer -Url "$baseUrl/auth/login")) {
    throw 'Backend did not become ready in time'
  }

  $helpSeeker = Login-User -Phone $helpSeekerPhone -PasswordText $password
  $volunteer = Login-User -Phone $volunteerPhone -PasswordText $password

  $historyBefore = Get-ChatHistory -RequestId $requestId -Token $helpSeeker.token
  $beforeItems = @($historyBefore.items)
  $beforeCount = $beforeItems.Count

  $helpSeekerText = "smoke-help-seeker-$(Get-Date -Format 'yyyyMMddHHmmss')"
  $sentByHelpSeeker = Invoke-Api -Method 'Post' -Path '/chat/' -Token $helpSeeker.token -Body @{
    requestId = $requestId
    receiverId = $volunteer.user.id
    text = $helpSeekerText
    type = 'text'
  }

  $unreadForVolunteerBeforeRead = Invoke-Api -Method 'Get' -Path "/chat/$requestId/unread" -Token $volunteer.token
  $historyForVolunteer = Get-ChatHistory -RequestId $requestId -Token $volunteer.token
  $volunteerItems = @($historyForVolunteer.items)
  $volunteerSawMessage = @($volunteerItems | Where-Object { $_.id -eq $sentByHelpSeeker.data.id -and $_.text -eq $helpSeekerText })

  $markReadResult = Invoke-Api -Method 'Put' -Path '/chat/read' -Token $volunteer.token -Body @{
    messageIds = @($sentByHelpSeeker.data.id)
  }
  $unreadForVolunteerAfterRead = Invoke-Api -Method 'Get' -Path "/chat/$requestId/unread" -Token $volunteer.token

  $volunteerText = "smoke-volunteer-$(Get-Date -Format 'yyyyMMddHHmmss')"
  $sentByVolunteer = Invoke-Api -Method 'Post' -Path '/chat/' -Token $volunteer.token -Body @{
    requestId = $requestId
    receiverId = $helpSeeker.user.id
    text = $volunteerText
    type = 'text'
  }

  $historyAfter = Get-ChatHistory -RequestId $requestId -Token $helpSeeker.token
  $afterItems = @($historyAfter.items)
  $afterCount = $afterItems.Count
  $helpSeekerSawReply = @($afterItems | Where-Object { $_.id -eq $sentByVolunteer.data.id -and $_.text -eq $volunteerText })

  $result = [ordered]@{
    requestId = $requestId
    helpSeeker = [ordered]@{
      id = $helpSeeker.user.id
      phone = $helpSeeker.user.phone
      role = $helpSeeker.user.role
    }
    volunteer = [ordered]@{
      id = $volunteer.user.id
      phone = $volunteer.user.phone
      role = $volunteer.user.role
    }
    checks = [ordered]@{
      loginHelpSeeker = $true
      loginVolunteer = $true
      historyLoaded = ($beforeCount -ge 1)
      beforeCount = $beforeCount
      sendHelpSeekerToVolunteer = ($sentByHelpSeeker.code -eq 200)
      volunteerHistoryCount = $volunteerItems.Count
      volunteerCanSeeNewMessage = ($volunteerSawMessage.Count -ge 1)
      unreadBeforeRead = $unreadForVolunteerBeforeRead.data
      markReadSucceeded = ($markReadResult.code -eq 200)
      unreadAfterRead = $unreadForVolunteerAfterRead.data
      sendVolunteerToHelpSeeker = ($sentByVolunteer.code -eq 200)
      afterCount = $afterCount
      helpSeekerCanSeeReply = ($helpSeekerSawReply.Count -ge 1)
      messageCountDelta = ($afterCount - $beforeCount)
    }
  }

  $result | ConvertTo-Json -Depth 10

  if (
    -not $result.checks.historyLoaded -or
    -not $result.checks.sendHelpSeekerToVolunteer -or
    -not $result.checks.volunteerCanSeeNewMessage -or
    -not $result.checks.markReadSucceeded -or
    $result.checks.unreadBeforeRead -lt 1 -or
    $result.checks.unreadAfterRead -ne 0 -or
    -not $result.checks.sendVolunteerToHelpSeeker -or
    -not $result.checks.helpSeekerCanSeeReply -or
    $result.checks.messageCountDelta -lt 2
  ) {
    exit 1
  }
} finally {
  Cleanup-SmokeMessages -Texts @($helpSeekerText, $volunteerText)

  if ($serverProcess -and -not $serverProcess.HasExited) {
    Stop-Process -Id $serverProcess.Id -Force
  }
}
