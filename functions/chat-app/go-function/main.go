package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

type User struct {
	UserID       string    `firestore:"userId"`
	BirthDate    time.Time `firestore:"birthDate"`
	Gender       string    `firestore:"gender"`
	Bio          string    `firestore:"bio"`
	Location     GeoPoint  `firestore:"location"`
	DeviceTokens []string  `firestore:"deviceTokens"`
}

type GeoPoint struct {
	Latitude  float64 `firestore:"latitude"`
	Longitude float64 `firestore:"longitude"`
}

type ChatEntry struct {
	MatchID         string    `firestore:"matchId"`
	Users           []string  `firestore:"users"`
	CreatedAt       time.Time `firestore:"createdAt"`
	LastMessage     string    `firestore:"lastMessage"`
	LastMessageTime time.Time `firestore:"lastMessageTime"`
	FriendRequest   []string  `firestore:"friendRequest"`
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

	fcmClient, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("Error getting FCM client: %v", err)
		return "", fmt.Errorf("error getting FCM client: %v", err)
	}
	log.Println("FCM client created successfully")

	// Get all users from matchQueue
	log.Println("Fetching users from matchQueue")
	iter := client.Collection("matchQueue").Documents(ctx)
	var users []User
	for {
		doc, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				log.Println("Finished iterating over matchQueue")
				break
			}
			log.Printf("Error iterating over matchQueue: %v", err)
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
			matchTime := time.Now()
			matchID := user1.UserID + "-" + user2.UserID

			// Create chat entry
			chatEntry := ChatEntry{
				MatchID:         matchID,
				Users:           []string{user1.UserID, user2.UserID},
				FriendRequest:   []string{},
				CreatedAt:       matchTime,
				LastMessage:     "",
				LastMessageTime: matchTime,
			}
			_, err = client.Collection("userChats").Doc(matchID).Set(ctx, chatEntry)

			if err != nil {
				log.Printf("Error creating match between %s and %s: %v", user1.UserID, user2.UserID, err)
				continue
			}
			log.Printf("Match created successfully between %s and %s at %v", user1.UserID, user2.UserID, matchTime)

			// Remove users from matchQueue
			_, err = client.Collection("matchQueue").Doc(user1.UserID).Delete(ctx)
			if err != nil {
				log.Printf("Error removing %s from matchQueue: %v", user1.UserID, err)
			}

			_, err = client.Collection("matchQueue").Doc(user2.UserID).Delete(ctx)
			if err != nil {
				log.Printf("Error removing %s from matchQueue: %v", user2.UserID, err)
			}

			// Notify users
			notifyUser(ctx, fcmClient, client, user1.UserID, "You have a new match!")
			notifyUser(ctx, fcmClient, client, user2.UserID, "You have a new match!")

			matchesCreated++
		}
	}

	log.Printf("Matching process completed. Created %d matches", matchesCreated)
	return fmt.Sprintf("Matching process completed. Created %d matches", matchesCreated), nil
}

func notifyUser(ctx context.Context, fcmClient *messaging.Client, firestoreClient *firestore.Client, userID string, message string) {
	userDoc, err := firestoreClient.Collection("users").Doc(userID).Get(ctx)
	if err != nil {
		log.Printf("Error fetching user data for %s: %v", userID, err)
		return
	}

	var user User
	if err := userDoc.DataTo(&user); err != nil {
		log.Printf("Error parsing user data for %s: %v", userID, err)
		return
	}

	if len(user.DeviceTokens) == 0 {
		log.Printf("No device tokens found for user %s", userID)
		return
	}

	for _, token := range user.DeviceTokens {
		notification := &messaging.Message{
			Token: token,
			Notification: &messaging.Notification{
				Title: "New Match!",
				Body:  message,
			},
			Data: map[string]string{
				"click_action": "FLUTTER_NOTIFICATION_CLICK",
				"type":         "match",
			},
		}

		response, err := fcmClient.Send(ctx, notification)
		if err != nil {
			log.Printf("Error sending notification to user %s (token: %s): %v", userID, token, err)
		} else {
			log.Printf("Successfully sent notification to user %s (token: %s): %s", userID, token, response)
		}
	}
}

func main() {
	lambda.Start(findMatches)
}
