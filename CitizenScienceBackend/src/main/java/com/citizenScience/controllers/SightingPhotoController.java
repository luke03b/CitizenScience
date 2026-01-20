package com.citizenScience.controllers;

import com.citizenScience.dto.ApiResponse;
import com.citizenScience.dto.SightingPhotoDTO;
import com.citizenScience.entities.SightingPhoto;
import com.citizenScience.services.SightingPhotoService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@RestController
@RequestMapping("/api/photos")
@RequiredArgsConstructor
public class SightingPhotoController {

    private final SightingPhotoService sightingPhotoService;

    @Value("${app.upload.dir:uploads/sightings}")
    private String uploadDir;

    @PostMapping("/upload")
    public ResponseEntity<?> upload(
            @RequestParam Long sightingId,
            @RequestParam Long userId,
            @RequestParam MultipartFile file,
            @RequestParam(defaultValue = "false") boolean isPrimary) {

        try {
            SightingPhoto photo = sightingPhotoService.uploadPhoto(sightingId, userId, file, isPrimary);
            return ResponseEntity.ok(SightingPhotoDTO.fromEntity(photo));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Upload fallito", e.getMessage()));
        }
    }

    @GetMapping("/sighting/{sightingId}")
    public ResponseEntity<List<SightingPhotoDTO>> getBySightingId(@PathVariable Long sightingId) {
        List<SightingPhotoDTO> photos = sightingPhotoService.findBySightingId(sightingId).stream()
                .map(SightingPhotoDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(photos);
    }

    @GetMapping("/sighting/{sightingId}/primary")
    public ResponseEntity<?> getPrimaryPhoto(@PathVariable Long sightingId) {
        return sightingPhotoService.findPrimaryPhoto(sightingId)
                .map(photo -> ResponseEntity.ok(SightingPhotoDTO.fromEntity(photo)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/file")
    public ResponseEntity<Resource> getFile(@PathVariable Long id) {
        return sightingPhotoService.findById(id)
                .map(photo -> {
                    try {
                        Path filePath = Paths.get(uploadDir).resolve(photo.getFilePath());
                        Resource resource = new UrlResource(filePath.toUri());

                        if (resource.exists() && resource.isReadable()) {
                            return ResponseEntity.ok()
                                    .contentType(MediaType.IMAGE_JPEG)
                                    .header(HttpHeaders.CONTENT_DISPOSITION,
                                            "inline; filename=\"" + filePath.getFileName() + "\"")
                                    .body(resource);
                        }
                        return ResponseEntity.notFound().<Resource>build();
                    } catch (MalformedURLException e) {
                        return ResponseEntity.internalServerError().<Resource>build();
                    }
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}/primary")
    public ResponseEntity<?> setPrimary(@PathVariable Long id, @RequestParam Long userId) {
        try {
            SightingPhoto photo = sightingPhotoService.setPrimaryPhoto(id, userId);
            return ResponseEntity.ok(SightingPhotoDTO.fromEntity(photo));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Operazione fallita", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id, @RequestParam Long userId) {
        try {
            sightingPhotoService.delete(id, userId);
            return ResponseEntity.ok(ApiResponse.success("Foto eliminata con successo"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Eliminazione fallita", e.getMessage()));
        }
    }
}