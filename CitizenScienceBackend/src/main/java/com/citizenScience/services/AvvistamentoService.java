package com.citizenScience.services;

import com.citizenScience.dto.AvvistamentoResponse;
import com.citizenScience.dto.UpdateNotesRequest;
import com.citizenScience.entities.Avvistamento;
import com.citizenScience.entities.FotoAvvistamento;
import com.citizenScience.entities.User;
import com.citizenScience.exceptions.AvvistamentoNotFoundException;
import com.citizenScience.exceptions.UnauthorizedAccessException;
import com.citizenScience.repositories.AvvistamentoRepository;
import com.citizenScience.repositories.FotoAvvistamentoRepository;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Service for managing sighting (avvistamento) operations.
 * Handles creation, updates, deletion, and retrieval of sightings with photo management.
 */
@Service
public class AvvistamentoService {

    private static final Logger logger = LoggerFactory.getLogger(AvvistamentoService.class);
    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024;
    
    private final AvvistamentoRepository avvistamentoRepository;
    private final FotoAvvistamentoRepository fotoAvvistamentoRepository;
    private final GeocodingService geocodingService;
    private final AiService aiService;
    private final GeometryFactory geometryFactory;

    @Value("${app.upload.dir}")
    private String uploadDir;

    /**
     * Constructs the AvvistamentoService with required dependencies.
     * 
     * @param avvistamentoRepository the repository for sighting data access
     * @param fotoAvvistamentoRepository the repository for photo data access
     * @param geocodingService the service for geocoding operations
     * @param aiService the service for AI flower identification
     */
    public AvvistamentoService(AvvistamentoRepository avvistamentoRepository, 
                               FotoAvvistamentoRepository fotoAvvistamentoRepository,
                               GeocodingService geocodingService,
                               AiService aiService) {
        this.avvistamentoRepository = avvistamentoRepository;
        this.fotoAvvistamentoRepository = fotoAvvistamentoRepository;
        this.geocodingService = geocodingService;
        this.aiService = aiService;
        this.geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
    }

    /**
     * Creates a new sighting with a photo, location, and AI flower identification.
     *
     * @param user the user creating the sighting
     * @param photo the photo file (required)
     * @param data the date and time of the sighting
     * @param latitudine the latitude coordinate
     * @param longitudine the longitude coordinate
     * @param note optional notes about the sighting
     * @param aiModelOverride optional AI model name to use instead of the user's default selection
     * @return AvvistamentoResponse containing the created sighting details
     * @throws IllegalArgumentException if no photo provided or invalid file
     * @throws IOException if photo storage fails
     */
    @Transactional
    public AvvistamentoResponse createAvvistamento(User user, MultipartFile photo, LocalDateTime data,
                                                    Double latitudine, Double longitudine, String note,
                                                    String aiModelOverride) throws IOException {
        if (photo == null || photo.isEmpty()) {
            throw new IllegalArgumentException("A photo is required for creating a sighting");
        }

        Point point = geometryFactory.createPoint(new Coordinate(longitudine, latitudine));

        String indirizzo = geocodingService.reverseGeocode(latitudine, longitudine);
        logger.info("Resolved address for coordinates ({}, {}): {}", latitudine, longitudine, indirizzo);

        String flowerName = "Avvistamento";
        String aiModelUsed = null;
        Double aiConfidence = null;
        
        try {
            var identificationResult = aiService.identifyFlower(photo, user, aiModelOverride);
            flowerName = identificationResult.getFlowerName();
            aiModelUsed = identificationResult.getModelUsed();
            aiConfidence = identificationResult.getConfidence();
            logger.info("Flower identified as: {} with confidence: {}", flowerName, aiConfidence);
        } catch (Exception e) {
            logger.warn("Could not identify flower, using default name", e);
        }

        Avvistamento avvistamento = Avvistamento.builder()
                .nome(flowerName)
                .posizione(point)
                .latitudine(latitudine)
                .longitudine(longitudine)
                .data(data)
                .user(user)
                .note(note)
                .indirizzo(indirizzo)
                .foto(new ArrayList<>())
                .aiModelUsed(aiModelUsed)
                .aiConfidence(aiConfidence)
                .build();

        avvistamento = avvistamentoRepository.save(avvistamento);

        List<FotoAvvistamento> fotoList = savePhoto(avvistamento, photo);
        avvistamento.setFoto(fotoList);

        return AvvistamentoResponse.from(avvistamento);
    }

