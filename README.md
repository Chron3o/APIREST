# Security API REST

Simple REST API in Go (Gin) for vulnerability summaries based on NIST NVD data, plus remediation tracking for IT assets.

## What It Does
- Fetches vulnerabilities from NVD (CVE 2.0 API).
- Stores normalized vulnerability data in PostgreSQL.
- Provides severity summaries.
- Tracks remediated CVEs per asset.
- Calculates uncorrected summary (vulnerabilities not remediated in any asset).

## Tech Stack
- Go 1.24
- Gin
- PostgreSQL 16
- Docker + Docker Compose

## Project Structure
- `main.go`: app bootstrap and route wiring
- `config/`: environment and secret-based config loading
- `database/`: PostgreSQL connection and migrations
- `handlers/`: HTTP handlers
- `services/`: NVD client and business logic
- `repositories/`: DB access layer
- `models/`: domain/request/response models

## Security Notes
- NVD key is loaded from Docker secret file via `NVD_API_KEY_FILE`.
- Fallback env var `NVD_API_KEY` is still supported.
- Local secrets are ignored by git (`secrets/`, `.env`).

## Requirements
- Docker Desktop (or Docker Engine + Compose)

## Configuration
Use `.env` (based on `.env.example`):

```env
POSTGRES_DB=security_api
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
NVD_API_KEY_SECRET_FILE=./secrets/nvd_api_key.txt
HTTP_TIMEOUT_SECONDS=20
NVD_RESULTS_PER_PAGE=500
NVD_MAX_PAGES=3
```

Create secret file (not committed):

```txt
secrets/nvd_api_key.txt
```

Put only your NVD API key in that file.

## Run
```bash
docker compose up -d
```

Check services:
```bash
docker compose ps
```

Stop:
```bash
docker compose down
```

## API Endpoints
1. `GET /vulnerabilities/summary`
- Returns severity summary from DB.
- If DB is empty, service performs initial sync from NVD.

2. `POST /assets/:asset_id/vulnerabilities`
- Registers remediated CVEs for an asset.
- Body:
```json
{
  "cves": ["CVE-2023-1234", "CVE-2022-9999"]
}
```

3. `GET /vulnerabilities/summary/uncorrected`
- Returns severity summary excluding CVEs already remediated.

Additional endpoint:
- `POST /vulnerabilities/sync` (manual sync trigger from NVD)

## Quick Test
```bash
curl http://localhost:8080/vulnerabilities/summary
curl http://localhost:8080/vulnerabilities/summary/uncorrected
curl -X POST http://localhost:8080/assets/server-01/vulnerabilities \
  -H "Content-Type: application/json" \
  -d '{"cves":["CVE-2023-1234"]}'
```

## Rotation of NVD Key
1. Update `secrets/nvd_api_key.txt`.
2. Recreate API container:
```bash
docker compose up -d --force-recreate api
```

## Notes for the Challenge
- No DB preloading at startup: only schema migration runs on boot.
- Data sync is explicit (`/vulnerabilities/sync`) or lazy on first summary call.

## GCP Deployment
Production deployment assets are in `infra/gcp/`.

Architecture target:
- Cloud Load Balancer (HTTPS) + Cloud Armor (WAF)
- Cloud Run (API)
- Cloud SQL (PostgreSQL)
- Secret Manager
- Cloud Scheduler (sync trigger)
- Optional Pub/Sub for async workflows

Start with:
1. `cp infra/gcp/variables.env.example infra/gcp/variables.env`
2. Edit `infra/gcp/variables.env`
3. `bash infra/gcp/bootstrap.sh`
4. `bash infra/gcp/deploy.sh`
5. `bash infra/gcp/scheduler.sh`
6. Optional: `bash infra/gcp/lb_waf.sh`
