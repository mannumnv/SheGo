package com.shego.testsupport;

import com.shego.user.User;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.Proxy;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;

public final class TestDoubles {
    private TestDoubles() {
    }

    @SuppressWarnings("unchecked")
    public static <T> T proxy(Class<T> type, Map<String, Object> handlers) {
        return (T) Proxy.newProxyInstance(type.getClassLoader(), new Class<?>[]{type}, (proxy, method, args) -> {
            Object handler = handlers.get(method.getName());
            if (handler instanceof Function<?, ?> function) {
                return ((Function<Object[], Object>) function).apply(args == null ? new Object[0] : args);
            }
            if (handler != null) {
                return handler;
            }
            return defaultValue(method.getReturnType());
        });
    }

    public static void authenticate(User user) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities()));
    }

    private static Object defaultValue(Class<?> returnType) {
        if (returnType.equals(Optional.class)) {
            return Optional.empty();
        }
        if (returnType.equals(List.class)) {
            return List.of();
        }
        if (returnType.equals(boolean.class)) {
            return false;
        }
        if (returnType.equals(long.class)) {
            return 0L;
        }
        if (returnType.equals(int.class)) {
            return 0;
        }
        return null;
    }
}
