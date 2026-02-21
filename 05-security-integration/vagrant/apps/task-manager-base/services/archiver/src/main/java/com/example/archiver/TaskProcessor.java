package com.example.archiver;

import org.springframework.stereotype.Component;

@Component
public class TaskProcessor {

    /**
     * Pure Logic: Determines if a task string should be archived.
     * This is decoupled from Redis, making it easy to unit test.
     */
    public boolean isArchivable(String taskJson) {
        if (taskJson == null || taskJson.isEmpty()) {
            return false;
        }
        // We look for the "Completed" status in the JSON string
        return taskJson.contains("\"status\": \"Completed\"") || 
               taskJson.contains("\"status\": \"completed\"");
    }
}