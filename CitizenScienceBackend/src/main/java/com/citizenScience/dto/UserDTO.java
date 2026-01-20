package com.citizenScience.dto;

import com.citizenScience.entities.User;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDTO {
    
    // Campi identificativi
    private Long id;
    
    // Campi profilo
    private String email;
    private String username;
    
    // Campi autenticazione (solo per request)
    private String password;
    private String oldPassword;
    private String newPassword;
    
    // Campi temporali (solo per response)
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static UserDTO fromEntity(User user) {
        return UserDTO.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}