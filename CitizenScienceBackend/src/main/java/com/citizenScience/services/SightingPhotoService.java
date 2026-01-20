package com.citizenScience.services;

import com.citizenScience.entities.Sighting;
import com.citizenScience.entities.SightingPhoto;
import com.citizenScience.repositories.SightingPhotoRepository;
import com.citizenScience.repositories.SightingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class SightingPhotoService {

    private final SightingPhotoRepository sightingPhotoRepository;
    private final SightingRepository sightingRepository;

    @Value("${app.upload.dir:uploads/sightings}")
    private String uploadDir;

    // ═══════════════════════════════════════════════════════════════
    // UPLOAD FOTO
    // ═══════════════════════════════════════════════════════════════

    public SightingPhoto uploadPhoto(Long sightingId, Long userId, MultipartFile file, boolean isPrimary) {
        Sighting sighting = sightingRepository.findById(sightingId)
                .orElseThrow(() -> new IllegalArgumentException("Avvistamento non trovato"));

        // Verifica che l'utente sia il proprietario
        if (!sighting.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("Non autorizzato a caricare foto per questo avvistamento");
        }

        // Salva il file
        String filePath = saveFile(sighting.getUser().getId(), sightingId, file);

        // Se è la foto principale, rimuovi il flag dalle altre
        if (isPrimary) {
            sightingPhotoRepository.findBySightingId(sightingId)
                    .forEach(photo -> {
                        photo.setIsPrimary(false);
                        sightingPhotoRepository.save(photo);
                    });
        }

        SightingPhoto photo = SightingPhoto.builder()
                .sighting(sighting)
                .filePath(filePath)
                .isPrimary(isPrimary)
                .build();

        return sightingPhotoRepository.save(photo);
    }

    // ═══════════════════════════════════════════════════════════════
    // LETTURA
    // ═══════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public List<SightingPhoto> findBySightingId(Long sightingId) {
        return sightingPhotoRepository.findBySightingId(sightingId);
    }

    @Transactional(readOnly = true)
    public Optional<SightingPhoto> findPrimaryPhoto(Long sightingId) {
        return sightingPhotoRepository.findBySightingIdAndIsPrimaryTrue(sightingId);
    }

    @Transactional(readOnly = true)
    public Optional<SightingPhoto> findById(Long id) {
        return sightingPhotoRepository.findById(id);
    }

    // ═══════════════════════════════════════════════════════════════
    // ELIMINAZIONE
    // ═══════════════════════════════════════════════════════════════

    public void delete(Long photoId, Long userId) {
        SightingPhoto photo = sightingPhotoRepository.findById(photoId)
                .orElseThrow(() -> new IllegalArgumentException("Foto non trovata"));

        // Verifica che l'utente sia il proprietario
        if (!photo.getSighting().getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("Non autorizzato a eliminare questa foto");
        }

        // Elimina il file fisico
        deleteFile(photo.getFilePath());

        sightingPhotoRepository.delete(photo);
    }

    // ═══════════════════════════════════════════════════════════════
    // IMPOSTA FOTO PRINCIPALE
    // ═══════════════════════════════════════════════════════════════

    public SightingPhoto setPrimaryPhoto(Long photoId, Long userId) {
        SightingPhoto photo = sightingPhotoRepository.findById(photoId)
                .orElseThrow(() -> new IllegalArgumentException("Foto non trovata"));

        // Verifica che l'utente sia il proprietario
        if (!photo.getSighting().getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("Non autorizzato a modificare questa foto");
        }

        // Rimuovi il flag dalle altre foto dello stesso avvistamento
        sightingPhotoRepository.findBySightingId(photo.getSighting().getId())
                .forEach(p -> {
                    p.setIsPrimary(false);
                    sightingPhotoRepository.save(p);
                });

        photo.setIsPrimary(true);
        return sightingPhotoRepository.save(photo);
    }

    // ═══════════════════════════════════════════════════════════════
    // UTILITY FILE SYSTEM
    // ═══════════════════════════════════════════════════════════════

    private String saveFile(Long userId, Long sightingId, MultipartFile file) {
        try {
            // Crea la directory se non esiste
            Path dirPath = Paths.get(uploadDir, userId.toString(), sightingId.toString());
            Files.createDirectories(dirPath);

            // Genera nome file univoco
            String originalFilename = file.getOriginalFilename();
            String extension = originalFilename != null && originalFilename.contains(".")
                    ? originalFilename.substring(originalFilename.lastIndexOf("."))
                    : ".jpg";
            String filename = UUID.randomUUID() + extension;

            // Salva il file
            Path filePath = dirPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath);

            // Ritorna il path relativo
            return Paths.get(userId.toString(), sightingId.toString(), filename).toString();

        } catch (IOException e) {
            throw new RuntimeException("Errore durante il salvataggio del file", e);
        }
    }

    private void deleteFile(String filePath) {
        try {
            Path path = Paths.get(uploadDir, filePath);
            Files.deleteIfExists(path);
        } catch (IOException e) {
            // Log dell'errore ma non bloccare l'operazione
        }
    }
}