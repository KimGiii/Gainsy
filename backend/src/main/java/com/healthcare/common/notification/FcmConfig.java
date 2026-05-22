package com.healthcare.common.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

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

        Path credentialsPath = Path.of(path);
        if (!Files.isRegularFile(credentialsPath)) {
            log.error("[FCM] credentials-path must point to a JSON file, but {} is not a regular file", path);
            return null;
        }
        if (!Files.isReadable(credentialsPath)) {
            log.error("[FCM] credentials-path is not readable: {}", path);
            return null;
        }

        try (InputStream is = Files.newInputStream(credentialsPath)) {
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
