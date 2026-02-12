package com.ingilizce.calismaapp.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@Service
public class ChatbotService {

  private static final Logger logger = LoggerFactory.getLogger(ChatbotService.class);
  private final GroqService groqService;
  private final ObjectMapper objectMapper;

  public ChatbotService(GroqService groqService) {
    this.groqService = groqService;
    this.objectMapper = new ObjectMapper();
  }

  /**
   * Cümle üretme servisi - UNIVERSAL MODE
   */
  public String generateSentences(String message) {
    PromptCatalog.PromptDef def = PromptCatalog.generateSentences();
    return callGroq(def,
        "Target word: '" + message + "'. Return ONLY pure, minified JSON. No other text.");
  }

  /**
   * Çeviri kontrolü servisi
   */
  public String checkTranslation(String message) {
    PromptCatalog.PromptDef def = PromptCatalog.checkTranslation();
    return callGroq(def, message);
  }

  /**
   * İngilizce Çeviri kontrolü servisi (TR -> EN)
   */
  public String checkEnglishTranslation(String message) {
    PromptCatalog.PromptDef def = PromptCatalog.checkEnglishTranslation();
    return callGroq(def, message);
  }

  /**
   * İngilizce sohbet pratiği servisi - Buddy Mode
   */
  public String chat(String message) {
    PromptCatalog.PromptDef def = PromptCatalog.chat();
    return callGroq(def, message);
  }

  /**
   * IELTS/TOEFL Speaking test soruları üretme servisi
   */
  public String generateSpeakingTestQuestions(String message) {
    PromptCatalog.PromptDef def = PromptCatalog.generateSpeakingTestQuestions();
    return callGroq(def, "Generate " + message + ". Return ONLY JSON.");
  }

  /**
   * IELTS/TOEFL Speaking test puanlama servisi
   */
  public String evaluateSpeakingTest(String message) {
    PromptCatalog.PromptDef def = PromptCatalog.evaluateSpeakingTest();
    return callGroq(def, message + " Return ONLY JSON.");
  }

  private String callGroq(PromptCatalog.PromptDef def, String userMessage) {
    List<Map<String, String>> messages = new ArrayList<>();

    Map<String, String> systemMsg = new HashMap<>();
    systemMsg.put("role", "system");
    systemMsg.put("content", def.systemPrompt() + "\n\nPROMPT_VERSION: " + def.version());
    messages.add(systemMsg);

    Map<String, String> userMsg = new HashMap<>();
    userMsg.put("role", "user");
    userMsg.put("content", userMessage);
    messages.add(userMsg);

    logger.info("Prompt {} v{}", def.id(), def.version());
    boolean jsonMode = def.output() != PromptCatalog.PromptOutput.TEXT;
    String raw = groqService.chatCompletion(messages, jsonMode);
    return normalizeJson(raw, def.output());
  }

  private String normalizeJson(String raw, PromptCatalog.PromptOutput output) {
    if (raw == null || output == PromptCatalog.PromptOutput.TEXT) {
      return raw;
    }

    String cleaned = raw.trim()
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();

    int objStart = cleaned.indexOf('{');
    int objEnd = cleaned.lastIndexOf('}');
    int arrStart = cleaned.indexOf('[');
    int arrEnd = cleaned.lastIndexOf(']');

    if (arrStart >= 0 && arrEnd > arrStart && (objStart < 0 || arrStart < objStart)) {
      cleaned = cleaned.substring(arrStart, arrEnd + 1).trim();
    } else if (objStart >= 0 && objEnd > objStart) {
      cleaned = cleaned.substring(objStart, objEnd + 1).trim();
    }

    try {
      Object parsed = objectMapper.readValue(cleaned, Object.class);
      if (output == PromptCatalog.PromptOutput.JSON_OBJECT && !(parsed instanceof Map)) {
        throw new IllegalArgumentException("Expected JSON object");
      }
      if (output == PromptCatalog.PromptOutput.JSON_ARRAY) {
        if (parsed instanceof List) {
          return cleaned;
        }
        if (parsed instanceof Map map && map.containsKey("sentences") && map.get("sentences") instanceof List) {
          return cleaned;
        }
        throw new IllegalArgumentException("Expected JSON array (or object with sentences list)");
      }
      return cleaned;
    } catch (Exception ex) {
      logger.warn("AI JSON validation failed for output type {}. Returning raw response.", output, ex);
      return raw;
    }
  }
}
