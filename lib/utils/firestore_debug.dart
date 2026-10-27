import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Firestore Debug Utility - System Connection Audit
/// ─────────────────────────────────────────────────────────────────────────────
class FirestoreDebug {
  /// Display comprehensive connection diagnostic widget
  static Widget buildDiagnosticWidget({
    required String screenName,
    required AsyncSnapshot<dynamic> snapshot,
    bool isAdmin = false,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.bug_report_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                'DEBUG: $screenName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.orange, height: 12),

          // Authentication Status
          _buildDiagnosticRow(
            label: 'Auth Status',
            value: currentUser != null ? '✅ Signed In (${currentUser.uid})' : '❌ Not Signed In',
            color: currentUser != null ? Colors.green : Colors.red,
          ),

          // Admin Status
          _buildDiagnosticRow(
            label: 'Admin Role',
            value: isAdmin ? '✅ Admin' : '⚠️ Not Admin',
            color: isAdmin ? Colors.green : Colors.yellow,
          ),

          // Connection State
          _buildDiagnosticRow(
            label: 'Connection',
            value: _getConnectionStateText(snapshot.connectionState),
            color: _getConnectionStateColor(snapshot.connectionState),
          ),

          // Error Check
          if (snapshot.hasError)
            _buildDiagnosticRow(
              label: 'Error Type',
              value: _getErrorTypeString(snapshot.error),
              color: Colors.red,
            ),

          // Data Status
          if (snapshot.hasData && snapshot.data != null)
            _buildDiagnosticRow(
              label: 'Data Received',
              value: '✅ Snapshot received',
              color: Colors.green,
            )
          else if (snapshot.connectionState == ConnectionState.done)
            _buildDiagnosticRow(
              label: 'Data Status',
              value: '⚠️ Empty snapshot',
              color: Colors.yellow,
            ),

          // Collection Info
          const SizedBox(height: 8),
          Text(
            'Collection: projects | Sub: stages | Auth: Firebase',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Build diagnostic row
  static Widget _buildDiagnosticRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Get connection state text
  static String _getConnectionStateText(ConnectionState? state) {
    switch (state) {
      case ConnectionState.none:
        return '⏳ Not connected';
      case ConnectionState.waiting:
        return '⏳ Waiting for data...';
      case ConnectionState.active:
        return '✅ Active stream';
      case ConnectionState.done:
        return '✓ Stream closed';
      default:
        return '❓ Unknown';
    }
  }

  /// Get connection state color
  static Color _getConnectionStateColor(ConnectionState? state) {
    switch (state) {
      case ConnectionState.waiting:
        return Colors.blue;
      case ConnectionState.active:
        return Colors.green;
      case ConnectionState.done:
        return Colors.grey;
      default:
        return Colors.yellow;
    }
  }

  /// Get error type string
  static String _getErrorTypeString(Object? error) {
    if (error == null) return 'Unknown error';
    final errorStr = error.toString();

    if (errorStr.contains('permission-denied') || errorStr.contains('Permission Denied')) {
      return '🔒 Permission Denied';
    } else if (errorStr.contains('not-found') || errorStr.contains('No document')) {
      return '📭 Collection not found';
    } else if (errorStr.contains('unauthenticated')) {
      return '🔑 Not authenticated';
    } else if (errorStr.contains('FAILED_PRECONDITION')) {
      return '⚠️ Firestore not configured';
    } else {
      return '❌ ${errorStr.split('\n').first.substring(0, 50)}...';
    }
  }

  /// Print detailed connection log
  static void printConnectionLog(
    String screenName,
    AsyncSnapshot<dynamic> snapshot,
    bool isAdmin,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 FIRESTORE CONNECTION AUDIT - $screenName');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📱 Auth User: ${currentUser?.email ?? 'NOT SIGNED IN'}');
    debugPrint('🔐 Admin: $isAdmin');
    debugPrint('📊 Connection State: ${snapshot.connectionState}');
    debugPrint('📦 Has Data: ${snapshot.hasData}');
    debugPrint('❌ Has Error: ${snapshot.hasError}');
    if (snapshot.hasError) {
      debugPrint('💥 Error: ${snapshot.error}');
    }
    if (snapshot.hasData) {
      debugPrint('✅ Data Count: ${_getDataCount(snapshot.data)}');
    }
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// Get data count for debugging
  static String _getDataCount(dynamic data) {
    if (data is List) {
      return data.length.toString();
    }
    return data != null ? '1' : '0';
  }

  /// Verify Firestore connection status
  static Future<Map<String, dynamic>> getConnectionStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final isSignedIn = currentUser != null;

      // Try to read a test collection
      final testDoc = await FirebaseFirestore.instance
          .collection('projects')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw 'Firestore read timeout',
          );

      return {
        'isSignedIn': isSignedIn,
        'userEmail': currentUser?.email ?? 'none',
        'canReadProjects': true,
        'projectsCount': testDoc.docs.length,
        'status': 'Connected',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isSignedIn': FirebaseAuth.instance.currentUser != null,
        'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'none',
        'canReadProjects': false,
        'projectsCount': 0,
        'status': 'Error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
