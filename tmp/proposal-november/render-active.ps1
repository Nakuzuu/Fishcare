$ErrorActionPreference='Stop'
$w=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
Write-Output 'Connected to Word'
$source=(Resolve-Path 'output/laporan/Proposal-FishCare-Kelompok-7-Revisi-November-2026.docx').Path
$d=$w.Documents.Open($source,$false,$true)
Write-Output 'Document opened'
try {$d.ExportAsFixedFormat((Join-Path (Get-Location) 'tmp/proposal-november/proposal.pdf'),17); Write-Output 'PDF exported'} finally {$d.Close(0)}
