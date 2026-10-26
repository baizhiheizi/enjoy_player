# Resolve Git Bash for the release scripts. Standard installs win, then any
# non-WSL bash on PATH (self-hosted runners may install Git via scoop).
$ErrorActionPreference = 'Stop'

$candidates = @(
  "${env:ProgramFiles}\Git\bin\bash.exe",
  "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
)
$candidates += @(
  Get-Command bash.exe -All -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Source }
)

$gitBash = $candidates |
  Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
  Where-Object { $_ -notmatch '\\Windows\\(System32|SysWOW64)\\bash\.exe$' } |
  Where-Object { $_ -notmatch '\\WindowsApps\\bash\.exe$' } |
  Select-Object -First 1

if (-not $gitBash) {
  throw 'Git Bash not found (WSL bash is not supported). Install Git for Windows or add its bin directory to PATH.'
}

$gitBash
