package com.citizenScience.controllers;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

/**
 * REST controller for serving sighting photos.
 * Provides endpoints to retrieve photo files associated with sightings.
 */
@RestController
@RequestMapping("/api/photos")
@Tag(name = "Photos", description = "Endpoints for serving sighting photos")
public class PhotoController {

    private static final Logger logger = LoggerFactory.getLogger(PhotoController.class);

    @Value("${app.upload.dir}")
    private String uploadDir;

    /**
     * Initializes the photo upload directory on application startup.
     * Creates the directory if it doesn't exist.
     * 
     * @throws IllegalStateException if the directory cannot be created or accessed
     */
    @PostConstruct
    public void init() {
        Path uploadPath = Paths.get(uploadDir);
        if (!Files.exists(uploadPath)) {
            try {
                Files.createDirectories(uploadPath);
                logger.info("Created upload directory: {}", uploadDir);
            } catch (IOException e) {
                logger.error("Failed to create upload directory: {}", uploadDir, e);
                throw new IllegalStateException("Cannot initialize photo upload directory", e);
            }
        } else if (!Files.isDirectory(uploadPath) || !Files.isReadable(uploadPath)) {
            throw new IllegalStateException("Upload directory is not accessible: " + uploadDir);
        }
        logger.info("Photo upload directory initialized: {}", uploadDir);
    }

    /**
     * Retrieves a photo file for a specific sighting.
     * Includes security checks to prevent path traversal attacks.
     * 
     * @param avvistamentoId the UUID of the sighting
     * @param filename the name of the photo file
     * @return ResponseEntity containing the photo resource or 404 if not found
     */
    @GetMapping("/{avvistamentoId}/{filename:.+}")
    @Operation(summary = "Get photo", description = "Retrieves a photo file for a specific sighting")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Photo successfully retrieved"),
        @ApiResponse(responseCode = "404", description = "Photo not found")
    })
    public ResponseEntity<Resource> getPhoto(
            @Parameter(description = "Sighting ID", required = true) @PathVariable String avvistamentoId,
            @Parameter(description = "Photo filename", required = true) @PathVariable String filename) {
        
        try {
            // Validate that avvistamentoId is a valid UUID
            try {
                UUID.fromString(avvistamentoId);
            } catch (IllegalArgumentException e) {
                logger.warn("Invalid UUID format for avvistamentoId: {}", avvistamentoId);
                return ResponseEntity.notFound().build();
            }
            
            // Construct the file path
            Path filePath = Paths.get(uploadDir).resolve(avvistamentoId).resolve(filename).normalize();
            
            // Security check: ensure the resolved path is within the upload directory
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            if (!filePath.toAbsolutePath().normalize().startsWith(uploadPath)) {
                logger.warn("Attempted path traversal attack: {}", filePath);
                return ResponseEntity.notFound().build();
            }
            
            // Check if file exists
            if (!Files.exists(filePath) || !Files.isRegularFile(filePath)) {
                logger.warn("Photo not found: {}", filePath);
                return ResponseEntity.notFound().build();
            }
            
            // Load file as Resource
            Resource resource = new UrlResource(filePath.toUri());
            
            // Determine content type
            String contentType = Files.probeContentType(filePath);
            if (contentType == null) {
                contentType = "application/octet-stream";
            }
            
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                    .body(resource);
                    
        } catch (MalformedURLException e) {
            logger.error("Malformed URL for photo: {}/{}", avvistamentoId, filename, e);
            return ResponseEntity.notFound().build();
        } catch (IOException e) {
            logger.error("Error reading photo: {}/{}", avvistamentoId, filename, e);
            return ResponseEntity.notFound().build();
        }
    }
}
