package com.citizenscience.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Entity representing a photo associated with a sighting.
 * Stores the file path relative to the upload directory.
 */
@Entity
@Table(name = "foto_avvistamenti")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FotoAvvistamento {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "avvistamento_id", nullable = false)
    private Avvistamento avvistamento;

    @Column(nullable = false, name = "photo_path")
    private String photoPath;
}
