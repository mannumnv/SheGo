package com.shego.config;

import com.shego.common.AccountStatus;
import com.shego.common.Role;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class DefaultAdminBootstrap implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(DefaultAdminBootstrap.class);

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final String adminFullName;
    private final String adminMobile;
    private final String adminEmail;
    private final String adminPassword;

    public DefaultAdminBootstrap(
            UserRepository users,
            PasswordEncoder passwordEncoder,
            @Value("${ADMIN_FULL_NAME:SheGo Local Admin}") String adminFullName,
            @Value("${ADMIN_MOBILE:}") String adminMobile,
            @Value("${ADMIN_EMAIL:}") String adminEmail,
            @Value("${ADMIN_PASSWORD:}") String adminPassword) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.adminFullName = adminFullName;
        this.adminMobile = adminMobile;
        this.adminEmail = adminEmail;
        this.adminPassword = adminPassword;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (users.existsAdminUser()) {
            return;
        }
        Map<String, String> dotenv = loadDotenv();
        String resolvedFullName = resolve("ADMIN_FULL_NAME", adminFullName, dotenv).orElse("SheGo Local Admin");
        String resolvedMobile = resolve("ADMIN_MOBILE", adminMobile, dotenv).orElse(null);
        String resolvedEmail = resolve("ADMIN_EMAIL", adminEmail, dotenv).orElse(null);
        String resolvedPassword = resolve("ADMIN_PASSWORD", adminPassword, dotenv).orElse(null);

        if (!StringUtils.hasText(resolvedMobile) || !StringUtils.hasText(resolvedPassword)) {
            log.warn("No ADMIN user exists, but ADMIN_MOBILE or ADMIN_PASSWORD is missing. Skipping default admin bootstrap. Create .env from .env.example or set environment variables.");
            return;
        }

        User admin = users.findByMobileNumber(resolvedMobile).orElseGet(User::new);
        admin.setFullName(StringUtils.hasText(resolvedFullName) ? resolvedFullName : "SheGo Local Admin");
        admin.setMobileNumber(resolvedMobile);
        if (StringUtils.hasText(resolvedEmail)) {
            admin.setEmail(resolvedEmail);
        }
        admin.setPasswordHash(passwordEncoder.encode(resolvedPassword));
        admin.setAccountStatus(AccountStatus.ACTIVE);
        admin.setFemaleVerified(true);

        Set<Role> roles = admin.getRoles() == null ? new HashSet<>() : new HashSet<>(admin.getRoles());
        roles.add(Role.ADMIN);
        admin.setRoles(roles);

        User saved = users.save(admin);
        log.info("Default SheGo admin bootstrapped for local development: userId={}, mobile={}", saved.getId(), saved.getMobileNumber());
    }

    private Optional<String> resolve(String key, String springValue, Map<String, String> dotenv) {
        if (StringUtils.hasText(springValue)) {
            return Optional.of(springValue);
        }
        return Optional.ofNullable(dotenv.get(key)).filter(StringUtils::hasText);
    }

    private Map<String, String> loadDotenv() {
        Path path = Path.of(".env");
        if (!Files.isRegularFile(path)) {
            return Map.of();
        }
        try {
            return Files.readAllLines(path).stream()
                    .map(String::trim)
                    .filter(line -> !line.isBlank() && !line.startsWith("#") && line.contains("="))
                    .map(line -> line.split("=", 2))
                    .collect(Collectors.toMap(parts -> parts[0].trim(), parts -> clean(parts[1].trim()), (left, right) -> right));
        } catch (IOException e) {
            log.warn("Unable to read .env for default admin bootstrap: {}", e.getMessage());
            return Map.of();
        }
    }

    private String clean(String value) {
        if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
            return value.substring(1, value.length() - 1);
        }
        return value;
    }
}
