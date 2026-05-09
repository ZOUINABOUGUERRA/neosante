"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createManualBackup = exports.scheduledBackup = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
const bucket = admin.storage().bucket();
// Scheduled backup - runs weekly on Sunday at 1 AM
exports.scheduledBackup = functions.pubsub
    .schedule('0 1 * * 0')
    .timeZone('Europe/Paris')
    .onRun(async (context) => {
    const backupId = `backup_${Date.now()}`;
    const backupData = {};
    // Collections to backup
    const collections = [
        'dossiers_prematures',
        'dossiers_a_terme',
        'users',
        'alerts',
        'transfers',
        'archives',
    ];
    for (const collection of collections) {
        const snapshot = await db.collection(collection).get();
        backupData[collection] = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
        }));
    }
    // Upload to Cloud Storage
    const fileName = `backups/${backupId}.json`;
    const file = bucket.file(fileName);
    const jsonContent = JSON.stringify(backupData, null, 2);
    await file.save(jsonContent, {
        metadata: {
            contentType: 'application/json',
            backupId,
            createdAt: new Date().toISOString(),
        },
    });
    // Save backup metadata
    await db.collection('backups').add({
        id: backupId,
        fileName,
        fileSizeMB: jsonContent.length / (1024 * 1024),
        backupType: 'full',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        collections: collections,
    });
    // Delete backups older than 90 days
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90);
    const oldBackups = await db
        .collection('backups')
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .get();
    for (const doc of oldBackups.docs) {
        const backup = doc.data();
        const oldFile = bucket.file(backup.fileName);
        await oldFile.delete().catch(() => { });
        await doc.ref.delete();
    }
    console.log(`Backup ${backupId} created successfully`);
    console.log(`Deleted ${oldBackups.docs.length} old backups`);
    return { backupId, collectionsBackedUp: collections.length };
});
// On-demand backup (admin only)
exports.createManualBackup = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Check if user is admin
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (userDoc.data()?.role !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
    const backupId = `manual_backup_${Date.now()}`;
    const backupData = {};
    const collections = data.collections || [
        'dossiers_prematures',
        'dossiers_a_terme',
        'users',
        'alerts',
        'transfers',
        'archives',
    ];
    for (const collection of collections) {
        const snapshot = await db.collection(collection).get();
        backupData[collection] = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
        }));
    }
    const fileName = `backups/${backupId}.json`;
    const file = bucket.file(fileName);
    const jsonContent = JSON.stringify(backupData, null, 2);
    await file.save(jsonContent, {
        metadata: {
            contentType: 'application/json',
            backupId,
            createdAt: new Date().toISOString(),
        },
    });
    await db.collection('backups').add({
        id: backupId,
        fileName,
        fileSizeMB: jsonContent.length / (1024 * 1024),
        backupType: 'manual',
        createdBy: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        collections: collections,
    });
    // Get download URL
    const [url] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
    });
    return { backupId, downloadUrl: url, fileSizeMB: jsonContent.length / (1024 * 1024) };
});
//# sourceMappingURL=index.js.map