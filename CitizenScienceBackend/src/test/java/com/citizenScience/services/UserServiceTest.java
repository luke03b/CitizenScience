package com.citizenscience.services;

import com.citizenscience.dto.UpdateUserRequest;
import com.citizenscience.dto.UserResponse;
import com.citizenscience.entities.User;
import com.citizenscience.exceptions.UserAlreadyExistsException;
import com.citizenscience.exceptions.UserNotFoundException;
import com.citizenscience.repositories.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for UserService.
 * All external dependencies are mocked; no Spring context or database is required.
 */
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(UUID.randomUUID())
                .nome("Mario")
                .cognome("Rossi")
                .email("mario@example.com")
                .passwordHash("hashedPassword")
                .ruolo("utente")
                .build();
    }

    // ── getCurrentUser ────────────────────────────────────────────────────────

    @Test
    void givenAuthenticatedUser_whenGetCurrentUser_thenReturnsUserResponse() {
        // Act
        UserResponse response = userService.getCurrentUser(testUser);

        // Assert
        assertThat(response.getId()).isEqualTo(testUser.getId());
        assertThat(response.getNome()).isEqualTo("Mario");
        assertThat(response.getCognome()).isEqualTo("Rossi");
        assertThat(response.getEmail()).isEqualTo("mario@example.com");
        assertThat(response.getRuolo()).isEqualTo("utente");
        verifyNoInteractions(userRepository);
    }

    // ── updateCurrentUser ─────────────────────────────────────────────────────

    @Test
    void givenAllFieldsProvided_whenUpdateCurrentUser_thenReturnsUpdatedResponse() {
        // Arrange
        UpdateUserRequest request = new UpdateUserRequest("Luigi", "Verdi", "luigi@example.com");
        User updatedUser = User.builder()
                .id(testUser.getId())
                .nome("Luigi")
                .cognome("Verdi")
                .email("luigi@example.com")
                .passwordHash("hashedPassword")
                .ruolo("utente")
                .build();

        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));
        when(userRepository.existsByEmail("luigi@example.com")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenReturn(updatedUser);

        // Act
        UserResponse response = userService.updateCurrentUser(testUser, request);

        // Assert
        assertThat(response.getNome()).isEqualTo("Luigi");
        assertThat(response.getCognome()).isEqualTo("Verdi");
        assertThat(response.getEmail()).isEqualTo("luigi@example.com");
        verify(userRepository).save(testUser);
    }

    @Test
    void givenOnlyNomeProvided_whenUpdateCurrentUser_thenOnlyNomeIsUpdated() {
        // Arrange
        UpdateUserRequest request = new UpdateUserRequest("Luigi", null, null);
        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // Act
        userService.updateCurrentUser(testUser, request);

        // Assert
        assertThat(testUser.getNome()).isEqualTo("Luigi");
        assertThat(testUser.getCognome()).isEqualTo("Rossi"); // unchanged
        assertThat(testUser.getEmail()).isEqualTo("mario@example.com"); // unchanged
    }

    @Test
    void givenSameEmail_whenUpdateCurrentUser_thenEmailCheckIsSkipped() {
        // Arrange – same email means no existsByEmail call
        UpdateUserRequest request = new UpdateUserRequest(null, null, "mario@example.com");
        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // Act
        userService.updateCurrentUser(testUser, request);

        // Assert
        verify(userRepository, never()).existsByEmail(any());
    }

    @Test
    void givenUserNotFound_whenUpdateCurrentUser_thenThrowsUserNotFoundException() {
        // Arrange
        UpdateUserRequest request = new UpdateUserRequest("Luigi", null, null);
        when(userRepository.findById(testUser.getId())).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> userService.updateCurrentUser(testUser, request))
                .isInstanceOf(UserNotFoundException.class);
    }

    @Test
    void givenEmailAlreadyTaken_whenUpdateCurrentUser_thenThrowsUserAlreadyExistsException() {
        // Arrange
        UpdateUserRequest request = new UpdateUserRequest(null, null, "taken@example.com");
        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));
        when(userRepository.existsByEmail("taken@example.com")).thenReturn(true);

        // Act & Assert
        assertThatThrownBy(() -> userService.updateCurrentUser(testUser, request))
                .isInstanceOf(UserAlreadyExistsException.class);
    }
}
