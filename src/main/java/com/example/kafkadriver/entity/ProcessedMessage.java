package com.example.kafkadriver.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "processed_messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProcessedMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String messageId;

    @Column(nullable = false, length = 1000)
    private String content;

    @Column(nullable = false)
    private String sender;

    @Column(length = 500)
    private String metadata;

    @Column(nullable = false)
    private LocalDateTime receivedAt;

    @Column(nullable = false)
    private LocalDateTime processedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProcessingStatus status;

    private String errorMessage;

    public enum ProcessingStatus {
        SUCCESS, FAILED, RETRY
    }
}