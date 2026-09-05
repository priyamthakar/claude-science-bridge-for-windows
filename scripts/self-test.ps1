# Compile proxy modules and run translation tests. No network, no secrets.
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows-lib.ps1")

$root = Get-BridgeRoot
$python = Get-BridgePython
Set-Location $root

& $python -m py_compile (Join-Path $root "proxy.py") (Join-Path $root "setup-token.py") (Join-Path $root "forward-443.py")
if ($LASTEXITCODE -ne 0) { throw "py_compile failed" }

Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | ForEach-Object {
    $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
}

& $python -c @"
import importlib.util
from pathlib import Path
path = Path(r'$root') / 'tests' / 'test_translation.py'
spec = importlib.util.spec_from_file_location('test_translation', path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
tests = sorted(name for name in dir(mod) if name.startswith('test_'))
for name in tests:
    getattr(mod, name)()
    print(f'{name} passed')
print(f'{len(tests)} translation tests passed')
"@
if ($LASTEXITCODE -ne 0) { throw "translation tests failed" }
Write-Output "self-test passed"
