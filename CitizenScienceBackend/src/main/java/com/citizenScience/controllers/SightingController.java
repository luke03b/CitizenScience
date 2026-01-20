package com.citizenScience.controllers;

import com.citizenScience.dto.ApiResponse;
import com.citizenScience.dto.SightingDTO;
import com.citizenScience.entities.Sighting;
import com.citizenScience.services.SightingService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sightings")
@RequiredArgsConstructor
public class SightingController {

    private final SightingService sightingService;

    @PostMapping
    public ResponseEntity<?> create(@RequestBody SightingDTO request) {
        try {
            Sighting sighting = sightingService.create(
                    request.getUserId(),
                    request.getFlowerName(),
                    request.getDescription(),
                    request.getLatitude(),
                    request.getLongitude(),
                    request.getSightingDate()
            );
            return ResponseEntity.ok(SightingDTO.fromEntity(sighting));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Creazione fallita", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return sightingService.findById(id)
                .map(sighting -> ResponseEntity.ok(SightingDTO.fromEntity(sighting)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<SightingDTO>> getAll() {
        List<SightingDTO> sightings = sightingService.findAll().stream()
                .map(SightingDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(sightings);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<SightingDTO>> getByUserId(@PathVariable Long userId) {
        List<SightingDTO> sightings = sightingService.findByUserId(userId).stream()
                .map(SightingDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(sightings);
    }

    @GetMapping("/user/{userId}/paged")
    public ResponseEntity<Page<SightingDTO>> getByUserIdPaged(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by("sightingDate").descending());
        Page<SightingDTO> sightings = sightingService.findByUserId(userId, pageRequest)
                .map(SightingDTO::fromEntity);
        return ResponseEntity.ok(sightings);
    }

    @GetMapping("/search")
    public ResponseEntity<List<SightingDTO>> searchByFlowerName(@RequestParam String flowerName) {
        List<SightingDTO> sightings = sightingService.findByFlowerName(flowerName).stream()
                .map(SightingDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(sightings);
    }

    @GetMapping("/nearby")
    public ResponseEntity<List<SightingDTO>> getNearby(
            @RequestParam double latitude,
            @RequestParam double longitude,
            @RequestParam(defaultValue = "5000") double radiusMeters) {

        List<SightingDTO> sightings = sightingService
                .findWithinRadius(latitude, longitude, radiusMeters).stream()
                .map(SightingDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(sightings);
    }

    @GetMapping("/bounds")
    public ResponseEntity<List<SightingDTO>> getWithinBounds(
            @RequestParam double minLat,
            @RequestParam double minLon,
            @RequestParam double maxLat,
            @RequestParam double maxLon) {

        List<SightingDTO> sightings = sightingService
                .findWithinBoundingBox(minLat, minLon, maxLat, maxLon).stream()
                .map(SightingDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(sightings);
    }

    @GetMapping("/nearest")
    public ResponseEntity<List<SightingDTO>> getNearest(
            @RequestParam double latitude,
            @RequestParam double longitude,
            @RequestParam(defaultValue = "10") int limit) {

        List<SightingDTO> sightings = sightingService
                .findNearestSightings(latitude, longitude, limit).stream()
                .map(SightingDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(sightings);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody SightingDTO request) {
        try {
            Sighting sighting = sightingService.update(
                    id,
                    request.getUserId(),
                    request.getFlowerName(),
                    request.getDescription(),
                    request.getLatitude(),
                    request.getLongitude(),
                    request.getSightingDate()
            );
            return ResponseEntity.ok(SightingDTO.fromEntity(sighting));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Aggiornamento fallito", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id, @RequestParam Long userId) {
        try {
            sightingService.delete(id, userId);
            return ResponseEntity.ok(ApiResponse.success("Avvistamento eliminato con successo"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Eliminazione fallita", e.getMessage()));
        }
    }
}