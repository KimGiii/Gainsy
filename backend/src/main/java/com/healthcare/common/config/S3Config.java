package com.healthcare.common.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.NoSuchBucketException;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import java.net.URI;

@Slf4j
@Configuration
public class S3Config {

    @Bean
    public S3Client s3Client(
            @Value("${app.s3.region}") String region,
            @Value("${app.s3.endpoint:}") String endpoint,
            @Value("${app.s3.path-style-access:false}") boolean pathStyleAccess,
            @Value("${app.s3.access-key:}") String accessKey,
            @Value("${app.s3.secret-key:}") String secretKey) {
        var builder = S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(resolveCredentials(accessKey, secretKey))
                .serviceConfiguration(S3Configuration.builder()
                        .pathStyleAccessEnabled(pathStyleAccess)
                        .build());

        if (StringUtils.hasText(endpoint)) {
            builder.endpointOverride(URI.create(endpoint));
        }

        return builder.build();
    }

    @Bean
    public S3Presigner s3Presigner(
            @Value("${app.s3.region}") String region,
            @Value("${app.s3.endpoint:}") String endpoint,
            @Value("${app.s3.public-endpoint:}") String publicEndpoint,
            @Value("${app.s3.path-style-access:false}") boolean pathStyleAccess,
            @Value("${app.s3.access-key:}") String accessKey,
            @Value("${app.s3.secret-key:}") String secretKey) {
        var builder = S3Presigner.builder()
                .region(Region.of(region))
                .credentialsProvider(resolveCredentials(accessKey, secretKey))
                .serviceConfiguration(S3Configuration.builder()
                        .pathStyleAccessEnabled(pathStyleAccess)
                        .build());

        // public-endpoint가 설정돼 있으면 pre-signed URL 생성에 사용 (클라이언트가 직접 접근 가능한 주소)
        // 없으면 endpoint를 fallback으로 사용
        String presignerEndpoint = StringUtils.hasText(publicEndpoint) ? publicEndpoint : endpoint;
        if (StringUtils.hasText(presignerEndpoint)) {
            builder.endpointOverride(URI.create(presignerEndpoint));
        }

        return builder.build();
    }

    @Bean
    public Boolean ensureBucketExists(S3Client s3Client, @Value("${app.s3.bucket}") String bucket) {
        try {
            s3Client.headBucket(HeadBucketRequest.builder().bucket(bucket).build());
        } catch (NoSuchBucketException e) {
            log.info("S3 bucket '{}' not found, creating...", bucket);
            s3Client.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
            log.info("S3 bucket '{}' created.", bucket);
        } catch (Exception e) {
            log.warn("Could not verify S3 bucket '{}': {}", bucket, e.getMessage());
        }
        return Boolean.TRUE;
    }

    private AwsCredentialsProvider resolveCredentials(String accessKey, String secretKey) {
        if (StringUtils.hasText(accessKey) && StringUtils.hasText(secretKey)) {
            return StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey));
        }
        return DefaultCredentialsProvider.create();
    }
}
