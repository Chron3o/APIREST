#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/variables.env"

gcloud config set project "${PROJECT_ID}"

TOPIC_NAME="nvd-sync-topic"
SUB_NAME="nvd-sync-sub"

if ! gcloud pubsub topics describe "${TOPIC_NAME}" >/dev/null 2>&1; then
  gcloud pubsub topics create "${TOPIC_NAME}"
fi

if ! gcloud pubsub subscriptions describe "${SUB_NAME}" >/dev/null 2>&1; then
  gcloud pubsub subscriptions create "${SUB_NAME}" --topic="${TOPIC_NAME}"
fi

echo "Pub/Sub resources created."
