package com.healthcare.common.notification;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;

public interface NotificationLogRepository extends JpaRepository<NotificationLog, Long> {

    boolean existsByUserIdAndTypeAndSentAtAfter(Long userId, String type, Instant after);
}
