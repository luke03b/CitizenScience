package com.citizenScience.controllers;

import com.citizenScience.dto.ApiResponse;
import com.citizenScience.dto.UserDTO;
import com.citizenScience.entities.User;
import com.citizenScience.services.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return userService.findById(id)
                .map(user -> ResponseEntity.ok(UserDTO.fromEntity(user)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody UserDTO request) {
        try {
            User user = userService.update(id, request.getUsername());
            return ResponseEntity.ok(UserDTO.fromEntity(user));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Aggiornamento fallito", e.getMessage()));
        }
    }

    @PutMapping("/{id}/password")
    public ResponseEntity<?> changePassword(@PathVariable Long id, @RequestBody UserDTO request) {
        try {
            userService.changePassword(id, request.getOldPassword(), request.getNewPassword());
            return ResponseEntity.ok(ApiResponse.success("Password aggiornata con successo"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Cambio password fallito", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        try {
            userService.delete(id);
            return ResponseEntity.ok(ApiResponse.success("Utente eliminato con successo"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Eliminazione fallita", e.getMessage()));
        }
    }
}