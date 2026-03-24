package com.citizenScience.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity representing the mapping between an AI model and the container that hosts it.
 * Populated by force-scanning all configured AI containers via their /models endpoint.
 */
@Entity
@Table(name = "ai_container_models")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiContainerModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Name of the AI model (e.g., "model_full_internet_last.pt"). */
    @Column(nullable = false, unique = true)
    private String modelName;

    /** Docker service / container name that exposes this model (e.g., "ai_service"). */
    @Column(nullable = false)
    private String containerName;

    /** Timestamp when this entry was last discovered/updated. */
    @Column(nullable = false)
    private LocalDateTime discoveredAt;

    /** Optional human-readable description of the model, reported by the AI container. */
    @Column(columnDefinition = "TEXT")
    private String description;

    /**
     * Whether this model is the system-wide default for identification requests.
     * At most one model across the entire table may have this flag set to {@code true}.
     */
    @Column(name = "is_default", nullable = false)
    private boolean isDefault;
}
