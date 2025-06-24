package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/go-playground/validator/v10"
	"github.com/rs/cors"
	"golang.org/x/crypto/bcrypt"

	"github.com/seenme/shared"
)

var (
	jwtSecret = []byte("your-secret-key-change-in-production")
	validate  = validator.New()
)

func main() {
	// Initialize database
	if err := shared.InitDB(); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// Create tables
	if err := shared.CreateTables(); err != nil {
		log.Fatal("Failed to create tables:", err)
	}

	// Setup routes
	r := mux.NewRouter()
	
	// Health check
	r.HandleFunc("/health", healthCheck).Methods("GET")
	
	// Auth routes
	r.HandleFunc("/register", register).Methods("POST")
	r.HandleFunc("/login", login).Methods("POST")
	r.HandleFunc("/verify", verifyToken).Methods("GET")

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

func register(w http.ResponseWriter, r *http.Request) {
	var req shared.UserRegistrationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Validate request
	if err := validate.Struct(req); err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   err.Error(),
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(response)
		return
	}

	// Check if user already exists
	var exists bool
	err := shared.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)", req.Email).Scan(&exists)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if exists {
		response := shared.APIResponse{
			Success: false,
			Error:   "User with this email already exists",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(response)
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Failed to hash password", http.StatusInternalServerError)
		return
	}

	// Create user
	userID := uuid.New()
	now := time.Now()

	_, err = shared.DB.Exec(`
		INSERT INTO users (id, email, password_hash, created_at, updated_at) 
		VALUES ($1, $2, $3, $4, $5)
	`, userID, req.Email, string(hashedPassword), now, now)

	if err != nil {
		log.Printf("Failed to create user: %v", err)
		http.Error(w, "Failed to create user", http.StatusInternalServerError)
		return
	}

	// Create JWT token
	token, err := generateJWT(userID, req.Email)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	user := shared.User{
		ID:        userID,
		Email:     req.Email,
		CreatedAt: now,
		UpdatedAt: now,
	}

	response := shared.APIResponse{
		Success: true,
		Message: "User registered successfully",
		Data: shared.AuthResponse{
			Token: token,
			User:  user,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

func login(w http.ResponseWriter, r *http.Request) {
	var req shared.UserLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Validate request
	if err := validate.Struct(req); err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   err.Error(),
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(response)
		return
	}

	// Get user from database
	var user shared.User
	var passwordHash string
	err := shared.DB.QueryRow(`
		SELECT id, email, password_hash, created_at, updated_at, profile_images
		FROM users WHERE email = $1
	`, req.Email).Scan(&user.ID, &user.Email, &passwordHash, &user.CreatedAt, &user.UpdatedAt, &user.ProfileImages)

	if err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   "Invalid email or password",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(response)
		return
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)); err != nil {
		response := shared.APIResponse{
			Success: false,
			Error:   "Invalid email or password",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(response)
		return
	}

	// Generate JWT token
	token, err := generateJWT(user.ID, user.Email)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	response := shared.APIResponse{
		Success: true,
		Message: "Login successful",
		Data: shared.AuthResponse{
			Token: token,
			User:  user,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func verifyToken(w http.ResponseWriter, r *http.Request) {
	tokenString := r.Header.Get("Authorization")
	if tokenString == "" {
		response := shared.APIResponse{
			Success: false,
			Error:   "Authorization header required",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(response)
		return
	}

	// Remove "Bearer " prefix if present
	if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
		tokenString = tokenString[7:]
	}

	userID, email, err := validateJWT(tokenString)
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

	response := shared.APIResponse{
		Success: true,
		Message: "Token is valid",
		Data: map[string]interface{}{
			"user_id": userID,
			"email":   email,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func generateJWT(userID uuid.UUID, email string) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID.String(),
		"email":   email,
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(), // 7 days
		"iat":     time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

func validateJWT(tokenString string) (uuid.UUID, string, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return jwtSecret, nil
	})

	if err != nil {
		return uuid.Nil, "", err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		userIDStr, ok := claims["user_id"].(string)
		if !ok {
			return uuid.Nil, "", fmt.Errorf("invalid user_id claim")
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			return uuid.Nil, "", fmt.Errorf("invalid user_id format")
		}

		email, ok := claims["email"].(string)
		if !ok {
			return uuid.Nil, "", fmt.Errorf("invalid email claim")
		}

		return userID, email, nil
	}

	return uuid.Nil, "", fmt.Errorf("invalid token")
}
