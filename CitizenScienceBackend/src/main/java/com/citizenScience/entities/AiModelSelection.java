package com.citizenScience.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity representing an AI model selection by a researcher.
 * Tracks which AI model a researcher has chosen for flower identification.
 */
@Entity
@Table(name = "ai_model_selection")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiModelSelection {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String modelName;

    @Column(nullable = false)
    private LocalDateTime selectedAt;
}
