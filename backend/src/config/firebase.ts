import admin from 'firebase-admin';
import { logger } from '@/utils/logger';

let firebaseApp: admin.app.App;

export function initializeFirebase(): void {
  try {
    if (!firebaseApp) {
      const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

      if (serviceAccountPath) {
        // Use service account file
        const serviceAccount = require(serviceAccountPath);
        firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: process.env.FIREBASE_PROJECT_ID
        });
      } else {
        // Use environment variables (for production)
        firebaseApp = admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
          })
        });
      }

      logger.info('🔥 Firebase Admin SDK initialized');
    }
  } catch (error) {
    logger.error('❌ Firebase initialization failed:', error);
    throw error;
  }
}

export function getFirebaseApp(): admin.app.App {
  if (!firebaseApp) {
    throw new Error('Firebase not initialized. Call initializeFirebase() first.');
  }
  return firebaseApp;
}

export function getAuth(): admin.auth.Auth {
  return admin.auth(getFirebaseApp());
}

export function getFirestore(): admin.firestore.Firestore {
  return admin.firestore(getFirebaseApp());
}

export function getMessaging(): admin.messaging.Messaging {
  return admin.messaging(getFirebaseApp());
}

// Firebase Authentication helpers
export async function verifyFirebaseToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
  try {
    const auth = getAuth();
    const decodedToken = await auth.verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    logger.error('❌ Firebase token verification failed:', error);
    throw new Error('Invalid authentication token');
  }
}

export async function createCustomToken(uid: string): Promise<string> {
  try {
    const auth = getAuth();
    const customToken = await auth.createCustomToken(uid);
    return customToken;
  } catch (error) {
    logger.error('❌ Custom token creation failed:', error);
    throw new Error('Failed to create custom token');
  }
}

export async function getUserByEmail(email: string): Promise<admin.auth.UserRecord | null> {
  try {
    const auth = getAuth();
    const userRecord = await auth.getUserByEmail(email);
    return userRecord;
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return null;
    }
    logger.error('❌ Get user by email failed:', error);
    throw error;
  }
}

export async function createUser(userData: {
  email: string;
  displayName?: string;
  photoURL?: string;
}): Promise<admin.auth.UserRecord> {
  try {
    const auth = getAuth();
    const userRecord = await auth.createUser(userData);
    return userRecord;
  } catch (error) {
    logger.error('❌ User creation failed:', error);
    throw error;
  }
}

export async function updateUser(uid: string, userData: {
  displayName?: string;
  photoURL?: string;
}): Promise<admin.auth.UserRecord> {
  try {
    const auth = getAuth();
    const userRecord = await auth.updateUser(uid, userData);
    return userRecord;
  } catch (error) {
    logger.error('❌ User update failed:', error);
    throw error;
  }
}

// Firestore helpers
export async function saveUserData(uid: string, data: any): Promise<void> {
  try {
    const firestore = getFirestore();
    await firestore.collection('users').doc(uid).set(data, { merge: true });
  } catch (error) {
    logger.error('❌ Save user data to Firestore failed:', error);
    throw error;
  }
}

export async function getUserData(uid: string): Promise<any | null> {
  try {
    const firestore = getFirestore();
    const doc = await firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  } catch (error) {
    logger.error('❌ Get user data from Firestore failed:', error);
    throw error;
  }
}

// Cloud Messaging helpers
export async function sendNotificationToUser(
  uid: string,
  notification: admin.messaging.Notification,
  data?: { [key: string]: string }
): Promise<string> {
  try {
    const messaging = getMessaging();

    // Get user's FCM tokens from Firestore
    const userData = await getUserData(uid);
    const fcmTokens = userData?.fcmTokens || [];

    if (fcmTokens.length === 0) {
      throw new Error('No FCM tokens found for user');
    }

    const message: admin.messaging.Message = {
      notification,
      data,
      tokens: fcmTokens
    };

    const result = await messaging.sendMulticast(message);
    logger.info(`📱 Notification sent to ${result.successCount} devices for user ${uid}`);

    if (result.failureCount > 0) {
      logger.warn(`⚠️  Failed to send to ${result.failureCount} devices:`, result.responses);
    }

    return result.successCount.toString();
  } catch (error) {
    logger.error('❌ Send notification failed:', error);
    throw error;
  }
}

export async function subscribeToTopic(
  tokens: string[],
  topic: string
): Promise<void> {
  try {
    const messaging = getMessaging();
    await messaging.subscribeToTopic(tokens, topic);
    logger.info(`📱 Subscribed ${tokens.length} tokens to topic: ${topic}`);
  } catch (error) {
    logger.error('❌ Subscribe to topic failed:', error);
    throw error;
  }
}

export async function unsubscribeFromTopic(
  tokens: string[],
  topic: string
): Promise<void> {
  try {
    const messaging = getMessaging();
    await messaging.unsubscribeFromTopic(tokens, topic);
    logger.info(`📱 Unsubscribed ${tokens.length} tokens from topic: ${topic}`);
  } catch (error) {
    logger.error('❌ Unsubscribe from topic failed:', error);
    throw error;
  }
}