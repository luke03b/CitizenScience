package com.citizenScience.controllers;

import com.citizenScience.entities.AiModelSelection;
import com.citizenScience.entities.User;
import com.citizenScience.repositories.AiModelSelectionRepository;
import com.citizenScience.services.AiService;
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
 * Provides endpoints for researchers to view available AI models and select their preferred model.
 */
@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Models", description = "Endpoints for managing AI model selection")
public class AiModelController {

    private static final String ROLE_RESEARCHER = "ricercatore";
    
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
     * Retrieves the list of available AI models.
     * Only accessible to users with researcher role.
     * 
     * @param user the authenticated user
     * @return ResponseEntity containing the list of available models or an error if user is not a researcher
     */
    @GetMapping("/models")
    @Operation(summary = "Get available AI models", description = "Retrieves list of available AI models (researchers only)")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved models list"),
        @ApiResponse(responseCode = "401", description = "User not authenticated"),
        @ApiResponse(responseCode = "403", description = "User is not a researcher")
    })
    public ResponseEntity<?> getAvailableModels(@AuthenticationPrincipal User user) {
        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Only researchers can access AI models"));
        }

        List<String> models = aiService.getAvailableModels();
        return ResponseEntity.ok(Map.of("models", models));
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
    public ResponseEntity<?> selectModel(
            @AuthenticationPrincipal User user,
            @RequestBody Map<String, String> request) {
        
        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Only researchers can select AI models"));
        }

        String modelName = request.get("modelName");
        if (modelName == null || modelName.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Model name is required"));
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
                "message", "Model selected successfully",
                "modelName", modelName
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
    public ResponseEntity<?> getSelectedModel(@AuthenticationPrincipal User user) {
        if (!ROLE_RESEARCHER.equalsIgnoreCase(user.getRuolo())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Only researchers can access AI models"));
        }

        var selection = aiModelSelectionRepository.findByUser(user);
        
        if (selection.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "No model selected"));
        }

        return ResponseEntity.ok(Map.of(
                "modelName", selection.get().getModelName(),
                "selectedAt", selection.get().getSelectedAt()
        ));
    }
}
