package com.example.kafkadriver.controller;

import com.example.kafkadriver.entity.ProcessedMessage;
import com.example.kafkadriver.entity.ProcessedMessage.ProcessingStatus;
import com.example.kafkadriver.model.MessageEvent;
import com.example.kafkadriver.producer.MessageProducer;
import com.example.kafkadriver.service.MessageProcessingService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/messages")
@Slf4j
public class MessageController {

    private final MessageProducer messageProducer;
    private final MessageProcessingService processingService;

    public MessageController(MessageProducer messageProducer,
                             MessageProcessingService processingService) {
        this.messageProducer = messageProducer;
        this.processingService = processingService;
    }

    @PostMapping("/produce")
    public ResponseEntity<Map<String, Object>> produceMessage(
            @Valid @RequestBody MessageEvent messageEvent) {

        log.info("Received request to produce message from sender: {}", messageEvent.getSender());

        try {
            if (messageEvent.getMessageId() == null || messageEvent.getMessageId().isEmpty()) {
                messageEvent.setMessageId(UUID.randomUUID().toString());
            }

            if (messageEvent.getTimestamp() == null) {
                messageEvent.setTimestamp(LocalDateTime.now());
            }

            messageProducer.sendMessage(messageEvent);

            Map<String, Object> response = new HashMap<>();
            response.put("status", "SUCCESS");
            response.put("message", "Message sent to Kafka successfully");
            response.put("messageId", messageEvent.getMessageId());
            response.put("timestamp", messageEvent.getTimestamp());

            return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
        } catch (Exception e) {
            log.error("Error producing message", e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "ERROR");
            errorResponse.put("message", "Failed to send message");
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", LocalDateTime.now());

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }

    @GetMapping("/processed")
    public ResponseEntity<Map<String, Object>> getAllProcessedMessages() {
        log.info("Fetching all processed messages");
        List<ProcessedMessage> messages = processingService.getAllProcessedMessages();

        Map<String, Object> response = new HashMap<>();
        response.put("total", messages.size());
        response.put("messages", messages);
        response.put("timestamp", LocalDateTime.now());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/processed/status/{status}")
    public ResponseEntity<Map<String, Object>> getMessagesByStatus(@PathVariable ProcessingStatus status) {
        log.info("Fetching messages with status: {}", status);
        List<ProcessedMessage> messages = processingService.getProcessedMessagesByStatus(status);

        Map<String, Object> response = new HashMap<>();
        response.put("status", status);
        response.put("total", messages.size());
        response.put("messages", messages);
        response.put("timestamp", LocalDateTime.now());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/processed/sender/{sender}")
    public ResponseEntity<Map<String, Object>> getMessagesBySender(@PathVariable String sender) {
        log.info("Fetching messages from sender: {}", sender);
        List<ProcessedMessage> messages = processingService.getProcessedMessagesBySender(sender);

        Map<String, Object> response = new HashMap<>();
        response.put("sender", sender);
        response.put("total", messages.size());
        response.put("messages", messages);
        response.put("timestamp", LocalDateTime.now());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", "kafkadriver");
        health.put("timestamp", LocalDateTime.now().toString());
        return ResponseEntity.ok(health);
    }

    @PostMapping("/test-batch")
    public ResponseEntity<Map<String, Object>> sendBatchMessages(
            @RequestParam(defaultValue = "5") int count) {

        log.info("Received request to send batch of {} messages", count);

        try {
            for (int i = 0; i < count; i++) {
                MessageEvent event = new MessageEvent(
                        UUID.randomUUID().toString(),
                        "Test message " + (i + 1),
                        "BatchProducer",
                        "batch-test"
                );
                messageProducer.sendMessage(event);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("status", "SUCCESS");
            response.put("message", count + " messages sent to Kafka");
            response.put("timestamp", LocalDateTime.now());

            return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
        } catch (Exception e) {
            log.error("Error sending batch messages", e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "ERROR");
            errorResponse.put("message", "Failed to send batch messages");
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", LocalDateTime.now());

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }
}

