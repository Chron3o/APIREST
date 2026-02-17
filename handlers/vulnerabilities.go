package handlers

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

// Pseudocódigo para simplificar

func GetSummary(c *gin.Context) {
	// Aquí llamarías al servicio que consume la API NVD en tiempo real
	summary := map[string]int{
		"critical": 10,
		"high":     20,
		"medium":   30,
		"low":      5,
		"info":     0,
	}
	c.JSON(http.StatusOK, summary)
}

func PostRemediations(c *gin.Context) {
	assetID := c.Param("asset_id")
	var body struct {
		CVEs []string `json:"cves"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Aquí validarías cada CVE contra NVD y guardarías en DB
	// Por ahora simulamos éxito
	c.JSON(http.StatusOK, gin.H{
		"asset_id":        assetID,
		"remediated_cves": body.CVEs,
	})
}

func GetUncorrectedSummary(c *gin.Context) {
	// Consultar base de datos y calcular resumen sin corregidas
	summary := map[string]int{
		"critical": 5,
		"high":     10,
		"medium":   15,
		"low":      3,
		"info":     0,
	}
	c.JSON(http.StatusOK, summary)
}
