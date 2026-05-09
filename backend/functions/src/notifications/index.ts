import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Send notification when transfer is requested
export const onTransferRequest = functions.firestore
  .document('transfers/{transferId}')
  .onCreate(async (snap, context) => {
    const transfer = snap.data();
    
    const notification = {
      userId: transfer.requestedTo,
      title: 'Nouvelle demande de transfert',
      body: `Le dossier ${transfer.dossierNumber} (${transfer.newbornName}) demande un transfert vers votre service`,
      type: 'transfer_request',
      data: {
        transferId: snap.id,
        dossierId: transfer.dossierId,
        dossierNumber: transfer.dossierNumber,
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await db.collection('notifications').add(notification);
    
    return { success: true };
  });

// Send notification when transfer is approved
export const onTransferApproved = functions.firestore
  .document('transfers/{transferId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.status !== 'approved' && after.status === 'approved') {
      const notification = {
        userId: after.requestedBy,
        title: 'Transfert approuvé',
        body: `Le transfert du dossier ${after.dossierNumber} a été approuvé. Vous pouvez accéder au dossier.`,
        type: 'transfer_approved',
        data: {
          transferId: context.params.transferId,
          dossierId: after.dossierId,
          dossierNumber: after.dossierNumber,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      await db.collection('notifications').add(notification);
    }
    
    if (before.status !== 'rejected' && after.status === 'rejected') {
      const notification = {
        userId: after.requestedBy,
        title: 'Transfert refusé',
        body: `Le transfert du dossier ${after.dossierNumber} a été refusé. Raison: ${after.rejectionReason || 'Non spécifiée'}`,
        type: 'transfer_rejected',
        data: {
          transferId: context.params.transferId,
          dossierId: after.dossierId,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      await db.collection('notifications').add(notification);
    }
    
    return { success: true };
  });

// Clean up old notifications (older than 30 days) - runs daily
export const cleanupOldNotifications = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Europe/Paris')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30);
    
    const oldNotifications = await db
      .collection('notifications')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
      .get();
    
    const batch = db.batch();
    oldNotifications.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`Cleaned up ${oldNotifications.docs.length} old notifications`);
    
    return { deletedCount: oldNotifications.docs.length };
  });