$port = 8791
$root = "C:\Users\Dell\Desktop\dergi"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root on http://localhost:$port/"

$mime = @{
  ".html"="text/html; charset=utf-8"; ".htm"="text/html; charset=utf-8"
  ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".gif"="image/gif"
  ".css"="text/css"; ".js"="application/javascript"; ".svg"="image/svg+xml"
  ".mp3"="audio/mpeg"; ".wav"="audio/wav"; ".json"="application/json"
}

while ($listener.IsListening) {
  try {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $path = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrEmpty($path)) { $path = "index.html" }
    $filePath = Join-Path $root $path
    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
      $contentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
      $response.ContentType = $contentType
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $response.StatusCode = 404
      $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
      $response.OutputStream.Write($msg, 0, $msg.Length)
    }
    $response.OutputStream.Close()
  } catch {
    Write-Host "Error: $_"
  }
}
