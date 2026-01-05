package com.example.kafkadriver.model;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MessageEvent {

    private String messageId; // Optional - auto-generated if not provided

    @NotBlank(message = "Message content cannot be empty")
    private String content;

    @NotBlank(message = "Sender cannot be empty")
    private String sender;

    private String metadata;
    private LocalDateTime timestamp;

    public MessageEvent(String messageId, String content, String sender, String metadata) {
        this.messageId = messageId;
        this.content = content;
        this.sender = sender;
        this.metadata = metadata;
        this.timestamp = LocalDateTime.now();
    }
}