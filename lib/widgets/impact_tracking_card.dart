import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/localization.dart';
import '../models/project_impact_model.dart';

class ImpactTrackingCard extends StatefulWidget {
  final ProjectImpactModel projectImpact;

  const ImpactTrackingCard({
    super.key,
    required this.projectImpact,
  });

  @override
  State<ImpactTrackingCard> createState() => _ImpactTrackingCardState();
}

class _ImpactTrackingCardState extends State<ImpactTrackingCard> {
  // Track which timeline stage is expanded for details
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    // Default expand the first active/ongoing stage, or fall back to the first pending/completed
    final stages = widget.projectImpact.stages;
    final ongoingIdx = stages.indexWhere((s) => s.status == ProjectStageStatus.ongoing);
    if (ongoingIdx != -1) {
      _expandedIndex = ongoingIdx;
    } else {
      final pendingIdx = stages.indexWhere((s) => s.status == ProjectStageStatus.pending);
      _expandedIndex = pendingIdx != -1 ? pendingIdx : 0;
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                clipBehavior: Clip.none,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    color: AppColors.surface,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Failed to load image proof',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isAr = loc.language == AppLanguage.ar;
    final stages = widget.projectImpact.stages;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.translate('project_stages_title'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Timeline Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final isLast = index == stages.length - 1;
                return _buildTimelineItem(
                  context: context,
                  index: index,
                  stage: stages[index],
                  isLast: isLast,
                  isExpanded: _expandedIndex == index,
                  isAr: isAr,
                  loc: loc,
                  onTap: () {
                    setState(() {
                      _expandedIndex = _expandedIndex == index ? -1 : index;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required int index,
    required ProjectStage stage,
    required bool isLast,
    required bool isExpanded,
    required bool isAr,
    required AppLocalization loc,
    required VoidCallback onTap,
  }) {
    // Determine status colors and text based on stage.status enum
    Color statusColor;
    Color statusBgColor;
    Color iconColor;
    Color lineColor;
    String statusText;

    switch (stage.status) {
      case ProjectStageStatus.completed:
        statusColor = AppColors.primary;
        statusBgColor = AppColors.primary.withValues(alpha: 0.12);
        iconColor = AppColors.primary;
        lineColor = AppColors.primary;
        statusText = loc.translate('status_completed');
        break;
      case ProjectStageStatus.ongoing:
        statusColor = AppColors.accent;
        statusBgColor = AppColors.accent.withValues(alpha: 0.12);
        iconColor = AppColors.accent;
        lineColor = AppColors.accent.withValues(alpha: 0.4);
        statusText = loc.translate('status_ongoing');
        break;
      case ProjectStageStatus.pending:
        statusColor = AppColors.textMuted;
        statusBgColor = AppColors.textMuted.withValues(alpha: 0.1);
        iconColor = AppColors.textMuted;
        lineColor = AppColors.textMuted.withValues(alpha: 0.25);
        statusText = loc.translate('status_pending');
        break;
    }

    final String title = isAr ? stage.titleAr : stage.titleEn;
    final String date = isAr ? stage.dateAr : stage.dateEn;
    final String detailsText = isAr ? stage.descriptionAr : stage.descriptionEn;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicator & Vertical Line Column
          Column(
            children: [
              // Icon Circle Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isExpanded ? statusBgColor : AppColors.surface,
                  border: Border.all(
                    color: iconColor,
                    width: isExpanded ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  stage.icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              // Connector Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      // Stage Title & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isExpanded ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                // Expandable Details
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detailsText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (stage.proofs != null && stage.proofs!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          // Section title for proofs
                          Text(
                            isAr ? 'إثبات التنفيذ (الصور والمستندات):' : 'Execution Proof (Photos & Documents):',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Horizontal list of thumbnails
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: stage.proofs!.length,
                              itemBuilder: (context, proofIdx) {
                                final proofUrl = stage.proofs![proofIdx];
                                return Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                                  child: InkWell(
                                    onTap: () => _showImagePreview(context, proofUrl),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: Image.network(
                                          proofUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return const Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.broken_image_rounded,
                                            size: 20,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                if (!isExpanded && !isLast) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
