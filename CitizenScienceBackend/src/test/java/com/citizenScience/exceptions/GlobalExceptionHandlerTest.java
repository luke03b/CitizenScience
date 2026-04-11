package com.citizenScience.exceptions;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for GlobalExceptionHandler.
 * Each test instantiates the handler directly and verifies the HTTP status
 * and the {@code "error"} key in the response body.
 */
class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    // ── UserNotFoundException → 404 ───────────────────────────────────────────

    @Test
    void givenUserNotFoundException_whenHandled_thenReturns404WithErrorMessage() {
        // Arrange
        UserNotFoundException ex = new UserNotFoundException("User not found");

        // Act
        ResponseEntity<Map<String, String>> response = handler.handleUserNotFound(ex);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).containsEntry("error", "User not found");
    }

    // ── UserAlreadyExistsException → 409 ─────────────────────────────────────

    @Test
    void givenUserAlreadyExistsException_whenHandled_thenReturns409WithErrorMessage() {
        // Arrange
        UserAlreadyExistsException ex = new UserAlreadyExistsException("Email already in use");

        // Act
        ResponseEntity<Map<String, String>> response = handler.handleUserAlreadyExists(ex);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody()).containsEntry("error", "Email already in use");
    }

    // ── InvalidCredentialsException → 401 ────────────────────────────────────

    @Test
    void givenInvalidCredentialsException_whenHandled_thenReturns401WithErrorMessage() {
        // Arrange
        InvalidCredentialsException ex = new InvalidCredentialsException("Invalid email or password");

        // Act
        ResponseEntity<Map<String, String>> response = handler.handleInvalidCredentials(ex);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getBody()).containsEntry("error", "Invalid email or password");
    }

    // ── AvvistamentoNotFoundException → 404 ──────────────────────────────────

    @Test
    void givenAvvistamentoNotFoundException_whenHandled_thenReturns404WithErrorMessage() {
        // Arrange
        AvvistamentoNotFoundException ex = new AvvistamentoNotFoundException("Sighting not found");

        // Act
        ResponseEntity<Map<String, String>> response = handler.handleAvvistamentoNotFound(ex);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).containsEntry("error", "Sighting not found");
    }

    // ── UnauthorizedAccessException → 403 ────────────────────────────────────

    @Test
    void givenUnauthorizedAccessException_whenHandled_thenReturns403WithErrorMessage() {
        // Arrange
        UnauthorizedAccessException ex = new UnauthorizedAccessException("Access denied");

        // Act
        ResponseEntity<Map<String, String>> response = handler.handleUnauthorizedAccess(ex);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(response.getBody()).containsEntry("error", "Access denied");
    }

    // ── MethodArgumentNotValidException → 400 ────────────────────────────────

    @Test
    void givenValidationException_whenHandled_thenReturns400WithFieldErrors() {
        // Arrange – build a minimal MethodArgumentNotValidException via binding result
        Object target = new Object();
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(target, "target");
        bindingResult.addError(new FieldError("target", "email", "Email should be valid"));
        bindingResult.addError(new FieldError("target", "nome", "Nome is required"));

        MethodArgumentNotValidException ex = new MethodArgumentNotValidException(null, bindingResult);

        // Act
        ResponseEntity<Map<String, String>> response = handler.handleValidationExceptions(ex);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody())
                .containsEntry("email", "Email should be valid")
                .containsEntry("nome", "Nome is required");
    }

    // ── Generic Exception → 500 ───────────────────────────────────────────────

    @Test
    void givenGenericException_whenHandled_thenReturns500WithGenericMessage() {
        // Arrange
        RuntimeException ex = new RuntimeException("Something went wrong");

        // Act
        ResponseEntity<Map<String, String>> response = handler.handleGenericException(ex);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).containsEntry("error", "An unexpected error occurred");
    }
}
