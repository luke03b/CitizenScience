package com.citizenscience.controllers;

import com.citizenscience.dto.UpdateUserRequest;
import com.citizenscience.dto.UserResponse;
import com.citizenscience.entities.User;
import com.citizenscience.services.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for user profile management.
 * 
 * Provides endpoints for authenticated users to view and update their profile information.
 * All endpoints require JWT authentication.
 * 
 * @author EcoFlora Team
 * @version 1.0
 */
@RestController
@RequestMapping("/api/users")
@Tag(name = "User Management", description = "Endpoints for managing user profiles")
public class UserController {

    private final UserService userService;

    /**
     * Constructs a new UserController with the specified UserService.
     *
     * @param userService the service handling user profile operations
     */
    public UserController(UserService userService) {
        this.userService = userService;
    }

    /**
     * Retrieves the profile of the currently authenticated user.
     *
     * @param user the authenticated user
     * @return ResponseEntity containing the user profile information
     */
    @GetMapping("/me")
    @Operation(summary = "Get current user", description = "Returns the profile information of the currently authenticated user")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved user profile"),
        @ApiResponse(responseCode = "401", description = "User not authenticated")
    })
    public ResponseEntity<UserResponse> getCurrentUser(@AuthenticationPrincipal User user) {
        UserResponse response = userService.getCurrentUser(user);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    /**
     * Updates the profile of the currently authenticated user.
     *
     * @param user the authenticated user
     * @param request the update request containing new profile information
     * @return ResponseEntity containing the updated user profile
     */
    @PutMapping("/me")
    @Operation(summary = "Update current user", description = "Updates the profile information of the currently authenticated user")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully updated user profile"),
        @ApiResponse(responseCode = "400", description = "Invalid input data"),
        @ApiResponse(responseCode = "401", description = "User not authenticated")
    })
    public ResponseEntity<UserResponse> updateCurrentUser(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody UpdateUserRequest request) {
        UserResponse response = userService.updateCurrentUser(user, request);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
}
