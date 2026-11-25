$ErrorActionPreference='Stop'
$taskPath=Join-Path $env:TEMP 'fishcare-proposal-november-qa'
$d=[Runtime.InteropServices.Marshal]::BindToMoniker((Join-Path $taskPath 'proposal.docx'))
Write-Output ('Bound: '+$d.Name)
$d.ExportAsFixedFormat((Join-Path $taskPath 'proposal.pdf'),17,$false,0,0,1,1,0,$false,$false,0,$false,$true,$false)
Write-Output 'Export finished'
Copy-Item -LiteralPath (Join-Path $taskPath 'proposal.pdf') -Destination 'tmp/proposal-november/proposal.pdf' -Force
