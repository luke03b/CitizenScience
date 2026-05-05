package com.citizenscience.controllers;

import com.citizenscience.entities.AiModelSelection;
import com.citizenscience.entities.User;
import com.citizenscience.dto.AiModelInfo;
import com.citizenscience.repositories.AiModelSelectionRepository;
import com.citizenscience.services.AiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * REST controller for managing AI model selection.
 * Provides endpoints for researchers to view available AI models,
 * trigger a force-scan of all configured AI containers, and
 * select their preferred model.
 */
@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Models", description = "Endpoints for managing AI model selection")
public class AiModelController {

    private static final String ROLE_RESEARCHER = "ricercatore";
    private static final String KEY_ERROR = "error";
    private static final String KEY_MODEL_NAME = "modelName";
    private static final String KEY_MESSAGE = "message";
    
    private final AiService aiService;
    private final AiModelSelectionRepository aiModelSelectionRepository;

    /**
     * Constructs the AiModelController with required dependencies.
     * 
     * @param aiService the service for AI operations
     * @param aiModelSelectionRepository the repository for model selections
     */
    public AiModelController(AiService aiService, AiModelSelectionRepository aiModelSelectionRepository) {
        this.aiService = aiService;
        this.aiModelSelectionRepository = aiModelSelectionRepository;
    }

    /**
     * Returns the list of AI models currently registered in the database.
     * Only accessible to users with researcher role.
     *
     * <p>The list is populated by calling {@code POST /api/ai/scan}. If no scan
     * has been performed yet the list will be empty.
     *
     * @param user the authenticated user
     * @return ResponseEntity containing the list of available models or an error if user is not a researcher
     */
    @GetMapping("/models")
    @Operation(summary = "Get available AI models",
               description = "Returns AI models registered in the database (researchers only). "
                           + "Call POST /api/ai/scan first to populate the list.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved models list"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User is not a researcher")
    })
    public ResponseEntity<Map<String, Object>> getAvailableModels(@AuthenticationPrincipal User user) {
        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of(KEY_ERROR, "Only researchers can access AI models"));
        }

        List<AiModelInfo> models = aiService.getAvailableModels();
        return ResponseEntity.ok(Map.of("models", models));
    }

    /**
     * Triggers a force scan of all configured AI containers.
     * Each container in the {@code ai.containers} configuration list is queried via
     * its {@code /models} endpoint; the results are persisted in the
     * {@code ai_container_models} database table, replacing any stale entries.
     * Only accessible to users with researcher role.
     *
     * @param user the authenticated user
     * @return ResponseEntity containing a map of container name → discovered model list
     */
    @PostMapping("/scan")
    @Operation(summary = "Force scan AI containers",
               description = "Queries all configured AI containers for available models and "
                           + "updates the database registry (researchers only).")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Scan completed successfully"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User is not a researcher")
    })
    public ResponseEntity<Map<String, Object>> forceScanModels(@AuthenticationPrincipal User user) {
        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of(KEY_ERROR, "Only researchers can trigger a model scan"));
        }

        Map<String, List<String>> scanResult = aiService.forceScanModels();
        return ResponseEntity.ok(Map.of("scannedContainers", scanResult));
    }

    /**
     * Selects an AI model for the authenticated researcher.
     * Creates a new selection or updates existing one.
     * 
     * @param user the authenticated user
     * @param request the request body containing modelName
     * @return ResponseEntity with success message or error
     */
    @PostMapping("/models/select")
    @Operation(summary = "Select AI model", description = "Selects an AI model for the researcher")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Model successfully selected"),
        @ApiResponse(responseCode = "400", description = "Invalid input"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User is not a researcher")
    })
    public ResponseEntity<Map<String, Object>> selectModel(
            @AuthenticationPrincipal User user,
            @RequestBody Map<String, String> request) {
        
        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of(KEY_ERROR, "Only researchers can select AI models"));
        }

        String modelName = request.get(KEY_MODEL_NAME);
        if (modelName == null || modelName.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of(KEY_ERROR, "Model name is required"));
        }

        var existingSelection = aiModelSelectionRepository.findByUser(user);
        
        AiModelSelection selection;
        if (existingSelection.isPresent()) {
            selection = existingSelection.get();
            selection.setModelName(modelName);
            selection.setSelectedAt(LocalDateTime.now());
        } else {
            selection = AiModelSelection.builder()
                    .user(user)
                    .modelName(modelName)
                    .selectedAt(LocalDateTime.now())
                    .build();
        }

        aiModelSelectionRepository.save(selection);

        return ResponseEntity.ok(Map.of(
            KEY_MESSAGE, "Model selected successfully",
            KEY_MODEL_NAME, modelName
        ));
    }

    /**
     * Retrieves the currently selected AI model for the authenticated researcher.
     * 
     * @param user the authenticated user
     * @return ResponseEntity containing the selected model or error if none selected
     */
    @GetMapping("/models/selected")
    @Operation(summary = "Get selected model", description = "Retrieves the currently selected AI model for the researcher")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved selected model"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User is not a researcher"),
        @ApiResponse(responseCode = "404", description = "No model selected")
    })
    public ResponseEntity<Map<String, Object>> getSelectedModel(@AuthenticationPrincipal User user) {
        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of(KEY_ERROR, "Only researchers can access AI models"));
        }

        var selection = aiModelSelectionRepository.findByUser(user);
        
        if (selection.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of(KEY_ERROR, "No model selected"));
        }

        return ResponseEntity.ok(Map.of(
            KEY_MODEL_NAME, selection.get().getModelName(),
                "selectedAt", selection.get().getSelectedAt()
        ));
    }

    /**
     * Sets the system-wide default AI model used when no specific model is requested
     * or the requested model is unreachable.
     * Only one model can be default at a time; calling this endpoint replaces any
     * previously set default.
     *
     * <p>Passing an empty {@code modelName} clears the current default so that no
     * model is marked as default.
     *
     * @param user    the authenticated researcher
     * @param request request body with {@code modelName} (may be empty to clear)
     * @return ResponseEntity with success message or error
     */
    @PostMapping("/models/set-default")
    @Operation(summary = "Set default AI model",
               description = "Marks a model as the system-wide default used when no specific model is "
                           + "requested or the requested model is unreachable (researchers only). "
                           + "Send an empty modelName to clear the current default.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Default model updated successfully"),
        @ApiResponse(responseCode = "400", description = "Model not found in registry"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User is not a researcher")
    })
    public ResponseEntity<Map<String, Object>> setDefaultModel(
            @AuthenticationPrincipal User user,
            @RequestBody Map<String, String> request) {

        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of(KEY_ERROR, "Only researchers can set the default AI model"));
        }

        String modelName = request.get(KEY_MODEL_NAME);

        try {
            aiService.setDefaultModel(modelName);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(KEY_ERROR, e.getMessage()));
        }

        if (modelName == null || modelName.isBlank()) {
            return ResponseEntity.ok(Map.of(KEY_MESSAGE, "Default model cleared"));
        }
        return ResponseEntity.ok(Map.of(
                KEY_MESSAGE, "Default model set successfully",
                KEY_MODEL_NAME, modelName
        ));
    }
}
