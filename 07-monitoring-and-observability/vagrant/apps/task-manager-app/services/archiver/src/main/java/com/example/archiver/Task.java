package com.example.archiver;

public class Task {
    private String id;
    private String title;
    private String priority;
    private String due_date;
    private String status;

    public Task() {}
    public Task(String id, String title, String priority, String due_date, String status) {
        this.id = id;
        this.title = title;
        this.priority = priority;
        this.due_date = due_date;
        this.status = status;
    }

    // Getters and Setters
    public String getId() { return id; }
    public String getTitle() { return title; }
    public String getPriority() { return priority; }
    public String getDueDate() { return due_date; }
    public String getStatus() { return status; }
}