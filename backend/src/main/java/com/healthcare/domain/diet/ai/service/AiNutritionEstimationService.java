package com.healthcare.domain.diet.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.healthcare.domain.diet.ai.dto.AiNutritionEstimateResponse;
import com.healthcare.domain.diet.entity.FoodCatalog.FoodCategory;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnExpression("'${app.ai.meal.openai-api-key:}' != ''")
public class AiNutritionEstimationService {

    private static final String DISCLAIMER =
            "AI 추정값이며 실제 영양성분과 다를 수 있습니다. 수정 후 저장하세요.";

    private final ObjectMapper objectMapper;

    @Value("${app.ai.meal.openai-api-key}")
    private String apiKey;

    @Value("${app.ai.meal.openai-base-url:https://api.openai.com}")
    private String baseUrl;

    @Value("${app.ai.meal.model:gpt-4.1-mini}")
    private String model;

    private RestClient client;

    @PostConstruct
    void initializeClient() {
        this.client = RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    public AiNutritionEstimateResponse estimate(String foodName) {
        String instructions = """
                당신은 한국 식단 기록 서비스의 영양성분 추정기입니다.
                사용자가 한국어 음식 이름을 입력하면 100g 기준 영양성분을 추정해 JSON으로 반환하세요.
                응답은 반드시 순수 JSON 객체 하나여야 하며, 마크다운 코드 블록이나 설명 문장은 포함하지 마세요.
                추정값은 신중하게 제시하고 불확실하면 confidence를 낮게 설정하세요.
                category는 반드시 다음 중 하나: GRAIN, PROTEIN_SOURCE, VEGETABLE, FRUIT, DAIRY, FAT, BEVERAGE, PROCESSED, OTHER
                JSON schema:
                {
                  "category": "string",
                  "caloriesPer100g": number,
                  "proteinPer100g": number,
                  "carbsPer100g": number,
                  "fatPer100g": number,
                  "confidence": number
                }
                """;

        Map<String, Object> requestBody = Map.of(
                "model", model,
                "instructions", instructions,
                "input", List.of(Map.of(
                        "role", "user",
                        "content", "'" + foodName + "'의 100g 기준 영양성분을 JSON으로 추정해 주세요."
                ))
        );

        JsonNode response = client.post()
                .uri("/v1/responses")
                .body(requestBody)
                .retrieve()
                .body(JsonNode.class);

        String rawText = extractOutputText(response);
        String jsonText = stripMarkdownFences(rawText);

        try {
            JsonNode parsed = objectMapper.readTree(jsonText);
            FoodCategory category = parseCategory(parsed.path("category").asText("OTHER"));

            return AiNutritionEstimateResponse.builder()
                    .foodName(foodName)
                    .category(category)
                    .caloriesPer100g(parsed.path("caloriesPer100g").asDouble(0.0))
                    .proteinPer100g(parsed.path("proteinPer100g").asDouble(0.0))
                    .carbsPer100g(parsed.path("carbsPer100g").asDouble(0.0))
                    .fatPer100g(parsed.path("fatPer100g").asDouble(0.0))
                    .confidence(parseConfidence(parsed.path("confidence")))
                    .disclaimer(DISCLAIMER)
                    .aiEstimated(true)
                    .build();
        } catch (Exception e) {
            log.error("AI 응답 JSON 파싱 실패: foodName={}, rawText={}, error={}",
                    foodName, rawText, e.getMessage());
            throw new IllegalStateException("AI 응답을 파싱할 수 없습니다: " + e.getMessage());
        }
    }

    private String extractOutputText(JsonNode response) {
        if (response == null) return "{}";

        JsonNode direct = response.path("output_text");
        if (direct.isTextual()) return direct.asText();

        JsonNode output = response.path("output");
        if (output.isArray()) {
            for (JsonNode item : output) {
                JsonNode content = item.path("content");
                if (!content.isArray()) continue;
                for (JsonNode contentItem : content) {
                    JsonNode textNode = contentItem.path("text");
                    if (textNode.isTextual()) return textNode.asText();
                }
            }
        }
        return "{}";
    }

    // OpenAI가 ```json ... ``` 형태로 감싸서 반환할 때 제거
    private String stripMarkdownFences(String text) {
        if (text == null) return "{}";
        String stripped = text.strip();
        if (stripped.startsWith("```")) {
            int firstNewline = stripped.indexOf('\n');
            if (firstNewline >= 0) {
                stripped = stripped.substring(firstNewline + 1).strip();
            }
            if (stripped.endsWith("```")) {
                stripped = stripped.substring(0, stripped.lastIndexOf("```")).strip();
            }
        }
        return stripped;
    }

    private FoodCategory parseCategory(String raw) {
        try {
            return FoodCategory.valueOf(raw.toUpperCase());
        } catch (IllegalArgumentException e) {
            return FoodCategory.OTHER;
        }
    }

    // 모델이 "high"/"medium"/"low" 문자열로 반환하는 경우 대비
    private double parseConfidence(JsonNode node) {
        if (node.isNumber()) return node.asDouble();
        return switch (node.asText("").toLowerCase()) {
            case "high"   -> 0.9;
            case "medium" -> 0.6;
            case "low"    -> 0.3;
            default       -> 0.5;
        };
    }
}
