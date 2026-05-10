import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failure.dart';

/// Generic Firestore service for CRUD operations.
/// Provides type-safe database operations with error handling.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a document by ID
  Future<DocumentSnapshot> getDocument(String collectionPath, String docId) async {
    try {
      return await _firestore.collection(collectionPath).doc(docId).get();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Get a document with type conversion
  Future<T?> getDocumentTyped<T>(
    String collectionPath,
    String docId,
    T Function(Map<String, dynamic> data, String id) fromJson,
  ) async {
    try {
      final doc = await _firestore.collection(collectionPath).doc(docId).get();
      if (!doc.exists) return null;
      return fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Get all documents from a collection
  Future<QuerySnapshot> getCollection(String collectionPath, {
    String? orderBy,
    bool descending = true,
    int? limit,
    List<Object?>? startAfter,
  }) async {
    try {
      Query query = _firestore.collection(collectionPath);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      if (startAfter != null && startAfter.isNotEmpty) {
        query = query.startAfter(startAfter);
      }
      
      return await query.get();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Get documents with where clause
  Future<QuerySnapshot> getDocumentsWhere(
    String collectionPath,
    String field,
    dynamic isEqualTo, {
    String? orderBy,
    bool descending = true,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(collectionPath)
          .where(field, isEqualTo: isEqualTo);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return await query.get();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Create a new document with auto-generated ID
  Future<String> addDocument(String collectionPath, Map<String, dynamic> data) async {
    try {
      final docRef = _firestore.collection(collectionPath).doc();
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Create a new document with specific ID
  Future<void> setDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).set(data);
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Update a document
  Future<void> updateDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String collectionPath, String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Stream a single document
  Stream<DocumentSnapshot> streamDocument(String collectionPath, String docId) {
    return _firestore.collection(collectionPath).doc(docId).snapshots();
  }

  /// Stream a collection with optional filters
  Stream<QuerySnapshot> streamCollection(
    String collectionPath, {
    String? orderBy,
    bool descending = true,
    String? whereField,
    dynamic whereValue,
    int? limit,
  }) {
    Query query = _firestore.collection(collectionPath);
    
    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  /// Batch write multiple operations
  Future<void> batchWrite(List<void Function(WriteBatch batch)> operations) async {
    final batch = _firestore.batch();
    for (final operation in operations) {
      operation(batch);
    }
    await batch.commit();
  }

  /// Run a transaction
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) transaction) async {
    try {
      return await _firestore.runTransaction(transaction);
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Increment a field value
  Future<void> incrementField(String collectionPath, String docId, String field, int amount) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update({
        field: FieldValue.increment(amount),
      });
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Array union (add unique item to array)
  Future<void> arrayUnion(String collectionPath, String docId, String field, dynamic value) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update({
        field: FieldValue.arrayUnion([value]),
      });
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// Array remove (remove item from array)
  Future<void> arrayRemove(String collectionPath, String docId, String field, dynamic value) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update({
        field: FieldValue.arrayRemove([value]),
      });
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }
}