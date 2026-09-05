# End-to-end proxy verification on Windows.
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows-lib.ps1")

$root = Get-BridgeRoot
Set-Location $root
$python = Get-BridgePython
$url = Get-BridgeProxyUrl
Write-Output "Verifying proxy at $url"

Write-Output "1. health"
$health = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 8
if ($health.status -ne "ok") { throw "health status is not ok" }
$configured = $health.deepseek_configured -or $health.openai_configured -or $health.custom_configured
if (-not $configured) { throw "No backend API key is configured. Configure config.json or the dashboard first." }
Write-Output ("os_family={0} backend={1}" -f $health.os_family, $health.default_backend)

Write-Output "2. models"
$models = Invoke-RestMethod -Uri "$url/v1/models" -TimeoutSec 8
if (-not $models.data -or $models.data.Count -lt 1) { throw "models list is empty" }
Write-Output ("models={0}" -f $models.data.Count)

Write-Output "3. messages"
$body = @{
    model = "claude-sonnet-4-5"
    max_tokens = 32
    messages = @(@{ role = "user"; content = "Reply with OK." })
} | ConvertTo-Json -Depth 6
$resp = Invoke-WebRequest -Uri "$url/v1/messages" -Method Post -ContentType "application/json" -Body $body -TimeoutSec 60
if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 300) { throw "Message request failed with HTTP $($resp.StatusCode)" }
$msg = $resp.Content | ConvertFrom-Json
if ($msg.type -eq "error" -or $msg.error) { throw ($resp.Content.Substring(0, [Math]::Min(1000, $resp.Content.Length))) }
if ($msg.type -ne "message") { throw "unexpected message type" }
Write-Output ("message_id={0} stop_reason={1}" -f $msg.id, $msg.stop_reason)

Write-Output "4. recent requests"
$recent = Invoke-RestMethod -Uri "$url/api/recent-requests" -TimeoutSec 8
$ok = @($recent.requests | Where-Object { $_.backend -in @("deepseek", "openai", "custom") -and $_.status -eq "success" })
if ($ok.Count -lt 1) { throw "No successful backend request found in recent requests." }
Write-Output ("successful_backend_requests={0}" -f $ok.Count)

if ($env:VERIFY_IMAGE -eq "1") {
    Write-Output "5. image message"
    $reqPath = Join-Path $env:TEMP "cs-bridge-image-request.json"
    & $python -c @"
import json, pathlib, os, base64, zlib, struct
def png(w, h, rgb=(255,0,0)):
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    raw = b''.join(b'\x00' + bytes(rgb) * w for _ in range(h))
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
payload = {
    'model': 'claude-opus-4-8',
    'max_tokens': 32,
    'messages': [{
        'role': 'user',
        'content': [
            {'type': 'text', 'text': 'Look at the image. If the dominant color is red, reply exactly: red. Otherwise reply exactly: no.'},
            {'type': 'image', 'source': {'type': 'base64', 'media_type': 'image/png', 'data': base64.b64encode(png(32, 32)).decode()}},
        ],
    }],
}
pathlib.Path(r'$reqPath').write_text(json.dumps(payload), encoding='utf-8')
"@
    $img = Invoke-WebRequest -Uri "$url/v1/messages" -Method Post -ContentType "application/json" -InFile $reqPath -TimeoutSec 90
    if ($img.StatusCode -lt 200 -or $img.StatusCode -ge 300) { throw "Image request failed with HTTP $($img.StatusCode)" }
    $imgMsg = $img.Content | ConvertFrom-Json
    $text = (($imgMsg.content | ForEach-Object { $_.text }) -join " ")
    if ($text -notmatch '(?i)\bred\b') { throw "Image verification did not confirm red. Response: $text" }
    Write-Output ("image_response={0}" -f $text.Substring(0, [Math]::Min(120, $text.Length)))
}

Write-Output "proxy verification passed"
