package com.citizenscience.dto;

import com.citizenscience.entities.Avvistamento;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Data Transfer Object for sighting responses.
 * Contains sighting details including location, photos, and user information.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AvvistamentoResponse {
    private UUID id;
    private String nome;
    private Double latitudine;
    private Double longitudine;
    private LocalDateTime data;
    private UUID userId;
    private String userNome;
    private String userCognome;
    private String note;
    private String indirizzo;
    private List<String> photoUrls;
    private String aiModelUsed;
    private Double aiConfidence;

    /**
     * Creates an AvvistamentoResponse from an Avvistamento entity.
     * 
     * @param avvistamento the sighting entity
     * @return AvvistamentoResponse instance
     */
    public static AvvistamentoResponse from(Avvistamento avvistamento) {
        return AvvistamentoResponse.builder()
                .id(avvistamento.getId())
                .nome(avvistamento.getNome())
                .latitudine(avvistamento.getLatitudine())
                .longitudine(avvistamento.getLongitudine())
                .data(avvistamento.getData())
                .userId(avvistamento.getUser().getId())
                .userNome(avvistamento.getUser().getNome())
                .userCognome(avvistamento.getUser().getCognome())
                .note(avvistamento.getNote())
                .indirizzo(avvistamento.getIndirizzo())
                .photoUrls(avvistamento.getFoto().stream()
                        .map(foto -> "/api/photos/" + foto.getPhotoPath())
                        .collect(Collectors.toList()))
                .aiModelUsed(avvistamento.getAiModelUsed())
                .aiConfidence(avvistamento.getAiConfidence())
                .build();
    }
}
