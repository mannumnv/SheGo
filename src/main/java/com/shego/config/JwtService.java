package com.shego.config;

import com.shego.user.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Map;

@Service
public class JwtService {
    private final SecretKey key;
    private final long accessMinutes;
    private final long refreshDays;

    public JwtService(@Value("${shego.security.jwt-secret}") String secret,
                      @Value("${shego.security.access-token-minutes}") long accessMinutes,
                      @Value("${shego.security.refresh-token-days}") long refreshDays) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessMinutes = accessMinutes;
        this.refreshDays = refreshDays;
    }

    public String accessToken(User user) {
        return token(user, Instant.now().plusSeconds(accessMinutes * 60), Map.of("type", "access"));
    }

    public String refreshToken(User user) {
        return token(user, Instant.now().plusSeconds(refreshDays * 86400), Map.of("type", "refresh"));
    }

    public String subject(String token) {
        return claims(token).getSubject();
    }

    public boolean valid(String token) {
        claims(token);
        return true;
    }

    private String token(User user, Instant expiry, Map<String, Object> claims) {
        return Jwts.builder()
                .claims(claims)
                .subject(user.getMobileNumber())
                .issuedAt(new Date())
                .expiration(Date.from(expiry))
                .signWith(key)
                .compact();
    }

    private Claims claims(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }
}
