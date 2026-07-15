# table.ps1 - Читает таблицу из файла и рисует
# table.ps1 path_to_data_file
param([string]$Path)

if (!(Test-Path $Path)) { exit }
$lines = Get-Content $Path -Encoding UTF8
if ($lines.Count -eq 0) { exit }

$table = @()
foreach ($line in $lines) {
    $table += ,($line -split '\|')
}

$colCount = ($table | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
$maxWidths = @()
for ($c = 0; $c -lt $colCount; $c++) {
    $max = 0
    foreach ($row in $table) {
        if ($c -lt $row.Count -and $row[$c].Length -gt $max) { $max = $row[$c].Length }
    }
    $maxWidths += $max
}

function Draw-Border {
    $line = "    +"
    for ($c = 0; $c -lt $colCount; $c++) {
        $line += ("-" * ($maxWidths[$c] + 2)) + "+"
    }
    return $line
}

Write-Host (Draw-Border)

for ($r = 0; $r -lt $table.Count; $r++) {
    $line = "    |"
    for ($c = 0; $c -lt $colCount; $c++) {
        $val = if ($c -lt $table[$r].Count) { $table[$r][$c] } else { "" }
        $pad = $maxWidths[$c] - $val.Length
        $line += " " + $val + (" " * $pad) + " |"
    }
    Write-Host $line
    if ($r -eq 0) { Write-Host (Draw-Border) }
}

Write-Host (Draw-Border)
