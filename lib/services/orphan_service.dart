import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/orphan.dart';

class OrphanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'orphans';

  /// Get all orphans as a stream
  Stream<List<Orphan>> getOrphansStream() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Orphan.fromFirestore(doc)).toList();
    }).handleError((error) {
      debugPrint('Error fetching orphans stream: $error');
      return [];
    });
  }

  /// Get a single orphan by ID
  Future<Orphan?> getOrphanById(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (doc.exists) {
        return Orphan.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching orphan: $e');
      return null;
    }
  }

  /// Add a new orphan
  Future<String> addOrphan(Orphan orphan) async {
    try {
      final docRef = await _firestore.collection(collectionName).add(
        orphan.toFirestore(),
      );
      debugPrint('Orphan added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding orphan: $e');
      rethrow;
    }
  }

  /// Update an orphan
  Future<void> updateOrphan(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(collectionName).doc(id).update(updates);
      debugPrint('Orphan $id updated');
    } catch (e) {
      debugPrint('Error updating orphan: $e');
      rethrow;
    }
  }

  /// Delete an orphan
  Future<void> deleteOrphan(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
      debugPrint('Orphan $id deleted');
    } catch (e) {
      debugPrint('Error deleting orphan: $e');
      rethrow;
    }
  }

  /// Mark orphan as sponsored
  Future<void> sponsorOrphan(
    String orphanId,
    String sponsorId,
    String sponsorName,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(orphanId).update({
        'status': 'sponsored',
        'sponsorId': sponsorId,
        'sponsorName': sponsorName,
      });
      debugPrint('Orphan $orphanId sponsored by $sponsorName');
    } catch (e) {
      debugPrint('Error sponsoring orphan: $e');
      rethrow;
    }
  }

  /// Seed dummy orphan data for testing
  Future<void> seedDummyOrphans() async {
    try {
      final orphans = [
        Orphan(
          id: 'orphan_1',
          name: 'Muhammad Ahmed',
          age: 8,
          bio:
              'Bright and curious boy who loves reading. Muhammad lost his parents at a young age and is being raised by his elderly grandmother. He dreams of becoming an engineer.',
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=500&fit=crop',
          sponsorshipAmount: 100.0,
          status: 'available',
          createdAt: DateTime.now(),
        ),
        Orphan(
          id: 'orphan_2',
          name: 'Fatima Hassan',
          age: 12,
          bio:
              'Compassionate and kind-hearted girl with exceptional academic performance. Fatima helps her younger siblings and contributes to household chores. She aspires to become a teacher.',
          imageUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=500&fit=crop',
          sponsorshipAmount: 120.0,
          status: 'available',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Orphan(
          id: 'orphan_3',
          name: 'Karim Ibrahim',
          age: 10,
          bio:
              'Active and enthusiastic boy who participates in community programs. Karim is resilient despite his challenges and brings joy to those around him. He is passionate about sports and outdoor activities.',
          imageUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=500&fit=crop',
          sponsorshipAmount: 110.0,
          status: 'available',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      // Check if orphans already exist
      final existingOrphans = await _firestore
          .collection(collectionName)
          .limit(1)
          .get();

      if (existingOrphans.docs.isNotEmpty) {
        debugPrint('Orphans collection already has data. Skipping seed.');
        return;
      }

      // Add all orphans
      for (final orphan in orphans) {
        await _firestore
            .collection(collectionName)
            .doc(orphan.id)
            .set(orphan.toFirestore());
      }

      debugPrint(
        'Successfully seeded ${orphans.length} dummy orphan profiles',
      );
    } catch (e) {
      debugPrint('Error seeding dummy orphans: $e');
      rethrow;
    }
  }

  /// Get orphans count
  Future<int> getOrphansCount() async {
    try {
      final snapshot =
          await _firestore.collection(collectionName).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting orphans count: $e');
      return 0;
    }
  }

  /// Get available orphans (not sponsored)
  Stream<List<Orphan>> getAvailableOrphansStream() {
    return _firestore
        .collection(collectionName)
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Orphan.fromFirestore(doc)).toList();
    }).handleError((error) {
      debugPrint('Error fetching available orphans: $error');
      return [];
    });
  }
}


