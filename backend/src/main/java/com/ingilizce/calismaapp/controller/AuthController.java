package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String password = request.get("password");

        if (email == null || password == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email and password required"));
        }

        if (userRepository.existsByEmail(email)) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email already in use"));
        }

        User user = new User(email, hashPassword(password));
        User savedUser = userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "User registered successfully", "userId", savedUser.getId()));
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String password = request.get("password");

        Optional<User> userOpt = userRepository.findByEmail(email);

        if (userOpt.isPresent()) {
            User user = userOpt.get();
            if (user.getPasswordHash().equals(hashPassword(password))) {
                Map<String, Object> response = new HashMap<>();
                response.put("userId", user.getId());
                response.put("email", user.getEmail());
                response.put("role", user.getRole());
                response.put("subscriptionEndDate", user.getSubscriptionEndDate());
                response.put("isSubscriptionActive", user.isSubscriptionActive());
                return ResponseEntity.ok(response);
            }
        }

        return ResponseEntity.status(401).body(Map.of("error", "Invalid credentials"));
    }

    // Simple SHA-256 (Not production secure, but sufficient for requirements
    // without deps)
    private String hashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] encodedhash = digest.digest(password.getBytes());
            return Base64.getEncoder().encodeToString(encodedhash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Error hashing password", e);
        }
    }
}
