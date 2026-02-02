package com.example.counter;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CounterController {

    private int count;

    public CounterController() {
        this.count = 0;
    }

    @GetMapping("/")
    public String hello() {
        this.count = this.count + 1;
        return "Hello! This Java Spring app has been viewed " + this.count + " times.\n";
    }
}
