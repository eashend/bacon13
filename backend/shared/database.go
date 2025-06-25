package shared

import (
	"context"
	"fmt"
	"log"
	"os"

	"cloud.google.com/go/firestore"
)

// FirestoreClient holds the Firestore client connection
var FirestoreClient *firestore.Client

// InitDB initializes the Firestore connection
func InitDB() error {
	projectID := os.Getenv("PROJECT_ID")
	if projectID == "" {
		return fmt.Errorf("PROJECT_ID environment variable is required")
	}

	ctx := context.Background()
	var err error
	FirestoreClient, err = firestore.NewClient(ctx, projectID)
	if err != nil {
		return fmt.Errorf("failed to create Firestore client: %v", err)
	}

	log.Println("Firestore connected successfully")
	return nil
}

// CreateTables is a no-op for Firestore since it's schemaless
// Collections are created automatically when documents are written
func CreateTables() error {
	log.Println("Firestore collections will be created automatically")
	return nil
}

// CloseDB closes the Firestore connection
func CloseDB() error {
	if FirestoreClient != nil {
		return FirestoreClient.Close()
	}
	return nil
}
