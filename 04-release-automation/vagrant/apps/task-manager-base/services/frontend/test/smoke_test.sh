#!/bin/bash
echo "🔍 Starting Frontend Smoke Test..."

# 1. Check if Nginx is serving the page
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$STATUS" -eq 200 ]; then
    echo "✅ [PASS] Nginx is up."
else
    echo "❌ [FAIL] Nginx is down (Status: $STATUS)"
    exit 1
fi

# 2. Check if the Task List container exists in the HTML
if curl -s http://localhost | grep -q 'id="task-list"'; then
    echo "✅ [PASS] Task List container found in DOM."
else
    echo "❌ [FAIL] Missing #task-list element. UI will not render tasks."
    exit 1
fi
