package com.citizenScience.entities;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Point;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "sightings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Sighting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "flower_name", nullable = false, length = 200)
    private String flowerName;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, columnDefinition = "GEOMETRY(Point, 4326)")
    private Point location;

    @Column(name = "sighting_date", nullable = false)
    private LocalDateTime sightingDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "sighting", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<SightingPhoto> photos = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Helper methods
    public void addPhoto(SightingPhoto photo) {
        photos.add(photo);
        photo.setSighting(this);
    }

    public void removePhoto(SightingPhoto photo) {
        photos.remove(photo);
        photo.setSighting(null);
    }

    public Double getLatitude() {
        return location != null ? location.getY() : null;
    }

    public Double getLongitude() {
        return location != null ? location.getX() : null;
    }
}