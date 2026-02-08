#!/usr/bin/env bash
set -e

docker rm -f api redis-db monitor frontend archiver 2>/dev/null || true

echo "* Create the custom dedicated network ..."
docker network create task-net || true

echo "* Starting Task Manager API container ..."
docker run -d \
  --name api \
  -p 5001:5000 \
  --net task-net \
  localhost:5000/task-manager-api:latest

echo "* Starting Task Manager Redis container ..."
docker run -d \
  --name redis-db \
  -p 6379:6379 \
  --net task-net \
  redis

echo "* Starting Task Manager Monitor container ..."
docker run -d \
  --name monitor \
  -p 5002:8080 \
  --net task-net \
  localhost:5000/task-manager-monitor:latest

echo "* Starting Task Manager Frontend container ..."
docker run -d \
  --name frontend \
  -p 80:80 \
  --net task-net \
  localhost:5000/task-manager-frontend:latest

echo "* Starting Task Manager Archiver container ..."
docker run -d \
  --name archiver \
  --net task-net \
  -e REDIS_HOST=redis-db \
  localhost:5000/task-manager-archiver:latest