package com.example.kafkadriver.repository;

import com.example.kafkadriver.entity.ProcessedMessage;
import com.example.kafkadriver.entity.ProcessedMessage.ProcessingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProcessedMessageRepository extends JpaRepository<ProcessedMessage, Long> {

    Optional<ProcessedMessage> findByMessageId(String messageId);
    List<ProcessedMessage> findByStatus(ProcessingStatus status);
    List<ProcessedMessage> findBySender(String sender);
    boolean existsByMessageId(String messageId);
}