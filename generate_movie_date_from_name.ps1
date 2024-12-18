# パスを入力
$patharg = $args[0]
$dir = "$patharg/img"

$names = @()

$names += $(Get-ChildItem -Path $dir -Filter *.jpg | Select-Object -ExpandProperty FullName)
$numOfIm = $names.Count

# 引数が渡されたかどうかを確認します。
if ($args -contains "-flip") {
    $flipImage = $true
} else {
    $flipImage = $false
}

#一時フォルダtmpを作成、すでにある場合は$doneListに追加
$tempFolderPath = "$PWD/tmp"
# Remove-Item -Path $tempFolderPath -Recurse -Force
New-Item -Path $tempFolderPath -ItemType Directory
$doneList = (Get-ChildItem -Path $tempFolderPath -Filter *.jpg).Name

# 連番画像に対して撮影時刻をオーバーレイ
$status = " 画像に撮影日時を書き込んでいます..."


for ($i = 0; $i -lt $numOfIm; $i++) {
    $prog = ($i/$numOfIm)*100
    Write-Progress -Activity $status -PercentComplete $prog

    $imagepath = $names[$i]
    $outputpath = "$tempFolderPath/$i.jpg"
    
    if ("$i.jpg" -in $doneList) {
        Write-Output "Skipping: $imagepath"
        continue
    }
    # 画像を読み込む
    $image = [System.Drawing.Image]::FromFile($imagePath)

    if ($flipImage) {
        $image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone)
    }

    
    # グラフィックスオブジェクトを作成
    $graphics = [System.Drawing.Graphics]::FromImage($image)
    
    # テキストを描画
    # 画像の高さに応じてフォントサイズを設定
    $fontHeight = 64
    $font = New-Object System.Drawing.Font("Arial", $fontHeight)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($imagepath) -replace "-", "/" -replace "_", ":"

    # 3つ目の "/" を " " に置き換える
    $splitFileName = $fileNameWithoutExtension -split "/"
    if ($splitFileName.Length -ge 4) {
        $date = $splitFileName[0..2] -join "/" # yyyy mm dd
        $fileNameWithoutExtension = ($date, $splitFileName[3]) -join " "
    }
    Write-Host $fileNameWithoutExtension

    $point = New-Object System.Drawing.PointF(10, 10)  # PointF を使用して Point を作成
    $graphics.DrawString($fileNameWithoutExtension, $font, $brush, $point)

    # 画像を保存
    $image.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    
    # リソースを解放
    $font.Dispose()
    $brush.Dispose()
    $graphics.Dispose()
    $image.Dispose()
}

# 画像を動画に変換
ffmpeg -i $PWD/tmp/%d.jpg -c:v libx264 -pix_fmt yuv420p -r 60 $patharg/datedmovie.mp4
ffmpeg -i $patharg/datedmovie.mp4 -crf 37 $patharg/compressed.mp4
