$ErrorActionPreference='Stop'
$taskPath=Join-Path $env:TEMP 'fishcare-proposal-november-qa'
New-Item -ItemType Directory -Force -Path $taskPath | Out-Null
Copy-Item -LiteralPath 'output/laporan/Proposal-FishCare-Kelompok-7-Revisi-November-2026.docx' -Destination (Join-Path $taskPath 'final.docx') -Force
$w=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
Write-Output ('Connected; documents '+$w.Documents.Count)
$d=$w.Documents.Open((Join-Path $taskPath 'final.docx'),$false,$true)
Write-Output ('Opened '+$d.Name)
$d.ExportAsFixedFormat((Join-Path $taskPath 'final.pdf'),17)
Write-Output 'PDF exported'
$d.Close(0)
Copy-Item -LiteralPath (Join-Path $taskPath 'final.pdf') -Destination 'tmp/proposal-november/proposal.pdf' -Force
