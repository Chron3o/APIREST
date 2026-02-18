package handlers

import (
	"APIREST/models"
	"APIREST/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type VulnerabilityHandler struct {
	service *services.VulnerabilityService
}

func NewVulnerabilityHandler(service *services.VulnerabilityService) *VulnerabilityHandler {
	return &VulnerabilityHandler{service: service}
}

func (h *VulnerabilityHandler) GetSummary(c *gin.Context) {
	summary, err := h.service.GetSummary(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, summary)
}

func (h *VulnerabilityHandler) PostRemediations(c *gin.Context) {
	assetID := c.Param("asset_id")
	var body models.RemediationRequest

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	remediatedCVEs, err := h.service.RegisterRemediations(c.Request.Context(), assetID, body.CVEs)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"asset_id":        assetID,
		"remediated_cves": remediatedCVEs,
	})
}

func (h *VulnerabilityHandler) GetUncorrectedSummary(c *gin.Context) {
	summary, err := h.service.GetUncorrectedSummary(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, summary)
}

func (h *VulnerabilityHandler) SyncVulnerabilities(c *gin.Context) {
	total, err := h.service.SyncVulnerabilities(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"synced_vulnerabilities": total,
	})
}
