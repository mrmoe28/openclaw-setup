param(
    [string]$OutputPath = (Join-Path $env:USERPROFILE "Desktop\OpenClaw\openclaw.ico")
)

Add-Type -AssemblyName System.Drawing

function Create-ClawBitmap([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    [float]$scale = $size / 256.0

    # Background gradient
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)),
        (New-Object System.Drawing.Point($size, $size)),
        [System.Drawing.Color]::FromArgb(255, 18, 22, 38),
        [System.Drawing.Color]::FromArgb(255, 30, 40, 65)
    )

    # Rounded rectangle background
    [int]$radius = [Math]::Max(4, [int](40 * $scale))
    [int]$w = $size - 1
    [int]$h = $size - 1
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $radius * 2, $radius * 2, 180, 90)
    $path.AddArc($w - $radius * 2, 0, $radius * 2, $radius * 2, 270, 90)
    $path.AddArc($w - $radius * 2, $h - $radius * 2, $radius * 2, $radius * 2, 0, 90)
    $path.AddArc(0, $h - $radius * 2, $radius * 2, $radius * 2, 90, 90)
    $path.CloseFigure()
    $g.FillPath($bgBrush, $path)

    # Border
    $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 80, 180, 255), [Math]::Max(1, [int](2 * $scale)))
    $g.DrawPath($borderPen, $path)

    # Claw marks - 3 diagonal slashes
    $clawColor = [System.Drawing.Color]::FromArgb(255, 0, 210, 140)
    $glowColor = [System.Drawing.Color]::FromArgb(50, 0, 255, 170)
    [int]$clawWidth = [Math]::Max(2, [int](16 * $scale))
    [int]$glowWidth = [Math]::Max(3, [int](26 * $scale))

    $lines = @(
        @(55, 50, 100, 205),
        @(108, 38, 138, 212),
        @(160, 50, 190, 205)
    )

    foreach ($line in $lines) {
        [int]$x1 = [int]($line[0] * $scale)
        [int]$y1 = [int]($line[1] * $scale)
        [int]$x2 = [int]($line[2] * $scale)
        [int]$y2 = [int]($line[3] * $scale)

        $glowPen = New-Object System.Drawing.Pen($glowColor, $glowWidth)
        $glowPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $glowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $g.DrawLine($glowPen, $x1, $y1, $x2, $y2)
        $glowPen.Dispose()

        $clawPen = New-Object System.Drawing.Pen($clawColor, $clawWidth)
        $clawPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $clawPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $g.DrawLine($clawPen, $x1, $y1, $x2, $y2)
        $clawPen.Dispose()
    }

    # Terminal prompt at bottom
    if ($size -ge 48) {
        $fontSize = [Math]::Max(8, [int](13 * $scale))
        $promptFont = New-Object System.Drawing.Font("Consolas", $fontSize, [System.Drawing.FontStyle]::Bold)
        $promptBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 210, 140))
        [int]$px = [int](62 * $scale)
        [int]$py = [int](212 * $scale)
        $g.DrawString(">_", $promptFont, $promptBrush, $px, $py)
        $promptFont.Dispose()
        $promptBrush.Dispose()
    }

    $g.Dispose()
    $bgBrush.Dispose()
    $borderPen.Dispose()
    $path.Dispose()

    return $bmp
}

# Generate bitmaps at multiple sizes
$bmp256 = Create-ClawBitmap 256
$bmp48 = Create-ClawBitmap 48
$bmp32 = Create-ClawBitmap 32
$bmp16 = Create-ClawBitmap 16

$allBitmaps = @($bmp256, $bmp48, $bmp32, $bmp16)

# Convert each to PNG bytes
$pngBytes = @()
foreach ($bm in $allBitmaps) {
    $pms = New-Object System.IO.MemoryStream
    $bm.Save($pms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes += ,($pms.ToArray())
    $pms.Dispose()
}

# Build ICO file
$parentDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }

$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)

$bw.Write([UInt16]0)
$bw.Write([UInt16]1)
$bw.Write([UInt16]4)

[int]$dataStart = 6 + (16 * 4)
$imgSizes = @(256, 48, 32, 16)
[int]$currentOffset = $dataStart

for ($i = 0; $i -lt 4; $i++) {
    [int]$s = $imgSizes[$i]
    $bw.Write([byte]$(if ($s -eq 256) { 0 } else { $s }))
    $bw.Write([byte]$(if ($s -eq 256) { 0 } else { $s }))
    $bw.Write([byte]0)
    $bw.Write([byte]0)
    $bw.Write([UInt16]1)
    $bw.Write([UInt16]32)
    $bw.Write([UInt32]$pngBytes[$i].Length)
    $bw.Write([UInt32]$currentOffset)
    $currentOffset += $pngBytes[$i].Length
}

foreach ($png in $pngBytes) { $bw.Write($png) }

$bw.Flush()
[System.IO.File]::WriteAllBytes($OutputPath, $ms.ToArray())

$bw.Dispose()
$ms.Dispose()
foreach ($bm in $allBitmaps) { $bm.Dispose() }

Write-Host "Icon created at: $OutputPath"
