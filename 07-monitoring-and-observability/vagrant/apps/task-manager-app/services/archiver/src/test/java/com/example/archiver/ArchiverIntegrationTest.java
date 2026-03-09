package com.example.archiver;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.redis.core.StringRedisTemplate;

@SpringBootTest
class ArchiverIntegrationTest {

    @Autowired
    private TaskArchiver archiver;

    @MockBean
    private StringRedisTemplate redisTemplate;

    @Test
    void contextLoads() {
        assertNotNull(archiver);
    }
}