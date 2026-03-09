package main

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/redis/go-redis/v9"
)

func TestRedisPing(t *testing.T) {
	host := os.Getenv("REDIS_HOST")
	if host == "" {
		t.Skip("Skipping Connectivity Test: REDIS_HOST not set (Local Mode)")
	}

	rdb := redis.NewClient(&redis.Options{
		Addr: host + ":6379",
	})

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	err := rdb.Ping(ctx).Err()
	if err != nil {
		t.Fatalf("Connectivity Fail: Could not reach Redis at %s. Error: %v", host, err)
	}
}
