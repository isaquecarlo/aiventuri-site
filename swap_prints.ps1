$base = 'C:\Users\Nitro 5\Downloads\LeoLP'
$src  = "$base\index.html"

Write-Host 'Reading HTML...'
$html = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::UTF8)

# 1. Embed chat_recrutador9.jpeg as base64
$path9 = "$base\chat_recrutador\chat_recrutador9.jpeg"
Write-Host "Encoding: chat_recrutador9.jpeg ($([math]::Round((Get-Item $path9).Length/1KB))KB)"
$bytes = [System.IO.File]::ReadAllBytes($path9)
$b64   = [System.Convert]::ToBase64String($bytes)
$uri9  = "data:image/jpeg;base64,$b64"

# 2. Find and replace the chat_recrutador.jpeg block in recruiter prints section
# The rp-1 div contains chat_recrutador/chat_recrutador.jpeg (already base64)
# We need to find the base64 URI of chat_recrutador.jpeg to replace it
# Strategy: find the rp-1 div and swap src to new URI

# Find the existing base64 for chat_recrutador.jpeg (it's the rp-1 image)
# The HTML has: <div class="chat-print rp-1">...<img src="data:image/jpeg;base64,XXXX"...>
# We'll locate "rp-1" block and swap its src

# Use regex to find rp-1 img src and replace
$pattern = '(<div class="chat-print rp-1">[^<]*<img src=")([^"]+)(")'
if ($html -match $pattern) {
    Write-Host "Found rp-1 image, replacing..."
    $html = [regex]::Replace($html, $pattern, "`${1}$uri9`${3}")
    Write-Host "Replaced chat_recrutador.jpeg with chat_recrutador9.jpeg in rp-1"
} else {
    Write-Host "WARNING: rp-1 pattern not found. Trying alt approach..."
    # Try without newlines restriction
    $pattern2 = 'class="chat-print rp-1"'
    if ($html.Contains('class="chat-print rp-1"')) {
        Write-Host "rp-1 div found. Manual replacement needed."
    }
}

# 3. Remove the cp-3 div (which contains 3.jpeg / chat_candidato/3.jpeg)
# The 3.jpeg is in cp-3
$cpPattern = '<div class="chat-print cp-3">.*?</div>\s*</div>'
$htmlNew = [regex]::Replace($html, $cpPattern, '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($htmlNew.Length -lt $html.Length) {
    Write-Host "Removed cp-3 (3.jpeg) block"
    $html = $htmlNew
} else {
    Write-Host "WARNING: cp-3 pattern not found"
}

Write-Host 'Writing index.html...'
[System.IO.File]::WriteAllText($src, $html, [System.Text.Encoding]::UTF8)
$size = [math]::Round((Get-Item $src).Length / 1MB, 1)
Write-Host "Done! Final size: ${size}MB"
