$ErrorActionPreference='Stop'
$taskPath=Join-Path $env:TEMP 'fishcare-proposal-november-qa'
New-Item -ItemType Directory -Force -Path $taskPath | Out-Null
Copy-Item -LiteralPath 'output/laporan/Proposal-FishCare-Kelompok-7-Revisi-November-2026.docx' -Destination (Join-Path $taskPath 'proposal.docx') -Force
$w=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
Write-Output 'Opening local temporary copy'
$d=$w.Documents.Open((Join-Path $taskPath 'proposal.docx'),$false,$true)
Write-Output 'Exporting local temporary copy'
$d.ExportAsFixedFormat((Join-Path $taskPath 'proposal.pdf'),17,$false,0,0,1,1,0,$false,$false,0,$false,$true,$false)
Write-Output 'Export finished'
$d.Close(0)
Copy-Item -LiteralPath (Join-Path $taskPath 'proposal.pdf') -Destination 'tmp/proposal-november/proposal.pdf' -Force
