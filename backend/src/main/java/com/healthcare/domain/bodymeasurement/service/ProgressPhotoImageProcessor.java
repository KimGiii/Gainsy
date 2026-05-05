package com.healthcare.domain.bodymeasurement.service;

import com.healthcare.common.exception.ValidationException;
import org.springframework.stereotype.Component;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Map;

@Component
public class ProgressPhotoImageProcessor {

    private static final Map<Integer, String> THUMBNAIL_SUFFIXES = Map.of(
            150, "_thumb_150",
            400, "_thumb_400",
            800, "_thumb_800"
    );

    public ProcessedImageSet process(byte[] originalBytes, String contentType, String storageKey) {
        BufferedImage source = readImage(originalBytes);
        String format = formatFor(contentType);
        byte[] strippedOriginal = encode(source, format);

        return new ProcessedImageSet(
                strippedOriginal,
                new Thumbnail(thumbnailKey(storageKey, 150), encode(resize(source, 150), format)),
                new Thumbnail(thumbnailKey(storageKey, 400), encode(resize(source, 400), format)),
                new Thumbnail(thumbnailKey(storageKey, 800), encode(resize(source, 800), format))
        );
    }

    private BufferedImage readImage(byte[] bytes) {
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(bytes));
            if (image == null) {
                throw new ValidationException("업로드된 이미지 파일을 읽을 수 없습니다.");
            }
            return image;
        } catch (IOException e) {
            throw new ValidationException("업로드된 이미지 파일을 읽을 수 없습니다.");
        }
    }

    private BufferedImage resize(BufferedImage source, int maxSide) {
        int sourceWidth = source.getWidth();
        int sourceHeight = source.getHeight();
        int longest = Math.max(sourceWidth, sourceHeight);
        if (longest <= maxSide) {
            return copyForEncoding(source);
        }

        double scale = (double) maxSide / longest;
        int targetWidth = Math.max(1, (int) Math.round(sourceWidth * scale));
        int targetHeight = Math.max(1, (int) Math.round(sourceHeight * scale));

        BufferedImage resized = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = resized.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            graphics.setColor(Color.WHITE);
            graphics.fillRect(0, 0, targetWidth, targetHeight);
            graphics.drawImage(source, 0, 0, targetWidth, targetHeight, null);
        } finally {
            graphics.dispose();
        }
        return resized;
    }

    private BufferedImage copyForEncoding(BufferedImage source) {
        BufferedImage copy = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = copy.createGraphics();
        try {
            graphics.setColor(Color.WHITE);
            graphics.fillRect(0, 0, copy.getWidth(), copy.getHeight());
            graphics.drawImage(source, 0, 0, null);
        } finally {
            graphics.dispose();
        }
        return copy;
    }

    private byte[] encode(BufferedImage image, String format) {
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            boolean written = ImageIO.write(copyForEncoding(image), format, output);
            if (!written) {
                throw new ValidationException("이미지 후처리에 실패했습니다.");
            }
            return output.toByteArray();
        } catch (IOException e) {
            throw new ValidationException("이미지 후처리에 실패했습니다.");
        }
    }

    private String formatFor(String contentType) {
        if ("image/png".equalsIgnoreCase(contentType)) {
            return "png";
        }
        return "jpg";
    }

    private String thumbnailKey(String storageKey, int maxSide) {
        String suffix = THUMBNAIL_SUFFIXES.get(maxSide);
        int dotIndex = storageKey.lastIndexOf('.');
        if (dotIndex < 0) {
            return storageKey + suffix;
        }
        return storageKey.substring(0, dotIndex) + suffix + storageKey.substring(dotIndex);
    }

    public record ProcessedImageSet(
            byte[] strippedOriginal,
            Thumbnail thumbnail150,
            Thumbnail thumbnail400,
            Thumbnail thumbnail800
    ) {
    }

    public record Thumbnail(String storageKey, byte[] bytes) {
    }
}
