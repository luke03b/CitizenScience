package com.citizenscience.exceptions;

/**
 * Exception thrown when a user attempts an unauthorized action.
 */
public class UnauthorizedAccessException extends RuntimeException {
    /**
     * Constructs an UnauthorizedAccessException with the specified message.
     * 
     * @param message the detail message
     */
    public UnauthorizedAccessException(String message) {
        super(message);
    }
}
