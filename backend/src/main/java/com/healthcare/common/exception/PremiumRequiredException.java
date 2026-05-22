package com.healthcare.common.exception;

/**
 * 프리미엄 전용 기능에 비프리미엄 사용자가 접근한 경우.
 * GlobalExceptionHandler에서 403 PREMIUM_REQUIRED로 매핑된다.
 */
public class PremiumRequiredException extends RuntimeException {

    public PremiumRequiredException() {
        super("프리미엄 구독이 필요한 기능입니다.");
    }

    public PremiumRequiredException(String message) {
        super(message);
    }
}
