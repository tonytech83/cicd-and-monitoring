package com.example.archiver;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.util.Set;

@Component
public class TaskArchiver {

    @Autowired
    private StringRedisTemplate redisTemplate;

    @Autowired
    private TaskProcessor processor; // Inject the logic processor

    // This makes the Java service "Self-Triggering"
    @Scheduled(fixedRate = 10000) // Runs every 10 seconds
    public void archiveCompletedTasks() {
        System.out.println("Looking for tasks to archive ...");

        Set<String> keys = redisTemplate.keys("task:*");
        if (keys == null) {
            System.out.println("Nothing found.");
            return;
        }

        System.out.println("Found: " + keys.size() + " task(s).");

        int archived = 0;

        for (String key : keys) {
            String taskJson = redisTemplate.opsForValue().get(key);
            // If task contains "status":"Completed", move it!
            //if (taskJson != null && taskJson.contains("\"status\":\"Completed\"")) {
            if (processor.isArchivable(taskJson)) {
                System.out.println("Archiving completed task: " + key);
                redisTemplate.opsForValue().set("archive:" + key, taskJson);
                redisTemplate.delete(key);
                archived++;
            }
        }

        if (archived > 0)
            System.out.println("Archived " + archived + " task(s).");
        else
            System.out.println("Nothing has been archived.");
    }
}