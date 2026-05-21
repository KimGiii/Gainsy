package com.healthcare.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

/**
 * /api/v1/auth/** 경로에 분당 20회 IP 기반 rate limit 적용.
 * 토큰 버킷: 1분마다 20개 리필, 초과 시 429 응답.
 *
 * <h2>클라이언트 IP 결정 정책</h2>
 * 기본적으로 컨테이너가 보는 원격 주소(`request.getRemoteAddr()`)만 사용한다.
 * 클라이언트가 임의로 보낸 X-Forwarded-For 헤더는 신뢰하지 않는다 — IP 스푸핑 방지.
 * <p>
 * 프로덕션처럼 Nginx/로드밸런서 뒤에 있는 경우 Spring의
 * {@code server.forward-headers-strategy=native} 설정으로 신뢰된 프록시의
 * X-Forwarded-For가 `getRemoteAddr()`에 정확히 반영되므로 별도 헤더 파싱이 필요 없다.
 */
@Component
public class RateLimitingFilter extends OncePerRequestFilter {

    private static final int CAPACITY = 20;
    private static final long REFILL_INTERVAL_MS = 60_000L;

    private final ConcurrentHashMap<String, long[]> buckets = new ConcurrentHashMap<>();

    /** 향후 정책 가시화를 위한 표시 플래그. 실제 IP 추출은 컨테이너/프록시 계층에 위임. */
    private final boolean trustForwardedHeaders;

    public RateLimitingFilter(
            @Value("${app.rate-limit.trust-forwarded-headers:false}") boolean trustForwardedHeaders) {
        this.trustForwardedHeaders = trustForwardedHeaders;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/v1/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String clientIp = request.getRemoteAddr();

        if (tryConsume(clientIp)) {
            filterChain.doFilter(request, response);
        } else {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setHeader("Retry-After", "60");
            response.getWriter().write(
                "{\"code\":\"RATE_LIMIT_EXCEEDED\",\"message\":\"요청이 너무 많습니다. 잠시 후 다시 시도해주세요.\"}"
            );
        }
    }

    boolean isTrustForwardedHeaders() {
        return trustForwardedHeaders;
    }

    // long[0] = 현재 남은 토큰, long[1] = 마지막 리필 시각(ms)
    private boolean tryConsume(String clientIp) {
        long now = System.currentTimeMillis();
        long[] state = buckets.computeIfAbsent(clientIp, k -> new long[]{CAPACITY, now});

        synchronized (state) {
            long elapsed = now - state[1];
            if (elapsed >= REFILL_INTERVAL_MS) {
                state[0] = CAPACITY;
                state[1] = now;
            }
            if (state[0] > 0) {
                state[0]--;
                return true;
            }
            return false;
        }
    }
}
