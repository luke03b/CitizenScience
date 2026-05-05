package com.citizenscience.services;

import com.citizenscience.dto.AiIdentificationResult;
import com.citizenscience.dto.AvvistamentoResponse;
import com.citizenscience.dto.UpdateNotesRequest;
import com.citizenscience.entities.Avvistamento;
import com.citizenscience.entities.FotoAvvistamento;
import com.citizenscience.entities.User;
import com.citizenscience.exceptions.AvvistamentoNotFoundException;
import com.citizenscience.exceptions.UnauthorizedAccessException;
import com.citizenscience.repositories.AvvistamentoRepository;
import com.citizenscience.repositories.FotoAvvistamentoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.IOException;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for AvvistamentoService.
 * File-system operations use a JUnit 5 {@code @TempDir} to avoid side effects.
 */
@ExtendWith(MockitoExtension.class)
class AvvistamentoServiceTest {

    @Mock
    private AvvistamentoRepository avvistamentoRepository;

    @Mock
    private FotoAvvistamentoRepository fotoAvvistamentoRepository;

    @Mock
    private GeocodingService geocodingService;

    @Mock
    private AiService aiService;

    @InjectMocks
    private AvvistamentoService avvistamentoService;

    @TempDir
    Path tempDir;

    private User testUser;
    private UUID sightingId;
    private Avvistamento sighting;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(avvistamentoService, "uploadDir", tempDir.toString());

        testUser = User.builder()
                .id(UUID.randomUUID())
                .nome("Mario")
                .cognome("Rossi")
                .email("mario@example.com")
                .passwordHash("hash")
                .ruolo("utente")
                .build();

