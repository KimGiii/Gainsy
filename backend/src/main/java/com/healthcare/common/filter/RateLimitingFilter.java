package com.healthcare.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * /api/v1/auth/** 경로에 분당 20회 IP 기반 rate limit 적용.
 * 토큰 버킷: 1분마다 20개 리필, 초과 시 429 응답.
 */
public class RateLimitingFilter extends OncePerRequestFilter {

    private static final int CAPACITY = 20;
    private static final long REFILL_INTERVAL_MS = 60_000L;

    private final ConcurrentHashMap<String, long[]> buckets = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/v1/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String clientIp = resolveClientIp(request);

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

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
