package com.citizenScience.services;

import com.citizenScience.dto.AiIdentificationResult;
import com.citizenScience.dto.AiModelInfo;
import com.citizenScience.entities.AiContainerModel;
import com.citizenScience.entities.AiModelSelection;
import com.citizenScience.entities.User;
import com.citizenScience.repositories.AiContainerModelRepository;
import com.citizenScience.repositories.AiModelSelectionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

/**
 * Unit tests for AiService.
 * Tests focus on model-selection logic and repository interactions that do not require
 * a live RestTemplate / AI container.
 */
@ExtendWith(MockitoExtension.class)
class AiServiceTest {

    @Mock
    private AiModelSelectionRepository aiModelSelectionRepository;

    @Mock
    private AiContainerModelRepository aiContainerModelRepository;

    @InjectMocks
    private AiService aiService;

    private User regularUser;
    private User researcher;
    private AiContainerModel model;

    @BeforeEach
    void setUp() {
        regularUser = User.builder()
                .id(UUID.randomUUID())
                .email("user@example.com")
                .ruolo("utente")
                .build();

        researcher = User.builder()
                .id(UUID.randomUUID())
                .email("researcher@example.com")
                .ruolo("ricercatore")
                .build();

        model = AiContainerModel.builder()
                .id(UUID.randomUUID())
                .modelName("model_v1.pt")
                .containerName("ai_service")
                .discoveredAt(LocalDateTime.now())
                .description("Test model")
                .isDefault(false)
                .build();
    }

    // ── getAvailableModels ────────────────────────────────────────────────────

    @Test
    void givenNoModelsInRegistry_whenGetAvailableModels_thenReturnsEmptyList() {
        // Arrange
        when(aiContainerModelRepository.findAll()).thenReturn(List.of());

        // Act
        List<AiModelInfo> result = aiService.getAvailableModels();

        // Assert
        assertThat(result).isEmpty();
    }

    @Test
    void givenModelsInRegistry_whenGetAvailableModels_thenReturnsMappedList() {
        // Arrange
        when(aiContainerModelRepository.findAll()).thenReturn(List.of(model));

        // Act
        List<AiModelInfo> result = aiService.getAvailableModels();

        // Assert
        assertThat(result).hasSize(1);
        assertThat(result.get(0).name()).isEqualTo("model_v1.pt");
        assertThat(result.get(0).description()).isEqualTo("Test model");
        assertThat(result.get(0).isDefault()).isFalse();
    }

    // ── setDefaultModel ───────────────────────────────────────────────────────

    @Test
    void givenValidModelName_whenSetDefaultModel_thenClearsOldAndSetsNew() {
        // Arrange
        when(aiContainerModelRepository.findByModelName("model_v1.pt"))
                .thenReturn(Optional.of(model));

        // Act
        aiService.setDefaultModel("model_v1.pt");

        // Assert
        verify(aiContainerModelRepository).clearAllDefaults();
        assertThat(model.isDefault()).isTrue();
        verify(aiContainerModelRepository).save(model);
    }

    @Test
    void givenNullModelName_whenSetDefaultModel_thenOnlyClearsDefaults() {
        // Act
        aiService.setDefaultModel(null);

        // Assert
        verify(aiContainerModelRepository).clearAllDefaults();
        verify(aiContainerModelRepository, never()).findByModelName(any());
        verify(aiContainerModelRepository, never()).save(any());
    }

    @Test
    void givenBlankModelName_whenSetDefaultModel_thenOnlyClearsDefaults() {
        // Act
        aiService.setDefaultModel("   ");

        // Assert
        verify(aiContainerModelRepository).clearAllDefaults();
        verify(aiContainerModelRepository, never()).findByModelName(any());
    }

    @Test
    void givenUnknownModelName_whenSetDefaultModel_thenThrowsIllegalArgumentException() {
        // Arrange
        when(aiContainerModelRepository.findByModelName("unknown.pt")).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> aiService.setDefaultModel("unknown.pt"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("unknown.pt");
    }

    // ── identifyFlower – fallback logic (no live container) ───────────────────

    @Test
    void givenNoModelsInRegistry_whenIdentifyFlower_thenReturnsUnknownFlowerResult() throws IOException {
        // Arrange – registry and selections are all empty → full fallback chain
        MockMultipartFile photo = new MockMultipartFile(
                "photo", "f.jpg", "image/jpeg", "bytes".getBytes());

        when(aiContainerModelRepository.findByIsDefaultTrue()).thenReturn(Optional.empty());
        when(aiContainerModelRepository.findFirstByOrderByDiscoveredAtAsc()).thenReturn(Optional.empty());

        // Act
        AiIdentificationResult result = aiService.identifyFlower(photo, regularUser, null);

        // Assert – service returns the unknown-flower sentinel value
        assertThat(result.getFlowerName()).isNotBlank();
        assertThat(result.getConfidence()).isEqualTo(0.0);
    }

    @Test
    void givenResearcherWithSavedModel_whenIdentifyFlowerAndContainerUnreachable_thenFallsBack()
            throws IOException {
        // Arrange
        MockMultipartFile photo = new MockMultipartFile(
                "photo", "f.jpg", "image/jpeg", "bytes".getBytes());

        AiModelSelection selection = AiModelSelection.builder()
                .user(researcher)
                .modelName("model_v1.pt")
                .selectedAt(LocalDateTime.now())
                .build();
        when(aiModelSelectionRepository.findByUser(researcher)).thenReturn(Optional.of(selection));
        when(aiContainerModelRepository.findByModelName("model_v1.pt")).thenReturn(Optional.of(model));

        // Container is unreachable → tryIdentify returns null → falls back
        when(aiContainerModelRepository.findByIsDefaultTrue()).thenReturn(Optional.empty());
        when(aiContainerModelRepository.findFirstByOrderByDiscoveredAtAsc()).thenReturn(Optional.empty());

        // Act
        AiIdentificationResult result = aiService.identifyFlower(photo, researcher, null);

        // Assert – fell all the way through to unknownFlowerResult
        assertThat(result.getConfidence()).isEqualTo(0.0);
    }

    @Test
    void givenModelOverrideNotInRegistry_whenIdentifyFlower_thenFallsBackToDefault() throws IOException {
        // Arrange
        MockMultipartFile photo = new MockMultipartFile(
                "photo", "f.jpg", "image/jpeg", "bytes".getBytes());

        when(aiContainerModelRepository.findByModelName("override.pt")).thenReturn(Optional.empty());
        when(aiContainerModelRepository.findByIsDefaultTrue()).thenReturn(Optional.empty());
        when(aiContainerModelRepository.findFirstByOrderByDiscoveredAtAsc()).thenReturn(Optional.empty());

        // Act
        AiIdentificationResult result = aiService.identifyFlower(photo, regularUser, "override.pt");

        // Assert – override not found → falls back through default and first → sentinel returned
        verify(aiContainerModelRepository).findByIsDefaultTrue();
        assertThat(result.getConfidence()).isEqualTo(0.0);
        assertThat(result.getFlowerName()).isNotBlank();
    }
}
