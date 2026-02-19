package com.citizenScience.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Map;

/**
 * Service for geocoding operations using OpenStreetMap Nominatim API.
 * Provides reverse geocoding to convert coordinates into human-readable addresses.
 */
@Service
public class GeocodingService {
    
    private static final Logger logger = LoggerFactory.getLogger(GeocodingService.class);
    private static final String NOMINATIM_API_URL = "https://nominatim.openstreetmap.org";
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(5);
    
    private final WebClient webClient;
    
    /**
     * Constructs the GeocodingService and initializes WebClient.
     */
    public GeocodingService() {
        this.webClient = WebClient.builder()
                .baseUrl(NOMINATIM_API_URL)
                .build();
    }
    
    /**
     * Performs reverse geocoding to convert coordinates into an address.
     * Uses Nominatim API with a 5-second timeout.
     * Falls back to coordinate format if geocoding fails.
     * 
     * @param latitude the latitude coordinate
     * @param longitude the longitude coordinate
     * @return human-readable address or formatted coordinates if geocoding fails
     */
    public String reverseGeocode(Double latitude, Double longitude) {
        try {
            Map<String, Object> response = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/reverse")
                            .queryParam("lat", latitude)
                            .queryParam("lon", longitude)
                            .queryParam("format", "json")
                            .queryParam("addressdetails", "1")
                            .build())
                    .header("User-Agent", "CitizenScienceApp/1.0")
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(REQUEST_TIMEOUT)
                    .onErrorResume(e -> {
                        logger.warn("Geocoding API error for coordinates ({}, {}): {}", 
                                latitude, longitude, e.getMessage());
                        return Mono.empty();
                    })
                    .block();
            
            if (response != null && response.containsKey("address")) {
                return buildAddressString(response);
            }
        } catch (Exception e) {
            logger.error("Error during reverse geocoding for coordinates ({}, {}): {}", 
                    latitude, longitude, e.getMessage());
        }
        
        return String.format("%.4f, %.4f", latitude, longitude);
    }
    
    /**
     * Builds a human-readable address string from Nominatim API response.
     * Prioritizes road, city/town/village, and state information.
     * 
     * @param response the Nominatim API response map
     * @return formatted address string
     */
    private String buildAddressString(Map<String, Object> response) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> address = (Map<String, Object>) response.get("address");
            
            if (address == null) {
                return (String) response.getOrDefault("display_name", "Unknown");
            }
            
            StringBuilder addressBuilder = new StringBuilder();
            
            String road = (String) address.get("road");
            if (road != null && !road.isEmpty()) {
                addressBuilder.append(road);
            }
            
            String city = (String) address.get("city");
            if (city == null) city = (String) address.get("town");
            if (city == null) city = (String) address.get("village");
            if (city == null) city = (String) address.get("municipality");
            
            if (city != null && !city.isEmpty()) {
                if (addressBuilder.length() > 0) {
                    addressBuilder.append(", ");
                }
                addressBuilder.append(city);
            }
            
            String state = (String) address.get("state");
            if (state != null && !state.isEmpty() && 
                (city == null || !state.equals(city))) {
                if (addressBuilder.length() > 0) {
                    addressBuilder.append(", ");
                }
                addressBuilder.append(state);
            }
            
            if (addressBuilder.length() > 0) {
                return addressBuilder.toString();
            }
            
            return (String) response.getOrDefault("display_name", "Unknown");
            
        } catch (Exception e) {
            logger.warn("Error building address string: {}", e.getMessage());
            return (String) response.getOrDefault("display_name", "Unknown");
        }
    }
}
