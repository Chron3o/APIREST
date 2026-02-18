package repositories

import (
	"context"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

type RemediationRepository struct {
	pool *pgxpool.Pool
}

func NewRemediationRepository(pool *pgxpool.Pool) *RemediationRepository {
	return &RemediationRepository{pool: pool}
}

func (r *RemediationRepository) UpsertByAsset(ctx context.Context, assetID string, cves []string) ([]string, error) {
	if len(cves) == 0 {
		return []string{}, nil
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	const query = `
INSERT INTO asset_remediations (asset_id, cve_id, remediated_at)
VALUES ($1, $2, NOW())
ON CONFLICT (asset_id, cve_id) DO NOTHING
`

	inserted := make([]string, 0, len(cves))
	for _, cve := range cves {
		clean := strings.ToUpper(strings.TrimSpace(cve))
		if clean == "" {
			continue
		}

		_, err = tx.Exec(ctx, query, assetID, clean)
		if err != nil {
			return nil, err
		}
		inserted = append(inserted, clean)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return inserted, nil
}