    /**
     * Saves a photo for a sighting to the file system and database.
     * 
     * @param avvistamento the sighting entity
     * @param photo the photo file
     * @return list containing the saved FotoAvvistamento entity
     * @throws IOException if file operations fail
     */
    private List<FotoAvvistamento> savePhoto(Avvistamento avvistamento, MultipartFile photo) throws IOException {
        List<FotoAvvistamento> fotoList = new ArrayList<>();
        String avvistamentoDir = uploadDir + "/" + avvistamento.getId();
        Path uploadPath = Paths.get(avvistamentoDir);

        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        validateImageFile(photo);

        String originalFilename = photo.getOriginalFilename();
        String sanitizedFilename = sanitizeFilename(originalFilename);
        String fileName = UUID.randomUUID() + "_" + sanitizedFilename;
        Path filePath = uploadPath.resolve(fileName);

        if (!filePath.normalize().startsWith(uploadPath.normalize())) {
            throw new IllegalArgumentException("Invalid file upload");
        }

        Files.copy(photo.getInputStream(), filePath);

        String relativePath = avvistamento.getId() + "/" + fileName;
        FotoAvvistamento foto = FotoAvvistamento.builder()
                .avvistamento(avvistamento)
                .photoPath(relativePath)
                .build();
        foto = fotoAvvistamentoRepository.save(foto);
        fotoList.add(foto);

        return fotoList;
    }

    /**
     * Validates that the uploaded file is an image and within size limits.
     * 
     * @param file the file to validate
     * @throws IllegalArgumentException if validation fails
     */
    private void validateImageFile(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("Only image files are allowed");
        }
        
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("File size exceeds maximum allowed size of 10MB");
        }
    }

    /**
     * Sanitizes a filename by removing potentially dangerous characters.
     * 
     * @param filename the original filename
     * @return sanitized filename
     */
    private String sanitizeFilename(String filename) {
        if (filename == null) {
            return "unnamed.jpg";
        }
        return filename.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    /**
     * Updates the notes for an existing sighting.
     * 
     * @param user the authenticated user
     * @param avvistamentoId the sighting ID
     * @param request the update request containing new notes
     * @return AvvistamentoResponse with updated sighting
     * @throws AvvistamentoNotFoundException if sighting not found
     * @throws UnauthorizedAccessException if user doesn't own the sighting
     */
    @Transactional
    public AvvistamentoResponse updateNotes(User user, UUID avvistamentoId, UpdateNotesRequest request) {
        Avvistamento avvistamento = avvistamentoRepository.findById(avvistamentoId)
                .orElseThrow(() -> new AvvistamentoNotFoundException("Avvistamento not found"));

        if (!avvistamento.getUser().getId().equals(user.getId())) {
            throw new UnauthorizedAccessException("You are not authorized to update this avvistamento");
        }

        avvistamento.setNote(request.getNote());
        avvistamento = avvistamentoRepository.save(avvistamento);

        return AvvistamentoResponse.from(avvistamento);
    }

    /**
     * Deletes a sighting and all associated photos.
     * 
     * @param user the authenticated user
     * @param avvistamentoId the sighting ID
     * @throws AvvistamentoNotFoundException if sighting not found
     * @throws UnauthorizedAccessException if user doesn't own the sighting
     * @throws IOException if file deletion fails
     */
    @Transactional
    public void deleteAvvistamento(User user, UUID avvistamentoId) throws IOException {
        Avvistamento avvistamento = avvistamentoRepository.findById(avvistamentoId)
                .orElseThrow(() -> new AvvistamentoNotFoundException("Avvistamento not found"));

        if (!avvistamento.getUser().getId().equals(user.getId())) {
            throw new UnauthorizedAccessException("You are not authorized to delete this avvistamento");
        }

        Path avvistamentoDir = Paths.get(uploadDir + "/" + avvistamento.getId());
        if (Files.exists(avvistamentoDir)) {
            try {
                Files.walk(avvistamentoDir)
                        .sorted((a, b) -> b.compareTo(a))
                        .forEach(path -> {
                            try {
                                Files.deleteIfExists(path);
                            } catch (IOException e) {
                                logger.warn("Failed to delete file: " + path);
                            }
                        });
            } catch (IOException e) {
                logger.error("Failed to delete directory: " + avvistamentoDir, e);
            }
        }

        avvistamentoRepository.delete(avvistamento);
    }

    /**
     * Retrieves all sightings in the system.
     * 
     * @return list of all sightings
     */
    @Transactional(readOnly = true)
    public List<AvvistamentoResponse> getAllAvvistamenti() {
        return avvistamentoRepository.findAll().stream()
                .map(AvvistamentoResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * Retrieves all sightings created by a specific user.
     * 
     * @param userId the user ID
     * @return list of sightings by the user
     */
    @Transactional(readOnly = true)
    public List<AvvistamentoResponse> getAvvistamentiByUser(UUID userId) {
        return avvistamentoRepository.findByUserId(userId).stream()
                .map(AvvistamentoResponse::from)
                .collect(Collectors.toList());
    }

    /**
     * Retrieves sightings within a specified radius from a location.
     * 
     * @param lat the latitude coordinate
     * @param lng the longitude coordinate
     * @param radiusKm the search radius in kilometers
     * @return list of sightings within the radius
     */
    @Transactional(readOnly = true)
    public List<AvvistamentoResponse> getAvvistamentiByLocation(Double lat, Double lng, Double radiusKm) {
        Double radiusMeters = radiusKm * 1000;
        return avvistamentoRepository.findWithinRadius(lat, lng, radiusMeters).stream()
                .map(AvvistamentoResponse::from)
                .collect(Collectors.toList());
    }
}
