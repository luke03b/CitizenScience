package com.citizenScience.services;

import com.citizenScience.dto.AuthResponse;
import com.citizenScience.dto.ChangePasswordRequest;
import com.citizenScience.dto.LoginRequest;
import com.citizenScience.dto.RegisterRequest;
import com.citizenScience.entities.User;
import com.citizenScience.exceptions.InvalidCredentialsException;
import com.citizenScience.exceptions.UserAlreadyExistsException;
import com.citizenScience.exceptions.UserNotFoundException;
import com.citizenScience.repositories.UserRepository;
import com.citizenScience.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Unit tests for AuthService.
 * All external dependencies are mocked; no Spring context or database is required.
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private AuthService authService;

    private User savedUser;

    @BeforeEach
    void setUp() {
        savedUser = User.builder()
                .id(UUID.randomUUID())
                .nome("Mario")
                .cognome("Rossi")
                .email("mario@example.com")
                .passwordHash("$2a$10$hashedpassword")
                .ruolo("utente")
                .build();
    }

    // ── register ─────────────────────────────────────────────────────────────

    @Test
    void givenNewUser_whenRegister_thenReturnsAuthResponseWithToken() {
        // Arrange
        RegisterRequest request = new RegisterRequest("Mario", "Rossi", "mario@example.com", "password123", "utente");
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(false);
        when(passwordEncoder.encode(request.getPassword())).thenReturn("$2a$10$hashedpassword");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(jwtUtil.generateToken(savedUser.getEmail())).thenReturn("jwt-token");

        // Act
        AuthResponse response = authService.register(request);

        // Assert
        assertThat(response.getToken()).isEqualTo("jwt-token");
        assertThat(response.getUser().getEmail()).isEqualTo("mario@example.com");
        assertThat(response.getUser().getRuolo()).isEqualTo("utente");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void givenExistingEmail_whenRegister_thenThrowsUserAlreadyExistsException() {
        // Arrange
        RegisterRequest request = new RegisterRequest("Mario", "Rossi", "mario@example.com", "password123", "utente");
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(true);

        // Act & Assert
        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(UserAlreadyExistsException.class)
                .hasMessageContaining("mario@example.com");
        verify(userRepository, never()).save(any());
    }

    @Test
    void givenNullRole_whenRegister_thenDefaultsToUtente() {
        // Arrange
        RegisterRequest request = new RegisterRequest("Mario", "Rossi", "mario@example.com", "password123", null);
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            assertThat(u.getRuolo()).isEqualTo("utente");
            return savedUser;
        });
        when(jwtUtil.generateToken(anyString())).thenReturn("token");

        // Act
        authService.register(request);

        // Assert – verified inside the save answer above
        verify(userRepository).save(any(User.class));
    }

    @Test
    void givenInvalidRole_whenRegister_thenDefaultsToUtente() {
        // Arrange
        RegisterRequest request = new RegisterRequest("Mario", "Rossi", "mario@example.com", "password123", "admin");
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            assertThat(u.getRuolo()).isEqualTo("utente");
            return savedUser;
        });
        when(jwtUtil.generateToken(anyString())).thenReturn("token");

        // Act
        authService.register(request);

        verify(userRepository).save(any(User.class));
    }

    @Test
    void givenResearcherRole_whenRegister_thenRoleIsPreserved() {
        // Arrange
        User researcher = User.builder()
                .id(UUID.randomUUID())
                .nome("Maria")
                .cognome("Bianchi")
                .email("maria@example.com")
                .passwordHash("hashed")
                .ruolo("ricercatore")
                .build();
        RegisterRequest request = new RegisterRequest("Maria", "Bianchi", "maria@example.com", "password123", "ricercatore");
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            assertThat(u.getRuolo()).isEqualTo("ricercatore");
            return researcher;
        });
        when(jwtUtil.generateToken(anyString())).thenReturn("token");

        // Act
        authService.register(request);

        verify(userRepository).save(any(User.class));
    }

    // ── login ─────────────────────────────────────────────────────────────────

    @Test
    void givenValidCredentials_whenLogin_thenReturnsAuthResponse() {
        // Arrange
        LoginRequest request = new LoginRequest("mario@example.com", "password123");
        when(userRepository.findByEmail(request.getEmail())).thenReturn(Optional.of(savedUser));
        when(passwordEncoder.matches(request.getPassword(), savedUser.getPasswordHash())).thenReturn(true);
        when(jwtUtil.generateToken(savedUser.getEmail())).thenReturn("jwt-token");

        // Act
        AuthResponse response = authService.login(request);

        // Assert
        assertThat(response.getToken()).isEqualTo("jwt-token");
        assertThat(response.getUser().getEmail()).isEqualTo("mario@example.com");
    }

    @Test
    void givenUnknownEmail_whenLogin_thenThrowsInvalidCredentialsException() {
        // Arrange
        LoginRequest request = new LoginRequest("unknown@example.com", "password123");
        when(userRepository.findByEmail(request.getEmail())).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void givenWrongPassword_whenLogin_thenThrowsInvalidCredentialsException() {
        // Arrange
        LoginRequest request = new LoginRequest("mario@example.com", "wrongpassword");
        when(userRepository.findByEmail(request.getEmail())).thenReturn(Optional.of(savedUser));
        when(passwordEncoder.matches(request.getPassword(), savedUser.getPasswordHash())).thenReturn(false);

        // Act & Assert
        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    // ── changePassword ────────────────────────────────────────────────────────

    @Test
    void givenCorrectOldPassword_whenChangePassword_thenReturnsSuccessMessage() {
        // Arrange
        ChangePasswordRequest request = new ChangePasswordRequest("oldPassword", "newPassword");
        when(userRepository.findById(savedUser.getId())).thenReturn(Optional.of(savedUser));
        when(passwordEncoder.matches(request.getOldPassword(), savedUser.getPasswordHash())).thenReturn(true);
        when(passwordEncoder.encode(request.getNewPassword())).thenReturn("$2a$10$newhashedpassword");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        // Act
        String message = authService.changePassword(savedUser, request);

        // Assert
        assertThat(message).isEqualTo("Password changed successfully");
        verify(userRepository).save(savedUser);
    }

    @Test
    void givenUserNotFound_whenChangePassword_thenThrowsUserNotFoundException() {
        // Arrange
        ChangePasswordRequest request = new ChangePasswordRequest("oldPassword", "newPassword");
        when(userRepository.findById(savedUser.getId())).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> authService.changePassword(savedUser, request))
                .isInstanceOf(UserNotFoundException.class);
    }

    @Test
    void givenWrongOldPassword_whenChangePassword_thenThrowsInvalidCredentialsException() {
        // Arrange
        ChangePasswordRequest request = new ChangePasswordRequest("wrongOld", "newPassword");
        when(userRepository.findById(savedUser.getId())).thenReturn(Optional.of(savedUser));
        when(passwordEncoder.matches(request.getOldPassword(), savedUser.getPasswordHash())).thenReturn(false);

        // Act & Assert
        assertThatThrownBy(() -> authService.changePassword(savedUser, request))
                .isInstanceOf(InvalidCredentialsException.class);
    }
}
