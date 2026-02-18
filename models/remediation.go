package models

import "time"

type SeveritySummary struct {
	Critical int `json:"critical"`
	High     int `json:"high"`
	Medium   int `json:"medium"`
	Low      int `json:"low"`
	Info     int `json:"info"`
}

type Vulnerability struct {
	CVEID            string
	Severity         string
	PublishedAt      *time.Time
	LastModifiedAt   *time.Time
	SourceIdentifier string
}

type RemediationRequest struct {
	CVEs []string `json:"cves" binding:"required,min=1"`
}
