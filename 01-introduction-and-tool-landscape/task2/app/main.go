package main

import (
    "context"
    "fmt"
    "net/http"
    "github.com/go-redis/redis/v8"
)

var ctx = context.Background()

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr: "redis-db:6379",
    })

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" { 
		http.NotFound(w, r)
	        return
	}	
        count, _ := rdb.Incr(ctx, "go-hits").Result()
        fmt.Fprintf(w, "Hello! This Go app has been viewed %d times.\n", count)
    })

    fmt.Println("Go server starting on port 8080...")
    http.ListenAndServe(":8080", nil)
}
