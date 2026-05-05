package com.citizenscience.repositories;

import com.citizenscience.entities.AiModelSelection;
import com.citizenscience.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Repository interface for AiModelSelection entity data access.
 * Provides methods for AI model selection-related database operations.
 */
@Repository
public interface AiModelSelectionRepository extends JpaRepository<AiModelSelection, UUID> {
    /**
     * Finds the AI model selection for a specific user.
     * 
     * @param user the user entity
     * @return Optional containing the model selection if found
     */
    Optional<AiModelSelection> findByUser(User user);
}
