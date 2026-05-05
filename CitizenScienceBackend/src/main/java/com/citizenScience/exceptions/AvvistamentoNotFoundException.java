package com.citizenscience.exceptions;

/**
 * Exception thrown when a requested sighting is not found.
 */
public class AvvistamentoNotFoundException extends RuntimeException {
    /**
     * Constructs an AvvistamentoNotFoundException with the specified message.
     * 
     * @param message the detail message
     */
    public AvvistamentoNotFoundException(String message) {
        super(message);
    }
}
