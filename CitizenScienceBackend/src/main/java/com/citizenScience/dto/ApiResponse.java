package com.citizenScience.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiResponse {
    
    private boolean success;
    private String message;
    private String error;

    public static ApiResponse success(String message) {
        return ApiResponse.builder()
                .success(true)
                .message(message)
                .build();
    }

    public static ApiResponse error(String error, String message) {
        return ApiResponse.builder()
                .success(false)
                .error(error)
                .message(message)
                .build();
    }
}