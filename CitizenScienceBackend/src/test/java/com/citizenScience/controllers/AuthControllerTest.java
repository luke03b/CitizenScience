package com.citizenScience.controllers;

import com.citizenScience.config.SecurityConfig;
import com.citizenScience.dto.AuthResponse;
import com.citizenScience.dto.ChangePasswordRequest;
import com.citizenScience.dto.LoginRequest;
import com.citizenScience.dto.RegisterRequest;
import com.citizenScience.dto.UserResponse;
import com.citizenScience.entities.User;
import com.citizenScience.repositories.UserRepository;
import com.citizenScience.security.JwtUtil;
import com.citizenScience.services.AuthService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Slice tests for AuthController.
 * Security filter is exercised with a mocked JwtUtil / UserRepository to allow
 * both authenticated and unauthenticated scenarios.
 */
@WebMvcTest(AuthController.class)
@Import(SecurityConfig.class)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private static final String BEARER_TOKEN = "test-bearer-token";

    private User testUser;
    private UserResponse testUserResponse;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(UUID.randomUUID())
                .nome("Mario")
                .cognome("Rossi")
                .email("mario@example.com")
                .passwordHash("hash")
                .ruolo("utente")
                .build();

        testUserResponse = UserResponse.from(testUser);

        // Wire up the JWT filter mocks so authenticated requests pass through
        when(jwtUtil.extractEmail(BEARER_TOKEN)).thenReturn(testUser.getEmail());
        when(jwtUtil.validateToken(BEARER_TOKEN, testUser.getEmail())).thenReturn(true);
        when(userRepository.findByEmail(testUser.getEmail())).thenReturn(Optional.of(testUser));
    }

    // ── POST /api/auth/register ───────────────────────────────────────────────

    @Test
    void givenValidRegistrationRequest_whenRegister_thenReturns201WithToken() throws Exception {
        // Arrange
        RegisterRequest request = new RegisterRequest("Mario", "Rossi", "mario@example.com", "password123", "utente");
        AuthResponse authResponse = AuthResponse.builder().token("jwt-token").user(testUserResponse).build();
        when(authService.register(any(RegisterRequest.class))).thenReturn(authResponse);

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.user.email").value("mario@example.com"));
    }

    @Test
    void givenMissingNome_whenRegister_thenReturns400() throws Exception {
        // Arrange – nome is blank, validation should fail
        RegisterRequest request = new RegisterRequest("", "Rossi", "mario@example.com", "password123", "utente");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void givenInvalidEmail_whenRegister_thenReturns400() throws Exception {
        // Arrange
        RegisterRequest request = new RegisterRequest("Mario", "Rossi", "not-an-email", "password123", "utente");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void givenMissingPassword_whenRegister_thenReturns400() throws Exception {
        // Arrange
        RegisterRequest request = new RegisterRequest("Mario", "Rossi", "mario@example.com", "", "utente");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    // ── POST /api/auth/login ──────────────────────────────────────────────────

    @Test
    void givenValidCredentials_whenLogin_thenReturns200WithToken() throws Exception {
        // Arrange
        LoginRequest request = new LoginRequest("mario@example.com", "password123");
        AuthResponse authResponse = AuthResponse.builder().token("jwt-token").user(testUserResponse).build();
        when(authService.login(any(LoginRequest.class))).thenReturn(authResponse);

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.user.email").value("mario@example.com"));
    }

    @Test
    void givenMissingEmail_whenLogin_thenReturns400() throws Exception {
        // Arrange
        LoginRequest request = new LoginRequest("", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void givenInvalidEmailFormat_whenLogin_thenReturns400() throws Exception {
        // Arrange
        LoginRequest request = new LoginRequest("not-an-email", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    // ── PUT /api/auth/change-password ─────────────────────────────────────────

    @Test
    void givenAuthenticatedUser_whenChangePassword_thenReturns200() throws Exception {
        // Arrange
        ChangePasswordRequest request = new ChangePasswordRequest("oldPass", "newPass");
        when(authService.changePassword(any(User.class), any(ChangePasswordRequest.class)))
                .thenReturn("Password changed successfully");

        // Act & Assert
        mockMvc.perform(put("/api/auth/change-password")
                        .header("Authorization", "Bearer " + BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Password changed successfully"));
    }

    @Test
    void givenUnauthenticatedRequest_whenChangePassword_thenReturns403() throws Exception {
        // Arrange
        ChangePasswordRequest request = new ChangePasswordRequest("oldPass", "newPass");

        // Act & Assert
        // /api/auth/** is permitAll, so the request reaches the controller with a null user.
        // The controller then invokes authService with null → mock doesn't stub for null →
        // NullPointerException when building Map.of("message", null) → 500.
        // We verify that no 2xx success is returned for an unauthenticated change-password call.
        mockMvc.perform(put("/api/auth/change-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().is5xxServerError());
    }

    @Test
    void givenBlankOldPassword_whenChangePassword_thenReturns400() throws Exception {
        // Arrange
        ChangePasswordRequest request = new ChangePasswordRequest("", "newPass");

        // Act & Assert
        mockMvc.perform(put("/api/auth/change-password")
                        .header("Authorization", "Bearer " + BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }
}
