import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Auto-expire pending transfers after 7 days
export const autoExpirePendingTransfers = functions.pubsub
  .schedule('0 4 * * *')
  .timeZone('Europe/Paris')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7);
    
    const expiredTransfers = await db
      .collection('transfers')
      .where('status', '==', 'pending')
      .where('requestedAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
      .get();
    
    const batch = db.batch();
    for (const doc of expiredTransfers.docs) {
      batch.update(doc.ref, {
        status: 'rejected',
        rejectionReason: 'Expiré - aucune réponse sous 7 jours',
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // Notify requester
      const transfer = doc.data();
      const notification = {
        userId: transfer.requestedBy,
        title: 'Transfert expiré',
        body: `Le transfert du dossier ${transfer.dossierNumber} a expiré (7 jours sans réponse)`,
        type: 'transfer_rejected',
        data: { transferId: doc.id, dossierId: transfer.dossierId },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      batch.set(db.collection('notifications').doc(), notification);
    }
    
    await batch.commit();
    console.log(`Expired ${expiredTransfers.docs.length} pending transfers`);
    
    return { expiredCount: expiredTransfers.docs.length };
  });

// Update dossier status when transfer is completed
export const onTransferCompleted = functions.firestore
  .document('transfers/{transferId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.status !== 'completed' && after.status === 'completed') {
      // Update dossier status
      const dossierRef = db.collection('dossiers_prematures').doc(after.dossierId);
      const dossierDoc = await dossierRef.get();
      
      if (dossierDoc.exists) {
        await dossierRef.update({
          status: 'archived',
          transferCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await db.collection('dossiers_a_terme').doc(after.dossierId).update({
          status: 'archived',
          transferCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
    
    return { success: true };
  });