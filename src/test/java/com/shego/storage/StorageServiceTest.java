package com.shego.storage;

import com.shego.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static com.shego.testsupport.TestDoubles.proxy;

class StorageServiceTest {
    @Test
    void uploadIntentReturnsServiceUnavailableWhenS3CredentialsAreMissing() {
        S3Presigner presigner = proxy(S3Presigner.class, java.util.Map.of(
                "presignPutObject", (java.util.function.Function<Object[], Object>) args -> {
                    throw SdkClientException.builder().message("missing credentials").build();
                }
        ));
        StorageService service = new StorageService("shego-dev-private", presigner);

        assertThatThrownBy(() -> service.uploadIntent(new StorageDtos.UploadIntentRequest("kyc", "aadhaar.png", "image/png")))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("S3 storage is not configured for this environment");
                    assertThat(exception.status()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
    }
}
