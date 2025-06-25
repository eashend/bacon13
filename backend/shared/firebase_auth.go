package shared

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
)

// FirebaseAuth holds the Firebase Auth client
var FirebaseAuth *auth.Client

// InitFirebaseAuth initializes the Firebase Auth client
func InitFirebaseAuth(ctx context.Context) error {
	// Initialize Firebase app with default credentials
	app, err := firebase.NewApp(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to initialize Firebase app: %v", err)
	}

	// Get Auth client
	FirebaseAuth, err = app.Auth(ctx)
	if err != nil {
		return fmt.Errorf("failed to initialize Firebase Auth client: %v", err)
	}

	log.Println("Firebase Auth initialized successfully")
	return nil
}

// VerifyIDToken verifies a Firebase ID token and returns the user info
func VerifyIDToken(ctx context.Context, idToken string) (*auth.Token, error) {
	token, err := FirebaseAuth.VerifyIDToken(ctx, idToken)
	if err != nil {
		return nil, fmt.Errorf("failed to verify ID token: %v", err)
	}
	return token, nil
}

// GetUserByUID retrieves a user record by Firebase UID
func GetUserByUID(ctx context.Context, uid string) (*auth.UserRecord, error) {
	userRecord, err := FirebaseAuth.GetUser(ctx, uid)
	if err != nil {
		return nil, fmt.Errorf("failed to get user by UID: %v", err)
	}
	return userRecord, nil
}

// CreateCustomToken creates a custom token for a user (optional - for admin use)
func CreateCustomToken(ctx context.Context, uid string) (string, error) {
	token, err := FirebaseAuth.CustomToken(ctx, uid)
	if err != nil {
		return "", fmt.Errorf("failed to create custom token: %v", err)
	}
	return token, nil
}