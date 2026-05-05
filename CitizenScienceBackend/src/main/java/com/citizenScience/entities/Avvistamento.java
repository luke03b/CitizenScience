package com.citizenscience.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.locationtech.jts.geom.Point;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Entity representing a sighting (avvistamento) of a flower.
 * Contains location information, photos, and identification details.
 */
@Entity
@Table(name = "avvistamenti")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Avvistamento {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String nome;

    @Column(columnDefinition = "geometry(Point,4326)")
    private Point posizione;

    @Column(nullable = false)
    private Double latitudine;

    @Column(nullable = false)
    private Double longitudine;

    @Column(nullable = false)
    private LocalDateTime data;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(length = 500)
    private String indirizzo;

    @OneToMany(mappedBy = "avvistamento", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<FotoAvvistamento> foto = new ArrayList<>();

    @Column(length = 255)
    private String aiModelUsed;

    @Column
    private Double aiConfidence;
}
