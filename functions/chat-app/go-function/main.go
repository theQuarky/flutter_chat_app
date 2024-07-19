package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"time"

	firebase "firebase.google.com/go"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"google.golang.org/api/option"
)

type User struct {
	UserID    string    `firestore:"userId"`
	BirthDate time.Time `firestore:"birthDate"`
	Gender    string    `firestore:"gender"`
	Bio       string    `firestore:"bio"`
	Location  GeoPoint  `firestore:"location"`
	Timestamp time.Time `firestore:"timestamp"`
}

type GeoPoint struct {
	Latitude  float64 `firestore:"latitude"`
	Longitude float64 `firestore:"longitude"`
}

func findMatches(ctx context.Context, event events.CloudWatchEvent) (string, error) {
	log.Println("FindMatches function started")

	opt := option.WithCredentialsFile("firebase-service-account.json")
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Printf("Error initializing Firebase app: %v", err)
		return "", fmt.Errorf("error initializing app: %v", err)
	}
	log.Println("Firebase app initialized successfully")

	client, err := app.Firestore(ctx)
	if err != nil {
		log.Printf("Error getting Firestore client: %v", err)
		return "", fmt.Errorf("error getting Firestore client: %v", err)
	}
	defer client.Close()
	log.Println("Firestore client created successfully")

	// Get all users from matchQueue
	log.Println("Fetching users from matchQueue")
	iter := client.Collection("matchQueue").Documents(ctx)
	var users []User
	for {
		doc, err := iter.Next()
		if err != nil {
			if err == nil {
				log.Println("Finished iterating over matchQueue")
			} else {
				log.Printf("Error iterating over matchQueue: %v", err)
			}
			break
		}
		var user User
		err = doc.DataTo(&user)
		if err != nil {
			log.Printf("Error parsing user data: %v", err)
			continue
		}
		users = append(users, user)
	}
	log.Printf("Found %d users in matchQueue", len(users))

	// Simple matching algorithm (random matching for demonstration)
	log.Println("Starting matching process")
	rand.Shuffle(len(users), func(i, j int) { users[i], users[j] = users[j], users[i] })

	matchesCreated := 0
	for i := 0; i < len(users); i += 2 {
		if i+1 < len(users) {
			user1 := users[i]
			user2 := users[i+1]

			log.Printf("Attempting to create match between %s and %s", user1.UserID, user2.UserID)

			// Create a match
			_, _, err := client.Collection("matches").Add(ctx, map[string]interface{}{
				"user1":     user1.UserID,
				"user2":     user2.UserID,
				"timestamp": time.Now(),
			})
			if err != nil {
				log.Printf("Error creating match between %s and %s: %v", user1.UserID, user2.UserID, err)
				continue
			}
			log.Printf("Match created successfully between %s and %s", user1.UserID, user2.UserID)

			// Remove users from matchQueue
			log.Printf("Removing %s from matchQueue", user1.UserID)
			_, err = client.Collection("matchQueue").Doc(user1.UserID).Delete(ctx)
			if err != nil {
				log.Printf("Error removing %s from matchQueue: %v", user1.UserID, err)
			}

			log.Printf("Removing %s from matchQueue", user2.UserID)
			_, err = client.Collection("matchQueue").Doc(user2.UserID).Delete(ctx)
			if err != nil {
				log.Printf("Error removing %s from matchQueue: %v", user2.UserID, err)
			}

			// Notify users (for demonstration, we'll just log it)
			log.Printf("Match created and users notified: %s and %s", user1.UserID, user2.UserID)

			matchesCreated++
		}
	}

	log.Printf("Matching process completed. Created %d matches", matchesCreated)
	return fmt.Sprintf("Matching process completed. Created %d matches", matchesCreated), nil
}

func main() {
	lambda.Start(findMatches)
}
