package config

import (
	"bytes"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port              string
	DatabaseURL       string
	NVDAPIKey         string
	HTTPTimeout       time.Duration
	NVDResultsPerPage int
	NVDMaxPages       int
}

func Load() Config {
	return Config{
		Port:              getEnv("PORT", "8080"),
		DatabaseURL:       getEnv("DATABASE_URL", ""),
		NVDAPIKey:         loadNVDAPIKey(),
		HTTPTimeout:       getEnvDurationSeconds("HTTP_TIMEOUT_SECONDS", 20),
		NVDResultsPerPage: getEnvInt("NVD_RESULTS_PER_PAGE", 500),
		NVDMaxPages:       getEnvInt("NVD_MAX_PAGES", 3),
	}
}

func loadNVDAPIKey() string {
	if key := strings.TrimSpace(os.Getenv("NVD_API_KEY")); key != "" {
		return key
	}

	secretFile := strings.TrimSpace(os.Getenv("NVD_API_KEY_FILE"))
	if secretFile == "" {
		return ""
	}

	secretPath := filepath.Clean(secretFile)
	content, err := os.ReadFile(secretPath)
	if err != nil {
		log.Printf("warning: could not read NVD_API_KEY_FILE %q: %v", secretPath, err)
		return ""
	}

	return strings.TrimSpace(string(bytes.TrimSpace(content)))
}

func getEnv(key string, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func getEnvInt(key string, defaultValue int) int {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}

	parsed, err := strconv.Atoi(value)
	if err != nil || parsed <= 0 {
		return defaultValue
	}
	return parsed
}

func getEnvDurationSeconds(key string, defaultValue int) time.Duration {
	seconds := getEnvInt(key, defaultValue)
	return time.Duration(seconds) * time.Second
}
