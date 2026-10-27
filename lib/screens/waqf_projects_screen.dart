import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/waqf_project.dart';
import '../services/waqf_project_service.dart';
import '../services/donation_success_flow.dart';
import '../utils/theme.dart';
import '../utils/firestore_debug.dart';
import 'donation_details_screen.dart';

class WaqfProjectsScreen extends StatefulWidget {
  const WaqfProjectsScreen({super.key});

  @override
  State<WaqfProjectsScreen> createState() => _WaqfProjectsScreenState();
}

class _WaqfProjectsScreenState extends State<WaqfProjectsScreen> {
  final WaqfProjectService _projectService = WaqfProjectService();

  /// Get localized text from the system locale
  String _getLocalizedText(String textEn, String textAr) {
    // This would typically be fetched from SharedPreferences or provider
    // For now, we'll return English by default
    return textEn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waqf Projects'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<WaqfProject>>(
        stream: _projectService.getAllProjectsStream(),
        builder: (context, snapshot) {
          // Log connection status for debugging
          FirestoreDebug.printConnectionLog('WaqfProjectsScreen', snapshot, false);

          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading projects...'),
                  const SizedBox(height: 24),
                  // Debug info
                  FirestoreDebug.buildDiagnosticWidget(
                    screenName: 'WaqfProjectsScreen',
                    snapshot: snapshot,
                    isAdmin: false,
                  ),
                ],
              ),
            );
          }

          // Error state with detailed debugging
          if (snapshot.hasError) {
            debugPrint('🔴 SNAPSHOT ERROR: ${snapshot.error}');
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Connection Error',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.red,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Debug diagnostic widget
                    FirestoreDebug.buildDiagnosticWidget(
                      screenName: 'WaqfProjectsScreen',
                      snapshot: snapshot,
                      isAdmin: false,
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          final projects = snapshot.data ?? [];
          if (projects.isEmpty) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    Icon(
                      Icons.assignment_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No projects available yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    // Debug info for empty state
                    FirestoreDebug.buildDiagnosticWidget(
                      screenName: 'WaqfProjectsScreen',
                      snapshot: snapshot,
                      isAdmin: false,
                    ),
                  ],
                ),
              ),
            );
          }

          // Successful state - display projects
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectCard(context, project);
            },
          );
        },
      ),
    );
  }

  /// Build individual project card with all details
  Widget _buildProjectCard(BuildContext context, WaqfProject project) {
    final isCompleted = project.isCompleted;
    final progressPercent = project.progressPercentage;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isCompleted ? 0 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted
            ? const BorderSide(color: Color(0xFF10B981), width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isCompleted
              ? LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.1),
                    const Color(0xFF10B981).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLocalizedText(project.titleEn, project.titleAr),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLocalizedText(project.descEn, project.descAr),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status badge
                  _buildStatusBadge(context, isCompleted, project.status),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              _buildProgressBar(context, progressPercent, isCompleted),
              const SizedBox(height: 8),

              // Financial information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialInfo(
                    context,
                    'Raised',
                    NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                        .format(project.raised),
                  ),
                  _buildFinancialInfo(
                    context,
                    'Target',
                    NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                        .format(project.target),
                  ),
                  _buildFinancialInfo(
                    context,
                    'Remaining',
                    NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                        .format(project.amountRemaining),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timeline/Stages
              if (project.stages.isNotEmpty) ...[
                _buildStagesTimeline(context, project.stages),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showProjectDetails(context, project),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isCompleted)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _navigateToDonation(context, project),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text(
                          'Donate Now',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Center(
                          child: Text(
                            '✓ Target Reached',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(
    BuildContext context,
    bool isCompleted,
    String status,
  ) {
    late Color badgeColor;
    late String badgeText;
    late IconData badgeIcon;

    if (isCompleted) {
      badgeColor = const Color(0xFF10B981);
      badgeText = 'Completed';
      badgeIcon = Icons.check_circle;
    } else {
      switch (status.toLowerCase()) {
        case 'active':
          badgeColor = Colors.blue;
          badgeText = 'Active';
          badgeIcon = Icons.autorenew;
          break;
        case 'paused':
          badgeColor = Colors.orange;
          badgeText = 'Paused';
          badgeIcon = Icons.pause_circle;
          break;
        default:
          badgeColor = Colors.grey;
          badgeText = status;
          badgeIcon = Icons.info;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress bar
  Widget _buildProgressBar(
    BuildContext context,
    double progressPercent,
    bool isCompleted,
  ) {
    final barColor = isCompleted ? const Color(0xFF10B981) : AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '${(progressPercent * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progressPercent,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  /// Build financial info widget
  Widget _buildFinancialInfo(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build stages timeline
  Widget _buildStagesTimeline(BuildContext context, List<Stage> stages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Implementation Stages',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stage = stages[index];
              final isCompleted = stage.status.toLowerCase() == 'completed';

              return Padding(
                padding: EdgeInsets.only(right: index < stages.length - 1 ? 12 : 0),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : AppTheme.primaryColor.withValues(alpha: 0.2),
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        stage.iconName == 'account_balance_rounded'
                            ? Icons.account_balance_rounded
                            : stage.iconName == 'people_alt_rounded'
                                ? Icons.people_alt_rounded
                                : stage.iconName == 'school_rounded'
                                    ? Icons.school_rounded
                                    : Icons.info_rounded,
                        color: isCompleted
                            ? Colors.white
                            : AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 60,
                      child: Text(
                        _getLocalizedText(stage.titleEn, stage.titleAr),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Navigate to donation details screen with success flow
  void _navigateToDonation(BuildContext context, WaqfProject project) {
    if (!mounted) return;
    
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    // Store context reference before navigation
    final currentContext = context;

    Navigator.push(
      currentContext,
      MaterialPageRoute(
        builder: (context) => DonationDetailsScreen(
          serviceName: project.titleEn,
          waqfProjectId: project.id,
        ),
      ),
    ).then((_) async {
      // After returning from donation screen, check if project reached milestone
      if (mounted && currentContext.mounted) {
        await _handlePostDonationFlow(currentContext, project, isDarkMode);
      }
    });
  }

  /// Handle post-donation flow: check milestone and show appropriate dialogs
  Future<void> _handlePostDonationFlow(
    BuildContext context,
    WaqfProject project,
    bool isDarkMode,
  ) async {
    if (!mounted) return;
    
    // Refresh project data to get latest raised amount
    final updatedProject = await _projectService.getProjectById(project.id);
    if (updatedProject == null || !mounted) return;

    // If project just reached completion, show milestone celebration
    if (updatedProject.isCompleted && !project.isCompleted) {
      // Get other projects for suggestions
      final allProjects = await _projectService.getAllProjectsStream().first;
      if (!mounted) return;
      
      final otherProjects = allProjects
          .where((p) => p.id != project.id && !p.isCompleted)
          .toList();

      if (mounted && context.mounted) {
        DonationSuccessFlow.showMilestoneCelebrationDialog(
          context: context,
          project: updatedProject,
          otherProjects: otherProjects,
        );
      }
    } else {
      // Show standard thank you dialog
      final donationAmountEstimate = updatedProject.raised - project.raised;
      if (donationAmountEstimate > 0 && mounted && context.mounted) {
        DonationSuccessFlow.showThankYouDialog(
          context: context,
          donationAmount: donationAmountEstimate,
          projectNameEn: project.titleEn,
          projectNameAr: project.titleAr,
          isDarkMode: isDarkMode,
        );
      }
    }
  }

  /// Show project details in a bottom sheet or dialog
  void _showProjectDetails(BuildContext context, WaqfProject project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getLocalizedText(project.titleEn, project.titleAr),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(_getLocalizedText(project.descEn, project.descAr)),
                const SizedBox(height: 24),

                // Project details
                Text(
                  'Project Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Status', project.status),
                _buildDetailRow(
                  'Target',
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(project.target),
                ),
                _buildDetailRow(
                  'Raised',
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(project.raised),
                ),
                _buildDetailRow(
                  'Progress',
                  '${(project.progressPercentage * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 24),

                // Stages
                if (project.stages.isNotEmpty) ...[
                  Text(
                    'Implementation Stages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...project.stages.map(
                    (stage) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  stage.iconName == 'account_balance_rounded'
                                      ? Icons.account_balance_rounded
                                      : Icons.info_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getLocalizedText(
                                      stage.titleEn,
                                      stage.titleAr,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: stage.status.toLowerCase() ==
                                            'completed'
                                        ? const Color(0xFF10B981)
                                            .withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    stage.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: stage.status.toLowerCase() ==
                                              'completed'
                                          ? const Color(0xFF10B981)
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getLocalizedText(
                                stage.descriptionEn,
                                stage.descriptionAr,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${_getLocalizedText(stage.dateEn, stage.dateAr)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build detail row for bottom sheet
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
