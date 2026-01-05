package com.example.kafkadriver.producer;

import com.example.kafkadriver.model.MessageEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;

@Service
@Slf4j
public class MessageProducer {

    private final KafkaTemplate<String, MessageEvent> kafkaTemplate;

    @Value("${kafka.topic.name}")
    private String topicName;

    public MessageProducer(KafkaTemplate<String, MessageEvent> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public CompletableFuture<SendResult<String, MessageEvent>> sendMessage(MessageEvent messageEvent) {
        log.info("Producing message to topic '{}': {}", topicName, messageEvent);

        CompletableFuture<SendResult<String, MessageEvent>> future =
                kafkaTemplate.send(topicName, messageEvent.getMessageId(), messageEvent);

        future.whenComplete((result, ex) -> {
            if (ex == null) {
                log.info("Message sent successfully: [messageId={}] with offset=[{}]",
                        messageEvent.getMessageId(),
                        result.getRecordMetadata().offset());
            } else {
                log.error("Failed to send message: [messageId={}]",
                        messageEvent.getMessageId(), ex);
            }
        });

        return future;
    }
}