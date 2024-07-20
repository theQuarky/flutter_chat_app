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
            location: location,
        };

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