package com.pathnex.javaapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class JavaAppApplication {

    public static void main(String[] args) {
        SpringApplication.run(JavaAppApplication.class, args);
    }

    @RestController
    static class ApiController {

        @GetMapping("/")
        public String home() {
            return "Hello from Pathnex Java Application";
        }

        @GetMapping("/health")
        public String health() {
            return "Java application is healthy";
        }
    }
}
