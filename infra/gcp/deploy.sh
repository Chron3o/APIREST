#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/variables.env"

gcloud config set project "${PROJECT_ID}"

IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${IMAGE_NAME}:latest"
CONNECTION_NAME="$(gcloud sql instances describe "${SQL_INSTANCE}" --format='value(connectionName)')"
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud builds submit --tag "${IMAGE_URI}" .

gcloud secrets add-iam-policy-binding database-url \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/secretmanager.secretAccessor" >/dev/null

gcloud secrets add-iam-policy-binding nvd-api-key \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/secretmanager.secretAccessor" >/dev/null

gcloud run deploy "${SERVICE_NAME}" \
  --image="${IMAGE_URI}" \
  --region="${REGION}" \
  --platform=managed \
  --ingress=internal-and-cloud-load-balancing \
  --no-allow-unauthenticated \
  --add-cloudsql-instances "${CONNECTION_NAME}" \
  --set-secrets DATABASE_URL=database-url:latest,NVD_API_KEY=nvd-api-key:latest \
  --set-env-vars PORT=8080,HTTP_TIMEOUT_SECONDS="${HTTP_TIMEOUT_SECONDS}",NVD_RESULTS_PER_PAGE="${NVD_RESULTS_PER_PAGE}",NVD_MAX_PAGES="${NVD_MAX_PAGES}"

echo "Deploy complete."
