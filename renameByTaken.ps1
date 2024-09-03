# 変更するファイルのパスを設定します。
$filePath = '2024-07-24/2024-07-30'  # ここにディレクトリのパスを入力

# 変更するファイルの拡張子を設定します。
$extension = '.jpg'

# 新しい連番の開始番号を設定します。
$newStartNumber = 1

# ファイルを取得し、新しい名前でリネームします。
Get-ChildItem -Path $filePath -Filter "*$extension" | Sort-Object CreationTime | ForEach-Object {
    $newFileName = '{0:D4}{1}' -f $newStartNumber, $extension
    Rename-Item -Path $_.FullName -NewName $newFileName
    $newStartNumber++
}