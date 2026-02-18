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
- In GCP, secrets are managed with Secret Manager (`db-password`, `nvd-api-key`, `iap-client-secret`, `database-url`).
- Terraform reads sensitive values from Secret Manager and avoids plaintext secrets in `terraform.tfvars`.
- Local `.env` files are ignored by git.

## Requirements
- Docker Desktop (or Docker Engine + Compose)

## Configuration
Use `.env` (based on `.env.example`):

```env
POSTGRES_DB=security_api
POSTGRES_USER=postgres
POSTGRES_PASSWORD=__SET_SECURE_VALUE__
NVD_API_KEY=__SET_OPTIONAL_FOR_LOCAL_DOCKER__
HTTP_TIMEOUT_SECONDS=20
NVD_RESULTS_PER_PAGE=500
NVD_MAX_PAGES=3
```

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
1. Add a new Secret Manager version for `nvd-api-key`.
2. Re-run Terraform apply (or redeploy Cloud Run) to pick up latest secret version.

Local Docker only:
1. Update `NVD_API_KEY` in your local `.env`.
2. Recreate API container:
```bash
docker compose up -d --force-recreate api
```

## Notes for the Challenge
- No DB preloading at startup: only schema migration runs on boot.
- Data sync is explicit (`/vulnerabilities/sync`) or lazy on first summary call.

## GCP Terraform Deployment
Terraform infrastructure for this architecture is available at `infra/terraform`:

- IAP (SSO + MFA) in front of HTTPS Load Balancer
- Cloud Run (Dockerized Gin API)
- Cloud SQL (PostgreSQL)
- Secret Manager
- Pub/Sub + Cloud Scheduler
- Cloud Armor (WAF)

Quick start:
1. `cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars`
2. Create required Secret Manager secrets (`db-password`, `nvd-api-key`, `iap-client-secret`)
3. Edit non-secret values in `infra/terraform/terraform.tfvars`
4. `cd infra/terraform`
5. `terraform init && terraform apply`
