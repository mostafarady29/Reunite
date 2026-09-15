import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getMessaging, Messaging } from 'firebase-admin/messaging';
import { notificationRepository } from '../repositories/notification.repository.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export interface NotificationPayload {
  title: string;
  body: string;
  type?: string;
  caseId?: string;
  data?: Record<string, string>;
}

class FcmService {
  private app: App | null = null;
  private messaging: Messaging | null = null;
  private initialized: boolean = false;

  constructor() {
    this.initFirebase();
  }

  private initFirebase(): void {
    if (getApps().length > 0) {
      this.app = getApps()[0]!;
      this.messaging = getMessaging(this.app);
      this.initialized = true;
      return;
    }

    try {
      // 1. Check environment variable for raw JSON or file path
      const envCred = process.env.FIREBASE_SERVICE_ACCOUNT;
      if (envCred) {
        let certObj: any;
        if (envCred.trim().startsWith('{')) {
          certObj = JSON.parse(envCred);
        } else if (fs.existsSync(envCred)) {
          certObj = JSON.parse(fs.readFileSync(envCred, 'utf8'));
        }
        if (certObj) {
          this.app = initializeApp({
            credential: cert(certObj),
          });
          this.messaging = getMessaging(this.app);
          this.initialized = true;
          console.log('[FCM] Firebase Admin initialized from FIREBASE_SERVICE_ACCOUNT env.');
          return;
        }
      }

      // 2. Check root or config directory for serviceAccountKey.json
      const possiblePaths = [
        path.resolve(__dirname, '../../serviceAccountKey.json'),
        path.resolve(__dirname, '../../../serviceAccountKey.json'),
        path.resolve(process.cwd(), 'serviceAccountKey.json'),
        path.resolve(process.cwd(), 'config/serviceAccountKey.json'),
      ];

      for (const p of possiblePaths) {
        if (fs.existsSync(p)) {
          const serviceAccount = JSON.parse(fs.readFileSync(p, 'utf8'));
          this.app = initializeApp({
            credential: cert(serviceAccount),
          });
          this.messaging = getMessaging(this.app);
          this.initialized = true;
          console.log(`[FCM] Firebase Admin initialized from file: ${p}`);
          return;
        }
      }

      console.warn(
        '[FCM] Firebase service account key not found. FCM push notifications will run in simulation mode. Place serviceAccountKey.json in backend-node root to enable live APNs/FCM delivery.'
      );
    } catch (error) {
      console.error('[FCM] Failed to initialize Firebase Admin:', error);
    }
  }

  public isAvailable(): boolean {
    return this.initialized;
  }

  public async sendToTokens(
    tokens: string[],
    payload: NotificationPayload
  ): Promise<{ successCount: number; failureCount: number }> {
    if (!tokens || tokens.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    const stringData: Record<string, string> = {
      type: payload.type || 'caseUpdate',
      title: payload.title,
      body: payload.body,
      caseId: payload.caseId || '',
      ...(payload.data || {}),
    };

    if (!this.initialized || !this.messaging) {
      console.log(
        `[FCM Simulation] Sending notification to ${tokens.length} token(s): "${payload.title}" - "${payload.body}"`
      );
      return { successCount: tokens.length, failureCount: 0 };
    }

    try {
      const response = await this.messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: stringData,
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
            priority: 'high',
            defaultSound: true,
          },
        },
      });

      // Cleanup stale tokens
      const badTokens: string[] = [];
      response.responses.forEach((resp: any, idx: number) => {
        if (!resp.success && resp.error) {
          const code = resp.error.code;
          if (
            code === 'messaging/invalid-registration-token' ||
            code === 'messaging/registration-token-not-registered'
          ) {
            badTokens.push(tokens[idx]);
          }
        }
      });

      for (const bt of badTokens) {
        await notificationRepository.removeDeviceToken(bt).catch(() => {});
      }

      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (err) {
      console.error('[FCM] Error sending multicast message:', err);
      return { successCount: 0, failureCount: tokens.length };
    }
  }

  public async sendToUser(
    userId: number,
    payload: NotificationPayload
  ): Promise<void> {
    // 1. Always persist to DB
    await notificationRepository.createNotification({
      userId,
      type: payload.type || 'caseUpdate',
      title: payload.title,
      body: payload.body,
      caseId: payload.caseId ? parseInt(payload.caseId, 10) || null : null,
      metadata: payload.data || {},
    });

    // 2. Fetch user's registered device tokens
    const tokens = await notificationRepository.getTokensByUserId(userId);
    if (tokens.length > 0) {
      await this.sendToTokens(tokens, payload);
    }
  }

  public async sendBroadcast(payload: NotificationPayload): Promise<void> {
    // 1. Always persist broadcast notification to DB for all users
    await notificationRepository.createNotification({
      userId: null,
      type: payload.type || 'caseUpdate',
      title: payload.title,
      body: payload.body,
      caseId: payload.caseId ? parseInt(payload.caseId, 10) || null : null,
      metadata: payload.data || {},
    });

    // 2. Multicast to all registered device tokens
    const tokens = await notificationRepository.getAllTokens();
    if (tokens.length > 0) {
      await this.sendToTokens(tokens, payload);
    }
  }
}

export const fcmService = new FcmService();
