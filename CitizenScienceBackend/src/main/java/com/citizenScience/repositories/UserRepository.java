package com.citizenScience.repositories;

import com.citizenScience.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

/**
 * Repository interface for User entity data access.
 * Provides methods for user-related database operations.
 */
public interface UserRepository extends JpaRepository<User, UUID> {
    /**
     * Finds a user by email address.
     * 
     * @param email the email address
     * @return Optional containing the user if found
     */
    Optional<User> findByEmail(String email);
    
    /**
     * Checks if a user with the given email exists.
     * 
     * @param email the email address
     * @return true if user exists, false otherwise
     */
    boolean existsByEmail(String email);
}
