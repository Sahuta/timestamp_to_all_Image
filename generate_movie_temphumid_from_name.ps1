# パスを入力
$patharg = $args[0]
$dir = "$patharg/img"

$names = @()

$names += $(Get-ChildItem -Path $dir -Filter *.png | Select-Object -ExpandProperty FullName)
$numOfIm = $names.Count

# 引数が渡されたかどうかを確認します。
if ($args -contains "-flip") {
    $flipImage = $true
} else {
    $flipImage = $false
}

#一時フォルダtmpを作成、すでにある場合は削除してから作成
$tempFolderPath = "$PWD/tmp"

Remove-Item -Path $tempFolderPath -Recurse -Force
New-Item -Path $tempFolderPath -ItemType Directory

# 連番画像に対して撮影時刻をオーバーレイ
$status = " 画像に撮影日時を書き込んでいます..."

$newString = "Temp 0C Humid 0%"

for ($i = 0; $i -lt $numOfIm; $i++) {
    $prog = ($i/$numOfIm)*100
    Write-Progress -Activity $status -PercentComplete $prog

    $imagepath = $names[$i]
    $outputpath = "$tempFolderPath/$i.jpg"
    
    # 画像を読み込む
    $image = [System.Drawing.Image]::FromFile($imagePath)

    if ($flipImage) {
        $image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone)
    }

    
    # グラフィックスオブジェクトを作成
    $graphics = [System.Drawing.Graphics]::FromImage($image)
    
    # テキストを描画
    # 画像の高さに応じてフォントサイズを設定
    $fontHeight = $image.Height / 20
    $font = New-Object System.Drawing.Font("Arial", $fontHeight)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($imagepath)

    $point = New-Object System.Drawing.PointF(10, 10)  # PointF を使用して Point を作成

    $parts = $fileNameWithoutExtension -split "_"

    if ($parts.Count -eq 3) {
        $temp = $parts[1]
        $humidity = $parts[2]
        # 新しい文字列を生成
        $newString = "Temp $temp`C Humid $humidity`%"
        $graphics.DrawString($newString, $font, $brush, $point)
    } elseif ($parts.Count -eq 1) {
        $graphics.DrawString($newString, $font, $brush, $point)
        Write-Host "温度と湿度の情報がありません。"
    } else {
        $graphics.DrawString($newString, $font, $brush, $point)
        Write-Host "不正な形式の文字列です。"
    }


    # 画像を保存
    $image.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    
    # リソースを解放
    $font.Dispose()
    $brush.Dispose()
    $graphics.Dispose()
    $image.Dispose()
}

# 画像を動画に変換
ffmpeg -i $PWD/tmp/%d.jpg -c:v libx264 -pix_fmt yuv444p -r 60 $patharg/datedmovie.mp4