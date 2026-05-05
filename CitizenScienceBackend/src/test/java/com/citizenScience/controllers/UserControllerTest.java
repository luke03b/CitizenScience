package com.citizenscience.controllers;

import com.citizenscience.config.SecurityConfig;
import com.citizenscience.dto.UpdateUserRequest;
import com.citizenscience.dto.UserResponse;
import com.citizenscience.entities.User;
import com.citizenscience.repositories.UserRepository;
import com.citizenscience.security.JwtUtil;
import com.citizenscience.services.UserService;
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
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Slice tests for UserController.
 */
@WebMvcTest(UserController.class)
@Import(SecurityConfig.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

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

        when(jwtUtil.extractEmail(BEARER_TOKEN)).thenReturn(testUser.getEmail());
        when(jwtUtil.validateToken(BEARER_TOKEN, testUser.getEmail())).thenReturn(true);
        when(userRepository.findByEmail(testUser.getEmail())).thenReturn(Optional.of(testUser));
    }

    // ── GET /api/users/me ─────────────────────────────────────────────────────

    @Test
    void givenAuthenticatedUser_whenGetCurrentUser_thenReturns200WithProfile() throws Exception {
        // Arrange
        when(userService.getCurrentUser(testUser)).thenReturn(testUserResponse);

        // Act & Assert
        mockMvc.perform(get("/api/users/me")
                        .header("Authorization", "Bearer " + BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("mario@example.com"))
                .andExpect(jsonPath("$.nome").value("Mario"))
                .andExpect(jsonPath("$.cognome").value("Rossi"))
                .andExpect(jsonPath("$.ruolo").value("utente"));
    }

    @Test
    void givenUnauthenticatedRequest_whenGetCurrentUser_thenReturns401() throws Exception {
        // Act & Assert
        mockMvc.perform(get("/api/users/me"))
                .andExpect(status().isUnauthorized());
    }

    // ── PUT /api/users/me ─────────────────────────────────────────────────────

    @Test
    void givenValidUpdateRequest_whenUpdateCurrentUser_thenReturns200WithUpdatedProfile() throws Exception {
        // Arrange
        UpdateUserRequest request = new UpdateUserRequest("Luigi", "Verdi", "luigi@example.com");
        UserResponse updatedResponse = UserResponse.builder()
                .id(testUser.getId())
                .nome("Luigi")
                .cognome("Verdi")
                .email("luigi@example.com")
                .ruolo("utente")
                .build();
        when(userService.updateCurrentUser(any(User.class), any(UpdateUserRequest.class)))
                .thenReturn(updatedResponse);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                        .with(csrf())
                        .header("Authorization", "Bearer " + BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Luigi"))
                .andExpect(jsonPath("$.cognome").value("Verdi"))
                .andExpect(jsonPath("$.email").value("luigi@example.com"));
    }

    @Test
    void givenUnauthenticatedRequest_whenUpdateCurrentUser_thenReturns401() throws Exception {
        // Arrange
        UpdateUserRequest request = new UpdateUserRequest("Luigi", null, null);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void givenInvalidEmailInRequest_whenUpdateCurrentUser_thenReturns400() throws Exception {
        // Arrange
        UpdateUserRequest request = new UpdateUserRequest(null, null, "not-valid-email");

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                        .with(csrf())
                        .header("Authorization", "Bearer " + BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void givenPartialUpdate_whenUpdateCurrentUser_thenReturns200() throws Exception {
        // Arrange – only nome is updated
        UpdateUserRequest request = new UpdateUserRequest("Luigi", null, null);
        UserResponse updatedResponse = UserResponse.builder()
                .id(testUser.getId())
                .nome("Luigi")
                .cognome("Rossi")
                .email("mario@example.com")
                .ruolo("utente")
                .build();
        when(userService.updateCurrentUser(any(User.class), any(UpdateUserRequest.class)))
                .thenReturn(updatedResponse);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                        .with(csrf())
                        .header("Authorization", "Bearer " + BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Luigi"))
                .andExpect(jsonPath("$.cognome").value("Rossi"));
    }
}
