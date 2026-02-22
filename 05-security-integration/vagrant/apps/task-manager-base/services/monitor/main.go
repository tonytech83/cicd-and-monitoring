// Go Monitor package
package main

import (
	"context"
	"log"
	"os"
	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
)

var ctx = context.Background()
const cErrorCode = 500

// CategorizeTask identifies if a task is 'Actionable' or 'Done'.
func CategorizeTask(status string) string {
	if status == "Completed" || status == "Archived" {
		return "Finished"
	}

	return "Active"
}

func main() {
	app := fiber.New()

	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "redis-db"
	}

	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}

	redisAddr := redisHost + ":" + redisPort
	redisPassword := os.Getenv("REDIS_PASSWORD")

	rdb := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: redisPassword,
	})

	// Health check endpoint (Integration check)
	app.Get("/health", func(context *fiber.Ctx) error {
		err := rdb.Ping(ctx).Err()
		if err != nil {
			return context.Status(cErrorCode).JSON(fiber.Map{
				"status": "unhealthy",
				"error":  err.Error(),
			})
		}

		return context.JSON(fiber.Map{"status": "healthy", "service": "go-monitor"})
	})

	// Simple metrics endpoint
	app.Get("/metrics", func(context *fiber.Ctx) error {
		// keys, _ := rdb.Keys(ctx, "task:*").Result()
		// return c.JSON(fiber.Map{
		// 	"total_tasks": len(keys),
		// })
		keys, _ := rdb.Keys(ctx, "task:*").Result()

		activeCount := 0
		finishedCount := 0

		for _, key := range keys {
			taskJSON, _ := rdb.Get(ctx, key).Result()

			// We use our tested function here!
			// We'll assume a simple string search for this demo
			// or a proper JSON unmarshal if you want to be fancy.
			category := CategorizeTask(taskJSON)

			if category == "Completed" {
				finishedCount++
			} else {
				activeCount++
			}
		}

		return context.JSON(fiber.Map{
			"total":    len(keys),
			"active":   activeCount,
			"finished": finishedCount,
		})
	})

	// Start the server on port 8080
	log.Println("Server listening on port 8080...")
	log.Fatal(app.Listen(":8080"))
}
