package com.healthcare.common.notification;

import com.healthcare.domain.insights.service.InsightsService;
import com.healthcare.domain.user.entity.User;
import com.healthcare.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final FcmService fcmService;
    private final NotificationLogRepository notificationLogRepository;
    private final UserRepository userRepository;
    private final InsightsService insightsService;

    /**
     * 전체 사용자에게 주간 요약 발송.
     *
     * <p>H-4 대응: 단일 대형 {@code @Transactional} 안에서 N명의 외부 HTTP(FCM) 호출이
     * 일어나면 한 건의 FCM 타임아웃이 전체 트랜잭션을 막거나 롤백시킨다. 따라서:
     * <ul>
     *   <li>외부 루프는 트랜잭션 없이 실행한다.</li>
     *   <li>FCM 전송은 트랜잭션 밖에서 수행한다.</li>
     *   <li>{@code NotificationLog} 저장만 짧은 트랜잭션(JPA 기본 동작)으로 처리한다.</li>
     *   <li>한 사용자 처리 중 예외가 발생해도 다음 사용자는 계속 진행한다.</li>
     * </ul>
     */
    public void sendWeeklySummaryToAll() {
        Instant cutoff = Instant.now().minus(6, ChronoUnit.DAYS);
        int sent = 0, skipped = 0, failed = 0;

        for (User user : userRepository.findAllWithFcmToken()) {
            if (notificationLogRepository.existsByUserIdAndTypeAndSentAtAfter(
                    user.getId(), NotificationType.WEEKLY_SUMMARY, cutoff)) {
                skipped++;
                continue;
            }

            try {
                sendWeeklySummary(user);
                sent++;
            } catch (Exception e) {
                failed++;
                log.warn("[Notification] Weekly summary failed userId={}: {}",
                        user.getId(), e.getMessage());
            }
        }

        log.info("[Notification] Weekly summary — sent={} skipped={} failed={}", sent, skipped, failed);
    }

    private void sendWeeklySummary(User user) {
        var summary = insightsService.getWeeklySummary(user.getId(), 0);

        String title = "이번 주 건강 요약";
        String body = buildWeeklySummaryBody(summary.getExerciseSessionCount(),
                summary.getTotalExerciseMinutes(), summary.getAvgDailyCalories());

        // FCM 호출은 트랜잭션 밖에서 — 외부 HTTP 호출이 DB 트랜잭션을 점유하지 않도록.
        FcmService.FcmResult result = fcmService.send(
                user.getFcmToken(), title, body,
                Map.of("type", NotificationType.WEEKLY_SUMMARY,
                        "weekStart", summary.getWeekStart().toString()));

        // Spring Data JPA의 save()는 자체 트랜잭션을 시작 — 외부 트랜잭션이 필요 없다.
        NotificationLog logEntry = NotificationLog.builder()
                .userId(user.getId())
                .type(NotificationType.WEEKLY_SUMMARY)
                .title(title)
                .body(body)
                .status(result.isSent() ? "SENT" : "FAILED")
                .fcmToken(user.getFcmToken())
                .errorMessage(result.isSent() ? null : result.detail())
                .build();
        notificationLogRepository.save(logEntry);
    }

    private String buildWeeklySummaryBody(int exerciseCount, int exerciseMinutes,
                                           Double avgCalories) {
        StringBuilder sb = new StringBuilder();

        if (exerciseCount > 0) {
            sb.append("운동 ").append(exerciseCount).append("회 (")
              .append(exerciseMinutes).append("분)");
        } else {
            sb.append("이번 주 운동 기록이 없어요");
        }

        if (avgCalories != null && avgCalories > 0) {
            sb.append(" · 평균 ").append(Math.round(avgCalories)).append("kcal");
        }

        return sb.toString();
    }

    public interface NotificationType {
        String WEEKLY_SUMMARY = "WEEKLY_SUMMARY";
    }
}
