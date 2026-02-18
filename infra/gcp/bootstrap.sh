#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/variables.env"

gcloud config set project "${PROJECT_ID}"

gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudscheduler.googleapis.com \
  pubsub.googleapis.com \
  compute.googleapis.com

if ! gcloud artifacts repositories describe "${AR_REPO}" --location="${REGION}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${AR_REPO}" \
    --repository-format=docker \
    --location="${REGION}"
fi

if ! gcloud sql instances describe "${SQL_INSTANCE}" >/dev/null 2>&1; then
  gcloud sql instances create "${SQL_INSTANCE}" \
    --database-version=POSTGRES_16 \
    --cpu=1 \
    --memory=3840MiB \
    --region="${REGION}"
fi

if ! gcloud sql databases describe "${SQL_DB}" --instance="${SQL_INSTANCE}" >/dev/null 2>&1; then
  gcloud sql databases create "${SQL_DB}" --instance="${SQL_INSTANCE}"
fi

if ! gcloud sql users list --instance="${SQL_INSTANCE}" --format="value(name)" | grep -qx "${SQL_USER}"; then
  gcloud sql users create "${SQL_USER}" --instance="${SQL_INSTANCE}" --password="${SQL_PASSWORD}"
else
  gcloud sql users set-password "${SQL_USER}" --instance="${SQL_INSTANCE}" --password="${SQL_PASSWORD}"
fi

CONNECTION_NAME="$(gcloud sql instances describe "${SQL_INSTANCE}" --format='value(connectionName)')"
DATABASE_URL="host=/cloudsql/${CONNECTION_NAME} user=${SQL_USER} password=${SQL_PASSWORD} dbname=${SQL_DB} sslmode=disable"

if ! gcloud secrets describe database-url >/dev/null 2>&1; then
  printf '%s' "${DATABASE_URL}" | gcloud secrets create database-url --data-file=-
else
  printf '%s' "${DATABASE_URL}" | gcloud secrets versions add database-url --data-file=-
fi

if ! gcloud secrets describe nvd-api-key >/dev/null 2>&1; then
  printf '%s' "${NVD_API_KEY}" | gcloud secrets create nvd-api-key --data-file=-
else
  printf '%s' "${NVD_API_KEY}" | gcloud secrets versions add nvd-api-key --data-file=-
fi

echo "Bootstrap complete."
