package com.citizenscience.controllers;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for testing backend connectivity.
 * Provides a simple endpoint to verify the backend is reachable.
 */
@RestController
@RequestMapping("/api/test")
@CrossOrigin(origins = "*")
@Tag(name = "Test", description = "Test endpoint to verify backend connectivity")
public class TestController {

    /**
     * Simple test endpoint to verify backend connectivity.
     * 
     * @return success message confirming backend is reachable
     */
    @GetMapping
    @Operation(summary = "Test backend connection", description = "Simple endpoint to test if the backend is reachable")
    @ApiResponse(responseCode = "200", description = "Backend is reachable")
    public String testGetEndpoint(){
        return "Backend reached successfully";
    }
}
