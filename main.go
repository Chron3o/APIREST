package main

import (
	"APIREST/config"
	"APIREST/database"
	"APIREST/handlers"
	"APIREST/repositories"
	"APIREST/services"
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	dbPool, err := database.NewPostgresPool(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}
	defer dbPool.Close()

	if err := database.RunMigrations(dbPool); err != nil {
		log.Fatalf("failed to run migrations: %v", err)
	}

	vulnRepo := repositories.NewVulnerabilityRepository(dbPool)
	remRepo := repositories.NewRemediationRepository(dbPool)
	nvdClient := services.NewNVDClient(cfg.NVDAPIKey, cfg.HTTPTimeout)
	vulnService := services.NewVulnerabilityService(vulnRepo, remRepo, nvdClient, cfg.NVDResultsPerPage, cfg.NVDMaxPages)
	vulnHandler := handlers.NewVulnerabilityHandler(vulnService)

	r := gin.Default()

	r.GET("/vulnerabilities/summary", vulnHandler.GetSummary)
	r.GET("/vulnerabilities/summary/uncorrected", vulnHandler.GetUncorrectedSummary)
	r.POST("/assets/:asset_id/vulnerabilities", vulnHandler.PostRemediations)
	r.POST("/vulnerabilities/sync", vulnHandler.SyncVulnerabilities)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("failed to run server: %v", err)
	}
}
