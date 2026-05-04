package com.healthcare.common.notification;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class FcmServiceTest {

    private FcmService fcmService;

    @BeforeEach
    void setUp() {
        @SuppressWarnings("unchecked")
        ObjectProvider<com.google.firebase.FirebaseApp> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(null); // mock mode
        fcmService = new FcmService(provider);
    }

    @Test
    @DisplayName("blank token → SKIPPED result")
    void send_blankToken_returnsSkipped() {
        var result = fcmService.send("", "title", "body", null);
        assertThat(result.status()).isEqualTo(FcmService.FcmResult.Status.SKIPPED);
        assertThat(result.isSent()).isFalse();
    }

    @Test
    @DisplayName("null token → SKIPPED result")
    void send_nullToken_returnsSkipped() {
        var result = fcmService.send(null, "title", "body", null);
        assertThat(result.status()).isEqualTo(FcmService.FcmResult.Status.SKIPPED);
    }

    @Test
    @DisplayName("mock mode (no FirebaseApp) → MOCKED result")
    void send_mockMode_returnsMocked() {
        var result = fcmService.send("valid-token-123", "주간 요약", "운동 3회", null);
        assertThat(result.status()).isEqualTo(FcmService.FcmResult.Status.MOCKED);
        assertThat(result.isSent()).isTrue();
    }
}
