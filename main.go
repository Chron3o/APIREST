package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	r.GET("/vulnerabilities/summary", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"critical": 10,
			"high":     20,
			"medium":   30,
			"low":      5,
			"info":     0,
		})
	})

	r.POST("/assets/:asset_id/vulnerabilities", func(c *gin.Context) {
		assetID := c.Param("asset_id")
		c.JSON(200, gin.H{
			"asset_id":        assetID,
			"remediated_cves": []string{"CVE-2023-1234"},
		})
	})

	r.GET("/vulnerabilities/summary/uncorrected", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"critical": 5,
			"high":     10,
			"medium":   15,
			"low":      3,
			"info":     0,
		})
	})

	r.Run(":8080")
}
