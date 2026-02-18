# GCP Deployment (Cloud Run + Cloud SQL + Secrets + Scheduler + Optional LB/WAF)

This folder contains scripts to deploy the API on Google Cloud with the architecture:

- Cloud Run (Gin REST API)
- Cloud SQL (PostgreSQL)
- Secret Manager
- Cloud Scheduler (periodic `/vulnerabilities/sync`)
- Optional Pub/Sub resources
- Optional HTTPS Load Balancer + Cloud Armor (WAF)

## 1) Prerequisites

- `gcloud` CLI installed and authenticated
- A GCP project with billing enabled
- Permission to manage IAM, Run, SQL, Secrets, Scheduler, and Compute resources

## 2) Configure Variables

Copy and edit:

```bash
cp infra/gcp/variables.env.example infra/gcp/variables.env
```

Set values in `infra/gcp/variables.env`:

- `PROJECT_ID`
- `REGION`
- `SQL_INSTANCE`
- `SQL_DB`
- `SQL_USER`
- `SQL_PASSWORD`
- `AR_REPO`
- `SERVICE_NAME`
- `NVD_API_KEY`
- Optional domain/LB vars

## 3) Bootstrap Infrastructure

```bash
bash infra/gcp/bootstrap.sh
```

This script enables APIs and creates:

- Artifact Registry repo
- Cloud SQL instance/database/user
- Secret Manager secrets:
  - `database-url`
  - `nvd-api-key`

## 4) Deploy Cloud Run

```bash
bash infra/gcp/deploy.sh
```

This script:

- Builds and pushes container image with Cloud Build
- Deploys Cloud Run with Cloud SQL attachment
- Injects secrets into env vars
- Sets ingress to `internal-and-cloud-load-balancing` (recommended when using LB/WAF)

## 5) Configure Scheduler Sync

```bash
bash infra/gcp/scheduler.sh
```

Creates a scheduler job that calls:

- `POST /vulnerabilities/sync`

using OIDC auth via a dedicated service account.

## 6) Optional Pub/Sub

```bash
bash infra/gcp/pubsub.sh
```

Creates topic/subscription for future async ingestion workflows.

## 7) Optional HTTPS Load Balancer + WAF

```bash
bash infra/gcp/lb_waf.sh
```

Creates:

- Serverless NEG to Cloud Run
- Backend service
- URL map
- HTTPS proxy + forwarding rule
- Cloud Armor policy attached to backend

Notes:

- This script is for baseline setup and may require domain/certificate adjustments.
- For production, configure managed certificate + DNS for your domain.

## 8) GitHub Auto Deploy (Cloud Build Trigger)

This repo now includes `cloudbuild.yaml` at project root.

Create a trigger for branch `main`:

```bash
gcloud beta builds triggers create github \
  --name="apirest-main-deploy" \
  --repo-name="APIREST" \
  --repo-owner="Chron3o" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.yaml" \
  --substitutions=_REGION=us-central1,_SERVICE_NAME=security-api,_AR_REPO=apirest,_IMAGE_NAME=apirest,_SQL_INSTANCE=apirest-pg,_HTTP_TIMEOUT_SECONDS=20,_NVD_RESULTS_PER_PAGE=500,_NVD_MAX_PAGES=3
```

Required IAM for Cloud Build service account:

- `roles/run.admin`
- `roles/artifactregistry.writer`
- `roles/iam.serviceAccountUser`
- `roles/cloudsql.client`
- `roles/secretmanager.admin` (or narrower secret IAM management)

Then each push to `main` will:

- Build image
- Push to Artifact Registry
- Deploy Cloud Run

## Rotation

- Rotate NVD key:
  - update secret version in Secret Manager (`nvd-api-key`)
  - redeploy Cloud Run (`bash infra/gcp/deploy.sh`)
