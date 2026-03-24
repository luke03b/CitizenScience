package com.citizenScience.services;

import com.citizenScience.dto.AiIdentificationResult;
import com.citizenScience.dto.AiModelInfo;
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
     * </ol>
     *
     * <p>Fallback order when the resolved model is not specified, not found in the registry,
     * or its container is unreachable:
     * <ol>
     *   <li>System-wide default model (flagged {@code is_default = true})</li>
     *   <li>First model found in the database registry</li>
     * </ol>
     *
     * @param photo             The photo file
     * @param user              The authenticated user
     * @param modelNameOverride Optional model name override; takes precedence when non-blank
     * @return The identification result with flower name, confidence, and model used
     * @throws IOException if there is an error processing the photo
     */
    public AiIdentificationResult identifyFlower(MultipartFile photo, User user, String modelNameOverride) throws IOException {
        // Extract photo bytes once to avoid re-reading the stream on each retry
        final byte[] photoBytes = photo.getBytes();
        final String photoFilename = photo.getOriginalFilename();
        final String photoContentType = photo.getContentType();

        // ── 1. Determine requested model ─────────────────────────────────────
        String requestedModel = null;
        if (modelNameOverride != null && !modelNameOverride.isBlank()) {
            requestedModel = modelNameOverride;
            logger.info("Using model override for identification: {}", requestedModel);
        } else if (user != null && "ricercatore".equalsIgnoreCase(user.getRuolo())) {
            var modelSelection = aiModelSelectionRepository.findByUser(user);
            if (modelSelection.isPresent()) {
                requestedModel = modelSelection.get().getModelName();
                logger.info("Using selected model for researcher: {}", requestedModel);
            }
        }

        // ── 2. Try requested model ────────────────────────────────────────────
        if (requestedModel != null) {
            Optional<AiContainerModel> mapping = aiContainerModelRepository.findByModelName(requestedModel);
            if (mapping.isPresent()) {
                AiIdentificationResult result = tryIdentify(photoBytes, photoFilename, photoContentType,
                        mapping.get().getContainerName(), requestedModel);
                if (result != null) return result;
                logger.warn("Requested model '{}' is not reachable; falling back to default model", requestedModel);
            } else {
                logger.warn("Requested model '{}' not found in registry; falling back to default model", requestedModel);
            }
        }

        // ── 3. Try system-wide default model ──────────────────────────────────
        Optional<AiContainerModel> defaultModel = aiContainerModelRepository.findByIsDefaultTrue();
        if (defaultModel.isPresent()) {
            AiIdentificationResult result = tryIdentify(photoBytes, photoFilename, photoContentType,
                    defaultModel.get().getContainerName(), defaultModel.get().getModelName());
            if (result != null) return result;
            logger.warn("Default model '{}' is not reachable; falling back to first available model",
                    defaultModel.get().getModelName());
        }

        // ── 4. Try first available model ──────────────────────────────────────
        Optional<AiContainerModel> firstModel = aiContainerModelRepository.findFirstByOrderByDiscoveredAtAsc();
        if (firstModel.isPresent()) {
            AiIdentificationResult result = tryIdentify(photoBytes, photoFilename, photoContentType,
                    firstModel.get().getContainerName(), firstModel.get().getModelName());
            if (result != null) return result;
            logger.warn("First available model '{}' is not reachable; no more fallbacks",
                    firstModel.get().getModelName());
        }

        logger.warn("No AI model is reachable; returning unknown flower result");
        return unknownFlowerResult();
    }

    /**
     * Returns the list of all AI models currently known to the backend,
     * reading from the {@code ai_container_models} database table.
     *
     * <p>Call {@link #forceScanModels()} to refresh this list from the live containers.
     *
     * @return list of {@link AiModelInfo} objects (name + optional description + isDefault),
     *         or empty list if none discovered yet
     */
    public List<AiModelInfo> getAvailableModels() {
        return aiContainerModelRepository.findAll()
                .stream()
                .map(m -> new AiModelInfo(m.getModelName(), m.getDescription(), m.isDefault()))
                .collect(Collectors.toList());
    }

    /**
     * Sets the given model as the system-wide default for identification requests.
     * Clears any previously set default before applying the new one.
     *
     * <p>If {@code modelName} is {@code null} or blank, all defaults are cleared
     * (no default model will be active).
     *
     * @param modelName the model to mark as default, or {@code null} / blank to clear
     * @throws IllegalArgumentException if a non-blank {@code modelName} is not found in the registry
     */
    @Transactional
    public void setDefaultModel(String modelName) {
        aiContainerModelRepository.clearAllDefaults();

        if (modelName != null && !modelName.isBlank()) {
            AiContainerModel model = aiContainerModelRepository.findByModelName(modelName)
                    .orElseThrow(() -> new IllegalArgumentException(
                            "Model '" + modelName + "' not found in the registry"));
            model.setDefault(true);
            aiContainerModelRepository.save(model);
            logger.info("Default model set to '{}'", modelName);
        } else {
            logger.info("Default model cleared");
        }
    }

    /**
     * Performs a force scan of all configured AI containers.
     * For each container in {@code ai.containers}, the backend calls {@code /models},
     * then upserts the resulting model names into the {@code ai_container_models} table.
     *
     * <p>Stale models previously associated with a container are removed before
     * re-populating, so containers that no longer expose a model are cleaned up.
     *
     * <p>Each item in the {@code models} array returned by a container may be either:
     * <ul>
     *   <li>a plain string (legacy format) – description is treated as {@code null}</li>
     *   <li>an object with {@code name} (required) and {@code description} (optional) fields</li>
     * </ul>
     *
     * @return a map from container name to the list of models discovered (including
     *         containers that could not be reached, mapped to an empty list)
     */
    @Transactional
    @SuppressWarnings("unchecked")
    public Map<String, List<String>> forceScanModels() {
        /** Internal holder for a discovered model name + optional description. */
        record ModelInfo(String name, String description) {}

        List<String> containers = parseContainerNames();
        Map<String, List<String>> result = new LinkedHashMap<>();

        for (String containerName : containers) {
            String containerUrl = buildContainerUrl(containerName);
            List<ModelInfo> discoveredModels = new ArrayList<>();

            try {
                ResponseEntity<Map> response = restTemplate.getForEntity(
                        containerUrl + "/models",
                        Map.class
                );

                if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                    Object modelsObj = response.getBody().get("models");
                    if (modelsObj instanceof List<?> rawList) {
                        for (Object item : rawList) {
                            if (item instanceof Map<?, ?> modelMap) {
                                // New format: {"name": "...", "description": "..."}
                                Object nameObj = modelMap.get("name");
                                Object descObj = modelMap.get("description");
                                if (nameObj instanceof String modelName) {
                                    String desc = descObj instanceof String s ? s : null;
                                    discoveredModels.add(new ModelInfo(modelName, desc));
                                }
                            } else if (item instanceof String modelName) {
                                // Legacy format: plain string
                                discoveredModels.add(new ModelInfo(modelName, null));
                            }
                        }
                    }
                    logger.info("Container '{}' reported {} model(s): {}", containerName,
                            discoveredModels.size(),
                            discoveredModels.stream().map(ModelInfo::name).toList());
                } else {
                    logger.warn("Container '{}' returned unexpected status: {}", containerName, response.getStatusCode());
                }
            } catch (Exception e) {
                logger.error("Could not reach container '{}' during force scan: {}", containerName, e.getMessage());
            }

            // Remove stale entries for this container, then insert fresh ones
            aiContainerModelRepository.deleteByContainerName(containerName);

            LocalDateTime now = LocalDateTime.now();
            for (ModelInfo modelInfo : discoveredModels) {
                String modelName = modelInfo.name();
                String description = modelInfo.description();
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
                            existing.setDescription(description);
                            aiContainerModelRepository.save(existing);
                        },
                        () -> aiContainerModelRepository.save(
                                AiContainerModel.builder()
                                        .modelName(modelName)
                                        .containerName(containerName)
                                        .discoveredAt(now)
                                        .description(description)
                                        .build()
                        )
                );
            }

            result.put(containerName, discoveredModels.stream().map(ModelInfo::name).collect(Collectors.toList()));
        }

        return result;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Attempts to call a specific AI container to identify a flower.
     *
     * @param photoBytes       raw bytes of the photo
     * @param photoFilename    original filename of the photo
     * @param photoContentType MIME type of the photo
     * @param containerName    Docker service / container name to call
     * @param modelName        model name to request from the container
     * @return the identification result, or {@code null} if the container is unreachable
     *         or returns an unexpected response
     */
    private AiIdentificationResult tryIdentify(byte[] photoBytes, String photoFilename,
                                               String photoContentType,
                                               String containerName, String modelName) {
        String containerUrl = buildContainerUrl(containerName);
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();

            ByteArrayResource resource = new ByteArrayResource(photoBytes) {
                @Override
                public String getFilename() {
                    return photoFilename;
                }
            };

            HttpHeaders partHeaders = new HttpHeaders();
            partHeaders.setContentType(MediaType.valueOf(photoContentType));
            HttpEntity<ByteArrayResource> fileEntity = new HttpEntity<>(resource, partHeaders);

            body.add("photo", fileEntity);
            body.add("model_name", modelName);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

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

                logger.info("Container {} identified flower as: {} with confidence: {}",
                        containerUrl, flowerName, confidence);

                return AiIdentificationResult.builder()
                        .flowerName(flowerName)
                        .confidence(confidence)
                        .modelUsed(usedModel)
                        .build();
            } else {
                logger.warn("Container {} returned unexpected status: {}", containerUrl, response.getStatusCode());
                return null;
            }
        } catch (Exception e) {
            logger.error("Error calling container {} with model '{}': {}", containerUrl, modelName, e.getMessage());
            return null;
        }
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
