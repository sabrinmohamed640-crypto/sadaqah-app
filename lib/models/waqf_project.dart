import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'project_impact_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Firestore-compatible Stage model for Waqf Project implementation stages
/// ─────────────────────────────────────────────────────────────────────────────
class Stage {
  final String id;
  final String titleEn;
  final String titleAr;
  final String dateEn;
  final String dateAr;
  final String descriptionEn;
  final String descriptionAr;
  final String status; // 'completed', 'ongoing', 'pending'
  final String iconName; // Name of the icon, e.g., 'account_balance'
  final List<String> proofs; // Image URLs
  final DateTime? createdAt;

  const Stage({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.dateEn,
    required this.dateAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.status,
    required this.iconName,
    this.proofs = const [],
    this.createdAt,
  });

  /// Convert Firestore document to Stage model
  factory Stage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Stage(
      id: doc.id,
      titleEn: data['titleEn'] ?? '',
      titleAr: data['titleAr'] ?? '',
      dateEn: data['dateEn'] ?? '',
      dateAr: data['dateAr'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      descriptionAr: data['descriptionAr'] ?? '',
      status: data['status'] ?? 'pending',
      iconName: data['iconName'] ?? 'info',
      proofs: List<String>.from(data['proofs'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert Stage to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'titleEn': titleEn,
      'titleAr': titleAr,
      'dateEn': dateEn,
      'dateAr': dateAr,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'status': status,
      'iconName': iconName,
      'proofs': proofs,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Convert to ProjectStage for backward compatibility with UI
  ProjectStage toProjectStage() {
    final statusEnum = status.toLowerCase() == 'completed'
        ? ProjectStageStatus.completed
        : status.toLowerCase() == 'ongoing'
            ? ProjectStageStatus.ongoing
            : ProjectStageStatus.pending;

    return ProjectStage(
      titleEn: titleEn,
      titleAr: titleAr,
      dateEn: dateEn,
      dateAr: dateAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      status: statusEnum,
      icon: _getIconFromName(iconName),
      proofs: proofs.isNotEmpty ? proofs : null,
    );
  }

  /// Get IconData from icon name string
  static IconData _getIconFromName(String name) {
    switch (name.toLowerCase()) {
      case 'account_balance':
      case 'account_balance_rounded':
        return Icons.account_balance_rounded;
      case 'people_alt':
      case 'people_alt_rounded':
        return Icons.people_alt_rounded;
      case 'school':
      case 'school_rounded':
        return Icons.school_rounded;
      case 'monetization_on':
      case 'monetization_on_rounded':
        return Icons.monetization_on_rounded;
      case 'plumbing':
      case 'plumbing_rounded':
        return Icons.plumbing_rounded;
      case 'opacity':
      case 'opacity_rounded':
        return Icons.opacity_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  /// Get icon name from IconData (for storage)
  static String getNameFromIcon(IconData icon) {
    if (icon == Icons.account_balance_rounded) return 'account_balance_rounded';
    if (icon == Icons.people_alt_rounded) return 'people_alt_rounded';
    if (icon == Icons.school_rounded) return 'school_rounded';
    if (icon == Icons.monetization_on_rounded) return 'monetization_on_rounded';
    if (icon == Icons.plumbing_rounded) return 'plumbing_rounded';
    if (icon == Icons.opacity_rounded) return 'opacity_rounded';
    return 'info_rounded';
  }

  @override
  String toString() => 'Stage($id, $titleEn, status: $status)';
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Firestore-compatible Waqf Project model
/// ─────────────────────────────────────────────────────────────────────────────
class WaqfProject {
  final String id;
  final String titleEn;
  final String titleAr;
  final String descEn;
  final String descAr;
  final double target;
  final double raised;
  final String status; // 'Active', 'Completed', 'Paused'
  final List<Stage> stages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WaqfProject({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descEn,
    required this.descAr,
    required this.target,
    required this.raised,
    required this.status,
    this.stages = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Calculate progress as percentage (0.0 to 1.0)
  double get progressPercentage {
    if (target <= 0) return 0.0;
    final percent = raised / target;
    return percent.clamp(0.0, 1.0);
  }

  /// Check if project is completed (raised >= target)
  bool get isCompleted => raised >= target;

  /// Amount remaining to reach target
  double get amountRemaining {
    final remaining = target - raised;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Convert Firestore document to WaqfProject model
  factory WaqfProject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WaqfProject(
      id: doc.id,
      titleEn: data['titleEn'] ?? '',
      titleAr: data['titleAr'] ?? '',
      descEn: data['descEn'] ?? '',
      descAr: data['descAr'] ?? '',
      target: (data['target'] ?? 0.0).toDouble(),
      raised: (data['raised'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Active',
      stages: const [], // Stages are loaded separately via sub-collection
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert WaqfProject to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'titleEn': titleEn,
      'titleAr': titleAr,
      'descEn': descEn,
      'descAr': descAr,
      'target': target,
      'raised': raised,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to ProjectImpactModel for backward compatibility with UI
  ProjectImpactModel toProjectImpactModel() {
    return ProjectImpactModel(
      projectId: id,
      projectNameEn: titleEn,
      projectNameAr: titleAr,
      stages: stages.map((stage) => stage.toProjectStage()).toList(),
    );
  }

  /// Create a copy with updated fields
  WaqfProject copyWith({
    String? id,
    String? titleEn,
    String? titleAr,
    String? descEn,
    String? descAr,
    double? target,
    double? raised,
    String? status,
    List<Stage>? stages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaqfProject(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      descEn: descEn ?? this.descEn,
      descAr: descAr ?? this.descAr,
      target: target ?? this.target,
      raised: raised ?? this.raised,
      status: status ?? this.status,
      stages: stages ?? this.stages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'WaqfProject($id, $titleEn, raised: $raised/$target)';
}
