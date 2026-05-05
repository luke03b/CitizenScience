package com.citizenscience.services;

import com.citizenscience.dto.UpdateUserRequest;
import com.citizenscience.dto.UserResponse;
import com.citizenscience.entities.User;
import com.citizenscience.exceptions.UserAlreadyExistsException;
import com.citizenscience.exceptions.UserNotFoundException;
import com.citizenscience.repositories.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service for managing user profile operations.
 * Provides functionality to retrieve and update user information.
 */
@Service
public class UserService {

    private final UserRepository userRepository;

    /**
     * Constructs the UserService with required dependencies.
     * 
     * @param userRepository the repository for user data access
     */
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Retrieves the current user's information.
     * 
     * @param user the authenticated user
     * @return UserResponse containing user details
     */
    public UserResponse getCurrentUser(User user) {
        return UserResponse.from(user);
    }

    /**
     * Updates the current user's profile information.
     * 
     * @param currentUser the authenticated user
     * @param request the update request containing new user details
     * @return UserResponse containing updated user information
     * @throws UserNotFoundException if user not found
     * @throws UserAlreadyExistsException if the new email is already in use
     */
    @Transactional
    public UserResponse updateCurrentUser(User currentUser, UpdateUserRequest request) {
        User user = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (request.getNome() != null) {
            user.setNome(request.getNome());
        }
        if (request.getCognome() != null) {
            user.setCognome(request.getCognome());
        }
        if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new UserAlreadyExistsException("Email already in use");
            }
            user.setEmail(request.getEmail());
        }

        user = userRepository.save(user);
        return UserResponse.from(user);
    }
}
