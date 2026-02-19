package com.citizenScience.services;

import com.citizenScience.dto.*;
import com.citizenScience.entities.User;
import com.citizenScience.exceptions.InvalidCredentialsException;
import com.citizenScience.exceptions.UserAlreadyExistsException;
import com.citizenScience.exceptions.UserNotFoundException;
import com.citizenScience.repositories.UserRepository;
import com.citizenScience.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service for handling user authentication operations.
 * Provides registration, login, and password change functionality.
 */
@Service
public class AuthService {

    private static final String ROLE_USER = "utente";
    private static final String ROLE_RESEARCHER = "ricercatore";
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /**
     * Constructs the AuthService with required dependencies.
     * 
     * @param userRepository the repository for user data access
     * @param passwordEncoder the encoder for password hashing
     * @param jwtUtil the utility for JWT token operations
     */
    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    /**
     * Registers a new user in the system.
     * 
     * @param request the registration request containing user details
     * @return AuthResponse containing JWT token and user information
     * @throws UserAlreadyExistsException if a user with the email already exists
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new UserAlreadyExistsException("User with email " + request.getEmail() + " already exists");
        }

        String ruolo = request.getRuolo();
        if (ruolo == null || (!ruolo.equals(ROLE_USER) && !ruolo.equals(ROLE_RESEARCHER))) {
            ruolo = ROLE_USER;
        }

        User user = User.builder()
                .nome(request.getNome())
                .cognome(request.getCognome())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .ruolo(ruolo)
                .build();

        user = userRepository.save(user);
        String token = jwtUtil.generateToken(user.getEmail());

        return AuthResponse.from(token, user);
    }

    /**
     * Authenticates a user and generates a JWT token.
     * 
     * @param request the login request containing email and password
     * @return AuthResponse containing JWT token and user information
     * @throws InvalidCredentialsException if email or password is invalid
     */
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }

        String token = jwtUtil.generateToken(user.getEmail());
        return AuthResponse.from(token, user);
    }

    /**
     * Changes the password for the currently authenticated user.
     * 
     * @param currentUser the authenticated user
     * @param request the password change request containing old and new passwords
     * @return success message
     * @throws UserNotFoundException if user not found
     * @throws InvalidCredentialsException if old password is incorrect
     */
    @Transactional
    public String changePassword(User currentUser, ChangePasswordRequest request) {
        User user = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPasswordHash())) {
            throw new InvalidCredentialsException("Old password is incorrect");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        return "Password changed successfully";
    }
}
