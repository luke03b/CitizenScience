package com.citizenScience.repositories;

import com.citizenScience.entities.Sighting;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SightingRepository extends JpaRepository<Sighting, Long> {

    // ═══════════════════════════════════════════════════════════════
    // QUERY PER UTENTE (Collezione personale)
    // ═══════════════════════════════════════════════════════════════

    List<Sighting> findByUserIdOrderBySightingDateDesc(Long userId);

    Page<Sighting> findByUserId(Long userId, Pageable pageable);

    long countByUserId(Long userId);

    // ═══════════════════════════════════════════════════════════════
    // QUERY PER NOME FIORE
    // ═══════════════════════════════════════════════════════════════

    List<Sighting> findByFlowerNameContainingIgnoreCase(String flowerName);

    // ═══════════════════════════════════════════════════════════════
    // QUERY PER DATA
    // ═══════════════════════════════════════════════════════════════

    List<Sighting> findBySightingDateBetween(LocalDateTime start, LocalDateTime end);

    // ═══════════════════════════════════════════════════════════════
    // QUERY GEOGRAFICHE (PostGIS)
    // ═══════════════════════════════════════════════════════════════

    /**
     * Trova avvistamenti entro un raggio (in metri) da un punto
     */
    @Query(value = """
        SELECT s.* FROM sightings s
        WHERE ST_DWithin(
            s.location::geography,
            ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography,
            :radiusMeters
        )
        ORDER BY s.sighting_date DESC
        """, nativeQuery = true)
    List<Sighting> findWithinRadius(
            @Param("latitude") double latitude,
            @Param("longitude") double longitude,
            @Param("radiusMeters") double radiusMeters
    );

    /**
     * Trova avvistamenti dentro un bounding box (per caricamento mappa)
     */
    @Query(value = """
        SELECT s.* FROM sightings s
        WHERE ST_Within(
            s.location,
            ST_MakeEnvelope(:minLon, :minLat, :maxLon, :maxLat, 4326)
        )
        ORDER BY s.sighting_date DESC
        """, nativeQuery = true)
    List<Sighting> findWithinBoundingBox(
            @Param("minLat") double minLat,
            @Param("minLon") double minLon,
            @Param("maxLat") double maxLat,
            @Param("maxLon") double maxLon
    );

    /**
     * Trova gli avvistamenti più vicini a un punto
     */
    @Query(value = """
        SELECT s.* FROM sightings s
        ORDER BY s.location <-> ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)
        LIMIT :limit
        """, nativeQuery = true)
    List<Sighting> findNearestSightings(
            @Param("latitude") double latitude,
            @Param("longitude") double longitude,
            @Param("limit") int limit
    );
}