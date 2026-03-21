package com.citizenScience.repositories;

import com.citizenScience.entities.AiContainerModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Repository interface for AiContainerModel entity data access.
 * Provides methods for querying the model-to-container mapping table.
 */
@Repository
public interface AiContainerModelRepository extends JpaRepository<AiContainerModel, UUID> {

    /**
     * Finds the container mapping for a specific model name.
     *
     * @param modelName the AI model filename (e.g., "model_full_internet_last.pt")
     * @return Optional containing the mapping if found
     */
    Optional<AiContainerModel> findByModelName(String modelName);

    /**
     * Finds all model mappings for a specific container.
     *
     * @param containerName the Docker service / container name
     * @return list of model mappings hosted by this container
     */
    List<AiContainerModel> findByContainerName(String containerName);

    /**
     * Bulk-deletes all model mappings for a specific container.
     * Used during a force-scan to remove stale entries before re-populating.
     *
     * @param containerName the Docker service / container name
     */
    @Modifying
    @Query("DELETE FROM AiContainerModel m WHERE m.containerName = :containerName")
    void deleteByContainerName(@Param("containerName") String containerName);
}
