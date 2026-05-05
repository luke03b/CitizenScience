package com.citizenscience.controllers;

import com.citizenscience.dto.AvvistamentoResponse;
import com.citizenscience.dto.UpdateNotesRequest;
import com.citizenscience.entities.User;
import com.citizenscience.services.AvvistamentoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * REST controller for managing citizen science sightings.
 * 
 * Provides comprehensive CRUD operations for sightings including photo uploads,
 * geospatial queries, and user-specific filtering. Supports multipart/form-data
 * for photo uploads and various retrieval methods.
 * 
 * @author EcoFlora Team
 * @version 1.0
 */
@RestController
@RequestMapping("/api/sightings")
@Tag(name = "Sightings", description = "Endpoints for managing citizen science sightings")
public class SightingController {

    private final AvvistamentoService avvistamentoService;

    /**
     * Constructs a new SightingController with the specified AvvistamentoService.
     *
     * @param avvistamentoService the service handling sighting operations
     */
    public SightingController(AvvistamentoService avvistamentoService) {
        this.avvistamentoService = avvistamentoService;
    }

    /**
     * Creates a new sighting with a photo and location data.
     *
     * @param user the authenticated user creating the sighting
     * @param photo the photo file (required)
     * @param data the date and time of the sighting
     * @param latitudine the latitude coordinate
     * @param longitudine the longitude coordinate
     * @param note optional notes about the sighting
     * @param aiModel optional AI model name to use for identification; overrides the user's default
     *                selection for this sighting only
     * @return ResponseEntity containing the created sighting details
     * @throws IOException if photo processing fails
     */
    @PostMapping
    @Operation(summary = "Create a new sighting", description = "Creates a new citizen science sighting with one photo required")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "Sighting successfully created"),
        @ApiResponse(responseCode = "400", description = "Invalid input data or missing required photo"),
        @ApiResponse(responseCode = "401", description = "User not authenticated")
    })
    public ResponseEntity<AvvistamentoResponse> createSighting(
            @AuthenticationPrincipal User user,
            @Parameter(description = "Photo of the sighting (required)", required = true) @RequestParam(value = "photo") MultipartFile photo,
            @Parameter(description = "Date and time of the sighting", required = true) @RequestParam("data") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime data,
            @Parameter(description = "Latitude coordinate", required = true) @RequestParam("latitudine") Double latitudine,
            @Parameter(description = "Longitude coordinate", required = true) @RequestParam("longitudine") Double longitudine,
            @Parameter(description = "Optional notes about the sighting") @RequestParam(value = "note", required = false) String note,
            @Parameter(description = "Optional AI model override for this sighting only") @RequestParam(value = "aiModel", required = false) String aiModel) throws IOException {
        
        AvvistamentoResponse response = avvistamentoService.createAvvistamento(
                user, photo, data, latitudine, longitudine, note, aiModel);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Updates the notes for an existing sighting.
     *
     * @param user the authenticated user requesting the update
     * @param id the UUID of the sighting to update
     * @param request the update request containing new notes
     * @return ResponseEntity containing the updated sighting
     */
    @PutMapping("/{id}/notes")
    @Operation(summary = "Update sighting notes", description = "Updates the notes for a specific sighting")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Notes successfully updated"),
        @ApiResponse(responseCode = "400", description = "Invalid input data"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User not authorized to update this sighting"),
        @ApiResponse(responseCode = "404", description = "Sighting not found")
    })
    public ResponseEntity<AvvistamentoResponse> updateNotes(
            @AuthenticationPrincipal User user,
            @Parameter(description = "Sighting ID", required = true) @PathVariable UUID id,
            @Valid @RequestBody UpdateNotesRequest request) {
        
        AvvistamentoResponse response = avvistamentoService.updateNotes(user, id, request);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    /**
     * Deletes a sighting and all its associated photos.
     *
     * @param user the authenticated user requesting the deletion
     * @param id the UUID of the sighting to delete
     * @return ResponseEntity with no content on success
     * @throws IOException if photo deletion fails
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a sighting", description = "Deletes a specific sighting and associated photos")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "204", description = "Sighting successfully deleted"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User not authorized to delete this sighting"),
        @ApiResponse(responseCode = "404", description = "Sighting not found")
    })
    public ResponseEntity<Void> deleteSighting(
            @AuthenticationPrincipal User user,
            @Parameter(description = "Sighting ID", required = true) @PathVariable UUID id) throws IOException {
        
        avvistamentoService.deleteAvvistamento(user, id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    /**
     * Retrieves all sightings in the system.
     *
     * @return ResponseEntity containing a list of all sightings
     */
    @GetMapping
    @Operation(summary = "Get all sightings", description = "Retrieves a list of all sightings in the system")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved sightings list")
    })
    public ResponseEntity<List<AvvistamentoResponse>> getAllSightings() {
        List<AvvistamentoResponse> sightings = avvistamentoService.getAllAvvistamenti();
        return new ResponseEntity<>(sightings, HttpStatus.OK);
    }

    /**
     * Retrieves all sightings created by a specific user.
     *
     * @param userId the UUID of the user
     * @return ResponseEntity containing a list of the user's sightings
     */
    @GetMapping("/user/{userId}")
    @Operation(summary = "Get sightings by user", description = "Retrieves all sightings created by a specific user")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved user's sightings"),
        @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<List<AvvistamentoResponse>> getSightingsByUser(
            @Parameter(description = "User ID", required = true) @PathVariable UUID userId) {
        List<AvvistamentoResponse> sightings = avvistamentoService.getAvvistamentiByUser(userId);
        return new ResponseEntity<>(sightings, HttpStatus.OK);
    }

    /**
     * Retrieves sightings within a specified radius of a geographic point.
     * Uses PostGIS spatial queries for efficient geospatial filtering.
     *
     * @param lat the latitude coordinate of the center point
     * @param lng the longitude coordinate of the center point
     * @param radiusKm the search radius in kilometers
     * @return ResponseEntity containing a list of nearby sightings
     */
    @GetMapping("/location")
    @Operation(summary = "Get sightings by location", description = "Retrieves sightings within a specified radius of a geographic point")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved nearby sightings")
    })
    public ResponseEntity<List<AvvistamentoResponse>> getSightingsByLocation(
            @Parameter(description = "Latitude coordinate", required = true) @RequestParam("lat") Double lat,
            @Parameter(description = "Longitude coordinate", required = true) @RequestParam("lng") Double lng,
            @Parameter(description = "Search radius in kilometers", required = true) @RequestParam("radiusKm") Double radiusKm) {
        
        List<AvvistamentoResponse> sightings = avvistamentoService.getAvvistamentiByLocation(lat, lng, radiusKm);
        return new ResponseEntity<>(sightings, HttpStatus.OK);
    }
}
