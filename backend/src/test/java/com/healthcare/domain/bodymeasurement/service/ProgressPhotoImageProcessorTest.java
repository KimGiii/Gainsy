package com.healthcare.domain.bodymeasurement.service;

import com.healthcare.common.exception.ValidationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("ProgressPhotoImageProcessor 단위 테스트")
class ProgressPhotoImageProcessorTest {

    private final ProgressPhotoImageProcessor processor = new ProgressPhotoImageProcessor();

    @Test
    @DisplayName("원본 이미지를 재인코딩하고 3가지 썸네일을 생성한다")
    void process_createsStrippedOriginalAndThumbnails() throws Exception {
        byte[] original = sampleImage(1_200, 600, "jpg");

        ProgressPhotoImageProcessor.ProcessedImageSet result = processor.process(
                original,
                "image/jpeg",
                "progress-photos/1/photo.jpg"
        );

        assertThat(result.strippedOriginal()).isNotEmpty();
        assertThat(result.thumbnail150().storageKey()).isEqualTo("progress-photos/1/photo_thumb_150.jpg");
        assertThat(result.thumbnail400().storageKey()).isEqualTo("progress-photos/1/photo_thumb_400.jpg");
        assertThat(result.thumbnail800().storageKey()).isEqualTo("progress-photos/1/photo_thumb_800.jpg");

        assertLongestSide(result.thumbnail150().bytes(), 150);
        assertLongestSide(result.thumbnail400().bytes(), 400);
        assertLongestSide(result.thumbnail800().bytes(), 800);
    }

    @Test
    @DisplayName("이미지로 읽을 수 없는 바이트면 ValidationException이 발생한다")
    void process_withInvalidBytes_throwsValidationException() {
        assertThatThrownBy(() -> processor.process(new byte[]{1, 2, 3}, "image/jpeg", "progress-photos/1/photo.jpg"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("이미지 파일");
    }

    private byte[] sampleImage(int width, int height, String format) throws Exception {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = image.createGraphics();
        try {
            graphics.setColor(Color.GREEN);
            graphics.fillRect(0, 0, width, height);
        } finally {
            graphics.dispose();
        }

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            ImageIO.write(image, format, out);
            return out.toByteArray();
        }
    }

    private void assertLongestSide(byte[] bytes, int expectedMaxSide) throws Exception {
        BufferedImage image = ImageIO.read(new ByteArrayInputStream(bytes));
        assertThat(image).isNotNull();
        assertThat(Math.max(image.getWidth(), image.getHeight())).isEqualTo(expectedMaxSide);
    }
}
