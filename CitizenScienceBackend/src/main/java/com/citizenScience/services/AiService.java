package com.citizenScience.services;

import com.citizenScience.dto.AiIdentificationResult;
import com.citizenScience.entities.AiContainerModel;
import com.citizenScience.entities.User;
import com.citizenScience.repositories.AiContainerModelRepository;
import com.citizenScience.repositories.AiModelSelectionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for interacting with AI containers.
 * Supports multiple AI containers that share the same /models and /identify API contract.
 * The model-to-container registry is stored in the database and refreshed via forceScanModels().
 */
@Service
public class AiService {

    private static final Logger logger = LoggerFactory.getLogger(AiService.class);

    /** Default port exposed by every AI container. */
    private static final int AI_CONTAINER_PORT = 8000;

    /**
     * Comma-separated list of Docker service / container names that expose
     * the /models and /identify endpoints (e.g., "ai_service,ai_service_2").
     */
    @Value("${ai.containers:ai_service}")
    private String aiContainersConfig;

    private final RestTemplate restTemplate;
    private final AiModelSelectionRepository aiModelSelectionRepository;
    private final AiContainerModelRepository aiContainerModelRepository;

    /**
     * Constructs the AiService and initializes RestTemplate.
     */
    public AiService(AiModelSelectionRepository aiModelSelectionRepository,
                     AiContainerModelRepository aiContainerModelRepository) {
        this.restTemplate = new RestTemplate();
        this.aiModelSelectionRepository = aiModelSelectionRepository;
        this.aiContainerModelRepository = aiContainerModelRepository;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Public API
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Calls the appropriate AI container to identify a flower from a photo.
     * The container is resolved by looking up the model name in the database registry.
     *
     * @param photo The photo file
     * @param user  The authenticated user (used to resolve the default model for researchers)
     * @return The identification result with flower name, confidence, and model used
     * @throws IOException if there is an error processing the photo
     */
    public AiIdentificationResult identifyFlower(MultipartFile photo, User user) throws IOException {
        return identifyFlower(photo, user, null);
    }

    /**
     * Calls the appropriate AI container to identify a flower from a photo,
     * with an optional model override.
     *
     * <p>Model resolution order:
     * <ol>
     *   <li>Explicit {@code modelNameOverride} (if non-blank)</li>
     *   <li>Researcher's saved model selection</li>
     *   <li>Any model found in the database registry (first entry)</li>
     * </ol>
     *
     * <p>The target container URL is constructed dynamically by looking up the
     * resolved model name in the {@code ai_container_models} table.
     *
     * @param photo             The photo file
     * @param user              The authenticated user
     * @param modelNameOverride Optional model name override; takes precedence when non-blank
     * @return The identification result with flower name, confidence, and model used
     * @throws IOException if there is an error processing the photo
     */
    public AiIdentificationResult identifyFlower(MultipartFile photo, User user, String modelNameOverride) throws IOException {
        try {
            // ── 1. Resolve model name ─────────────────────────────────────────
            String modelName = null;
            if (modelNameOverride != null && !modelNameOverride.isBlank()) {
                modelName = modelNameOverride;
                logger.info("Using model override for identification: {}", modelName);
            } else if (user != null && "ricercatore".equalsIgnoreCase(user.getRuolo())) {
                var modelSelection = aiModelSelectionRepository.findByUser(user);
                if (modelSelection.isPresent()) {
                    modelName = modelSelection.get().getModelName();
                    logger.info("Using selected model for researcher: {}", modelName);
                }
            }

            // ── 2. Resolve container URL from registry ────────────────────────
            String containerUrl = resolveContainerUrl(modelName);
            if (containerUrl == null) {
                logger.warn("No container found for model '{}'; cannot identify flower", modelName);
                return unknownFlowerResult();
            }

            // ── 3. Build multipart request ────────────────────────────────────
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();

            ByteArrayResource resource = new ByteArrayResource(photo.getBytes()) {
                @Override
                public String getFilename() {
                    return photo.getOriginalFilename();
                }
            };

            HttpHeaders partHeaders = new HttpHeaders();
            partHeaders.setContentType(MediaType.valueOf(photo.getContentType()));
            HttpEntity<ByteArrayResource> fileEntity = new HttpEntity<>(resource, partHeaders);

            body.add("photo", fileEntity);

            if (modelName != null) {
                body.add("model_name", modelName);
            }

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // ── 4. Call /identify on the resolved container ───────────────────
            ResponseEntity<Map> response = restTemplate.exchange(
                    containerUrl + "/identify",
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();
                String flowerName = (String) responseBody.get("flower_name");
                Double confidence = ((Number) responseBody.getOrDefault("confidence", 0.0)).doubleValue();
                String usedModel = (String) responseBody.get("model_used");

                logger.info("AI container {} identified flower as: {} with confidence: {}",
                        containerUrl, flowerName, confidence);

                return AiIdentificationResult.builder()
                        .flowerName(flowerName)
                        .confidence(confidence)
                        .modelUsed(usedModel)
                        .build();
            } else {
                logger.warn("AI container {} returned unexpected status: {}", containerUrl, response.getStatusCode());
                return unknownFlowerResult();
            }
        } catch (Exception e) {
            logger.error("Error calling AI container for flower identification", e);
            return unknownFlowerResult();
        }
    }

    /**
     * Returns the list of all AI models currently known to the backend,
     * reading from the {@code ai_container_models} database table.
     *
     * <p>Call {@link #forceScanModels()} to refresh this list from the live containers.
     *
     * @return list of model filenames, or empty list if none discovered yet
     */
    public List<String> getAvailableModels() {
        return aiContainerModelRepository.findAll()
                .stream()
                .map(AiContainerModel::getModelName)
                .collect(Collectors.toList());
    }

    /**
     * Performs a force scan of all configured AI containers.
     * For each container in {@code ai.containers}, the backend calls {@code /models},
     * then upserts the resulting model names into the {@code ai_container_models} table.
     *
     * <p>Stale models previously associated with a container are removed before
     * re-populating, so containers that no longer expose a model are cleaned up.
     *
     * @return a map from container name to the list of models discovered (including
     *         containers that could not be reached, mapped to an empty list)
     */
    @Transactional
    @SuppressWarnings("unchecked")
    public Map<String, List<String>> forceScanModels() {
        List<String> containers = parseContainerNames();
        Map<String, List<String>> result = new LinkedHashMap<>();

        for (String containerName : containers) {
            String containerUrl = buildContainerUrl(containerName);
            List<String> discoveredModels = new ArrayList<>();

            try {
                ResponseEntity<Map> response = restTemplate.getForEntity(
                        containerUrl + "/models",
                        Map.class
                );

                if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                    Object modelsObj = response.getBody().get("models");
                    if (modelsObj instanceof List<?> rawList) {
                        for (Object item : rawList) {
                            if (item instanceof String modelName) {
                                discoveredModels.add(modelName);
                            }
                        }
                    }
                    logger.info("Container '{}' reported {} model(s): {}", containerName, discoveredModels.size(), discoveredModels);
                } else {
                    logger.warn("Container '{}' returned unexpected status: {}", containerName, response.getStatusCode());
                }
            } catch (Exception e) {
                logger.error("Could not reach container '{}' during force scan: {}", containerName, e.getMessage());
            }

            // Remove stale entries for this container, then insert fresh ones
            aiContainerModelRepository.deleteByContainerName(containerName);

            LocalDateTime now = LocalDateTime.now();
            for (String modelName : discoveredModels) {
                // If another container already registered this model, log a warning and
                // update the mapping (last-scanned container wins; model names are expected
                // to be unique across the network).
                aiContainerModelRepository.findByModelName(modelName).ifPresentOrElse(
                        existing -> {
                            if (!containerName.equals(existing.getContainerName())) {
                                logger.warn(
                                        "Model '{}' was previously registered to container '{}'; "
                                        + "reassigning to '{}'. Ensure model names are unique across containers.",
                                        modelName, existing.getContainerName(), containerName);
                            }
                            existing.setContainerName(containerName);
                            existing.setDiscoveredAt(now);
                            aiContainerModelRepository.save(existing);
                        },
                        () -> aiContainerModelRepository.save(
                                AiContainerModel.builder()
                                        .modelName(modelName)
                                        .containerName(containerName)
                                        .discoveredAt(now)
                                        .build()
                        )
                );
            }

            result.put(containerName, discoveredModels);
        }

        return result;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Resolves the base URL of the container that hosts the given model.
     * If {@code modelName} is null or not found in the registry, falls back to
     * the first available model in the database (if any).
     *
     * @param modelName the requested model name (may be null)
     * @return base URL (e.g., "http://ai_service:8000") or {@code null} if no container is known
     */
    private String resolveContainerUrl(String modelName) {
        if (modelName != null) {
            Optional<AiContainerModel> mapping = aiContainerModelRepository.findByModelName(modelName);
            if (mapping.isPresent()) {
                return buildContainerUrl(mapping.get().getContainerName());
            }
            logger.warn("Model '{}' not found in registry; trying first available model", modelName);
        }

        // Fallback: use the first model in the registry
        return aiContainerModelRepository.findAll()
                .stream()
                .findFirst()
                .map(m -> buildContainerUrl(m.getContainerName()))
                .orElse(null);
    }

    /**
     * Constructs the base URL for a container given its Docker service name.
     *
     * @param containerName Docker service / container name
     * @return base URL string (e.g., "http://ai_service:8000")
     */
    private String buildContainerUrl(String containerName) {
        return "http://" + containerName + ":" + AI_CONTAINER_PORT;
    }

    /**
     * Parses the comma-separated {@code ai.containers} configuration value.
     *
     * @return list of trimmed, non-empty container names
     */
    private List<String> parseContainerNames() {
        if (aiContainersConfig == null || aiContainersConfig.isBlank()) {
            return List.of();
        }
        return Arrays.stream(aiContainersConfig.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    /** Convenience factory for a "flower unknown" fallback result. */
    private AiIdentificationResult unknownFlowerResult() {
        return AiIdentificationResult.builder()
                .flowerName("Fiore Sconosciuto PROBLEMA")
                .confidence(0.0)
                .modelUsed(null)
                .build();
    }
}
