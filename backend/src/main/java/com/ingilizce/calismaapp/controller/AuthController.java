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
        System.out.println("Processing registration request: " + request); // Debug log
        try {
            String email = request.get("email");
            String password = request.get("password");
            String displayName = request.get("displayName");

            if (email == null || password == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Email and password required"));
            }

            if (userRepository.existsByEmail(email)) {
                System.out.println("Email already exists: " + email);
                return ResponseEntity.badRequest().body(Map.of("error", "Email already in use"));
            }

            User user = new User(email, hashPassword(password), displayName);
            User savedUser = userRepository.save(user);
            System.out.println("User registered successfully: " + savedUser.getId());

            return ResponseEntity.ok(Map.of("success", true, "message", "User registered successfully", "userId",
                    savedUser.getId(), "user", savedUser));
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Error during registration: " + e.getMessage());
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Internal server error: " + e.getMessage(), "success", false));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> request) {
        System.out.println("Processing login request for: " + request.get("email"));
        try {
            String email = request.get("emailOrTag"); // Frontend sends emailOrTag
            if (email == null)
                email = request.get("email"); // Fallback

            String password = request.get("password");

            Optional<User> userOpt = userRepository.findByEmail(email);

            if (userOpt.isPresent()) {
                User user = userOpt.get();
                if (user.getPasswordHash().equals(hashPassword(password))) {
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", true);
                    response.put("userId", user.getId());
                    response.put("email", user.getEmail());
                    response.put("role", user.getRole());
                    response.put("displayName", user.getDisplayName());
                    response.put("userTag", user.getUserTag());
                    response.put("subscriptionEndDate", user.getSubscriptionEndDate());
                    response.put("isSubscriptionActive", user.isSubscriptionActive());
                    response.put("user", user); // Frontend expects 'user' object
                    System.out.println("Login successful for user: " + user.getId());
                    return ResponseEntity.ok(response);
                } else {
                    System.out.println("Invalid password for user: " + email);
                }
            } else {
                System.out.println("User not found: " + email);
            }

            return ResponseEntity.status(401).body(Map.of("error", "Invalid credentials", "success", false));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(Map.of("error", "Internal login error", "success", false));
        }
    }

    @PostMapping("/google-login")
    public ResponseEntity<Map<String, Object>> googleLogin(@RequestBody Map<String, String> request) {
        System.out.println("Processing Google login request: " + request);
        try {
            String email = request.get("email");
            String displayName = request.get("displayName");
            String photoUrl = request.get("photoUrl");
            String googleId = request.get("googleId"); // Optional

            if (email == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Email is required"));
            }

            Optional<User> userOpt = userRepository.findByEmail(email);
            User user;

            if (userOpt.isPresent()) {
                // User exists, log them in (trusting Google auth from frontend)
                user = userOpt.get();
                System.out.println("Google login: User found: " + user.getId());

                // Update displayName if it was null/default before
                if ((user.getDisplayName() == null || user.getDisplayName().equals("User")) && displayName != null) {
                    user.setDisplayName(displayName);
                    userRepository.save(user);
                }
            } else {
                // User doesn't exist, create proper account
                System.out.println("Google login: User not found, creating new account for: " + email);
                // Use googleId as password seed or random string
                String dummyPassword = googleId != null ? "google_auth_" + googleId : "google_auth_" + email;

                user = new User(email, hashPassword(dummyPassword), displayName);
                user = userRepository.save(user);
                System.out.println("Google login: New user created: " + user.getId());
            }

            // Return success response structure (same as login)
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("userId", user.getId());
            response.put("email", user.getEmail());
            response.put("role", user.getRole());
            response.put("displayName", user.getDisplayName());
            response.put("userTag", user.getUserTag());
            response.put("subscriptionEndDate", user.getSubscriptionEndDate());
            response.put("isSubscriptionActive", user.isSubscriptionActive());
            response.put("user", user);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Google login error: " + e.getMessage(), "success", false));
        }
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
