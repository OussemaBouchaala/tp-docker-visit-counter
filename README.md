# TP Docker - Containerisation & Orchestration

[![CI-CD Visit-Counter](https://github.com/OussemaBouchaala/tp-docker-visit-counter/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/OussemaBouchaala/tp-docker-visit-counter/actions/workflows/ci-cd.yml)

Docker Hub image: https://hub.docker.com/r/oussemabouchaala/counter-app

Students: Oussema Bouchaala, Mouin El Dabbabi, Mohamed Amin Saddoud, Mohamed Helmi Lakhdhar

| Folder | Content |
|---|---|
| `partA-tutorial/` | Graded Docker tutorial (Packt course): Spring Boot app, Spring Boot + MongoDB, Docker Compose |
| `partB-visit-counter/` | Visit-Counter micro-services (Flask + Redis): Dockerfile, network, volume, Compose, scaling |
| `.github/workflows/ci-cd.yml` | Part C - CI/CD pipeline: tests + image build & push to Docker Hub on every push to `main` |
| `report/` | LaTeX report (PDF) with screenshots |

## Quick start (Part B)
```bash
cd partB-visit-counter
docker build -t counter-app:1.0 .
docker compose up -d --scale web=3          # replicas on ports 8081-8083
docker compose --profile lb up -d --scale web=3   # + nginx load balancer on port 80
```
