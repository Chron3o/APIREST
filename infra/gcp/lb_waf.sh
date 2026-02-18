#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${ROOT_DIR}/variables.env"

gcloud config set project "${PROJECT_ID}"

if [[ "${DOMAIN_NAME}" == "api.example.com" ]]; then
  echo "Set DOMAIN_NAME in infra/gcp/variables.env before running LB setup."
  exit 1
fi

if ! gcloud compute network-endpoint-groups describe "${NEG_NAME}" --region="${REGION}" >/dev/null 2>&1; then
  gcloud compute network-endpoint-groups create "${NEG_NAME}" \
    --region="${REGION}" \
    --network-endpoint-type=serverless \
    --cloud-run-service="${SERVICE_NAME}" \
    --cloud-run-region="${REGION}"
fi

if ! gcloud compute backend-services describe "${BACKEND_NAME}" --global >/dev/null 2>&1; then
  gcloud compute backend-services create "${BACKEND_NAME}" \
    --global \
    --load-balancing-scheme=EXTERNAL_MANAGED
fi

if ! gcloud compute backend-services describe "${BACKEND_NAME}" --global --format="value(backends.group)" | grep -q "${NEG_NAME}"; then
  gcloud compute backend-services add-backend "${BACKEND_NAME}" \
    --global \
    --network-endpoint-group="${NEG_NAME}" \
    --network-endpoint-group-region="${REGION}"
fi

if ! gcloud compute security-policies describe "${ARMOR_POLICY}" >/dev/null 2>&1; then
  gcloud compute security-policies create "${ARMOR_POLICY}" \
    --description="WAF policy for ${SERVICE_NAME}"

  gcloud compute security-policies rules create 1000 \
    --security-policy="${ARMOR_POLICY}" \
    --expression="evaluatePreconfiguredWaf('sqli-v33-stable') || evaluatePreconfiguredWaf('xss-v33-stable')" \
    --action=deny-403 \
    --description="Block common SQLi/XSS payloads"
fi

gcloud compute backend-services update "${BACKEND_NAME}" \
  --global \
  --security-policy="${ARMOR_POLICY}" >/dev/null

if ! gcloud compute url-maps describe "${URL_MAP_NAME}" >/dev/null 2>&1; then
  gcloud compute url-maps create "${URL_MAP_NAME}" \
    --default-service="${BACKEND_NAME}"
fi

if ! gcloud compute ssl-certificates describe "${SSL_CERT_NAME}" >/dev/null 2>&1; then
  gcloud compute ssl-certificates create "${SSL_CERT_NAME}" \
    --domains="${DOMAIN_NAME}"
fi

if ! gcloud compute target-https-proxies describe "${HTTPS_PROXY_NAME}" >/dev/null 2>&1; then
  gcloud compute target-https-proxies create "${HTTPS_PROXY_NAME}" \
    --ssl-certificates="${SSL_CERT_NAME}" \
    --url-map="${URL_MAP_NAME}"
fi

if ! gcloud compute forwarding-rules describe "${FORWARDING_RULE_NAME}" --global >/dev/null 2>&1; then
  gcloud compute forwarding-rules create "${FORWARDING_RULE_NAME}" \
    --global \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --network-tier=PREMIUM \
    --target-https-proxy="${HTTPS_PROXY_NAME}" \
    --ports=443
fi

LB_IP="$(gcloud compute forwarding-rules describe "${FORWARDING_RULE_NAME}" --global --format='value(IPAddress)')"
echo "Load Balancer ready. Point DNS A record for ${DOMAIN_NAME} to ${LB_IP}."
