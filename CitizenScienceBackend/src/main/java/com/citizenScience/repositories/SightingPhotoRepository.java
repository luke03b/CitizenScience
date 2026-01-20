package com.citizenScience.repositories;

import com.citizenScience.entities.SightingPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SightingPhotoRepository extends JpaRepository<SightingPhoto, Long> {

    List<SightingPhoto> findBySightingId(Long sightingId);

    Optional<SightingPhoto> findBySightingIdAndIsPrimaryTrue(Long sightingId);

    long countBySightingId(Long sightingId);

    void deleteBySightingId(Long sightingId);
}