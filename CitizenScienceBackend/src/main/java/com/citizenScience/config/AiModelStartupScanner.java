package com.citizenscience.config;

import com.citizenscience.services.AiService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Triggers a forced scan of all configured AI containers at application startup.
 * This populates the model registry in the database so that models are available
 * for AI inference without requiring a manual scan.
 */
@Component
public class AiModelStartupScanner {

    private static final Logger logger = LoggerFactory.getLogger(AiModelStartupScanner.class);

    private final AiService aiService;

    public AiModelStartupScanner(AiService aiService) {
        this.aiService = aiService;
    }

    /**
     * Runs a forced scan of all AI containers once the application is fully started.
     * Fires after the Spring context is refreshed and the application is ready to serve requests.
     */
    @EventListener(ApplicationReadyEvent.class)
    public void scanModelsOnStartup() {
        logger.info("Application ready – starting forced scan of AI container models...");
        try {
            Map<String, List<String>> result = aiService.forceScanModels();
            int totalModels = result.values().stream().mapToInt(List::size).sum();
            logger.info("Startup model scan complete: {} container(s) scanned, {} model(s) registered. Details: {}",
                    result.size(), totalModels, result);
        } catch (Exception e) {
            logger.error("Startup model scan failed; the registry may be empty until a manual scan is triggered.", e);
        }
    }
}
