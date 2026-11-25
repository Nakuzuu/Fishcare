$ErrorActionPreference='Stop'
$word=New-Object -ComObject Word.Application
$word.Visible=$false
$word.DisplayAlerts=0
try {
$source=(Resolve-Path 'output/laporan/Proposal-FishCare-Kelompok-7-Revisi-November-2026.docx').Path
$doc=$word.Documents.Open($source,$false,$true)
$pdf=Join-Path (Get-Location) 'tmp/proposal-november/proposal.pdf'
$doc.ExportAsFixedFormat($pdf,17)
$doc.Close(0)
Write-Output $pdf
} finally {$word.Quit()}
