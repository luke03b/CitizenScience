package com.citizenscience.controllers;

import com.citizenscience.config.SecurityConfig;
import com.citizenscience.dto.AiModelInfo;
import com.citizenscience.entities.AiModelSelection;
import com.citizenscience.entities.User;
import com.citizenscience.repositories.AiModelSelectionRepository;
import com.citizenscience.repositories.UserRepository;
import com.citizenscience.security.JwtUtil;
import com.citizenscience.services.AiService;
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

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Slice tests for AiModelController.
 */
@WebMvcTest(AiModelController.class)
@Import(SecurityConfig.class)
class AiModelControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AiService aiService;

    @MockitoBean
    private AiModelSelectionRepository aiModelSelectionRepository;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private static final String RESEARCHER_TOKEN = "researcher-token";
    private static final String USER_TOKEN = "user-token";

    private User researcher;
    private User regularUser;

    @BeforeEach
    void setUp() {
        researcher = User.builder()
                .id(UUID.randomUUID())
                .nome("Ricercatrice")
                .cognome("Bianchi")
                .email("researcher@example.com")
                .passwordHash("hash")
                .ruolo("ricercatore")
                .build();

        regularUser = User.builder()
                .id(UUID.randomUUID())
                .nome("Mario")
                .cognome("Rossi")
                .email("mario@example.com")
                .passwordHash("hash")
                .ruolo("utente")
                .build();

        // Researcher JWT setup
        when(jwtUtil.extractEmail(RESEARCHER_TOKEN)).thenReturn(researcher.getEmail());
        when(jwtUtil.validateToken(RESEARCHER_TOKEN, researcher.getEmail())).thenReturn(true);
        when(userRepository.findByEmail(researcher.getEmail())).thenReturn(Optional.of(researcher));

        // Regular user JWT setup
        when(jwtUtil.extractEmail(USER_TOKEN)).thenReturn(regularUser.getEmail());
        when(jwtUtil.validateToken(USER_TOKEN, regularUser.getEmail())).thenReturn(true);
        when(userRepository.findByEmail(regularUser.getEmail())).thenReturn(Optional.of(regularUser));
    }

    // ── GET /api/ai/models ────────────────────────────────────────────────────

    @Test
    void givenResearcher_whenGetAvailableModels_thenReturns200WithModelList() throws Exception {
        // Arrange
        AiModelInfo modelInfo = new AiModelInfo("model_v1.pt", "Version 1", false);
        when(aiService.getAvailableModels()).thenReturn(List.of(modelInfo));

        // Act & Assert
        mockMvc.perform(get("/api/ai/models")
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.models[0].name").value("model_v1.pt"));
    }

    @Test
    void givenRegularUser_whenGetAvailableModels_thenReturns403() throws Exception {
        // Act & Assert
        mockMvc.perform(get("/api/ai/models")
                        .header("Authorization", "Bearer " + USER_TOKEN))
                .andExpect(status().isForbidden());
    }

    @Test
    void givenUnauthenticatedRequest_whenGetAvailableModels_thenReturns401() throws Exception {
        // Act & Assert
        mockMvc.perform(get("/api/ai/models"))
                .andExpect(status().isUnauthorized());
    }

    // ── POST /api/ai/scan ─────────────────────────────────────────────────────

    @Test
    void givenResearcher_whenForceScan_thenReturns200WithScanResult() throws Exception {
        // Arrange
        when(aiService.forceScanModels()).thenReturn(Map.of("ai_service", List.of("model_v1.pt")));

        // Act & Assert
        mockMvc.perform(post("/api/ai/scan")
                        .with(csrf())
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scannedContainers.ai_service[0]").value("model_v1.pt"));
    }

    @Test
    void givenRegularUser_whenForceScan_thenReturns403() throws Exception {
        // Act & Assert
        mockMvc.perform(post("/api/ai/scan")
                        .with(csrf())
                        .header("Authorization", "Bearer " + USER_TOKEN))
                .andExpect(status().isForbidden());
    }

    // ── POST /api/ai/models/select ────────────────────────────────────────────

    @Test
    void givenResearcherAndValidModelName_whenSelectModel_thenReturns200() throws Exception {
        // Arrange
        when(aiModelSelectionRepository.findByUser(researcher)).thenReturn(Optional.empty());
        when(aiModelSelectionRepository.save(any(AiModelSelection.class))).thenReturn(null);

        Map<String, String> request = Map.of("modelName", "model_v1.pt");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/select")
                        .with(csrf())
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Model selected successfully"))
                .andExpect(jsonPath("$.modelName").value("model_v1.pt"));
    }

    @Test
    void givenResearcherAndExistingSelection_whenSelectModel_thenUpdatesAndReturns200() throws Exception {
        // Arrange
        AiModelSelection existing = AiModelSelection.builder()
                .id(UUID.randomUUID())
                .user(researcher)
                .modelName("old_model.pt")
                .selectedAt(LocalDateTime.now().minusDays(1))
                .build();
        when(aiModelSelectionRepository.findByUser(researcher)).thenReturn(Optional.of(existing));
        when(aiModelSelectionRepository.save(any(AiModelSelection.class))).thenReturn(existing);

        Map<String, String> request = Map.of("modelName", "model_v2.pt");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/select")
                        .with(csrf())
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.modelName").value("model_v2.pt"));
    }

    @Test
    void givenResearcherAndEmptyModelName_whenSelectModel_thenReturns400() throws Exception {
        // Arrange
        Map<String, String> request = Map.of("modelName", "");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/select")
                        .with(csrf())
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void givenRegularUser_whenSelectModel_thenReturns403() throws Exception {
        // Arrange
        Map<String, String> request = Map.of("modelName", "model_v1.pt");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/select")
                        .with(csrf())
                        .header("Authorization", "Bearer " + USER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    // ── GET /api/ai/models/selected ───────────────────────────────────────────

    @Test
    void givenResearcherWithSelectedModel_whenGetSelectedModel_thenReturns200() throws Exception {
        // Arrange
        AiModelSelection selection = AiModelSelection.builder()
                .id(UUID.randomUUID())
                .user(researcher)
                .modelName("model_v1.pt")
                .selectedAt(LocalDateTime.now())
                .build();
        when(aiModelSelectionRepository.findByUser(researcher)).thenReturn(Optional.of(selection));

        // Act & Assert
        mockMvc.perform(get("/api/ai/models/selected")
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.modelName").value("model_v1.pt"));
    }

    @Test
    void givenResearcherWithNoSelectedModel_whenGetSelectedModel_thenReturns404() throws Exception {
        // Arrange
        when(aiModelSelectionRepository.findByUser(researcher)).thenReturn(Optional.empty());

        // Act & Assert
        mockMvc.perform(get("/api/ai/models/selected")
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN))
                .andExpect(status().isNotFound());
    }

    @Test
    void givenRegularUser_whenGetSelectedModel_thenReturns403() throws Exception {
        // Act & Assert
        mockMvc.perform(get("/api/ai/models/selected")
                        .header("Authorization", "Bearer " + USER_TOKEN))
                .andExpect(status().isForbidden());
    }

    // ── POST /api/ai/models/set-default ──────────────────────────────────────

    @Test
    void givenResearcherAndValidModelName_whenSetDefaultModel_thenReturns200() throws Exception {
        // Arrange
        Map<String, String> request = Map.of("modelName", "model_v1.pt");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/set-default")
                        .with(csrf())
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Default model set successfully"))
                .andExpect(jsonPath("$.modelName").value("model_v1.pt"));
    }

    @Test
    void givenResearcherAndEmptyModelName_whenSetDefaultModel_thenReturns200WithClearedMessage() throws Exception {
        // Arrange
        Map<String, String> request = Map.of("modelName", "");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/set-default")
                        .with(csrf())
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Default model cleared"));
    }

    @Test
    void givenResearcherAndUnknownModel_whenSetDefaultModel_thenReturns400() throws Exception {
        // Arrange
        doThrow(new IllegalArgumentException("Model 'unknown.pt' not found in the registry"))
                .when(aiService).setDefaultModel("unknown.pt");

        Map<String, String> request = Map.of("modelName", "unknown.pt");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/set-default")
                        .with(csrf())
                        .header("Authorization", "Bearer " + RESEARCHER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Model 'unknown.pt' not found in the registry"));
    }

    @Test
    void givenRegularUser_whenSetDefaultModel_thenReturns403() throws Exception {
        // Arrange
        Map<String, String> request = Map.of("modelName", "model_v1.pt");

        // Act & Assert
        mockMvc.perform(post("/api/ai/models/set-default")
                        .with(csrf())
                        .header("Authorization", "Bearer " + USER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }
}
