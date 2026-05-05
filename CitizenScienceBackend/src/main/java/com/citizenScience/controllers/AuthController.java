package com.citizenscience.controllers;

import com.citizenscience.dto.*;
import com.citizenscience.entities.User;
import com.citizenscience.services.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * REST controller for authentication operations.
 * 
 * Handles user registration, login, and password management with JWT-based authentication.
 * All authentication endpoints are publicly accessible except password change.
 * 
 * @author EcoFlora Team
 * @version 1.0
 */
@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "Endpoints for user registration, login, and password management")
public class AuthController {

    private final AuthService authService;

    /**
     * Constructs a new AuthController with the specified AuthService.
     *
     * @param authService the service handling authentication logic
     */
    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /**
     * Registers a new user account.
     *
     * @param request the registration request containing user details
     * @return ResponseEntity containing the authentication response with JWT token
     */
    @PostMapping("/register")
    @Operation(summary = "Register a new user", description = "Creates a new user account and returns authentication token")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "User successfully registered"),
        @ApiResponse(responseCode = "400", description = "Invalid input or user already exists")
    })
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Authenticates a user and returns a JWT token.
     *
     * @param request the login request containing email and password
     * @return ResponseEntity containing the authentication response with JWT token
     */
    @PostMapping("/login")
    @Operation(summary = "User login", description = "Authenticates a user and returns a JWT token")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully authenticated"),
        @ApiResponse(responseCode = "401", description = "Invalid credentials")
    })
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    /**
     * Changes the password for the currently authenticated user.
     *
     * @param user the authenticated user
     * @param request the change password request containing old and new passwords
     * @return ResponseEntity containing a success message
     */
    @PutMapping("/change-password")
    @Operation(summary = "Change password", description = "Changes the password for the authenticated user")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Password successfully changed"),
        @ApiResponse(responseCode = "400", description = "Invalid password or validation error"),
        @ApiResponse(responseCode = "401", description = "User not authenticated")
    })
    public ResponseEntity<Map<String, String>> changePassword(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ChangePasswordRequest request) {
        String message = authService.changePassword(user, request);
        return new ResponseEntity<>(Map.of("message", message), HttpStatus.OK);
    }
}
