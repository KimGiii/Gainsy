package com.healthcare.domain.goals.controller;

import com.healthcare.common.config.SecurityConfig;
import com.healthcare.common.exception.UnauthorizedException;
import com.healthcare.domain.goals.service.GoalService;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = GoalController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
@DisplayName("목표 도메인 권한 경계 테스트")
class GoalAuthorizationBoundaryTest {

    private static final long ATTACKER_ID = 2L;
    private static final long GOAL_ID = 100L;
    private static final String ATTACKER_TOKEN = "attacker.jwt.token";

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GoalService goalService;

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
    @DisplayName("목표 권한 경계 시나리오")
    Stream<DynamicTest> goalAuthorizationBoundaryScenarios() {
        return Stream.of(
                new AuthorizationBoundaryScenario(
                        "다른 사용자의 목표 단건 조회 시 401 반환",
                        get("/api/v1/goals/{id}", GOAL_ID)
                                .header("Authorization", "Bearer " + ATTACKER_TOKEN),
                        () -> given(goalService.getGoalById(ATTACKER_ID, GOAL_ID))
                                .willThrow(new UnauthorizedException("다른 사용자의 목표에 접근할 수 없습니다.")),
                        true),
                new AuthorizationBoundaryScenario(
                        "다른 사용자의 목표 수정 시 401 반환",
                        patch("/api/v1/goals/{id}", GOAL_ID)
                                .header("Authorization", "Bearer " + ATTACKER_TOKEN)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"targetWeightKg\": 68.0}"),
                        () -> given(goalService.updateGoal(org.mockito.ArgumentMatchers.eq(ATTACKER_ID), org.mockito.ArgumentMatchers.eq(GOAL_ID), org.mockito.ArgumentMatchers.any()))
                                .willThrow(new UnauthorizedException("다른 사용자의 목표에 접근할 수 없습니다.")),
                        true),
                new AuthorizationBoundaryScenario(
                        "다른 사용자의 목표 진행률 조회 시 401 반환",
                        get("/api/v1/goals/{id}/progress", GOAL_ID)
                                .header("Authorization", "Bearer " + ATTACKER_TOKEN),
                        () -> given(goalService.getGoalProgress(ATTACKER_ID, GOAL_ID))
                                .willThrow(new UnauthorizedException("다른 사용자의 목표에 접근할 수 없습니다.")),
                        true),
                new AuthorizationBoundaryScenario(
                        "다른 사용자의 목표 포기 시 401 반환",
                        delete("/api/v1/goals/{id}", GOAL_ID)
                                .header("Authorization", "Bearer " + ATTACKER_TOKEN),
                        () -> doThrow(new UnauthorizedException("다른 사용자의 목표에 접근할 수 없습니다."))
                                .when(goalService).abandonGoal(ATTACKER_ID, GOAL_ID),
                        true),
                new AuthorizationBoundaryScenario(
                        "Authorization 헤더 없이 목표 조회 시 401 반환",
                        get("/api/v1/goals/{id}", GOAL_ID),
                        () -> {
                        },
                        true),
                new AuthorizationBoundaryScenario(
                        "Bearer 접두사 없는 토큰으로 목표 조회 시 401 반환",
                        get("/api/v1/goals/{id}", GOAL_ID)
                                .header("Authorization", "rawtoken"),
                        () -> {
                        },
                        false)
        ).map(scenario -> DynamicTest.dynamicTest(scenario.displayName(), () -> {
            scenario.stub().execute();
            var resultActions = mockMvc.perform(scenario.request())
                    .andExpect(status().isUnauthorized());
            if (scenario.expectUnauthorizedCode()) {
                resultActions.andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
            }
        }));
    }

    private record AuthorizationBoundaryScenario(
            String displayName,
            RequestBuilder request,
            Executable stub,
            boolean expectUnauthorizedCode
    ) {
    }
}
