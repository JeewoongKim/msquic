# Copy the fuzzers selected by the OSS-Fuzz manifest to $OUT.

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:OUT)) {
    throw 'OSS-Fuzz OUT environment variable is required'
}

$RootDir = Split-Path $PSScriptRoot -Parent
$BuildConfig = & (Join-Path $PSScriptRoot 'get-buildconfig.ps1')
$BuildDir = Join-Path $RootDir "build/$($BuildConfig.Platform)/$($BuildConfig.Arch)_$($BuildConfig.Tls)"
$BinDir = Join-Path $BuildDir 'fuzzers'

$ManifestPath = Join-Path $RootDir 'src/fuzzing/oss-fuzz.json'
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

foreach ($Target in $Manifest.targets) {
    $Source = Join-Path $BinDir $Target.name

    Copy-Item -LiteralPath $Source `
        -Destination (Join-Path $env:OUT $Target.name) -Force

    if ($Target.PSObject.Properties['options']) {
        $Lines = @('[libfuzzer]')
        foreach ($Option in $Target.options.libfuzzer.PSObject.Properties) {
            $Lines += "$($Option.Name) = $($Option.Value)"
        }

        $OptionsPath = Join-Path $env:OUT "$($Target.name).options"
        $Lines | Set-Content -LiteralPath $OptionsPath -Encoding utf8
        Write-Host "Packaged options: $($Target.name).options"
    }

    Write-Host "Packaged: $($Target.name)"
}
