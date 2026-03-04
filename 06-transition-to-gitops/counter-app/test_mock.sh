#!/bin/bash

BASE_URL="http://127.0.0.1:5000"

declare -a endpoints=(
    "/"
)

declare -a methods=(
  "GET"
)

declare -a payloads=(
  ""
)

echo "Testing all mock endpoints..."

for i in "${!endpoints[@]}"; do
    method=${methods[$i]}
    url="$BASE_URL${endpoints[$i]}"
    data=${payloads[$i]}
    echo
    echo "============= $method $url ============="
    if [[ "$method" == "GET" || "$method" == "DELETE" ]]; then
        curl -s -X $method "$url" -H "Content-Type: application/json"
    else
        curl -s -X $method "$url" -H "Content-Type: application/json" -d "$data"
    fi
    echo
done
