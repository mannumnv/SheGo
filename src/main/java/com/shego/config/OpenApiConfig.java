package com.shego.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    private static final String JWT_SECURITY_SCHEME = "bearerAuth";

    @Bean
    OpenAPI sheGoOpenApi() {
        return new OpenAPI()
                .components(new Components()
                        .addSecuritySchemes(JWT_SECURITY_SCHEME, new SecurityScheme()
                                .name(JWT_SECURITY_SCHEME)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("JWT access token from /api/auth/login. Paste the token in Swagger Authorize; Swagger sends it as a Bearer token.")))
                .addSecurityItem(new SecurityRequirement().addList(JWT_SECURITY_SCHEME))
                .info(new Info()
                        .title("SheGo API")
                        .version("0.1.0")
                        .description("Women-first SCOOTY and BIKE ride booking APIs with rider/driver eligibility verification."));
    }
}
