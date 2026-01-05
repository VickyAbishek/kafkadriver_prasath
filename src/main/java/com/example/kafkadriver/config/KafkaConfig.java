package com.example.kafkadriver.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.listener.CommonErrorHandler;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

@Configuration
public class KafkaConfig {

    @Value("${kafka.topic.name}")
    private String topicName;

    @Value("${kafka.topic.partitions}")
    private int partitions;

    @Value("${kafka.topic.replication-factor}")
    private int replicationFactor;

    @Bean
    public NewTopic messageEventsTopic() {
        return TopicBuilder
                .name(topicName)
                .partitions(partitions)
                .replicas(replicationFactor)
                .build();
    }

    @Bean
    public CommonErrorHandler errorHandler() {
        return new DefaultErrorHandler(new FixedBackOff(1000, 3));
    }
}

