// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/donation.dart';
import '../models/mustahik.dart';
import '../utils/constants.dart';

/// Centralized Firestore data-access layer.
///
/// Every public method prints the exact Firestore path it touches
/// so you can trace reads/writes in the debug console.
class DatabaseService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  //  COLLECTION PATH CONSTANTS
  // ──────────────────────────────────────────────
  static const String _colTest = 'test_collection';
  static const String _colProjects = 'projects';
  static const String _colDonations = 'donations';
  static const String _colCampaigns = 'campaigns';
  static const String _colMustahik = 'mustahik';
  static const String _colAidRequests = 'aid_requests';
  static const String _colZakatCalcs = 'zakat_calculations';
  static const String _colAuditLogs = 'audit_logs';

  // ──────────────────────────────────────────────
  //  CONNECTION TEST
  // ──────────────────────────────────────────────

  /// Writes a timestamped document to verify Firestore connectivity.
  Future<void> addTestDocument() async {
    const String path = '$_colTest (auto-id)';
    print('Firestore Path Accessed: $_colTest');
    debugPrint('🔗 [DB] addTestDocument → Firestore path: $path');
    try {
      await _firestore.collection(_colTest).add({
        'message': 'Connection successful!',
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [DB] Firestore Connection Test: Success!');
    } catch (e) {
      debugPrint('❌ [DB] Firestore Connection Test Failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  SEEDING – PROJECTS
  // ──────────────────────────────────────────────

  /// Seeds the `projects` collection with default Waqf data if it is empty.
  Future<void> seedProjectsIfEmpty() async {
    const String path = _colProjects;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] seedProjectsIfEmpty → Firestore path: $path');
    try {
      final CollectionReference projectsRef = _firestore.collection(path);
      final QuerySnapshot snapshot = await projectsRef.limit(1).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('📝 [DB] Projects collection is empty. Starting atomic seeding...');

        WriteBatch batch = _firestore.batch();

        final List<Map<String, dynamic>> defaultProjects = [
          {
            'id': 'waqf_edu',
            'title_en': 'Educational Waqf',
            'title_ar': 'الوقف التعليمي',
            'desc_en': 'Supporting Islamic schools, sponsoring students.',
            'desc_ar': 'دعم المدارس الإسلامية وكفالة طلاب العلم.',
            'raised': 85000.0,
            'target': 100000.0,
          },
          {
            'id': 'waqf_water',
            'title_en': 'Water Well Waqf',
            'title_ar': 'وقف آبار المياه',
            'desc_en': 'Digging artesian wells and providing clean water.',
            'desc_ar': 'حفر الآبار وتوفير مياه الشرب النظيفة.',
            'raised': 42000.0,
            'target': 60000.0,
          },
          {
            'id': 'waqf_quran',
            'title_en': 'Quran Printing Waqf',
            'title_ar': 'وقف طباعة المصحف',
            'desc_en': 'Printing and distributing the Holy Quran.',
            'desc_ar': 'طباعة وتوزيع المصحف الشريف.',
            'raised': 120000.0,
            'target': 150000.0,
          },
        ];

        for (final project in defaultProjects) {
          final docPath = '$path/${project['id']}';
          debugPrint('   📄 [DB] Seeding project → $docPath');
          DocumentReference docRef = projectsRef.doc(project['id'] as String);
          batch.set(docRef, project);
        }

        await batch.commit();
        debugPrint('✅ [DB] Firestore Seeding: All projects seeded successfully.');
      } else {
        debugPrint('✅ [DB] Firestore Seeding: Projects already exist, skipping.');
      }
    } catch (e) {
      debugPrint('❌ [DB] Firestore Seeding Failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  SEEDING – MUSTAHIK (Zakat Recipients)
  // ──────────────────────────────────────────────

  /// Seeds the `mustahik` collection with sample recipient data if empty.
  Future<void> seedMustahikIfEmpty() async {
    const String path = _colMustahik;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] seedMustahikIfEmpty → Firestore path: $path');
    try {
      final ref = _firestore.collection(path);
      final snapshot = await ref.limit(1).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('📝 [DB] Mustahik collection is empty. Seeding sample recipients...');

        WriteBatch batch = _firestore.batch();

        final List<Map<String, dynamic>> sampleMustahik = [
          {
            'id': 'mst_001',
            'name': 'Fatima Al-Zahra',
            'email': 'fatima.z@example.com',
            'phoneNumber': '+966501234567',
            'status': 'Verified',
            'category': 'Fakir',
            'description': 'Widow with 4 children, no income source.',
            'monthlyIncome': 200.0,
            'registeredAt': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
          },
          {
            'id': 'mst_002',
            'name': 'Omar Hassan',
            'email': 'omar.h@example.com',
            'phoneNumber': '+966509876543',
            'status': 'Verified',
            'category': 'Gharimin',
            'description': 'In debt due to medical expenses for chronic illness.',
            'monthlyIncome': 450.0,
            'registeredAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          },
          {
            'id': 'mst_003',
            'name': 'Aisha Khalid',
            'email': 'aisha.k@example.com',
            'phoneNumber': '+966507654321',
            'status': 'Pending',
            'category': 'Miskin',
            'description': 'Elderly woman living alone, income below subsistence.',
            'monthlyIncome': 300.0,
            'registeredAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          },
          {
            'id': 'mst_004',
            'name': 'Yusuf Ibrahim',
            'email': 'yusuf.i@example.com',
            'phoneNumber': '+966502345678',
            'status': 'Verified',
            'category': 'Ibnu Sabil',
            'description': 'Stranded traveler, student unable to return home.',
            'monthlyIncome': 0.0,
            'registeredAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          },
          {
            'id': 'mst_005',
            'name': 'Maryam Noor',
            'email': 'maryam.n@example.com',
            'phoneNumber': '+966508765432',
            'status': 'Verified',
            'category': 'Fisabilillah',
            'description': 'Student of Islamic knowledge seeking scholarship support.',
            'monthlyIncome': 150.0,
            'registeredAt': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
          },
        ];

        for (final m in sampleMustahik) {
          final docPath = '$path/${m['id']}';
          debugPrint('   📄 [DB] Seeding mustahik → $docPath');
          batch.set(ref.doc(m['id'] as String), m);
        }

        await batch.commit();
        debugPrint('✅ [DB] Mustahik seeding complete.');
      } else {
        debugPrint('✅ [DB] Mustahik already seeded, skipping.');
      }
    } catch (e) {
      debugPrint('❌ [DB] Mustahik seeding failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  SEEDING – MUZAKKI
  // ──────────────────────────────────────────────

  /// Seeds the `muzakki` collection with default donor data if empty.
  Future<void> seedMuzakkiIfEmpty() async {
    const String path = 'muzakki';
    print('Firestore Path Accessed: $path');
    try {
      final ref = _firestore.collection(path);
      final snapshot = await ref.doc('muz_101').get();

      if (!snapshot.exists) {
        debugPrint('📝 [DB] Muzakki document is empty. Seeding default donor...');
        await ref.doc('muz_101').set({
          'id': 'muz_101',
          'name': 'Ahmad Abdullah',
          'email': 'ahmad.abdullah@example.com',
          'phoneNumber': '+966500000000',
          'profileImageUrl': null,
          'registeredAt': DateTime.now().toIso8601String(),
          'totalZakatPaid': 0.0,
          'totalSadaqahPaid': 0.0,
        });
        debugPrint('✅ [DB] Muzakki seeding complete.');
      } else {
        debugPrint('✅ [DB] Muzakki already seeded, skipping.');
      }
    } catch (e) {
      debugPrint('❌ [DB] Muzakki seeding failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  INITIALIZATION – MUZAKKI DOCUMENT GUARD
  // ──────────────────────────────────────────────

  /// Ensures the canonical Muzakki document (`muzakki/muz_101`) exists in
  /// Firestore. If it is missing it is created with the three fields required
  /// by the UI (`name`, `email`, `initials`).
  ///
  /// Call this once at startup, right after [Firebase.initializeApp()].
  /// The operation is idempotent — if the document already exists it is left
  /// unchanged.
  Future<void> initializeMuzakkiIfEmpty() async {
    const String path = 'muzakki';
    const String docId = 'muz_101';
    final String fullPath = '$path/$docId';
    print('Firestore Path Accessed: $fullPath');
    debugPrint('🔗 [DB] initializeMuzakkiIfEmpty → Firestore path: $fullPath');
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(path).doc(docId).get();

      if (!doc.exists) {
        debugPrint(
            '📝 [DB] muzakki/$docId not found — creating default document...');
        await _firestore.collection(path).doc(docId).set({
          'name': 'Ahmad Abdullah',
          'email': 'ahmad@example.com',
          'initials': 'AA',
        });
        debugPrint('✅ [DB] muzakki/$docId created successfully.');
      } else {
        debugPrint('✅ [DB] muzakki/$docId already exists — skipping init.');
      }
    } catch (e) {
      debugPrint('❌ [DB] initializeMuzakkiIfEmpty failed: $e');
      // Non-fatal — UI falls back to hard-coded defaults.
    }
  }

  // ──────────────────────────────────────────────
  //  DONATIONS – WRITE
  // ──────────────────────────────────────────────

  /// Writes a donation document to Firestore.
  Future<void> logDonation(Donation donation) async {
    final String docPath = '$_colDonations/${donation.id}';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] logDonation → Firestore path: $docPath');
    try {
      await _firestore.collection(_colDonations).doc(donation.id).set(donation.toMap());
      debugPrint('✅ [DB] Donation logged successfully: $docPath');
    } catch (e) {
      debugPrint('❌ [DB] Donation log failed at $docPath: $e');
      rethrow;
    }
  }

  /// Processes a quick donation with atomic updates to user totals
  /// - Logs the donation to the donations collection
  /// - Updates the user's totalZakatPaid or totalSadaqahPaid using FieldValue.increment()
  Future<void> processQuickDonation(Donation donation) async {
    final String donationPath = '$_colDonations/${donation.id}';
    final String userPath = 'users/${donation.donorId}';
    print('Firestore Paths Accessed: $donationPath, $userPath');
    debugPrint('🔗 [DB] processQuickDonation → Donation: $donationPath, User: $userPath, Amount: \$${donation.amount}, Type: ${donation.type}');
    
    try {
      // Determine which field to increment
      final fieldToIncrement = donation.type == 'Zakat' ? 'totalZakatPaid' : 'totalSadaqahPaid';

      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // Add donation to donations collection
      batch.set(
        _firestore.collection(_colDonations).doc(donation.id),
        donation.toMap(),
      );

      // Update user totals atomically
      batch.update(
        _firestore.collection('users').doc(donation.donorId),
        {
          fieldToIncrement: FieldValue.increment(donation.amount),
        },
      );

      // Commit the batch
      await batch.commit();

      debugPrint('✅ [DB] Quick donation processed successfully:');
      debugPrint('   📝 Donation logged: $donationPath');
      debugPrint('   💰 User $fieldToIncrement incremented by \$${donation.amount}');
    } catch (e) {
      debugPrint('❌ [DB] Quick donation processing failed: $e');
      rethrow;
    }
  }

  /// Retrieves the user's name from the users collection
  Future<String> getUserName(String userId) async {
    const String path = 'users';
    final String docPath = '$path/$userId';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] getUserName → Firestore path: $docPath');
    try {
      final doc = await _firestore.collection(path).doc(userId).get();
      final name = doc.data()?['name'] as String? ?? 'Anonymous';
      debugPrint('✅ [DB] User name retrieved: $name');
      return name;
    } catch (e) {
      debugPrint('❌ [DB] getUserName failed at $docPath: $e');
      return 'Anonymous';
    }
  }

  // ──────────────────────────────────────────────
  //  DONATIONS – REAL-TIME STREAMS
  // ──────────────────────────────────────────────

  /// Returns a real-time stream of the most recent donations, ordered by
  /// timestamp descending. When [donorId] is set, only that donor's records
  /// are returned (required by Firestore security rules for non-admin users).
  Stream<List<Donation>> getRecentDonationsStream({
    int limit = 10,
    String? donorId,
  }) {
    const String path = _colDonations;
    print('Firestore Path Accessed: $path');
    debugPrint(
      '🔗 [DB] getRecentDonationsStream → path: $path '
      '(limit: $limit, donorId: $donorId)',
    );

    // Composite index required when [donorId] is set:
    //   donations — donorId ASC, timestamp DESC
    // (see firestore.indexes.json)
    final Query<Map<String, dynamic>> query;
    if (donorId != null) {
      query = _firestore
          .collection(path)
          .where('donorId', isEqualTo: donorId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
    } else {
      query = _firestore
          .collection(path)
          .orderBy('timestamp', descending: true)
          .limit(limit);
    }

    return query.snapshots()
        .map((snapshot) {
      debugPrint(
        '   📥 [DB] Received ${snapshot.docs.length} donation docs from $path',
      );
      return snapshot.docs.map((doc) {
        return Donation.fromMap(doc.data());
      }).toList();
    });
  }

  /// Returns a real-time stream of the raw QuerySnapshot for donations.
  Stream<QuerySnapshot> getDonationsStream({int limit = 10}) {
    const String path = _colDonations;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] getDonationsStream → Firestore path: $path (limit: $limit)');
    return _firestore
        .collection(path)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // ──────────────────────────────────────────────
  //  DONATIONS – AGGREGATION STREAMS
  // ──────────────────────────────────────────────

  /// Real-time stream that computes the total amount for a specific
  /// donation type (e.g. "Zakat" or "Sadaqah").
  ///
  /// Pass [donorId] to scope totals to one muzakki (enforced by security rules).
  Stream<double> _getTotalByTypeStream(String type, {String? donorId}) {
    final String path = '$_colDonations?type=$type&status=Completed'
        '${donorId != null ? '&donorId=$donorId' : ''}';
    print('Firestore Path Accessed: $_colDonations');
    debugPrint('🔗 [DB] _getTotalByTypeStream → Firestore query: $path');
    // Composite indexes (see firestore.indexes.json):
    //   with donorId    → donorId ASC, type ASC, status ASC
    //   without donorId → type ASC, status ASC
    final Query<Map<String, dynamic>> query;
    if (donorId != null) {
      query = _firestore
          .collection(_colDonations)
          .where('donorId', isEqualTo: donorId)
          .where('type', isEqualTo: type)
          .where('status', isEqualTo: 'Completed');
    } else {
      query = _firestore
          .collection(_colDonations)
          .where('type', isEqualTo: type)
          .where('status', isEqualTo: 'Completed');
    }
    return query.snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (final doc in snapshot.docs) {
        total += AppConstants.parseDouble(doc.data()['amount']);
      }
      debugPrint(
        '   📊 [DB] Total $type (Completed): \$${total.toStringAsFixed(2)}',
      );
      return total;
    });
  }

  /// Real-time total of completed Zakat donations (optionally per [donorId]).
  Stream<double> getZakatTotalStream({String? donorId}) {
    print('Firestore Path Accessed: $_colDonations (type=Zakat)');
    debugPrint('🔗 [DB] getZakatTotalStream → type=Zakat, donorId: $donorId');
    return _getTotalByTypeStream('Zakat', donorId: donorId);
  }

  /// Real-time total of completed Sadaqah donations (optionally per [donorId]).
  Stream<double> getSadaqahTotalStream({String? donorId}) {
    print('Firestore Path Accessed: $_colDonations (type=Sadaqah)');
    debugPrint('🔗 [DB] getSadaqahTotalStream → type=Sadaqah, donorId: $donorId');
    return _getTotalByTypeStream('Sadaqah', donorId: donorId);
  }

  // ──────────────────────────────────────────────
  //  MUSTAHIK (RECIPIENTS) – STREAM & WRITE
  // ──────────────────────────────────────────────

  /// Real-time stream of all mustahik (Zakat recipients).
  Stream<QuerySnapshot> getMustahikStream() {
    const String path = _colMustahik;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] getMustahikStream → Firestore path: $path');
    return _firestore.collection(path).snapshots();
  }

  /// Real-time stream of mustahik as parsed model objects.
  Stream<List<Mustahik>> getMustahikListStream() {
    const String path = _colMustahik;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] getMustahikListStream → Firestore path: $path');
    return _firestore.collection(path).snapshots().map((snapshot) {
      debugPrint('   📥 [DB] Received ${snapshot.docs.length} mustahik docs from $path');
      return snapshot.docs.map((doc) {
        return Mustahik.fromMap(doc.data());
      }).toList();
    });
  }

  /// Adds a new mustahik record.
  Future<void> addMustahik(Mustahik mustahik) async {
    final String docPath = '$_colMustahik/${mustahik.id}';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] addMustahik → Firestore path: $docPath');
    try {
      await _firestore.collection(_colMustahik).doc(mustahik.id).set(mustahik.toMap());
      debugPrint('✅ [DB] Mustahik added: $docPath');
    } catch (e) {
      debugPrint('❌ [DB] addMustahik failed at $docPath: $e');
      rethrow;
    }
  }

  /// Updates the status of a mustahik record (Pending → Verified → Rejected)
  Future<void> updateMustahikStatus(String mustahikId, String newStatus) async {
    final String docPath = '$_colMustahik/$mustahikId';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] updateMustahikStatus → Firestore path: $docPath, newStatus: $newStatus');
    try {
      await _firestore.collection(_colMustahik).doc(mustahikId).update({
        'status': newStatus,
      });
      debugPrint('✅ [DB] Mustahik status updated: $docPath → $newStatus');
    } catch (e) {
      debugPrint('❌ [DB] updateMustahikStatus failed at $docPath: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────
  //  AID REQUESTS
  // ──────────────────────────────────────────────

  /// Submits an aid request to the `aid_requests` collection.
  Future<void> addAidRequest(Map<String, dynamic> request) async {
    final String id = request['id'] ?? 'aid_${DateTime.now().millisecondsSinceEpoch}';
    final String docPath = '$_colAidRequests/$id';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] addAidRequest → Firestore path: $docPath');
    try {
      await _firestore.collection(_colAidRequests).doc(id).set({
        ...request,
        'id': id,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });
      debugPrint('✅ [DB] Aid request submitted: $docPath');
    } catch (e) {
      debugPrint('❌ [DB] addAidRequest failed at $docPath: $e');
      rethrow;
    }
  }

  /// Submits an aid request with user context
  /// - Creates a new aid request in the `aid_requests` collection
  /// - Sets status to 'Pending' by default
  /// - Includes user ID to link the request to the applicant
  Future<void> submitAidRequest({
    required String userId,
    required String name,
    required String phone,
    required double amountNeeded,
    required String reason,
  }) async {
    final String id = 'aid_${DateTime.now().millisecondsSinceEpoch}';
    final String docPath = '$_colAidRequests/$id';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] submitAidRequest → Firestore path: $docPath, UserId: $userId, Amount: \$${amountNeeded.toStringAsFixed(2)}');

    try {
      await _firestore.collection(_colAidRequests).doc(id).set({
        'id': id,
        'userId': userId,
        'name': name,
        'phone': phone,
        'amountNeeded': amountNeeded,
        'reason': reason,
        'status': 'Pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [DB] Aid request submitted successfully:');
      debugPrint('   📋 Request ID: $id');
      debugPrint('   👤 Applicant: $name');
      debugPrint('   💰 Amount Needed: \$${amountNeeded.toStringAsFixed(2)}');
      debugPrint('   📞 Phone: $phone');
    } catch (e) {
      debugPrint('❌ [DB] submitAidRequest failed at $docPath: $e');
      rethrow;
    }
  }

  /// Real-time stream of all aid requests from the `aid_requests` collection.
  /// Optionally filter by status (e.g., 'Pending', 'Approved', etc.)
  Stream<List<Map<String, dynamic>>> getAidRequestsStream({String? filterStatus}) {
    const String path = _colAidRequests;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] getAidRequestsStream → Firestore path: $path, filterStatus: $filterStatus');
    
    Query<Map<String, dynamic>> query = _firestore.collection(path);
    
    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus);
    }
    
    return query.orderBy('submittedAt', descending: true).snapshots().map((snapshot) {
      debugPrint('   📥 [DB] Received ${snapshot.docs.length} aid request docs from $path');
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Converts an aid request to a mustahik record and updates the aid request status
  /// - Creates a new mustahik document with details from the aid request
  /// - Includes aidType classification (emergency or sustainable)
  /// - Sets supportStatus to 'approved' to mark as verified beneficiary
  /// - Updates the aid_request status to 'Approved'
  /// - Uses atomic batch operations for consistency
  Future<void> convertAidRequestToMustahik({
    required String aidRequestId,
    required String name,
    required String phone,
    required double amountNeeded,
    required String reason,
    required String category,
    required String aidType, // 'emergency' or 'sustainable'
  }) async {
    final String mustahikId = 'mst_${DateTime.now().millisecondsSinceEpoch}';
    final String aidRequestPath = '$_colAidRequests/$aidRequestId';
    final String mustahikPath = '$_colMustahik/$mustahikId';
    
    print('Firestore Paths Accessed: $aidRequestPath, $mustahikPath');
    debugPrint('🔗 [DB] convertAidRequestToMustahik → AidRequest: $aidRequestPath, Mustahik: $mustahikPath, AidType: $aidType');
    
    try {
      final batch = _firestore.batch();
      
      // Create new mustahik document from aid request with dual classification
      batch.set(
        _firestore.collection(_colMustahik).doc(mustahikId),
        {
          'id': mustahikId,
          'name': name,
          'phoneNumber': phone,
          'monthlyIncome': amountNeeded,
          'description': reason,
          'category': category,
          'status': 'Verified', // Admin approval status
          'aidType': aidType, // 'emergency' or 'sustainable'
          'supportStatus': 'approved', // Lifecycle status
          'registeredAt': FieldValue.serverTimestamp(),
          'convertedFromAidRequest': aidRequestId,
        },
      );
      
      // Update aid request status to 'Approved'
      batch.update(
        _firestore.collection(_colAidRequests).doc(aidRequestId),
        {
          'status': 'Approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'convertedToMustahikId': mustahikId,
          'convertedWithAidType': aidType,
        },
      );
      
      await batch.commit();
      
      debugPrint('✅ [DB] Aid request converted to Mustahik successfully:');
      debugPrint('   👤 Mustahik: $name ($aidType) → $mustahikPath');
      debugPrint('   💼 AidType: $aidType, SupportStatus: approved');
      debugPrint('   ✓ AidRequest marked as Approved: $aidRequestPath');
    } catch (e) {
      debugPrint('❌ [DB] convertAidRequestToMustahik failed: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────
  //  ZAKAT CALCULATIONS – LOG
  // ──────────────────────────────────────────────

  /// Saves a Zakat calculation record for audit / history.
  Future<void> logZakatCalculation(Map<String, dynamic> calculation) async {
    final String id = calculation['id'] ?? 'zc_${DateTime.now().millisecondsSinceEpoch}';
    final String docPath = '$_colZakatCalcs/$id';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] logZakatCalculation → Firestore path: $docPath');
    try {
      await _firestore.collection(_colZakatCalcs).doc(id).set({
        ...calculation,
        'id': id,
        'calculatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [DB] Zakat calculation logged: $docPath');
    } catch (e) {
      debugPrint('❌ [DB] logZakatCalculation failed at $docPath: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────
  //  AUDIT LOGS – READ STREAM
  // ──────────────────────────────────────────────

  /// Model class used by the stream below.
  /// Returned as plain maps so screens don't need an extra model file.
  ///
  /// Each document is expected to have:
  ///   type       : String  – 'Success' | 'Warning' | 'Error' | 'Info'
  ///   title      : String
  ///   detail     : String
  ///   actor      : String
  ///   timestamp  : Timestamp (Firestore server timestamp)
  Stream<List<Map<String, dynamic>>> getAuditLogsStream({int limit = 5}) {
    print('Firestore Path Accessed: $_colAuditLogs (last $limit)');
    debugPrint('🔗 [DB] getAuditLogsStream → Firestore path: $_colAuditLogs (limit: $limit)');
    return _firestore
        .collection(_colAuditLogs)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      debugPrint('   📥 [DB] Received ${snapshot.docs.length} audit log docs');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'Info',
          'title': data['title'] ?? 'System Event',
          'detail': data['detail'] ?? '',
          'actor': data['actor'] ?? 'System',
          'timestamp': data['timestamp'], // Firestore Timestamp or null
        };
      }).toList();
    });
  }

  // ──────────────────────────────────────────────
  //  AUDIT LOGS – WRITE HELPER
  // ──────────────────────────────────────────────

  /// Writes a structured event to the `audit_logs` collection.
  ///
  /// Call this whenever an admin performs a meaningful action (approve,
  /// reject, add beneficiary, generate report, sign out, etc.).
  ///
  /// [type]   : 'Success' | 'Warning' | 'Error' | 'Info'
  /// [title]  : Short headline (e.g. 'Beneficiary Approved')
  /// [detail] : Full description sentence.
  /// [actor]  : Who triggered the event (admin email, 'System', IP, etc.)
  Future<void> logAuditEvent({
    required String type,
    required String title,
    required String detail,
    required String actor,
  }) async {
    const String path = _colAuditLogs;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] logAuditEvent → type=$type title=$title actor=$actor');
    try {
      await _firestore.collection(path).add({
        'type': type,
        'title': title,
        'detail': detail,
        'actor': actor,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [DB] Audit event logged: $title');
    } catch (e) {
      debugPrint('❌ [DB] logAuditEvent failed: $e');
      // Non-fatal – admin action still completes even if log write fails.
    }
  }

  // ──────────────────────────────────────────────
  //  AUDIT LOGS – SEEDING (dev / first-run only)
  // ──────────────────────────────────────────────

  /// Seeds the `audit_logs` collection with sample data for development.
  /// Safe to call repeatedly — only seeds when the collection is empty.
  Future<void> seedAuditLogsIfEmpty() async {
    const String path = _colAuditLogs;
    print('Firestore Path Accessed: $path');
    debugPrint('🔗 [DB] seedAuditLogsIfEmpty → Firestore path: $path');
    try {
      final snapshot = await _firestore.collection(path).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ [DB] Audit logs already seeded, skipping.');
        return;
      }

      debugPrint('📝 [DB] Seeding audit_logs with sample data...');
      final WriteBatch batch = _firestore.batch();
      final ref = _firestore.collection(path);

      final List<Map<String, dynamic>> samples = [
        {
          'type': 'Success',
          'title': 'Successful Audit Completed',
          'detail': 'Full compliance audit passed — 0 discrepancies found.',
          'actor': 'System Automator',
          'timestamp': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(minutes: 2))),
        },
        {
          'type': 'Info',
          'title': 'Disbursement Batch #109 Released',
          'detail': 'RM 48,200 distributed across 38 verified beneficiaries.',
          'actor': 'Admin: Sarah J.',
          'timestamp': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(minutes: 45))),
        },
        {
          'type': 'Error',
          'title': 'Failed Login Attempt',
          'detail': 'Unauthorized access attempt detected and blocked.',
          'actor': 'IP: 192.168.1.45',
          'timestamp': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 2))),
        },
        {
          'type': 'Warning',
          'title': 'Fund Reserve Below Threshold',
          'detail': 'Emergency reserve fell below the 15% safety margin.',
          'actor': 'System Monitor',
          'timestamp': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 4))),
        },
        {
          'type': 'Info',
          'title': 'New Beneficiary Registered',
          'detail': 'Application by Mariam Yusuf submitted and queued for review.',
          'actor': 'Admin: Khalid R.',
          'timestamp': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 6))),
        },
      ];

      for (final log in samples) {
        batch.set(ref.doc(), log);
      }
      await batch.commit();
      debugPrint('✅ [DB] Audit logs seeded successfully.');
    } catch (e) {
      debugPrint('❌ [DB] seedAuditLogsIfEmpty failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  CAMPAIGNS – INCREMENT FUNDING
  // ──────────────────────────────────────────────

  /// Increments the `currentAmount` field of a campaign document by the
  /// specified amount using Firestore's atomic increment operation.
  /// This ensures thread-safe updates when multiple donations arrive simultaneously.
  Future<void> incrementCampaignFunding(String campaignId, double amount) async {
    final String docPath = '$_colCampaigns/$campaignId';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] incrementCampaignFunding → path: $docPath, amount: \$$amount');
    try {
      await _firestore.collection(_colCampaigns).doc(campaignId).update({
        'currentAmount': FieldValue.increment(amount),
      });
      debugPrint('✅ [DB] Campaign funding incremented: $docPath by \$$amount');
    } catch (e) {
      debugPrint('❌ [DB] incrementCampaignFunding failed at $docPath: $e');
      rethrow;
    }
  }

  /// Retrieves a single campaign document from Firestore by campaign ID.
  /// Useful for fetching the latest campaign data after a donation.
  Future<Map<String, dynamic>?> getCampaignData(String campaignId) async {
    final String docPath = '$_colCampaigns/$campaignId';
    print('Firestore Path Accessed: $docPath');
    debugPrint('🔗 [DB] getCampaignData → path: $docPath');
    try {
      final doc = await _firestore.collection(_colCampaigns).doc(campaignId).get();
      if (doc.exists) {
        debugPrint('✅ [DB] Campaign data retrieved: $docPath');
        return doc.data();
      }
      debugPrint('⚠️ [DB] Campaign not found: $docPath');
      return null;
    } catch (e) {
      debugPrint('❌ [DB] getCampaignData failed at $docPath: $e');
      rethrow;
    }
  }
}