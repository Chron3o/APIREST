package services

import (
	"APIREST/models"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const nvdBaseURL = "https://services.nvd.nist.gov/rest/json/cves/2.0"

type NVDClient struct {
	httpClient *http.Client
	apiKey     string
}

func NewNVDClient(apiKey string, timeout time.Duration) *NVDClient {
	return &NVDClient{
		httpClient: &http.Client{Timeout: timeout},
		apiKey:     apiKey,
	}
}

func (c *NVDClient) FetchPage(ctx context.Context, startIndex int, resultsPerPage int) ([]models.Vulnerability, error) {
	u, err := url.Parse(nvdBaseURL)
	if err != nil {
		return nil, err
	}

	query := u.Query()
	query.Set("startIndex", fmt.Sprintf("%d", startIndex))
	query.Set("resultsPerPage", fmt.Sprintf("%d", resultsPerPage))
	u.RawQuery = query.Encode()

	var resp nvdResponse
	if err := c.doRequest(ctx, u.String(), &resp); err != nil {
		return nil, err
	}

	return toDomainVulnerabilities(resp.Vulnerabilities), nil
}

func (c *NVDClient) FetchByCVE(ctx context.Context, cveID string) (*models.Vulnerability, error) {
	u, err := url.Parse(nvdBaseURL)
	if err != nil {
		return nil, err
	}

	query := u.Query()
	query.Set("cveId", strings.ToUpper(strings.TrimSpace(cveID)))
	u.RawQuery = query.Encode()

	var resp nvdResponse
	if err := c.doRequest(ctx, u.String(), &resp); err != nil {
		return nil, err
	}

	vulns := toDomainVulnerabilities(resp.Vulnerabilities)
	if len(vulns) == 0 {
		return nil, nil
	}

	return &vulns[0], nil
}

func (c *NVDClient) doRequest(ctx context.Context, endpoint string, target any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return err
	}

	if c.apiKey != "" {
		req.Header.Set("apiKey", c.apiKey)
	}
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		return fmt.Errorf("nvd request failed with status %d", resp.StatusCode)
	}

	return json.NewDecoder(resp.Body).Decode(target)
}

func toDomainVulnerabilities(items []nvdVulnerabilityItem) []models.Vulnerability {
	out := make([]models.Vulnerability, 0, len(items))
	for _, item := range items {
		v := item.CVE
		out = append(out, models.Vulnerability{
			CVEID:            strings.ToUpper(v.ID),
			Severity:         detectSeverity(v.Metrics),
			PublishedAt:      v.Published.Ptr(),
			LastModifiedAt:   v.LastModified.Ptr(),
			SourceIdentifier: v.SourceIdentifier,
		})
	}
	return out
}

func detectSeverity(metrics nvdMetrics) string {
	for _, m := range metrics.CVSSMetricV31 {
		if m.CVSSData.BaseSeverity != "" {
			return strings.ToUpper(m.CVSSData.BaseSeverity)
		}
	}
	for _, m := range metrics.CVSSMetricV30 {
		if m.CVSSData.BaseSeverity != "" {
			return strings.ToUpper(m.CVSSData.BaseSeverity)
		}
	}
	for _, m := range metrics.CVSSMetricV2 {
		if m.BaseSeverity != "" {
			return strings.ToUpper(m.BaseSeverity)
		}
	}
	return "INFO"
}

type nvdResponse struct {
	Vulnerabilities []nvdVulnerabilityItem `json:"vulnerabilities"`
}

type nvdVulnerabilityItem struct {
	CVE nvdCVE `json:"cve"`
}

type nvdCVE struct {
	ID               string       `json:"id"`
	SourceIdentifier string       `json:"sourceIdentifier"`
	Published        nvdTimestamp `json:"published"`
	LastModified     nvdTimestamp `json:"lastModified"`
	Metrics          nvdMetrics   `json:"metrics"`
}

type nvdMetrics struct {
	CVSSMetricV31 []nvdCVSSV31 `json:"cvssMetricV31"`
	CVSSMetricV30 []nvdCVSSV30 `json:"cvssMetricV30"`
	CVSSMetricV2  []nvdCVSSV2  `json:"cvssMetricV2"`
}

type nvdCVSSV31 struct {
	CVSSData nvdCVSSData `json:"cvssData"`
}

type nvdCVSSV30 struct {
	CVSSData nvdCVSSData `json:"cvssData"`
}

type nvdCVSSData struct {
	BaseSeverity string `json:"baseSeverity"`
}

type nvdCVSSV2 struct {
	BaseSeverity string `json:"baseSeverity"`
}

type nvdTimestamp struct {
	value *time.Time
}

func (t *nvdTimestamp) UnmarshalJSON(data []byte) error {
	raw := strings.Trim(string(data), `"`)
	if raw == "" || raw == "null" {
		t.value = nil
		return nil
	}

	layouts := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02T15:04:05.000",
		"2006-01-02T15:04:05",
	}

	for _, layout := range layouts {
		parsed, err := time.Parse(layout, raw)
		if err == nil {
			t.value = &parsed
			return nil
		}
	}

	return fmt.Errorf("unsupported nvd timestamp format: %s", raw)
}

func (t nvdTimestamp) Ptr() *time.Time {
	return t.value
}
