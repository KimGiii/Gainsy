package com.healthcare.support;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;

import java.util.Collections;

public final class SecurityTestSupport {

    private SecurityTestSupport() {}

    public static void authenticate(Long userId) {
        var principal = new User(userId.toString(), "", Collections.emptyList());
        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(principal, null, Collections.emptyList())
        );
    }

    public static void clear() {
        SecurityContextHolder.clearContext();
    }
}
