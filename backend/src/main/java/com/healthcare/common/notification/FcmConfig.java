package com.healthcare.common.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Slf4j
@Configuration
@EnableConfigurationProperties(FcmProperties.class)
public class FcmConfig {

    @Bean
    public FirebaseApp firebaseApp(FcmProperties props) throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.getInstance();
        }

        if (props.mock()) {
            log.info("[FCM] Mock mode — Firebase not initialized");
            return null;
        }

        String path = props.credentialsPath();
        if (path == null || path.isBlank()) {
            log.warn("[FCM] credentials-path not set — FCM disabled");
            return null;
        }

        try (InputStream is = new FileInputStream(path)) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(is))
                    .build();
            FirebaseApp app = FirebaseApp.initializeApp(options);
            log.info("[FCM] FirebaseApp initialized from {}", path);
            return app;
        } catch (IOException e) {
            log.error("[FCM] Failed to load credentials from {}: {}", path, e.getMessage());
            return null;
        }
    }
}
