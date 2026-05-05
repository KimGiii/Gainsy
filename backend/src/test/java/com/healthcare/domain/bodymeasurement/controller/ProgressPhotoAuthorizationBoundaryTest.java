package com.healthcare.domain.bodymeasurement.controller;

import com.healthcare.common.config.SecurityConfig;
import com.healthcare.common.exception.UnauthorizedException;
import com.healthcare.domain.bodymeasurement.service.ProgressPhotoService;
import com.healthcare.security.CustomUserDetailsService;
import com.healthcare.security.JwtAuthenticationFilter;
import com.healthcare.security.JwtTokenProvider;
import com.healthcare.security.RestAccessDeniedHandler;
import com.healthcare.security.RestAuthenticationEntryPoint;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import org.junit.jupiter.api.function.Executable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.RequestBuilder;

import java.util.stream.Stream;

import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.doThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ProgressPhotoController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
@DisplayName("진행 사진 도메인 권한 경계 테스트")
class ProgressPhotoAuthorizationBoundaryTest {

    private static final Long ATTACKER_ID = 2L;
    private static final Long PHOTO_ID = 100L;
    private static final String ATTACKER_TOKEN = "attacker.jwt.token";

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProgressPhotoService progressPhotoService;

    @MockBean
    private JwtTokenProvider jwtTokenProvider;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @BeforeEach
    void setUp() {
        UserDetails attackerDetails = User.withUsername(String.valueOf(ATTACKER_ID))
                .password("encoded")
                .authorities("ROLE_USER")
                .build();
        given(jwtTokenProvider.validateToken(ATTACKER_TOKEN)).willReturn(true);
        given(jwtTokenProvider.getUserId(ATTACKER_TOKEN)).willReturn(ATTACKER_ID);
        given(customUserDetailsService.loadUserById(ATTACKER_ID)).willReturn(attackerDetails);
    }

    @TestFactory
    @DisplayName("진행 사진 권한 경계 시나리오")
    Stream<DynamicTest> progressPhotoAuthorizationBoundaryScenarios() {
        return Stream.of(
                new AuthorizationBoundaryScenario(
                        "다른 사용자의 진행 사진 삭제 시 401 반환",
                        delete("/api/v1/body-measurements/photos/{photoId}", PHOTO_ID)
                                .header("Authorization", "Bearer " + ATTACKER_TOKEN),
                        () -> doThrow(new UnauthorizedException("다른 사용자의 진행 사진에 접근할 수 없습니다."))
                                .when(progressPhotoService).deletePhoto(ATTACKER_ID, PHOTO_ID)),
                new AuthorizationBoundaryScenario(
                        "인증 토큰 없이 진행 사진 목록 조회 시 401 반환",
                        get("/api/v1/body-measurements/photos"),
                        () -> {
                        }),
                new AuthorizationBoundaryScenario(
                        "인증 토큰 없이 진행 사진 업로드 URL 생성 시 401 반환",
                        post("/api/v1/body-measurements/photos/upload-url")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "photoType": "FRONT",
                                          "fileName": "progress.jpg",
                                          "contentType": "image/jpeg",
                                          "fileSizeBytes": 1024
                                        }
                                        """),
                        () -> {
                        }),
                new AuthorizationBoundaryScenario(
                        "인증 토큰 없이 진행 사진 등록 시 401 반환",
                        post("/api/v1/body-measurements/photos")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                        {
                                          "storageKey": "progress-photos/1/2026/05/progress.jpg",
                                          "photoType": "FRONT",
                                          "capturedAt": "2026-05-05",
                                          "fileSizeBytes": 1024,
                                          "contentType": "image/jpeg"
                                        }
                                        """),
                        () -> {
                        })
        ).map(scenario -> DynamicTest.dynamicTest(scenario.displayName(), () -> {
            scenario.stub().execute();
            mockMvc.perform(scenario.request())
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
        }));
    }

    private record AuthorizationBoundaryScenario(
            String displayName,
            RequestBuilder request,
            Executable stub
    ) {
    }
}
