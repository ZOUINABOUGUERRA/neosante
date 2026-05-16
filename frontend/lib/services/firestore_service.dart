import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/failure.dart';
import '../shared/models/user_model.dart';

/// ===============================
/// GENERIC FIRESTORE SERVICE
/// ===============================
class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// ===============================
  /// GET SINGLE DOCUMENT
  /// ===============================
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collectionPath,
    String docId,
  ) async {
    try {
      return await _firestore
          .collection(collectionPath)
          .doc(docId)
          .get();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// GET COLLECTION
  /// ===============================
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    String collectionPath, {
    String? orderBy,
    bool descending = true,
    int? limit,
    List<Object?>? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(collectionPath);

      if (orderBy != null) {
        query = query.orderBy(
          orderBy,
          descending: descending,
        );
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (startAfter != null &&
          startAfter.isNotEmpty) {
        query = query.startAfter(startAfter);
      }

      return await query.get();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// WHERE QUERY
  /// ===============================
  Future<QuerySnapshot<Map<String, dynamic>>>
      getDocumentsWhere(
    String collectionPath,
    String field,
    dynamic isEqualTo, {
    String? orderBy,
    bool descending = true,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore
              .collection(collectionPath)
              .where(
                field,
                isEqualTo: isEqualTo,
              );

      if (orderBy != null) {
        query = query.orderBy(
          orderBy,
          descending: descending,
        );
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// ADD DOCUMENT
  /// ===============================
  Future<String> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef =
          _firestore.collection(collectionPath).doc();

      await docRef.set(data);

      return docRef.id;
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// SET DOCUMENT
  /// ===============================
  Future<void> setDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .set(data);
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// UPDATE DOCUMENT
  /// ===============================
  Future<void> updateDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .update(data);
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// DELETE DOCUMENT
  /// ===============================
  Future<void> deleteDocument(
    String collectionPath,
    String docId,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .delete();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// STREAM DOCUMENT
  /// ===============================
  Stream<DocumentSnapshot<Map<String, dynamic>>>
      streamDocument(
    String collectionPath,
    String docId,
  ) {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .snapshots();
  }

  /// ===============================
  /// STREAM COLLECTION
  /// ===============================
  Stream<QuerySnapshot<Map<String, dynamic>>>
      streamCollection(
    String collectionPath, {
    String? orderBy,
    bool descending = true,
    String? whereField,
    dynamic whereValue,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(collectionPath);

    if (whereField != null &&
        whereValue != null) {
      query = query.where(
        whereField,
        isEqualTo: whereValue,
      );
    }

    if (orderBy != null) {
      query = query.orderBy(
        orderBy,
        descending: descending,
      );
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// ===============================
  /// BATCH WRITE
  /// ===============================
  Future<void> batchWrite(
    List<void Function(WriteBatch batch)>
        operations,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        operation(batch);
      }

      await batch.commit();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// TRANSACTION
  /// ===============================
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction)
        transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(
        transactionHandler,
      );
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// INCREMENT FIELD
  /// ===============================
  Future<void> incrementField(
    String collectionPath,
    String docId,
    String field,
    int amount,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .update({
        field: FieldValue.increment(amount),
      });
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// ARRAY UNION
  /// ===============================
  Future<void> arrayUnion(
    String collectionPath,
    String docId,
    String field,
    dynamic value,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .update({
        field: FieldValue.arrayUnion([value]),
      });
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// ARRAY REMOVE
  /// ===============================
  Future<void> arrayRemove(
    String collectionPath,
    String docId,
    String field,
    dynamic value,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .update({
        field: FieldValue.arrayRemove([value]),
      });
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// SEARCH USERS
  /// ===============================
  Future<List<UserModel>> searchUsers(
    String query,
  ) async {
    try {
      final lowerQuery =
          query.trim().toLowerCase();

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where(
            'email',
            isGreaterThanOrEqualTo:
                lowerQuery,
          )
          .where(
            'email',
            isLessThanOrEqualTo:
                '$lowerQuery\uf8ff',
          )
          .limit(20)
          .get();

      return snapshot.docs
          .map(
            (doc) => UserModel.fromJson(
              doc.data(),
              docId: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }

  /// ===============================
  /// USERS COUNT
  /// ===============================
  Future<int> getUsersCount() async {
    try {
      final snapshot = await _firestore
          .collection(
            AppConstants.usersCollection,
          )
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw mapFirestoreExceptionToFailure(e);
    }
  }
}