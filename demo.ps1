# =====================================================================
#  TP Docker - live demo script (run from this folder in PowerShell)
#  Usage:   powershell -ExecutionPolicy Bypass -File .\demo.ps1
#  Press ENTER between steps. Stop everything with .\demo-stop.ps1
# =====================================================================
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = $PSScriptRoot
function Step($t) { Write-Host "`n==================== $t ====================" -ForegroundColor Yellow }
function Pause()  { Read-Host "`n[ENTER] next step" | Out-Null }
function Hit($p)  { for ($i=0; $i -lt 30; $i++) { $r = curl.exe -s "http://localhost:$p" | Select-String "Bonjour"; if ($r) { return $r.Line.Trim() }; Start-Sleep 1 }; "(no answer on port $p yet)" }

Step "0. Environment"
docker version --format "Client {{.Client.Version}} / Server {{.Server.Version}}"
Pause

# ---------------- PART B ----------------
Set-Location "$root\partB-visit-counter"
Step "B1. Build the image (Alpine, non-root, cache-friendly)"
docker build --progress=plain -t counter-app:1.0 . 2>&1 | Select-String "CACHED|DONE|naming"
docker images counter-app
Pause

Step "B2. Manual deployment: network + volume + 2 containers"
docker network create app-network | Out-Null
docker volume create redis-data | Out-Null
docker run -d --name db-service --network app-network -v redis-data:/data redis:7-alpine redis-server --appendonly yes | Out-Null
docker run -d --name web-app --network app-network -p 80:5000 counter-app:1.0 | Out-Null
Start-Sleep 4
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
docker network inspect app-network --format "{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{println}}{{end}}"
1..3 | % { Hit 80 }
Write-Host "Open http://localhost in the browser" -ForegroundColor Cyan
Pause

Step "B3. Robustness: delete Redis, relaunch on the same volume"
docker rm -f db-service | Out-Null
docker run -d --name db-service --network app-network -v redis-data:/data redis:7-alpine redis-server --appendonly yes | Out-Null
Start-Sleep 3
Hit 80
Pause

Step "B4. Docker Compose: 3 replicas + nginx load balancer"
docker rm -f web-app db-service | Out-Null
docker network rm app-network | Out-Null
docker compose --ansi never --profile lb up -d --scale web=3
Start-Sleep 5
docker compose --profile lb ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
Write-Host "--- each replica on its own port (8081-8083)" -ForegroundColor Cyan
8081..8083 | % { (Hit $_) + "   <- :$_" }
Write-Host "--- single entry point :80 (round robin)" -ForegroundColor Cyan
1..6 | % { Hit 80 }
Pause

# ---------------- PART A ----------------
Set-Location "$root\partA-tutorial\item-service-mongodb"
Step "A. Spring Boot item-service + MongoDB (Compose)"
docker compose --ansi never up -d --build
Write-Host "waiting for Spring Boot to start..." -ForegroundColor Cyan
$u = "http://localhost:8090/api/v1/items"
for ($i=0; $i -lt 120; $i++) { if (curl.exe -s $u) { break }; Start-Sleep 2 }
Invoke-WebRequest -UseBasicParsing -Method Post -Uri $u -ContentType "application/json" -Body '{"name":"Laptop","description":"Dell XPS","price":1500.0,"categoryId":"c1"}' | % { "$($_.StatusCode) " + $_.Headers.Location }
curl.exe -s $u; ""
docker exec mongodb-container-one mongosh item-service-db --quiet --eval "db.Item.countDocuments()"
Pause

Step "C. Pipeline: https://github.com/OussemaBouchaala/tp-docker-visit-counter/actions"
Write-Host "Docker Hub : https://hub.docker.com/r/oussemabouchaala/counter-app"
Set-Location $root
