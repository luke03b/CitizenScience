package com.citizenScience.dto;

import com.citizenScience.entities.SightingPhoto;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SightingPhotoDTO {
    
    // Campi identificativi
    private Long id;
    private Long sightingId;
    private Long userId;  // Per autorizzazione nelle request
    
    // Campi foto
    private String filePath;
    private String fileUrl;
    private Boolean isPrimary;
    
    // Campi temporali (solo per response)
    private LocalDateTime uploadedAt;

    public static SightingPhotoDTO fromEntity(SightingPhoto photo) {
        return SightingPhotoDTO.builder()
                .id(photo.getId())
                .sightingId(photo.getSighting().getId())
                .filePath(photo.getFilePath())
                .fileUrl("/api/photos/" + photo.getId() + "/file")
                .isPrimary(photo.getIsPrimary())
                .uploadedAt(photo.getUploadedAt())
                .build();
    }
}