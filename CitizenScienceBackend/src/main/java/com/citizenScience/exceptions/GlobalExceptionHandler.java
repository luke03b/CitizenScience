package com.citizenscience.exceptions;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler for the application.
 * Catches and handles exceptions across all controllers, converting them to appropriate HTTP responses.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * Handles UserNotFoundException exceptions.
     * 
     * @param ex the exception
     * @return ResponseEntity with error message and 404 status
     */
    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleUserNotFound(UserNotFoundException ex) {
        return createErrorResponse(ex.getMessage(), HttpStatus.NOT_FOUND);
    }

    /**
     * Handles UserAlreadyExistsException exceptions.
     * 
     * @param ex the exception
     * @return ResponseEntity with error message and 409 status
     */
    @ExceptionHandler(UserAlreadyExistsException.class)
    public ResponseEntity<Map<String, String>> handleUserAlreadyExists(UserAlreadyExistsException ex) {
        return createErrorResponse(ex.getMessage(), HttpStatus.CONFLICT);
    }

    /**
     * Handles InvalidCredentialsException exceptions.
     * 
     * @param ex the exception
     * @return ResponseEntity with error message and 401 status
     */
    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<Map<String, String>> handleInvalidCredentials(InvalidCredentialsException ex) {
        return createErrorResponse(ex.getMessage(), HttpStatus.UNAUTHORIZED);
    }

    /**
     * Handles AvvistamentoNotFoundException exceptions.
     * 
     * @param ex the exception
     * @return ResponseEntity with error message and 404 status
     */
    @ExceptionHandler(AvvistamentoNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleAvvistamentoNotFound(AvvistamentoNotFoundException ex) {
        return createErrorResponse(ex.getMessage(), HttpStatus.NOT_FOUND);
    }

    /**
     * Handles UnauthorizedAccessException exceptions.
     * 
     * @param ex the exception
     * @return ResponseEntity with error message and 403 status
     */
    @ExceptionHandler(UnauthorizedAccessException.class)
    public ResponseEntity<Map<String, String>> handleUnauthorizedAccess(UnauthorizedAccessException ex) {
        return createErrorResponse(ex.getMessage(), HttpStatus.FORBIDDEN);
    }

    /**
     * Handles validation exceptions from request body validation.
     * 
     * @param ex the validation exception
     * @return ResponseEntity with field error messages and 400 status
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        return new ResponseEntity<>(errors, HttpStatus.BAD_REQUEST);
    }

    /**
     * Handles all uncaught exceptions.
     * 
     * @param ex the exception
     * @return ResponseEntity with generic error message and 500 status
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGenericException(Exception ex) {
        logger.error("Unexpected error occurred", ex);
        return createErrorResponse("An unexpected error occurred", HttpStatus.INTERNAL_SERVER_ERROR);
    }

    /**
     * Helper method to create error response with consistent format.
     * 
     * @param message the error message
     * @param status the HTTP status
     * @return ResponseEntity with error map and status
     */
    private ResponseEntity<Map<String, String>> createErrorResponse(String message, HttpStatus status) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return new ResponseEntity<>(error, status);
    }
}
