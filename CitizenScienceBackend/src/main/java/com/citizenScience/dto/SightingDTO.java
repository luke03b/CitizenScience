package com.citizenScience.dto;

import com.citizenScience.entities.Sighting;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SightingDTO {
    
    private Long id;
    private Long userId;
    private String username;
    private String flowerName;
    private String description;
    private Double latitude;
    private Double longitude;
    private LocalDateTime sightingDate;
    private LocalDateTime createdAt;
    private List<SightingPhotoDTO> photos;

    public static SightingDTO fromEntity(Sighting sighting) {
        return SightingDTO.builder()
                .id(sighting.getId())
                .userId(sighting.getUser().getId())
                .username(sighting.getUser().getUsername())
                .flowerName(sighting.getFlowerName())
                .description(sighting.getDescription())
                .latitude(sighting.getLatitude())
                .longitude(sighting.getLongitude())
                .sightingDate(sighting.getSightingDate())
                .createdAt(sighting.getCreatedAt())
                .build();
    }

    public static SightingDTO fromEntityWithPhotos(Sighting sighting) {
        return SightingDTO.builder()
                .id(sighting.getId())
                .userId(sighting.getUser().getId())
                .username(sighting.getUser().getUsername())
                .flowerName(sighting.getFlowerName())
                .description(sighting.getDescription())
                .latitude(sighting.getLatitude())
                .longitude(sighting.getLongitude())
                .sightingDate(sighting.getSightingDate())
                .createdAt(sighting.getCreatedAt())
                .photos(sighting.getPhotos().stream()
                        .map(SightingPhotoDTO::fromEntity)
                        .toList())
                .build();
    }
}