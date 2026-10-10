$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
if (Test-Path -LiteralPath 'firebase-config.json') {
    & flutter build web --release --no-web-resources-cdn --dart-define-from-file=firebase-config.json
} else {
    & flutter build web --release --no-web-resources-cdn
}
if ($LASTEXITCODE -ne 0) { throw 'Web build failed.' }
& dart run tool/serve.dart 8080
