#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/variables.env"

gcloud config set project "${PROJECT_ID}"

SERVICE_URL="$(gcloud run services describe "${SERVICE_NAME}" --region="${REGION}" --format='value(status.url)')"
SCHEDULER_SA_EMAIL="${SCHEDULER_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe "${SCHEDULER_SA_EMAIL}" >/dev/null 2>&1; then
  gcloud iam service-accounts create "${SCHEDULER_SA}" \
    --display-name="Scheduler invoker for ${SERVICE_NAME}"
fi

gcloud run services add-iam-policy-binding "${SERVICE_NAME}" \
  --region="${REGION}" \
  --member="serviceAccount:${SCHEDULER_SA_EMAIL}" \
  --role="roles/run.invoker" >/dev/null

if gcloud scheduler jobs describe "${SCHEDULER_JOB}" --location="${REGION}" >/dev/null 2>&1; then
  gcloud scheduler jobs update http "${SCHEDULER_JOB}" \
    --location="${REGION}" \
    --schedule="${SCHEDULER_CRON}" \
    --time-zone="${SCHEDULER_TIMEZONE}" \
    --uri="${SERVICE_URL}/vulnerabilities/sync" \
    --http-method=POST \
    --oidc-service-account-email="${SCHEDULER_SA_EMAIL}" \
    --oidc-token-audience="${SERVICE_URL}"
else
  gcloud scheduler jobs create http "${SCHEDULER_JOB}" \
    --location="${REGION}" \
    --schedule="${SCHEDULER_CRON}" \
    --time-zone="${SCHEDULER_TIMEZONE}" \
    --uri="${SERVICE_URL}/vulnerabilities/sync" \
    --http-method=POST \
    --oidc-service-account-email="${SCHEDULER_SA_EMAIL}" \
    --oidc-token-audience="${SERVICE_URL}"
fi

echo "Scheduler configured."
