package com.citizenScience.controllers;

import com.citizenScience.dto.ApiResponse;
import com.citizenScience.dto.UserDTO;
import com.citizenScience.entities.User;
import com.citizenScience.services.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody UserDTO request) {
        try {
            User user = userService.register(
                    request.getEmail(),
                    request.getPassword(),
                    request.getUsername()
            );
            return ResponseEntity.ok(UserDTO.fromEntity(user));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Registrazione fallita", e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody UserDTO request) {
        try {
            User user = userService.authenticate(request.getEmail(), request.getPassword());
            return ResponseEntity.ok(UserDTO.fromEntity(user));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Login fallito", e.getMessage()));
        }
    }
}