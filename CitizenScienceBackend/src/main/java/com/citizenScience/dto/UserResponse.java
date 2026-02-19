package com.citizenScience.dto;

import com.citizenScience.entities.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Data Transfer Object for user information responses.
 * Contains user details without sensitive information.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponse {
    private UUID id;
    private String nome;
    private String cognome;
    private String email;
    private String ruolo;

    /**
     * Creates a UserResponse from a User entity.
     * 
     * @param user the user entity
     * @return UserResponse instance
     */
    public static UserResponse from(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .nome(user.getNome())
                .cognome(user.getCognome())
                .email(user.getEmail())
                .ruolo(user.getRuolo())
                .build();
    }
}
