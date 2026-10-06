# Stops and removes everything started by demo.ps1 (project scope only)
Set-Location "$PSScriptRoot\partB-visit-counter"
docker rm -f web-app db-service 2>$null | Out-Null
docker compose --profile lb down --volumes --remove-orphans
Set-Location "$PSScriptRoot\partA-tutorial\item-service-mongodb"
docker compose down --volumes
Set-Location $PSScriptRoot
