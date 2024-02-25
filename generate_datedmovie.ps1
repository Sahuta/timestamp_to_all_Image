# パスを入力
$dir = "$args/img"

$names = @()

$names += $(Get-ChildItem -Path $dir -Filter *.jpg | Select-Object -ExpandProperty FullName)
$numOfIm = $names.Count

$timestamps = $(exiftool -DateTimeOriginal -ext jpg  -s -s -s $dir  | Where-Object {$_ -notmatch "^[\d\s]+image files read$"} | ForEach-Object { ($_ -split '========')[0]})
# 改行でデータを分割し、空行を除去
$timestamps = $timestamps -split "`n" | Where-Object { $_ -ne '' }

# リストに変換
$timestamps = $timestamps | ForEach-Object {
    # 各行を追加
    $_
}


Write-Host "画像の数: $numOfIm"
Write-Host $timestamps[0]
Write-Host $timestamps[1]

#一時フォルダのパスを指定
$tempFolderPath = "$PWD/tmp"

Remove-Item -Path $tempFolderPath -Recurse -Force
New-Item -Path $tempFolderPath -ItemType Directory

# 連番画像に対して撮影時刻をオーバーレイ
$status = " 画像に撮影日時を書き込んでいます..."
for ($i = 0; $i -lt $numOfIm; $i++) {
    $prog = ($i/$numOfIm)*100
    Write-Progress -Activity $status -PercentComplete $prog

    $timestamp = $timestamps[$i]
    $imagepath = $names[$i]
    $outputpath = "$tempFolderPath/$i.jpg"
    
    # 画像を読み込む
    $image = [System.Drawing.Image]::FromFile($imagePath)
    
    # グラフィックスオブジェクトを作成
    $graphics = [System.Drawing.Graphics]::FromImage($image)
    
    # テキストを描画
    # 画像の高さに応じてフォントサイズを設定
    $fontHeight = $image.Height / 20
    $font = New-Object System.Drawing.Font("Arial", $fontHeight)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $point = New-Object System.Drawing.PointF(10, 10)  # PointF を使用して Point を作成
    $graphics.DrawString($timestamp, $font, $brush, $point)
    
    # 画像を保存
    $image.Save($outputPath)
    
    # リソースを解放
    $font.Dispose()
    $brush.Dispose()
    $graphics.Dispose()
    $image.Dispose()
}

ffmpeg -i $PWD/tmp/%d.jpg -c:v libx264 -pix_fmt yuv420p -r 60 $args/datedmovie.mp4