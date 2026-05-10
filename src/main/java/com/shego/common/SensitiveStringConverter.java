package com.shego.common;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;

@Converter
public class SensitiveStringConverter implements AttributeConverter<String, String> {
    private static final String PREFIX = "ENC:";
    private static final int GCM_TAG_BITS = 128;
    private static final int IV_BYTES = 12;
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final SecretKeySpec KEY = key();

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null || attribute.isBlank()) {
            return attribute;
        }
        try {
            byte[] iv = new byte[IV_BYTES];
            RANDOM.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, KEY, new GCMParameterSpec(GCM_TAG_BITS, iv));
            byte[] encrypted = cipher.doFinal(attribute.getBytes(StandardCharsets.UTF_8));
            byte[] payload = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, payload, 0, iv.length);
            System.arraycopy(encrypted, 0, payload, iv.length, encrypted.length);
            return PREFIX + Base64.getEncoder().encodeToString(payload);
        } catch (Exception e) {
            throw new IllegalStateException("Unable to encrypt sensitive data", e);
        }
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return dbData;
        }
        try {
            if (dbData.startsWith(PREFIX)) {
                byte[] payload = Base64.getDecoder().decode(dbData.substring(PREFIX.length()));
                byte[] iv = Arrays.copyOfRange(payload, 0, IV_BYTES);
                byte[] encrypted = Arrays.copyOfRange(payload, IV_BYTES, payload.length);
                Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
                cipher.init(Cipher.DECRYPT_MODE, KEY, new GCMParameterSpec(GCM_TAG_BITS, iv));
                return new String(cipher.doFinal(encrypted), StandardCharsets.UTF_8);
            }
            try {
                return new String(Base64.getDecoder().decode(dbData), StandardCharsets.UTF_8);
            } catch (IllegalArgumentException ignored) {
                return dbData;
            }
        } catch (Exception e) {
            throw new IllegalStateException("Unable to decrypt sensitive data", e);
        }
    }

    private static SecretKeySpec key() {
        try {
            String source = System.getenv().getOrDefault("SHEGO_DATA_ENCRYPTION_KEY",
                    "change-this-local-data-encryption-key");
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(source.getBytes(StandardCharsets.UTF_8));
            return new SecretKeySpec(digest, "AES");
        } catch (Exception e) {
            throw new IllegalStateException("Unable to initialize sensitive data encryption", e);
        }
    }
}
