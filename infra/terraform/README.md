# Terraform Deployment for GCP Security API

This Terraform stack provisions:

- Cloud Run (private ingress for LB/IAP)
- Cloud SQL PostgreSQL
- Secret Manager (`database-url`, `nvd-api-key`)
- Pub/Sub (`cve-sync-topic` + subscription + DLQ)
- Cloud Scheduler (publishes CVE sync messages)
- HTTPS Load Balancer + Cloud Armor WAF
- IAP access control for operators (SSO + MFA)

## Prerequisites

- Terraform >= 1.6
- `gcloud auth application-default login`
- A GCP project with billing enabled
- A domain mapped to the load balancer public IP
- IAP OAuth Client ID/Secret created in Google Cloud Console

## Usage

1. Copy and edit vars:

```bash
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

2. Create required secrets in Secret Manager (one-time):

```bash
gcloud config set project <PROJECT_ID>
printf "<STRONG_DB_PASSWORD>" | gcloud secrets create db-password --data-file=- || printf "<STRONG_DB_PASSWORD>" | gcloud secrets versions add db-password --data-file=-
printf "<NVD_API_KEY>" | gcloud secrets create nvd-api-key --data-file=- || printf "<NVD_API_KEY>" | gcloud secrets versions add nvd-api-key --data-file=-
printf "<IAP_CLIENT_SECRET>" | gcloud secrets create iap-client-secret --data-file=- || printf "<IAP_CLIENT_SECRET>" | gcloud secrets versions add iap-client-secret --data-file=-
```

3. Set non-secret values in `terraform.tfvars`:
- `project_id`
- `container_image`
- `domain_name`
- `operator_group_email`
- `iap_client_id`
- optional secret IDs if you use different names

2. Initialize and plan:

```bash
cd infra/terraform
terraform init
terraform plan
```

4. Apply:

```bash
terraform apply
```

## Notes

- Cloud Run is deployed with `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`, so direct public calls to the run URL are blocked by design.
- Operator access is controlled through IAP group binding:
  - `roles/iap.httpsResourceAccessor` on backend service
- Scheduler publishes messages to Pub/Sub every `scheduler_cron`.
- You can consume Pub/Sub from a worker service/job to run async CVE ingestion.
- Secrets are sourced from Secret Manager (not plain tfvars) for DB password, NVD API key, and IAP client secret.

## Post-Apply

1. Get LB IP from output `lb_ip_address`.
2. Point your DNS A record (`domain_name`) to this IP.
3. Wait for managed SSL cert to become active.
4. Test login flow through IAP with your operator account.
