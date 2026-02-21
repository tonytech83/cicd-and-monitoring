package com.example.archiver;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TaskProcessorTest {

    private final TaskProcessor processor = new TaskProcessor();

    @Test
    void shouldReturnTrueForCompletedStatus() {
        String json = "{\"id\": \"123\", \"status\": \"Completed\"}";
        assertTrue(processor.isArchivable(json), "Should archive completed tasks");
    }

    @Test
    void shouldReturnFalseForPendingStatus() {
        String json = "{\"id\": \"123\", \"status\": \"Pending\"}";
        assertFalse(processor.isArchivable(json), "Should NOT archive pending tasks");
    }

    @Test
    void shouldHandleNullOrEmpty() {
        assertFalse(processor.isArchivable(null));
        assertFalse(processor.isArchivable(""));
    }
}