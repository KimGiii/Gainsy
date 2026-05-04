package com.healthcare.common.notification;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
public class FcmService {

    private final ObjectProvider<FirebaseApp> firebaseAppProvider;

    public FcmService(ObjectProvider<FirebaseApp> firebaseAppProvider) {
        this.firebaseAppProvider = firebaseAppProvider;
    }

    public FcmResult send(String fcmToken, String title, String body, Map<String, String> data) {
        if (fcmToken == null || fcmToken.isBlank()) {
            return FcmResult.skipped("FCM token is blank");
        }

        FirebaseApp app = firebaseAppProvider.getIfAvailable();
        if (app == null) {
            log.info("[FCM] Mock send — title='{}' token={}...", title,
                    fcmToken.substring(0, Math.min(10, fcmToken.length())));
            return FcmResult.mocked();
        }

        try {
            Message.Builder builder = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build());

            if (data != null && !data.isEmpty()) {
                builder.putAllData(data);
            }

            String messageId = FirebaseMessaging.getInstance(app).send(builder.build());
            log.info("[FCM] Sent messageId={}", messageId);
            return FcmResult.success(messageId);
        } catch (FirebaseMessagingException e) {
            log.error("[FCM] Send failed: {}", e.getMessage());
            return FcmResult.failed(e.getMessage());
        }
    }

    public record FcmResult(Status status, String detail) {
        public enum Status { SUCCESS, MOCKED, SKIPPED, FAILED }

        static FcmResult success(String id)   { return new FcmResult(Status.SUCCESS, id); }
        static FcmResult mocked()             { return new FcmResult(Status.MOCKED,  null); }
        static FcmResult skipped(String msg)  { return new FcmResult(Status.SKIPPED, msg); }
        static FcmResult failed(String msg)   { return new FcmResult(Status.FAILED,  msg); }

        public boolean isSent() {
            return status == Status.SUCCESS || status == Status.MOCKED;
        }
    }
}
