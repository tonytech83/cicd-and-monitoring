package main

import (
	"context"
	"fmt"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
)

var ctx = context.Background()

// CategorizeTask identifies if a task is 'Actionable' or 'Done'
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
	redisAddr := fmt.Sprintf("%s:6379", redisHost)

	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	// Health check endpoint (Integration check)
	app.Get("/health", func(c *fiber.Ctx) error {
		err := rdb.Ping(ctx).Err()
		if err != nil {
			return c.Status(500).JSON(fiber.Map{
				"status": "unhealthy",
				"error":  err.Error(),
			})
		}
		return c.JSON(fiber.Map{"status": "healthy", "service": "go-monitor"})
	})

	// Simple metrics endpoint
	app.Get("/metrics", func(c *fiber.Ctx) error {
		// keys, _ := rdb.Keys(ctx, "task:*").Result()
		// return c.JSON(fiber.Map{
		// 	"total_tasks": len(keys),
		// })
		keys, _ := rdb.Keys(ctx, "task:*").Result()

		activeCount := 0
		finishedCount := 0

		for _, key := range keys {
			taskJson, _ := rdb.Get(ctx, key).Result()

			// We use our tested function here!
			// We'll assume a simple string search for this demo
			// or a proper JSON unmarshal if you want to be fancy.
			category := CategorizeTask(taskJson)

			if category == "Completed" {
				finishedCount++
			} else {
				activeCount++
			}
		}

		return c.JSON(fiber.Map{
			"total":    len(keys),
			"active":   activeCount,
			"finished": finishedCount,
		})
	})

	app.Listen(":8080")
}
