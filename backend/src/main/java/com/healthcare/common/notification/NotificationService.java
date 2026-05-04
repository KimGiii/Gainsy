package com.healthcare.common.notification;

import com.healthcare.domain.insights.service.InsightsService;
import com.healthcare.domain.user.entity.User;
import com.healthcare.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    @Transactional
    public void sendWeeklySummaryToAll() {
        Instant cutoff = Instant.now().minus(6, ChronoUnit.DAYS);
        int sent = 0, skipped = 0;

        for (User user : userRepository.findAllWithFcmToken()) {
            if (notificationLogRepository.existsByUserIdAndTypeAndSentAtAfter(
                    user.getId(), NotificationType.WEEKLY_SUMMARY, cutoff)) {
                skipped++;
                continue;
            }

            sendWeeklySummary(user);
            sent++;
        }

        log.info("[Notification] Weekly summary — sent={} skipped={}", sent, skipped);
    }

    private void sendWeeklySummary(User user) {
        var summary = insightsService.getWeeklySummary(user.getId(), 0);

        String title = "이번 주 건강 요약";
        String body = buildWeeklySummaryBody(summary.getExerciseSessionCount(),
                summary.getTotalExerciseMinutes(), summary.getAvgDailyCalories());

        FcmService.FcmResult result = fcmService.send(
                user.getFcmToken(), title, body,
                Map.of("type", NotificationType.WEEKLY_SUMMARY,
                        "weekStart", summary.getWeekStart().toString()));

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
