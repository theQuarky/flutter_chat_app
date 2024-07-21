import * as admin from 'firebase-admin';
import { APIGatewayProxyHandler } from 'aws-lambda';
import AWS from 'aws-sdk';

const eventbridge = new AWS.EventBridge();

interface UserData {
    userId: string;
    bio?: string;
    birthDate: string;
    gender: string;
    location?: {
        latitude: number;
        longitude: number;
    };
    timestamp?: number;
}

interface RequestBody {
    userId: string;
    location?: {
        latitude: number;
        longitude: number;
    };
}

interface NotificationData {
    recipientUserId: string;
    body?: string;
    type: "text" | "photo" | "video" | "audio";
    senderId: string;
    chatId: string;
}

const serviceAccount = require('./firebase-service-account.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

export const addToMatchQueueHandler: APIGatewayProxyHandler = async (event) => {
    console.log('Function started');
    if (!event.body) {
        console.log('No event body');
        return { statusCode: 400, body: JSON.stringify({ message: 'Invalid input' }) };
    }

    const { userId, location }: RequestBody = JSON.parse(event.body);
    console.log(`Received request for user: ${userId}`);

    const idToken = event.headers['Authorization']?.split('Bearer ')[1];
    if (!idToken) {
        console.log('No ID token provided');
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }) };
    }

    try {
        console.log('Verifying ID token');
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        if (decodedToken.uid !== userId) {
            console.log('Token UID does not match userId');
            return { statusCode: 403, body: JSON.stringify({ message: 'Forbidden' }) };
        }

        console.log('Retrieving user data from Firestore');
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) {
            console.log('User not found in Firestore');
            return { statusCode: 404, body: JSON.stringify({ message: 'User not found' }) };
        }

        const userData = userDoc.data() as UserData;
        console.log('User data retrieved');

        const matchQueueData: UserData = {
            userId,
            birthDate: userData.birthDate,
            gender: userData.gender,
            bio: userData.bio,
            timestamp: Date.now(),
        };

        // Only add location if it's provided in the request
        if (location && typeof location.latitude === 'number' && typeof location.longitude === 'number') {
            matchQueueData.location = location;
        }

        console.log('Adding user to match queue');
        await db.collection('matchQueue').doc(userId).set(matchQueueData);
        console.log('User added to match queue');

        const params = {
            Entries: [
                {
                    Source: 'com.matchmaking.queue',
                    DetailType: 'MatchQueueUpdate',
                    Detail: JSON.stringify({
                        action: 'add',
                        userId: userId
                    }),
                    EventBusName: 'default'
                }
            ]
        };

        await eventbridge.putEvents(params).promise();
        console.log('Event emitted to trigger FindMatchesFunction');

        return { statusCode: 200, body: JSON.stringify({ message: 'Added to match queue' }) };
    } catch (error) {
        console.error('Error in addToMatchQueueHandler:', error);
        if (error instanceof Error) {
            return { statusCode: 500, body: JSON.stringify({ message: `Server error: ${error.message}` }) };
        }
        return { statusCode: 500, body: JSON.stringify({ message: 'Unknown server error' }) };
    }
};

export const removeFromMatchQueueHandler: APIGatewayProxyHandler = async (event) => {
    console.log('RemoveFromMatchQueue function started');
    if (!event.body) {
        console.log('No event body');
        return { statusCode: 400, body: JSON.stringify({ message: 'Invalid input' }) };
    }

    const { userId }: RequestBody = JSON.parse(event.body);
    console.log(`Received request to remove user: ${userId}`);

    const idToken = event.headers['Authorization']?.split('Bearer ')[1];
    if (!idToken) {
        console.log('No ID token provided');
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }) };
    }

    try {
        console.log('Verifying ID token');
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        if (decodedToken.uid !== userId) {
            console.log('Token UID does not match userId');
            return { statusCode: 403, body: JSON.stringify({ message: 'Forbidden' }) };
        }

        console.log('Removing user from match queue');
        await db.collection('matchQueue').doc(userId).delete();
        console.log('User removed from match queue');

        return { statusCode: 200, body: JSON.stringify({ message: 'Removed from match queue' }) };
    } catch (error) {
        console.error('Error in removeFromMatchQueueHandler:', error);
        if (error instanceof Error) {
            return { statusCode: 500, body: JSON.stringify({ message: `Server error: ${error.message}` }) };
        }
        return { statusCode: 500, body: JSON.stringify({ message: 'Unknown server error' }) };
    }
};


export const sendNewMessageNotificationHandler: APIGatewayProxyHandler = async (event) => {
    console.log('SendNotification function started');
    const idToken = event.headers['Authorization']?.split('Bearer ')[1];

    if (!idToken) {
        console.log('No ID token provided');
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }) };
    }

    if (!event.body) {
        console.log('No event body');
        return { statusCode: 400, body: JSON.stringify({ message: 'Invalid input' }) };
    }

    const { recipientUserId, body, type, senderId, chatId }: NotificationData = JSON.parse(event.body);
    console.log(`Received request to send notification to user: ${recipientUserId}`);

    if (type === "text" && body === undefined) {
        return {
            statusCode: 401,
            body: JSON.stringify({ message: 'can not send empty text message' })
        }
    }

    try {
        console.log('Verifying ID token');
        await admin.auth().verifyIdToken(idToken);

        console.log('Retrieving recipient user data from Firestore');
        const userDoc = await db.collection('users').doc(recipientUserId).get();

        if (!userDoc.exists) {
            console.log('Recipient user not found in Firestore');
            return { statusCode: 404, body: JSON.stringify({ message: 'Recipient user not found' }) };
        }

        const userData = userDoc.data();
        const fcmTokens: string[] = userData?.deviceTokens;
        const userName = userData?.displayName;

        if (!fcmTokens) {
            console.log('FCM token not found for recipient user');
            return { statusCode: 400, body: JSON.stringify({ message: 'FCM token not found for recipient user' }) };
        }

        const notificationBody: Record<NotificationData['type'], string | undefined> = {
            "text": body,
            "audio": "Sent Audio",
            "photo": "Sent Photo",
            "video": "Sent Video"
        }

        console.log('Sending notification');
        await Promise.all(fcmTokens.map(token => {
            const message: admin.messaging.Message = {
                notification: {
                    title: userName,
                    body: notificationBody[type],
                },
                data: {
                    chatId,
                    senderId,
                    type: type,
                    // You can add more data here if needed
                },
                token: token,
                android: {
                    notification: {
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                        priority: 'high',
                    },
                },
            }
            return admin.messaging().send(message);
        }));
        return { statusCode: 200, body: JSON.stringify({ message: 'Notification sent successfully' }) };
    } catch (error) {
        console.error('Error in sendNotificationHandler:', error);
        if (error instanceof Error) {
            return { statusCode: 500, body: JSON.stringify({ message: `Server error: ${error.message}` }) };
        }
        return { statusCode: 500, body: JSON.stringify({ message: 'Unknown server error' }) };
    }
};