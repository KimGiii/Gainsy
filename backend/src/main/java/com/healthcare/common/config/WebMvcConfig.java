package com.healthcare.common.config;

import com.healthcare.security.CurrentUserIdArgumentResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;

@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final CurrentUserIdArgumentResolver currentUserIdArgumentResolver;

    /**
     * CORS 허용 origin 목록. 환경별 application-*.yml에서 명시 설정 필수.
     * 와일드카드(*) 기본값을 사용하지 않는다 — 누락 시 시작 단계에서 명시적으로 실패시킨다.
     */
    @Value("${app.cors.allowed-origins}")
    private String allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (!StringUtils.hasText(allowedOrigins)) {
            throw new IllegalStateException(
                "app.cors.allowed-origins 설정이 비어 있습니다. 환경별 application-*.yml에 명시하세요."
            );
        }

        String[] origins = allowedOrigins.split(",");
        for (String origin : origins) {
            if ("*".equals(origin.trim())) {
                throw new IllegalStateException(
                    "app.cors.allowed-origins에 와일드카드(*)를 사용할 수 없습니다. 허용 출처를 명시적으로 지정하세요."
                );
            }
        }

        registry.addMapping("/api/**")
            .allowedOriginPatterns(origins)
            .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
    }

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(currentUserIdArgumentResolver);
    }
}
