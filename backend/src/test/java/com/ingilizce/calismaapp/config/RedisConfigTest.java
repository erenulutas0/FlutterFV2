package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.Test;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RedisConfigTest {

    @Test
    void redisConnectionFactory_ShouldApplyConfiguredProperties() {
        RedisConfig config = new RedisConfig();
        ReflectionTestUtils.setField(config, "redisHost", "localhost");
        ReflectionTestUtils.setField(config, "redisPort", 6379);
        ReflectionTestUtils.setField(config, "redisPassword", "secret");
        ReflectionTestUtils.setField(config, "redisDatabase", 2);
        ReflectionTestUtils.setField(config, "redisTimeout", Duration.ofSeconds(3));

        LettuceConnectionFactory factory = config.redisConnectionFactory();

        assertNotNull(factory);
        assertEquals("localhost", factory.getHostName());
        assertEquals(6379, factory.getPort());
        assertEquals(2, factory.getDatabase());
    }

    @Test
    void redisTemplate_ShouldSetSerializersAndFactory() {
        RedisConfig config = new RedisConfig();
        ReflectionTestUtils.setField(config, "redisHost", "localhost");
        ReflectionTestUtils.setField(config, "redisPort", 6379);
        ReflectionTestUtils.setField(config, "redisPassword", "");
        ReflectionTestUtils.setField(config, "redisDatabase", 0);
        ReflectionTestUtils.setField(config, "redisTimeout", Duration.ofSeconds(2));

        LettuceConnectionFactory factory = config.redisConnectionFactory();
        RedisTemplate<String, Object> template = config.redisTemplate(factory);

        assertNotNull(template);
        assertNotNull(template.getKeySerializer());
        assertNotNull(template.getValueSerializer());
    }
}
