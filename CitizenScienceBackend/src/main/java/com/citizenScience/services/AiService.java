package com.citizenScience.services;

import com.citizenScience.dto.AiIdentificationResult;
import com.citizenScience.entities.AiModelSelection;
import com.citizenScience.entities.User;
import com.citizenScience.repositories.AiModelSelectionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Service for interacting with the AI service.
 * Provides flower identification and model management functionality.
 */
@Service
public class AiService {

    private static final Logger logger = LoggerFactory.getLogger(AiService.class);

    @Value("${ai.service.url:http://ai_service:8000}")
    private String aiServiceUrl;

    private final RestTemplate restTemplate;
    private final AiModelSelectionRepository aiModelSelectionRepository;

    /**
     * Constructs the AiService and initializes RestTemplate.
     */
    public AiService(AiModelSelectionRepository aiModelSelectionRepository) {
        this.restTemplate = new RestTemplate();
        this.aiModelSelectionRepository = aiModelSelectionRepository;
    }

    /**
     * Calls the AI service to identify a flower from a photo
     * 
     * @param photo The photo file
     * @param user The authenticated user (to determine selected model for researchers)
     * @return The identification result with flower name, confidence, and model used
     * @throws IOException if there's an error processing the photo
     */
    public AiIdentificationResult identifyFlower(MultipartFile photo, User user) throws IOException {
        try {
            // Determine which model to use
            String modelName = null;
            if (user != null && "ricercatore".equalsIgnoreCase(user.getRuolo())) {
                var modelSelection = aiModelSelectionRepository.findByUser(user);
                if (modelSelection.isPresent()) {
                    modelName = modelSelection.get().getModelName();
                    logger.info("Using selected model for researcher: {}", modelName);
                }
            }

            // Prepare the multipart request
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            
            // Convert MultipartFile to ByteArrayResource con content type
            ByteArrayResource resource = new ByteArrayResource(photo.getBytes()) {
                @Override
                public String getFilename() {
                    return photo.getOriginalFilename();
                }
            };
            
            // Aggiungi il file con gli header corretti
            HttpHeaders partHeaders = new HttpHeaders();
            partHeaders.setContentType(MediaType.valueOf(photo.getContentType()));
            HttpEntity<ByteArrayResource> fileEntity = new HttpEntity<>(resource, partHeaders);
            
            body.add("photo", fileEntity);
            
            // Add model_name if specified
            if (modelName != null) {
                body.add("model_name", modelName);
            }

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // Make the request
            ResponseEntity<Map> response = restTemplate.exchange(
                aiServiceUrl + "/identify",
                HttpMethod.POST,
                requestEntity,
                Map.class
            );

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();
                String flowerName = (String) responseBody.get("flower_name");
                Double confidence = ((Number) responseBody.getOrDefault("confidence", 0.0)).doubleValue();
                String usedModel = (String) responseBody.get("model_used");
                
                logger.info("AI service identified flower as: {} with confidence: {}", flowerName, confidence);
                
                return AiIdentificationResult.builder()
                        .flowerName(flowerName)
                        .confidence(confidence)
                        .modelUsed(usedModel)
                        .build();
            } else {
                logger.warn("AI service returned unexpected response: {}", response.getStatusCode());
                return AiIdentificationResult.builder()
                        .flowerName("Fiore Sconosciuto PROBLEMA")
                        .confidence(0.0)
                        .modelUsed(null)
                        .build();
            }
        } catch (Exception e) {
            logger.error("Error calling AI service for flower identification", e);
            // Return a default value if the AI service is unavailable
            return AiIdentificationResult.builder()
                    .flowerName("Fiore Sconosciuto PROBLEMA")
                    .confidence(0.0)
                    .modelUsed(null)
                    .build();
        }
    }

    /**
     * Retrieves the list of available AI models from the AI service.
     * 
     * @return list of model filenames, or empty list if service unavailable
     */
    @SuppressWarnings("unchecked")
    public List<String> getAvailableModels() {
        try {
            ResponseEntity<Map> response = restTemplate.getForEntity(
                aiServiceUrl + "/models",
                Map.class
            );

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return (List<String>) response.getBody().get("models");
            } else {
                logger.warn("AI service returned unexpected response for models: {}", response.getStatusCode());
                return List.of();
            }
        } catch (Exception e) {
            logger.error("Error calling AI service for available models", e);
            return List.of();
        }
    }
}
