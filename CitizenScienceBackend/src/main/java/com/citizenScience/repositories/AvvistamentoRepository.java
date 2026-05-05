package com.citizenscience.repositories;

import com.citizenscience.entities.Avvistamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

/**
 * Repository interface for Avvistamento entity data access.
 * Provides methods for sighting-related database operations including spatial queries.
 */
public interface AvvistamentoRepository extends JpaRepository<Avvistamento, UUID> {
    /**
     * Finds all sightings created by a specific user.
     * 
     * @param userId the user ID
     * @return list of sightings by the user
     */
    List<Avvistamento> findByUserId(UUID userId);

    /**
     * Finds all sightings within a specified radius from a point.
     * Uses PostGIS spatial functions for geographic distance calculation.
     * 
     * @param lat the latitude coordinate
     * @param lng the longitude coordinate
     * @param radiusMeters the search radius in meters
     * @return list of sightings within the radius
     */
    @Query(value = "SELECT * FROM avvistamenti WHERE ST_DWithin(posizione::geography, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radiusMeters)",
            nativeQuery = true)
    List<Avvistamento> findWithinRadius(@Param("lat") Double lat, @Param("lng") Double lng, @Param("radiusMeters") Double radiusMeters);
}
