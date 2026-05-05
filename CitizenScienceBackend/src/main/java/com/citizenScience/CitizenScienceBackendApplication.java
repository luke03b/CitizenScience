package com.citizenscience;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main application class for the EcoFlora backend.
 * Entry point for the Spring Boot application.
 */
@SpringBootApplication
public class CitizenScienceBackendApplication {

	/**
	 * Main method to start the Spring Boot application.
	 * 
	 * @param args command-line arguments
	 */
	public static void main(String[] args) {
		SpringApplication.run(CitizenScienceBackendApplication.class, args);
	}

}
