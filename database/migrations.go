package database

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

func RunMigrations(pool *pgxpool.Pool) error {
	const migrationSQL = `
CREATE TABLE IF NOT EXISTS vulnerabilities (
    cve_id TEXT PRIMARY KEY,
    severity TEXT NOT NULL,
    published_at TIMESTAMPTZ NULL,
    last_modified_at TIMESTAMPTZ NULL,
    source_identifier TEXT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS asset_remediations (
    id BIGSERIAL PRIMARY KEY,
    asset_id TEXT NOT NULL,
    cve_id TEXT NOT NULL REFERENCES vulnerabilities(cve_id) ON DELETE CASCADE,
    remediated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (asset_id, cve_id)
);

CREATE INDEX IF NOT EXISTS idx_vulnerabilities_severity ON vulnerabilities(severity);
CREATE INDEX IF NOT EXISTS idx_asset_remediations_cve_id ON asset_remediations(cve_id);
CREATE INDEX IF NOT EXISTS idx_asset_remediations_asset_id ON asset_remediations(asset_id);
`

	_, err := pool.Exec(context.Background(), migrationSQL)
	return err
}
