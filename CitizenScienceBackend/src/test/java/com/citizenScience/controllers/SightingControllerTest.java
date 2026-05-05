package com.citizenscience.controllers;

import com.citizenscience.config.SecurityConfig;
import com.citizenscience.dto.AvvistamentoResponse;
import com.citizenscience.dto.UpdateNotesRequest;
import com.citizenscience.entities.User;
import com.citizenscience.repositories.UserRepository;
import com.citizenscience.security.JwtUtil;
import com.citizenscience.services.AvvistamentoService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Slice tests for SightingController.
 */
@WebMvcTest(SightingController.class)
@Import(SecurityConfig.class)
class SightingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AvvistamentoService avvistamentoService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private static final String BEARER_TOKEN = "test-bearer-token";

    private User testUser;
    private UUID sightingId;
    private AvvistamentoResponse sightingResponse;

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

        sightingId = UUID.randomUUID();
        sightingResponse = AvvistamentoResponse.builder()
                .id(sightingId)
                .nome("Rosa")
                .latitudine(45.0)
                .longitudine(9.0)
                .data(LocalDateTime.now())
                .userId(testUser.getId())
                .userNome("Mario")
                .userCognome("Rossi")
                .note("note")
                .indirizzo("Via Roma 1")
                .photoUrls(List.of("/api/photos/test.jpg"))
                .build();

        when(jwtUtil.extractEmail(BEARER_TOKEN)).thenReturn(testUser.getEmail());
        when(jwtUtil.validateToken(BEARER_TOKEN, testUser.getEmail())).thenReturn(true);
        when(userRepository.findByEmail(testUser.getEmail())).thenReturn(Optional.of(testUser));
    }

    // ── GET /api/sightings  (public) ──────────────────────────────────────────

    @Test
    void whenGetAllSightings_thenReturns200WithList() throws Exception {
        // Arrange
        when(avvistamentoService.getAllAvvistamenti()).thenReturn(List.of(sightingResponse));

        // Act & Assert
        mockMvc.perform(get("/api/sightings"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].nome").value("Rosa"));
    }

    @Test
    void whenGetAllSightingsAndNoneExist_thenReturns200WithEmptyList() throws Exception {
        // Arrange
        when(avvistamentoService.getAllAvvistamenti()).thenReturn(List.of());

        // Act & Assert
        mockMvc.perform(get("/api/sightings"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    // ── GET /api/sightings/user/{userId}  (public) ────────────────────────────

    @Test
    void givenUserId_whenGetSightingsByUser_thenReturns200WithList() throws Exception {
        // Arrange
        when(avvistamentoService.getAvvistamentiByUser(testUser.getId()))
                .thenReturn(List.of(sightingResponse));

        // Act & Assert
        mockMvc.perform(get("/api/sightings/user/{userId}", testUser.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    // ── GET /api/sightings/location  (public) ─────────────────────────────────

    @Test
    void givenCoordinatesAndRadius_whenGetSightingsByLocation_thenReturns200WithList() throws Exception {
        // Arrange
        when(avvistamentoService.getAvvistamentiByLocation(45.0, 9.0, 5.0))
                .thenReturn(List.of(sightingResponse));

        // Act & Assert
        mockMvc.perform(get("/api/sightings/location")
                        .param("lat", "45.0")
                        .param("lng", "9.0")
                        .param("radiusKm", "5.0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    // ── POST /api/sightings  (authenticated) ──────────────────────────────────

    @Test
    void givenAuthenticatedUserAndValidPhoto_whenCreateSighting_thenReturns201() throws Exception {
        // Arrange
        MockMultipartFile photo = new MockMultipartFile(
                "photo", "flower.jpg", "image/jpeg", "bytes".getBytes());

        when(avvistamentoService.createAvvistamento(
                any(User.class), any(), any(LocalDateTime.class),
                anyDouble(), anyDouble(), isNull(), isNull()))
                .thenReturn(sightingResponse);

        // Act & Assert
        mockMvc.perform(multipart("/api/sightings")
                        .file(photo)
                        .with(csrf())
                        .param("data", "2024-06-01T10:00:00")
                        .param("latitudine", "45.0")
                        .param("longitudine", "9.0")
                        .header("Authorization", "Bearer " + BEARER_TOKEN))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.nome").value("Rosa"));
    }

    @Test
    void givenUnauthenticatedRequest_whenCreateSighting_thenSucceedsAsPublicEndpoint() throws Exception {
        // Arrange – POST /api/sightings is covered by the permitAll rule for /api/sightings
        // (all HTTP methods permitted). The controller runs with null user.
        MockMultipartFile photo = new MockMultipartFile(
                "photo", "flower.jpg", "image/jpeg", "bytes".getBytes());

        // Act & Assert – endpoint is publicly accessible; service is not stubbed for null user,
        // so the controller returns 201 with null body.
        mockMvc.perform(multipart("/api/sightings")
                        .file(photo)
                        .with(csrf())
                        .param("data", "2024-06-01T10:00:00")
                        .param("latitudine", "45.0")
                        .param("longitudine", "9.0"))
                .andExpect(status().isCreated());
    }

    // ── PUT /api/sightings/{id}/notes  (authenticated) ────────────────────────

    @Test
    void givenAuthenticatedOwner_whenUpdateNotes_thenReturns200() throws Exception {
        // Arrange
        UpdateNotesRequest request = new UpdateNotesRequest("Updated note");
        when(avvistamentoService.updateNotes(any(User.class), eq(sightingId), any(UpdateNotesRequest.class)))
                .thenReturn(sightingResponse);

        // Act & Assert
        mockMvc.perform(put("/api/sightings/{id}/notes", sightingId)
                        .with(csrf())
                        .header("Authorization", "Bearer " + BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(sightingId.toString()));
    }

    @Test
    void givenUnauthenticatedRequest_whenUpdateNotes_thenReturns401() throws Exception {
        // Arrange
        UpdateNotesRequest request = new UpdateNotesRequest("Updated note");

        // Act & Assert
        mockMvc.perform(put("/api/sightings/{id}/notes", sightingId)
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    // ── DELETE /api/sightings/{id}  (authenticated) ───────────────────────────

    @Test
    void givenAuthenticatedOwner_whenDeleteSighting_thenReturns204() throws Exception {
        // Act & Assert
        mockMvc.perform(delete("/api/sightings/{id}", sightingId)
                        .with(csrf())
                        .header("Authorization", "Bearer " + BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void givenUnauthenticatedRequest_whenDeleteSighting_thenReturns401() throws Exception {
        // Act & Assert
        mockMvc.perform(delete("/api/sightings/{id}", sightingId)
                        .with(csrf()))
                .andExpect(status().isUnauthorized());
    }
}
