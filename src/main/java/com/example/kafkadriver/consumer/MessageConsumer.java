package com.example.kafkadriver.consumer;

import com.example.kafkadriver.entity.ProcessedMessage;
import com.example.kafkadriver.entity.ProcessedMessage.ProcessingStatus;
import com.example.kafkadriver.model.MessageEvent;
import com.example.kafkadriver.service.MessageProcessingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.retry.annotation.Backoff;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@Slf4j
public class MessageConsumer {

        private final MessageProcessingService processingService;

        public MessageConsumer(MessageProcessingService processingService) {
                this.processingService = processingService;
        }

        @RetryableTopic(attempts = "4", backoff = @Backoff(delay = 1000, multiplier = 2.0), topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE, autoCreateTopics = "true")
        @KafkaListener(topics = "${kafka.topic.name}", groupId = "${spring.kafka.consumer.group-id}")
        public void consume(
                        @Payload MessageEvent messageEvent,
                        @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
                        @Header(KafkaHeaders.OFFSET) long offset,
                        @Header(name = "kafka_receivedTopic", required = false) String topic) {

                log.info("Consuming message [topic={}, partition={}, offset={}]: messageId={}, sender={}",
                                topic, partition, offset, messageEvent.getMessageId(), messageEvent.getSender());

                ProcessedMessage processedMessage = new ProcessedMessage();
                processedMessage.setMessageId(messageEvent.getMessageId());
                processedMessage.setContent(messageEvent.getContent());
                processedMessage.setSender(messageEvent.getSender());
                processedMessage.setMetadata(messageEvent.getMetadata());
                processedMessage.setReceivedAt(messageEvent.getTimestamp() != null ? messageEvent.getTimestamp()
                                : LocalDateTime.now());
                processedMessage.setProcessedAt(LocalDateTime.now());

                try {
                        // Check for duplicates first
                        if (processingService.isDuplicateMessage(messageEvent.getMessageId())) {
                                log.warn("Duplicate message detected: messageId={}, skipping processing",
                                                messageEvent.getMessageId());
                                return;
                        }

                        // Set status BEFORE saving to database
                        processedMessage.setStatus(ProcessingStatus.SUCCESS);
                        processingService.processMessage(processedMessage);

                        log.info("Message processed successfully: [messageId={}, sender={}]",
                                        messageEvent.getMessageId(), messageEvent.getSender());
                } catch (IllegalStateException e) {
                        log.warn("Duplicate message handling: {}", e.getMessage());
                        processedMessage.setStatus(ProcessingStatus.SUCCESS);
                        processingService.saveProcessedMessage(processedMessage);
                } catch (Exception e) {
                        log.error("Error processing message: [messageId={}], error: {}",
                                        messageEvent.getMessageId(), e.getMessage(), e);
                        processedMessage.setStatus(ProcessingStatus.FAILED);
                        processedMessage.setErrorMessage(e.getMessage());
                        processingService.saveProcessedMessage(processedMessage);
                        throw e; // Re-throw to trigger retry
                }
        }
}
