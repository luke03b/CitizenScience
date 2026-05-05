package com.citizenscience.dto;

import lombok.*;

/**
 * Data Transfer Object for generic API responses.
 * Used for success and error messages.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiResponse {
    
    private boolean success;
    private String message;
    private String error;

    /**
     * Creates a success response.
     * 
     * @param message the success message
     * @return ApiResponse with success status
     */
    public static ApiResponse success(String message) {
        return ApiResponse.builder()
                .success(true)
                .message(message)
                .build();
    }

    /**
     * Creates an error response.
     * 
     * @param error the error type
     * @param message the error message
     * @return ApiResponse with error status
     */
    public static ApiResponse error(String error, String message) {
        return ApiResponse.builder()
                .success(false)
                .error(error)
                .message(message)
                .build();
    }
}