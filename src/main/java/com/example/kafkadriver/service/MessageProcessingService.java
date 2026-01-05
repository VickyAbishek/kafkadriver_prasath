package com.example.kafkadriver.service;

import com.example.kafkadriver.entity.ProcessedMessage;
import com.example.kafkadriver.repository.ProcessedMessageRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
public class MessageProcessingService {

    private final ProcessedMessageRepository repository;

    public MessageProcessingService(ProcessedMessageRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public void processMessage(ProcessedMessage message) {
        log.debug("Processing message: {}", message);

        if (repository.existsByMessageId(message.getMessageId())) {
            throw new IllegalStateException("Duplicate message: " + message.getMessageId());
        }

        saveProcessedMessage(message);
    }

    public boolean isDuplicateMessage(String messageId) {
        return repository.existsByMessageId(messageId);
    }

    @Transactional
    public ProcessedMessage saveProcessedMessage(ProcessedMessage message) {
        ProcessedMessage saved = repository.save(message);
        log.info("Message saved to database: [id={}, messageId={}, status={}]",
                saved.getId(), saved.getMessageId(), saved.getStatus());
        return saved;
    }

    public List<ProcessedMessage> getAllProcessedMessages() {
        return repository.findAll();
    }

    public List<ProcessedMessage> getProcessedMessagesByStatus(ProcessedMessage.ProcessingStatus status) {
        return repository.findByStatus(status);
    }

    public List<ProcessedMessage> getProcessedMessagesBySender(String sender) {
        return repository.findBySender(sender);
    }
}

