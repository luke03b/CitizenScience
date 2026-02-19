package com.citizenScience.repositories;

import com.citizenScience.entities.FotoAvvistamento;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/**
 * Repository interface for FotoAvvistamento entity data access.
 * Provides methods for photo-related database operations.
 */
public interface FotoAvvistamentoRepository extends JpaRepository<FotoAvvistamento, UUID> {
}
