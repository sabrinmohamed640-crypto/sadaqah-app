import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// PROFESSIONAL LOADING STATE WIDGETS
/// ─────────────────────────────────────────────────────────────────────────────
/// Beautifully designed loading indicators and skeleton screens for smooth UX.
/// ═══════════════════════════════════════════════════════════════════════════════

/// ──────────────────────────────────────────────────────────────────────────────
/// CenteredLoadingIndicator
/// ──────────────────────────────────────────────────────────────────────────────
/// Centered professional loading spinner with optional text.
class CenteredLoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const CenteredLoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? AppTheme.gold,
              strokeWidth: 4,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// LoadingOverlay
/// ──────────────────────────────────────────────────────────────────────────────
/// Full-screen modal loading overlay with backdrop.
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isDismissible;
  final Color? backgroundColor;
  final double backdropOpacity;

  const LoadingOverlay({
    super.key,
    this.message,
    this.isDismissible = false,
    this.backgroundColor,
    this.backdropOpacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => isDismissible,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: backdropOpacity),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: backgroundColor ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: AppTheme.gold,
                        strokeWidth: 4,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        message!,
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// ShimmerLoadingCard
/// ──────────────────────────────────────────────────────────────────────────────
/// Skeleton/shimmer loading effect for cards (placeholder while data loads).
class ShimmerLoadingCard extends StatefulWidget {
  final double height;
  final double borderRadius;

  const ShimmerLoadingCard({
    super.key,
    this.height = 200,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<ShimmerLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _controller.value - 0.5,
                _controller.value,
                _controller.value + 0.5,
              ],
              colors: isDark
                  ? [
                      AppTheme.darkSurface,
                      AppTheme.darkSurface.withValues(alpha: 0.5),
                      AppTheme.darkSurface,
                    ]
                  : [
                      AppTheme.lightSurfaceAlt,
                      AppTheme.lightSurface,
                      AppTheme.lightSurfaceAlt,
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// PaginatedListLoadingState
/// ──────────────────────────────────────────────────────────────────────────────
/// Loading state for paginated list views.
class PaginatedListLoadingState extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const PaginatedListLoadingState({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoadingCard(height: itemHeight),
        );
      },
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// ErrorStateWidget
/// ──────────────────────────────────────────────────────────────────────────────
/// Professional error state display with retry button.
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.charcoal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// EmptyStateWidget
/// ──────────────────────────────────────────────────────────────────────────────
/// Professional empty state display when no data is available.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppTheme.gold,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.charcoal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// ProgressStepIndicator
/// ──────────────────────────────────────────────────────────────────────────────
/// Visual progress indicator for multi-step processes.
class ProgressStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const ProgressStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: currentStep / totalSteps,
            backgroundColor: isDark
                ? AppTheme.darkSurfaceAlt
                : AppTheme.lightSurfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
          ),
        ),
        const SizedBox(height: 12),
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: index == 0 || index == totalSteps - 1 ? 0 : 4,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent
                            ? AppTheme.gold
                            : (isDark
                                ? AppTheme.darkSurfaceAlt
                                : AppTheme.lightSurfaceAlt),
                        border: Border.all(
                          color: isCurrent
                              ? AppTheme.gold
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: AppTheme.charcoal,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? AppTheme.charcoal
                                      : (isDark
                                          ? AppTheme.textSecondary
                                          : AppTheme.textSecondaryLight),
                                ),
                              ),
                      ),
                    ),
                    if (stepLabels.isNotEmpty &&
                        index < stepLabels.length) ...[
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          stepLabels[index],
                          style: AppTypography.labelSmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
