import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/waqf_project.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Waqf Projects Firestore Service - Handles all database operations
/// ─────────────────────────────────────────────────────────────────────────────
class WaqfProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ─── FETCH OPERATIONS ───────────────────────────────────────────────────────

  /// Get all projects from the 'projects' collection as a real-time stream.
  /// Converts each document to a WaqfProject model.
  Stream<List<WaqfProject>> getAllProjectsStream() {
    return _db.collection('projects').snapshots().map((snapshot) {
      final projects = <WaqfProject>[];
      
      for (final doc in snapshot.docs) {
        try {
          final project = WaqfProject.fromFirestore(doc);
          projects.add(project);
        } catch (e) {
          debugPrint('❌ Error parsing projects doc ${doc.id}: $e');
        }
      }
      
      debugPrint('✅ Fetched ${projects.length} documents from projects collection');
      return projects;
    }).handleError((error) {
      debugPrint('🔴 Stream error: $error');
      throw error;
    });
  }

  /// Get a single project by ID directly from the unified 'projects' collection
  Future<WaqfProject?> getProjectById(String projectId) async {
    try {
      final doc = await _db.collection('projects').doc(projectId).get();
      if (doc.exists) {
        return WaqfProject.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching project by ID: $e');
      return null;
    }
  }

  /// Get project by service name directly from the unified 'projects' collection
  Future<WaqfProject?> getProjectByServiceName(String serviceName) async {
    try {
      // Try camelCase field titleEn
      var query = await _db
          .collection('projects')
          .where('titleEn', isEqualTo: serviceName)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return WaqfProject.fromFirestore(query.docs.first);
      }

      // Fallback check for snake_case title_en (as seeded in DatabaseService)
      query = await _db
          .collection('projects')
          .where('title_en', isEqualTo: serviceName)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return WaqfProject.fromFirestore(query.docs.first);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching project by name: $e');
      return null;
    }
  }

  // ─── Direct updates disabled/delegated to transaction layer ──────────────────
  
  Future<String> createProject(WaqfProject project) async {
    throw UnsupportedError('Direct project creation disabled. Use Firebase Console.');
  }

  Future<String> createStage(String projectId, Stage stage) async {
    throw UnsupportedError('Direct stage creation disabled. Use Firebase Console.');
  }

  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    throw UnsupportedError('Direct project updates disabled. Use Firebase Console.');
  }

  Future<void> updateProjectRaised(String projectId, double newAmount) async {
    throw UnsupportedError('Direct raised updates disabled. Use Firebase Console.');
  }

  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    throw UnsupportedError('Direct status updates disabled. Use Firebase Console.');
  }

  Future<void> updateStage(String projectId, String stageId, Map<String, dynamic> data) async {
    throw UnsupportedError('Direct stage updates disabled. Use Firebase Console.');
  }

  Future<void> updateStageStatus(String projectId, String stageId, String newStatus) async {
    throw UnsupportedError('Direct stage updates disabled. Use Firebase Console.');
  }

  Future<void> deleteProject(String projectId) async {
    throw UnsupportedError('Direct project deletion disabled. Use Firebase Console.');
  }

  Future<void> deleteStage(String projectId, String stageId) async {
    throw UnsupportedError('Direct stage deletion disabled. Use Firebase Console.');
  }

  /// Get project statistics
  Future<Map<String, dynamic>> getProjectStatistics(String projectId) async {
    try {
      final project = await getProjectById(projectId);
      if (project == null) return {};

      return {
        'totalRaised': project.raised,
        'totalTarget': project.target,
        'progressPercentage': project.progressPercentage,
        'amountRemaining': project.amountRemaining,
        'isCompleted': project.isCompleted,
        'totalStages': project.stages.length,
        'completedStages': project.stages
            .where((s) => s.status == 'completed')
            .length,
        'ongoingStages': project.stages
            .where((s) => s.status == 'ongoing')
            .length,
      };
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return {};
    }
  }
}