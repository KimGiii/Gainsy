package com.healthcare.domain.goals.scheduler;

import com.healthcare.domain.goals.service.GoalService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 활성 목표의 주간 체크포인트를 매일 한 번 채워 넣는다.
 *
 * <p>이전에는 {@code GoalService.getGoalProgress}가 조회 시점에 체크포인트를 upsert했으나,
 * 동시 GET 요청에서 중복 INSERT 위험과 GET 경로 DB 쓰기 문제(H-3)가 있어 분리했다.
 *
 * <p>한 목표의 실패가 다른 목표에 영향을 주지 않도록 목표별로 try/catch + 별도 트랜잭션.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.scheduling.enabled", havingValue = "true", matchIfMissing = true)
public class GoalCheckpointScheduler {

    private final GoalService goalService;

    // 매일 KST 03:00 (UTC 18:00 전날) — 사용자가 적은 시간대.
    @Scheduled(cron = "0 0 3 * * *", zone = "Asia/Seoul")
    public void maintainCheckpoints() {
        List<Long> goalIds = goalService.findActiveGoalIds();
        log.info("[Scheduler] Goal checkpoint maintenance start — activeGoals={}", goalIds.size());

        int processed = 0;
        int failed = 0;
        for (Long goalId : goalIds) {
            try {
                goalService.maintainCheckpointsForGoal(goalId);
                processed++;
            } catch (Exception e) {
                failed++;
                log.warn("[Scheduler] Checkpoint maintenance failed for goalId={}: {}",
                        goalId, e.getMessage());
            }
        }
        log.info("[Scheduler] Goal checkpoint maintenance done — processed={} failed={}",
                processed, failed);
    }
}
