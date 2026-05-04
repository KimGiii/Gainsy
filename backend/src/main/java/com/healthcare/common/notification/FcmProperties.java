package com.healthcare.common.notification;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.fcm")
public record FcmProperties(
        boolean mock,
        String credentialsPath
) {
    public FcmProperties {
        if (credentialsPath == null) credentialsPath = "";
    }
}
