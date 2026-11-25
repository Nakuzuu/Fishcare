$ErrorActionPreference='Stop'
$path=(Resolve-Path 'output/laporan/Proposal-FishCare-Kelompok-7-2026.docx').Path
$w=[Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application')
$d=$w.Documents.Open($path,$false,$true)
Write-Output ('Opened '+$d.Name)
