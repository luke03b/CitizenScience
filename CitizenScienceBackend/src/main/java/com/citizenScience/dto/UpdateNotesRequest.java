package com.citizenScience.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object for updating sighting notes.
 * Contains the new note text.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateNotesRequest {
    private String note;
}
