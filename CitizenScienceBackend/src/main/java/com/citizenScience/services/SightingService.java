package com.citizenScience.services;

import com.citizenScience.entities.Sighting;
import com.citizenScience.entities.User;
import com.citizenScience.repositories.SightingRepository;
import com.citizenScience.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class SightingService {

    private final SightingRepository sightingRepository;
    private final UserRepository userRepository;

    // GeometryFactory per creare punti PostGIS (SRID 4326 = WGS84)
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    // ═══════════════════════════════════════════════════════════════
    // CREAZIONE AVVISTAMENTO
    // ═══════════════════════════════════════════════════════════════

    public Sighting create(Long userId, String flowerName, String description,
                           double latitude, double longitude, LocalDateTime sightingDate) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Utente non trovato"));

        Point location = createPoint(latitude, longitude);

        Sighting sighting = Sighting.builder()
                .user(user)
                .flowerName(flowerName)
                .description(description)
                .location(location)
                .sightingDate(sightingDate != null ? sightingDate : LocalDateTime.now())
                .build();

        return sightingRepository.save(sighting);
    }

    // ═══════════════════════════════════════════════════════════════
    // LETTURA
    // ═══════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public Optional<Sighting> findById(Long id) {
        return sightingRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public List<Sighting> findAll() {
        return sightingRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<Sighting> findByUserId(Long userId) {
        return sightingRepository.findByUserIdOrderBySightingDateDesc(userId);
    }

    @Transactional(readOnly = true)
    public Page<Sighting> findByUserId(Long userId, Pageable pageable) {
        return sightingRepository.findByUserId(userId, pageable);
    }

    @Transactional(readOnly = true)
    public List<Sighting> findByFlowerName(String flowerName) {
        return sightingRepository.findByFlowerNameContainingIgnoreCase(flowerName);
    }

    // ═══════════════════════════════════════════════════════════════
    // QUERY GEOGRAFICHE
    // ═══════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public List<Sighting> findWithinRadius(double latitude, double longitude, double radiusMeters) {
        return sightingRepository.findWithinRadius(latitude, longitude, radiusMeters);
    }

    @Transactional(readOnly = true)
    public List<Sighting> findWithinBoundingBox(double minLat, double minLon, double maxLat, double maxLon) {
        return sightingRepository.findWithinBoundingBox(minLat, minLon, maxLat, maxLon);
    }

    @Transactional(readOnly = true)
    public List<Sighting> findNearestSightings(double latitude, double longitude, int limit) {
        return sightingRepository.findNearestSightings(latitude, longitude, limit);
    }

    // ═══════════════════════════════════════════════════════════════
    // AGGIORNAMENTO
    // ═══════════════════════════════════════════════════════════════

    public Sighting update(Long id, Long userId, String flowerName, String description,
                           Double latitude, Double longitude, LocalDateTime sightingDate) {

        Sighting sighting = sightingRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Avvistamento non trovato"));

        // Verifica che l'utente sia il proprietario
        if (!sighting.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("Non autorizzato a modificare questo avvistamento");
        }

        if (flowerName != null) {
            sighting.setFlowerName(flowerName);
        }

        if (description != null) {
            sighting.setDescription(description);
        }

        if (latitude != null && longitude != null) {
            sighting.setLocation(createPoint(latitude, longitude));
        }

        if (sightingDate != null) {
            sighting.setSightingDate(sightingDate);
        }

        return sightingRepository.save(sighting);
    }

    // ═══════════════════════════════════════════════════════════════
    // ELIMINAZIONE
    // ═══════════════════════════════════════════════════════════════

    public void delete(Long id, Long userId) {
        Sighting sighting = sightingRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Avvistamento non trovato"));

        // Verifica che l'utente sia il proprietario
        if (!sighting.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("Non autorizzato a eliminare questo avvistamento");
        }

        sightingRepository.delete(sighting);
    }

    // ═══════════════════════════════════════════════════════════════
    // UTILITY
    // ═══════════════════════════════════════════════════════════════

    private Point createPoint(double latitude, double longitude) {
        return geometryFactory.createPoint(new Coordinate(longitude, latitude));
    }
}