package com.citizenscience.services;

import com.citizenscience.dto.AiIdentificationResult;
import com.citizenscience.dto.AiModelInfo;
import com.citizenscience.entities.AiContainerModel;
import com.citizenscience.entities.User;
import com.citizenscience.repositories.AiContainerModelRepository;
import com.citizenscience.repositories.AiModelSelectionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
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

        String requestedModel = resolveRequestedModel(user, modelNameOverride);

        AiIdentificationResult requestedResult = tryRequestedModel(
                requestedModel, photoBytes, photoFilename, photoContentType);
        if (requestedResult != null) {
            return requestedResult;
        }

        AiIdentificationResult defaultResult = tryDefaultModel(photoBytes, photoFilename, photoContentType);
        if (defaultResult != null) {
            return defaultResult;
        }

        AiIdentificationResult firstAvailableResult = tryFirstAvailableModel(photoBytes, photoFilename, photoContentType);
        if (firstAvailableResult != null) {
            return firstAvailableResult;
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
                .toList();
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
    public Map<String, List<String>> forceScanModels() {
        List<String> containers = parseContainerNames();
        Map<String, List<String>> result = new LinkedHashMap<>();

        for (String containerName : containers) {
            List<ModelInfo> discoveredModels = fetchContainerModels(containerName);
            refreshContainerMappings(containerName, discoveredModels);
            result.put(containerName, discoveredModels.stream().map(ModelInfo::name).toList());
        }

        return result;
    }

    /** Internal holder for a discovered model name + optional description. */
    private record ModelInfo(String name, String description) {}

    // ──────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ──────────────────────────────────────────────────────────────────────────

    private String resolveRequestedModel(User user, String modelNameOverride) {
        if (modelNameOverride != null && !modelNameOverride.isBlank()) {
            logger.info("Using model override for identification: {}", modelNameOverride);
            return modelNameOverride;
        }
        if (user == null || !"ricercatore".equalsIgnoreCase(user.getRuolo())) {
            return null;
        }
        return aiModelSelectionRepository.findByUser(user)
                .map(selection -> {
                    logger.info("Using selected model for researcher: {}", selection.getModelName());
                    return selection.getModelName();
                })
                .orElse(null);
    }

    private AiIdentificationResult tryRequestedModel(String requestedModel,
                                                     byte[] photoBytes,
                                                     String photoFilename,
                                                     String photoContentType) {
        if (requestedModel == null) {
            return null;
        }

        return aiContainerModelRepository.findByModelName(requestedModel)
                .map(mapping -> {
                    AiIdentificationResult result = tryIdentify(
                            photoBytes,
                            photoFilename,
                            photoContentType,
                            mapping.getContainerName(),
                            requestedModel
                    );
                    if (result == null) {
                        logger.warn("Requested model '{}' is not reachable; falling back to default model", requestedModel);
                    }
                    return result;
                })
                .orElseGet(() -> {
                    logger.warn("Requested model '{}' not found in registry; falling back to default model", requestedModel);
                    return null;
                });
    }

    private AiIdentificationResult tryDefaultModel(byte[] photoBytes,
                                                   String photoFilename,
                                                   String photoContentType) {
        Optional<AiContainerModel> defaultModel = aiContainerModelRepository.findByIsDefaultTrue();
        if (defaultModel.isEmpty()) {
            return null;
        }

        AiContainerModel model = defaultModel.get();
        AiIdentificationResult result = tryIdentify(
                photoBytes,
                photoFilename,
                photoContentType,
                model.getContainerName(),
                model.getModelName()
        );
        if (result == null) {
            logger.warn("Default model '{}' is not reachable; falling back to first available model", model.getModelName());
        }
        return result;
    }

    private AiIdentificationResult tryFirstAvailableModel(byte[] photoBytes,
                                                          String photoFilename,
                                                          String photoContentType) {
        Optional<AiContainerModel> firstModel = aiContainerModelRepository.findFirstByOrderByDiscoveredAtAsc();
        if (firstModel.isEmpty()) {
            return null;
        }

        AiContainerModel model = firstModel.get();
        AiIdentificationResult result = tryIdentify(
                photoBytes,
                photoFilename,
                photoContentType,
                model.getContainerName(),
                model.getModelName()
        );
        if (result == null) {
            logger.warn("First available model '{}' is not reachable; no more fallbacks", model.getModelName());
        }
        return result;
    }

    private List<ModelInfo> fetchContainerModels(String containerName) {
        String containerUrl = buildContainerUrl(containerName);
        try {
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                    containerUrl + "/models",
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<>() {
                    }
            );
            return parseDiscoveredModels(containerName, response);
        } catch (Exception e) {
            logger.error("Could not reach container '{}' during force scan: {}", containerName, e.getMessage());
            return List.of();
        }
    }

    private List<ModelInfo> parseDiscoveredModels(String containerName, ResponseEntity<Map<String, Object>> response) {
        if (response.getStatusCode() != HttpStatus.OK) {
            logger.warn("Container '{}' returned unexpected status: {}", containerName, response.getStatusCode());
            return List.of();
        }

        Map<String, Object> responseBody = response.getBody();
        if (responseBody == null) {
            logger.warn("Container '{}' returned an empty response body", containerName);
            return List.of();
        }

        List<ModelInfo> discoveredModels = extractModelInfo(responseBody.get("models"));
        logger.info("Container '{}' reported {} model(s): {}", containerName,
                discoveredModels.size(), discoveredModels.stream().map(ModelInfo::name).toList());
        return discoveredModels;
    }

    private List<ModelInfo> extractModelInfo(Object modelsObj) {
        if (!(modelsObj instanceof List<?> rawList)) {
            return List.of();
        }

        List<ModelInfo> discoveredModels = new ArrayList<>();
        for (Object item : rawList) {
            ModelInfo modelInfo = toModelInfo(item);
            if (modelInfo != null) {
                discoveredModels.add(modelInfo);
            }
        }
        return discoveredModels;
    }

    private ModelInfo toModelInfo(Object item) {
        if (item instanceof Map<?, ?> modelMap) {
            Object nameObj = modelMap.get("name");
            Object descObj = modelMap.get("description");
            if (nameObj instanceof String modelName) {
                String description = descObj instanceof String s ? s : null;
                return new ModelInfo(modelName, description);
            }
            return null;
        }
        if (item instanceof String modelName) {
            return new ModelInfo(modelName, null);
        }
        return null;
    }

    private void refreshContainerMappings(String containerName, List<ModelInfo> discoveredModels) {
        aiContainerModelRepository.deleteByContainerName(containerName);
        LocalDateTime now = LocalDateTime.now();
        for (ModelInfo modelInfo : discoveredModels) {
            upsertContainerModel(containerName, modelInfo, now);
        }
    }

    private void upsertContainerModel(String containerName, ModelInfo modelInfo, LocalDateTime discoveredAt) {
        String modelName = modelInfo.name();
        String description = modelInfo.description();

        aiContainerModelRepository.findByModelName(modelName).ifPresentOrElse(
                existing -> {
                    if (!containerName.equals(existing.getContainerName())) {
                        logger.warn(
                                "Model '{}' was previously registered to container '{}'; "
                                        + "reassigning to '{}'. Ensure model names are unique across containers.",
                                modelName, existing.getContainerName(), containerName);
                    }
                    existing.setContainerName(containerName);
                    existing.setDiscoveredAt(discoveredAt);
                    existing.setDescription(description);
                    aiContainerModelRepository.save(existing);
                },
                () -> aiContainerModelRepository.save(
                        AiContainerModel.builder()
                                .modelName(modelName)
                                .containerName(containerName)
                                .discoveredAt(discoveredAt)
                                .description(description)
                                .build()
                )
        );
    }

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

            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                    containerUrl + "/identify",
                    HttpMethod.POST,
                    requestEntity,
                    new ParameterizedTypeReference<>() {
                    }
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
                .toList();
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
