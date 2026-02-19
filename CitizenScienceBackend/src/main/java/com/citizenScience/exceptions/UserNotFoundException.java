package com.citizenScience.exceptions;

/**
 * Exception thrown when a requested user is not found.
 */
public class UserNotFoundException extends RuntimeException {
    /**
     * Constructs a UserNotFoundException with the specified message.
     * 
     * @param message the detail message
     */
    public UserNotFoundException(String message) {
        super(message);
    }
}
