package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/go-playground/validator/v10"
	"github.com/rs/cors"

	"github.com/bacon13/shared"
)

var (
	validate = validator.New()
)

func main() {
	ctx := context.Background()

	// Initialize Firestore
	if err := shared.InitDB(); err != nil {
		log.Fatal("Failed to initialize Firestore:", err)
	}

	// Initialize Firebase Auth
	if err := shared.InitFirebaseAuth(ctx); err != nil {
		log.Fatal("Failed to initialize Firebase Auth:", err)
	}

	// Create collections (no-op for Firestore)
	if err := shared.CreateTables(); err != nil {
		log.Fatal("Failed to create collections:", err)
	}

	// Setup routes
	r := mux.NewRouter()
	
	// Health check
	r.HandleFunc("/health", healthCheck).Methods("GET")
	
	// Auth routes - Note: Registration/login now handled by Firebase SDK on client
	// These endpoints are for server-side verification and user profile management
	r.HandleFunc("/verify", verifyToken).Methods("POST")
	r.HandleFunc("/profile", getUserProfile).Methods("GET")
	r.HandleFunc("/profile", updateUserProfile).Methods("PUT")

	// Setup CORS
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"*"},
	})

	handler := c.Handler(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("Auth service starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, handler))
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	response := shared.APIResponse{
		Success: true,
		Message: "Auth service is healthy",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// verifyToken verifies a Firebase ID token and returns user info
func verifyToken(w http.ResponseWriter, r *http.Request) {
	// Get token from request body
	var tokenRequest struct {
		Token string `json:"token" validate:"required"`
	}
	
	if err := json.NewDecoder(r.Body).Decode(&tokenRequest); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if err := validate.Struct(tokenRequest); err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   err.Error(),
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(response)
		return
	}

	ctx := r.Context()
	
	// Verify Firebase ID token
	token, err := shared.VerifyIDToken(ctx, tokenRequest.Token)
	if err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   "Invalid token",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(response)
		return
	}

	// Get or create user profile in Firestore
	user, err := getOrCreateUserProfile(ctx, token.UID, token.Claims["email"].(string))
	if err != nil {
		log.Printf("Failed to get/create user profile: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	response := shared.APIResponse{
		Success: true,
		Message: "Token is valid",
		Data: map[string]interface{}{
			"uid":   token.UID,
			"email": token.Claims["email"],
			"user":  user,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// getUserProfile gets user profile by Firebase UID from Authorization header
func getUserProfile(w http.ResponseWriter, r *http.Request) {
	uid, err := getUIDFromAuthHeader(r)
	if err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   "Invalid authorization",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(response)
		return
	}

	ctx := r.Context()
	userRef := shared.FirestoreClient.Collection("users").Doc(uid)
	doc, err := userRef.Get(ctx)
	if err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   "User not found",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(response)
		return
	}

	var user shared.User
	if err := doc.DataTo(&user); err != nil {
		log.Printf("Failed to decode user data: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	response := shared.APIResponse{
		Success: true,
		Data:    user,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// updateUserProfile updates user profile
func updateUserProfile(w http.ResponseWriter, r *http.Request) {
	uid, err := getUIDFromAuthHeader(r)
	if err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   "Invalid authorization",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(response)
		return
	}

	var updateData map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&updateData); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Add updated timestamp
	updateData["updated_at"] = time.Now()

	ctx := r.Context()
	userRef := shared.FirestoreClient.Collection("users").Doc(uid)
	
	// Build update map
	updates := make(map[string]interface{})
	updates["updated_at"] = updateData["updated_at"]
	
	// Add other allowed fields
	if profileImages, ok := updateData["profile_images"]; ok {
		updates["profile_images"] = profileImages
	}
	
	_, err = userRef.Update(ctx, updates)
	if err != nil {
		log.Printf("Failed to update user: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	response := shared.APIResponse{
		Success: true,
		Message: "Profile updated successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Helper functions

// getUIDFromAuthHeader extracts and verifies Firebase UID from Authorization header
func getUIDFromAuthHeader(r *http.Request) (string, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return "", fmt.Errorf("authorization header required")
	}

	// Remove "Bearer " prefix if present
	tokenString := authHeader
	if strings.HasPrefix(authHeader, "Bearer ") {
		tokenString = authHeader[7:]
	}

	ctx := r.Context()
	token, err := shared.VerifyIDToken(ctx, tokenString)
	if err != nil {
		return "", err
	}

	return token.UID, nil
}

// getOrCreateUserProfile gets existing user or creates new profile from Firebase user
func getOrCreateUserProfile(ctx context.Context, uid, email string) (*shared.User, error) {
	userRef := shared.FirestoreClient.Collection("users").Doc(uid)
	doc, err := userRef.Get(ctx)
	
	if err != nil {
		// User doesn't exist, create new profile
		now := time.Now()
		user := &shared.User{
			ID:            uid,
			Email:         email,
			CreatedAt:     now,
			UpdatedAt:     now,
			ProfileImages: []string{},
		}

		_, err = userRef.Set(ctx, user)
		if err != nil {
			return nil, fmt.Errorf("failed to create user profile: %v", err)
		}

		return user, nil
	}

	// User exists, return existing profile
	var user shared.User
	if err := doc.DataTo(&user); err != nil {
		return nil, fmt.Errorf("failed to decode user data: %v", err)
	}

	return &user, nil
}
