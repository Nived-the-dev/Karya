# One-command local verifier for a Windows PC with Flutter and Android Studio.
# Run inside the extracted project: powershell -ExecutionPolicy Bypass -File .\tool\BUILD_KARYA_WINDOWS.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
function Step($title, $command) {
  Write-Host "`n==> $title" -ForegroundColor Cyan
  $argsList = @($command | Select-Object -Skip 1)
  & $command[0] @argsList
  if ($LASTEXITCODE -ne 0) { throw "Failed: $title (exit code $LASTEXITCODE)" }
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter not found. Install Flutter and Android Studio and restart PowerShell. See tool/BOOTSTRAP_ANDROID.md.'
}
Step 'Flutter environment' @('flutter','doctor')
Step 'Complete missing Android/Gradle platform files' @('flutter','create','--platforms=android','--project-name=karya_app','--no-pub','.')
Step 'Resolve dependencies' @('flutter','pub','get')
Step 'Format source' @('dart','format','lib','test','integration_test')
Step 'Analyze app' @('flutter','analyze')
Step 'Run tests' @('flutter','test','test')
Step 'Build installable debug APK' @('flutter','build','apk','--debug')
$apk = Join-Path (Get-Location) 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not (Test-Path $apk)) { throw 'APK output not found; investigate build logs.' }
New-Item -ItemType Directory -Force -Path 'exports' | Out-Null
Copy-Item $apk 'exports\Karya_2.0_Test.apk' -Force
Write-Host "`nSuccess. Your test APK is at: exports\Karya_2.0_Test.apk" -ForegroundColor Green
Write-Host 'This is a DEBUG APK, not a signed Google Play release bundle.'
