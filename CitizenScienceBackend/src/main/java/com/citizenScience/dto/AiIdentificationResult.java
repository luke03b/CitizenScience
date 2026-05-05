package com.citizenscience.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object for AI identification results.
 * Contains the identified flower name, confidence score, and model used.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiIdentificationResult {
    private String flowerName;
    private Double confidence;
    private String modelUsed;
}
