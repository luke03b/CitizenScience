package com.citizenscience.dto;

import com.citizenscience.entities.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object for authentication responses.
 * Contains JWT token and user information.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {
    private String token;
    private UserResponse user;

    /**
     * Creates an AuthResponse from token and user entity.
     * 
     * @param token the JWT token
     * @param user the user entity
     * @return AuthResponse instance
     */
    public static AuthResponse from(String token, User user) {
        return AuthResponse.builder()
                .token(token)
                .user(UserResponse.from(user))
                .build();
    }
}
