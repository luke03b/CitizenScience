package com.citizenScience.services;

import com.citizenScience.entities.User;
import com.citizenScience.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    // ═══════════════════════════════════════════════════════════════
    // REGISTRAZIONE
    // ═══════════════════════════════════════════════════════════════

    public User register(String email, String password, String username) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email già registrata");
        }

        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username già in uso");
        }

        User user = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .username(username)
                .build();

        return userRepository.save(user);
    }

    // ═══════════════════════════════════════════════════════════════
    // AUTENTICAZIONE
    // ═══════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public User authenticate(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Credenziali non valide"));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new IllegalArgumentException("Credenziali non valide");
        }

        return user;
    }

    // ═══════════════════════════════════════════════════════════════
    // CRUD
    // ═══════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    @Transactional(readOnly = true)
    public List<User> findAll() {
        return userRepository.findAll();
    }

    public User update(Long id, String username) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Utente non trovato"));

        if (username != null && !username.equals(user.getUsername())) {
            if (userRepository.existsByUsername(username)) {
                throw new IllegalArgumentException("Username già in uso");
            }
            user.setUsername(username);
        }

        return userRepository.save(user);
    }

    public void changePassword(Long id, String oldPassword, String newPassword) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Utente non trovato"));

        if (!passwordEncoder.matches(oldPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Password attuale non corretta");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    public void delete(Long id) {
        if (!userRepository.existsById(id)) {
            throw new IllegalArgumentException("Utente non trovato");
        }
        userRepository.deleteById(id);
    }
}