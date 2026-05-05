package com.citizenscience.exceptions;

/**
 * Exception thrown when login credentials are invalid.
 */
public class InvalidCredentialsException extends RuntimeException {
    /**
     * Constructs an InvalidCredentialsException with the specified message.
     * 
     * @param message the detail message
     */
    public InvalidCredentialsException(String message) {
        super(message);
    }
}
