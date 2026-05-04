package com.healthcare.common.notification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.scheduling.enabled", havingValue = "true", matchIfMissing = true)
public class WeeklyNotificationScheduler {

    private final NotificationService notificationService;

    // 매주 월요일 오전 9시 (KST = UTC+9)
    @Scheduled(cron = "0 0 0 * * MON", zone = "UTC")
    public void sendWeeklySummaries() {
        log.info("[Scheduler] Weekly summary notification triggered");
        try {
            notificationService.sendWeeklySummaryToAll();
        } catch (Exception e) {
            log.error("[Scheduler] Weekly summary failed: {}", e.getMessage(), e);
        }
    }
}
