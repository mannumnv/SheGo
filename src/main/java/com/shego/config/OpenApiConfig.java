package com.shego.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    OpenAPI sheGoOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("SheGo API")
                        .version("0.1.0")
                        .description("Women-first SCOOTY and BIKE ride booking APIs with rider/driver eligibility verification."));
    }
}
