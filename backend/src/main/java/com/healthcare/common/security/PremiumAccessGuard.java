package com.healthcare.common.security;

import com.healthcare.common.exception.PremiumRequiredException;
import com.healthcare.common.exception.ResourceNotFoundException;
import com.healthcare.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * 프리미엄 전용 기능 진입부에서 사용자 등급을 검증한다.
 * 비프리미엄 사용자에게는 {@link PremiumRequiredException}을 던져
 * 403 PREMIUM_REQUIRED 응답으로 매핑되게 한다.
 */
@Component
@RequiredArgsConstructor
public class PremiumAccessGuard {

    private final UserRepository userRepository;

    public void assertPremium(Long userId) {
        var user = userRepository.findByIdAndDeletedAtIsNull(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        if (!user.isPremium()) {
            throw new PremiumRequiredException();
        }
    }
}
