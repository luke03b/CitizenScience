package com.citizenScience.dto;

/**
 * Data transfer object representing an AI model with its optional description.
 * Returned by {@code GET /api/ai/models}.
 *
 * @param name        the model filename (e.g., "model_full_internet_last.pt")
 * @param description optional human-readable description of the model; may be {@code null}
 * @param isDefault   whether this model is the system-wide default for identification requests
 */
public record AiModelInfo(String name, String description, boolean isDefault) {}