        sightingId = UUID.randomUUID();
        sighting = Avvistamento.builder()
                .id(sightingId)
                .nome("Rosa")
                .latitudine(45.0)
                .longitudine(9.0)
                .data(LocalDateTime.now())
                .user(testUser)
                .note("note")
                .indirizzo("Via Roma 1")
                .foto(new ArrayList<>())
                .build();
    }

    // ── createAvvistamento ────────────────────────────────────────────────────

    @Test
    void givenValidPhotoAndData_whenCreateAvvistamento_thenReturnsSavedResponse() throws IOException {
        // Arrange
        MockMultipartFile photo = new MockMultipartFile(
                "photo", "flower.jpg", "image/jpeg", "fake-image-bytes".getBytes());

        when(geocodingService.reverseGeocode(45.0, 9.0)).thenReturn("Via Roma 1");
        when(aiService.identifyFlower(any(), any(), any()))
                .thenReturn(AiIdentificationResult.builder()
                        .flowerName("Rosa")
                        .confidence(0.9)
                        .modelUsed("test-model")
                        .build());

        Avvistamento savedSighting = Avvistamento.builder()
                .id(sightingId)
                .nome("Rosa")
                .latitudine(45.0)
                .longitudine(9.0)
                .data(LocalDateTime.now())
                .user(testUser)
                .note(null)
                .indirizzo("Via Roma 1")
                .foto(new ArrayList<>())
                .aiModelUsed("test-model")
                .aiConfidence(0.9)
                .build();

        when(avvistamentoRepository.save(any(Avvistamento.class))).thenReturn(savedSighting);

        FotoAvvistamento savedFoto = FotoAvvistamento.builder()
                .id(UUID.randomUUID())
                .avvistamento(savedSighting)
                .photoPath(sightingId + "/photo.jpg")
                .build();
        when(fotoAvvistamentoRepository.save(any(FotoAvvistamento.class))).thenReturn(savedFoto);

        // Act
        AvvistamentoResponse response = avvistamentoService.createAvvistamento(
                testUser, photo, LocalDateTime.now(), 45.0, 9.0, null, null);

        // Assert
        assertThat(response.getNome()).isEqualTo("Rosa");
        assertThat(response.getLatitudine()).isEqualTo(45.0);
        verify(avvistamentoRepository).save(any(Avvistamento.class));
        verify(fotoAvvistamentoRepository).save(any(FotoAvvistamento.class));
    }

    @Test
    void givenNullPhoto_whenCreateAvvistamento_thenThrowsIllegalArgumentException() {
        LocalDateTime timestamp = LocalDateTime.of(2025, 1, 1, 12, 0);

        // Act & Assert
        assertThatThrownBy(() -> avvistamentoService.createAvvistamento(
                testUser, null, timestamp, 45.0, 9.0, null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("photo");
    }

    @Test
    void givenEmptyPhoto_whenCreateAvvistamento_thenThrowsIllegalArgumentException() {
        // Arrange
        MockMultipartFile emptyPhoto = new MockMultipartFile("photo", new byte[0]);
        LocalDateTime timestamp = LocalDateTime.of(2025, 1, 1, 12, 0);

        // Act & Assert
        assertThatThrownBy(() -> avvistamentoService.createAvvistamento(
                testUser, emptyPhoto, timestamp, 45.0, 9.0, null, null))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void givenNonImageFile_whenCreateAvvistamento_thenThrowsIllegalArgumentException() throws IOException {
        // Arrange
        MockMultipartFile textFile = new MockMultipartFile(
                "photo", "doc.txt", "text/plain", "not an image".getBytes());
        LocalDateTime timestamp = LocalDateTime.of(2025, 1, 1, 12, 0);

        when(geocodingService.reverseGeocode(anyDouble(), anyDouble())).thenReturn("Via Roma");
        when(aiService.identifyFlower(any(), any(), any()))
                .thenReturn(AiIdentificationResult.builder()
                        .flowerName("Avvistamento").confidence(0.0).modelUsed(null).build());
        when(avvistamentoRepository.save(any())).thenReturn(sighting);

        // Act & Assert – savePhoto validates content type
        assertThatThrownBy(() -> avvistamentoService.createAvvistamento(
                testUser, textFile, timestamp, 45.0, 9.0, null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("image");
    }

    @Test
    void givenAiServiceFails_whenCreateAvvistamento_thenUsesDefaultName() throws IOException {
        // Arrange
        MockMultipartFile photo = new MockMultipartFile(
                "photo", "flower.jpg", "image/jpeg", "bytes".getBytes());

        when(geocodingService.reverseGeocode(anyDouble(), anyDouble())).thenReturn("Via Roma");
        when(aiService.identifyFlower(any(), any(), any()))
                .thenThrow(new RuntimeException("AI service unavailable"));

        Avvistamento defaultNameSighting = Avvistamento.builder()
                .id(sightingId)
                .nome("Avvistamento")
                .latitudine(45.0)
                .longitudine(9.0)
                .data(LocalDateTime.now())
                .user(testUser)
                .foto(new ArrayList<>())
                .build();

        when(avvistamentoRepository.save(any(Avvistamento.class))).thenReturn(defaultNameSighting);
        when(fotoAvvistamentoRepository.save(any())).thenReturn(FotoAvvistamento.builder()
                .id(UUID.randomUUID())
                .avvistamento(defaultNameSighting)
                .photoPath(sightingId + "/flower.jpg")
                .build());

        // Act
        AvvistamentoResponse response = avvistamentoService.createAvvistamento(
                testUser, photo, LocalDateTime.now(), 45.0, 9.0, null, null);

        // Assert – fallback name "Avvistamento" is used
        assertThat(response.getNome()).isEqualTo("Avvistamento");
    }

    // ── updateNotes ───────────────────────────────────────────────────────────

    @Test
    void givenOwnerAndExistingSighting_whenUpdateNotes_thenReturnsUpdatedResponse() {
        // Arrange
        UpdateNotesRequest request = new UpdateNotesRequest("Updated notes");
        when(avvistamentoRepository.findById(sightingId)).thenReturn(Optional.of(sighting));
        when(avvistamentoRepository.save(sighting)).thenReturn(sighting);

        // Act
        avvistamentoService.updateNotes(testUser, sightingId, request);

        // Assert
        assertThat(sighting.getNote()).isEqualTo("Updated notes");
        verify(avvistamentoRepository).save(sighting);
    }

    @Test
    void givenNonExistentSighting_whenUpdateNotes_thenThrowsAvvistamentoNotFoundException() {
        // Arrange
        when(avvistamentoRepository.findById(sightingId)).thenReturn(Optional.empty());
                UpdateNotesRequest request = new UpdateNotesRequest("notes");

        // Act & Assert
                assertThatThrownBy(() -> avvistamentoService.updateNotes(testUser, sightingId, request))
                .isInstanceOf(AvvistamentoNotFoundException.class);
    }

    @Test
    void givenDifferentUser_whenUpdateNotes_thenThrowsUnauthorizedAccessException() {
        // Arrange
        User otherUser = User.builder().id(UUID.randomUUID()).email("other@example.com").build();
        when(avvistamentoRepository.findById(sightingId)).thenReturn(Optional.of(sighting));
                UpdateNotesRequest request = new UpdateNotesRequest("notes");

        // Act & Assert
                assertThatThrownBy(() -> avvistamentoService.updateNotes(otherUser, sightingId, request))
                .isInstanceOf(UnauthorizedAccessException.class);
    }

    // ── deleteAvvistamento ────────────────────────────────────────────────────

    @Test
    void givenOwnerAndExistingSighting_whenDeleteAvvistamento_thenDeletesFromRepository() throws IOException {
        // Arrange
        when(avvistamentoRepository.findById(sightingId)).thenReturn(Optional.of(sighting));

        // Act
        avvistamentoService.deleteAvvistamento(testUser, sightingId);

        // Assert
        verify(avvistamentoRepository).delete(sighting);
    }

    @Test
    void givenNonExistentSighting_whenDeleteAvvistamento_thenThrowsAvvistamentoNotFoundException() {
        // Arrange
        when(avvistamentoRepository.findById(sightingId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> avvistamentoService.deleteAvvistamento(testUser, sightingId))
                .isInstanceOf(AvvistamentoNotFoundException.class);
    }

    @Test
    void givenDifferentUser_whenDeleteAvvistamento_thenThrowsUnauthorizedAccessException() {
        // Arrange
        User otherUser = User.builder().id(UUID.randomUUID()).email("other@example.com").build();
        when(avvistamentoRepository.findById(sightingId)).thenReturn(Optional.of(sighting));

        // Act & Assert
        assertThatThrownBy(() -> avvistamentoService.deleteAvvistamento(otherUser, sightingId))
                .isInstanceOf(UnauthorizedAccessException.class);
        verify(avvistamentoRepository, never()).delete(any());
    }

    // ── getAllAvvistamenti ────────────────────────────────────────────────────

    @Test
    void whenGetAllAvvistamenti_thenReturnsMappedList() {
        // Arrange
        when(avvistamentoRepository.findAll()).thenReturn(List.of(sighting));

        // Act
        List<AvvistamentoResponse> result = avvistamentoService.getAllAvvistamenti();

        // Assert
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getId()).isEqualTo(sightingId);
    }

    @Test
    void givenNoSightings_whenGetAllAvvistamenti_thenReturnsEmptyList() {
        // Arrange
        when(avvistamentoRepository.findAll()).thenReturn(List.of());

        // Act
        List<AvvistamentoResponse> result = avvistamentoService.getAllAvvistamenti();

        // Assert
        assertThat(result).isEmpty();
    }

    // ── getAvvistamentiByUser ─────────────────────────────────────────────────

    @Test
    void givenUserId_whenGetAvvistamentiByUser_thenReturnsMappedList() {
        // Arrange
        UUID userId = testUser.getId();
        when(avvistamentoRepository.findByUserId(userId)).thenReturn(List.of(sighting));

        // Act
        List<AvvistamentoResponse> result = avvistamentoService.getAvvistamentiByUser(userId);

        // Assert
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getUserId()).isEqualTo(userId);
    }

    // ── getAvvistamentiByLocation ─────────────────────────────────────────────

    @Test
    void givenCoordinatesAndRadius_whenGetAvvistamentiByLocation_thenCallsRepositoryWithMeters() {
        // Arrange
        when(avvistamentoRepository.findWithinRadius(45.0, 9.0, 5000.0)).thenReturn(List.of(sighting));

        // Act
        List<AvvistamentoResponse> result = avvistamentoService.getAvvistamentiByLocation(45.0, 9.0, 5.0);

        // Assert – radiusKm 5.0 is converted to 5000 m before the query
        assertThat(result).hasSize(1);
        verify(avvistamentoRepository).findWithinRadius(45.0, 9.0, 5000.0);
    }
}
