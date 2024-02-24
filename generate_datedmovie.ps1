# パスを入力
$dir = "$args/img"

# 空の配列を宣言
$timestamps = @()
$names = $(Get-ChildItem -Path $dir -Filter *.jpg | Select-Object -ExpandProperty FullName)
$length = $names.Count
$status = "画像の撮影日時を取得中..."

# 撮影時刻を取得して配列に追加
for ($i = 0; $i -lt $names.Count; $i++) {
    $prog = ($i/$length)*100
    Write-Progress -Activity $status -PercentComplete $prog
    $timestamp = exiftool -DateTimeOriginal $names[$i] -s -s -s -stay_open 1
    $timestamps += $timestamp
}
# 一時フォルダのパスを指定
$tempFolderPath = "$PWD/tmp"

# 一時フォルダが存在しない場合は作成する
if (-not (Test-Path $tempFolderPath)) {
    New-Item -Path $tempFolderPath -ItemType Directory
}

# 連番画像に対して撮影時刻をオーバーレイ
$status = " 画像に撮影日時を書き込んでいます..."
for ($i = 0; $i -lt $names.Count; $i++) {
    $prog = ($i/$length)*100
    Write-Progress -Activity $status -PercentComplete $prog

    $timestamp = $timestamps[$i - 1]
    $imagepath = $names[$i - 1]
    $outputpath = "$PWD/tmp/$i.jpg"
    
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
Remove-Item -Path $PWD/tmp -Recurse -Force