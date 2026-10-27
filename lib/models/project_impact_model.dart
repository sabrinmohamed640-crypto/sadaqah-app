import 'package:flutter/material.dart';

enum ProjectStageStatus { completed, ongoing, pending }

class ProjectStage {
  final String titleEn;
  final String titleAr;
  final String dateEn;
  final String dateAr;
  final String descriptionEn;
  final String descriptionAr;
  final ProjectStageStatus status;
  final IconData icon;
  final List<String>? proofs;

  const ProjectStage({
    required this.titleEn,
    required this.titleAr,
    required this.dateEn,
    required this.dateAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.status,
    required this.icon,
    this.proofs,
  });
}

class ProjectImpactModel {
  final String projectId;
  final String projectNameEn;
  final String projectNameAr;
  final List<ProjectStage> stages;

  const ProjectImpactModel({
    required this.projectId,
    required this.projectNameEn,
    required this.projectNameAr,
    required this.stages,
  });
}
