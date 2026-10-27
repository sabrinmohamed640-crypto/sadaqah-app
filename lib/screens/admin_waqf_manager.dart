import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/waqf_project.dart';
import '../services/waqf_project_service.dart';
import '../utils/theme.dart';
import '../utils/firestore_debug.dart';

class AdminWaqfManager extends StatefulWidget {
  const AdminWaqfManager({super.key});

  @override
  State<AdminWaqfManager> createState() => _AdminWaqfManagerState();
}

class _AdminWaqfManagerState extends State<AdminWaqfManager> {
  final WaqfProjectService _projectService = WaqfProjectService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  /// Verify that current user is an admin
  Future<void> _checkAdminStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isAdmin = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        if (mounted) setState(() => _isAdmin = false);
        return;
      }

      final role = (userDoc.data()?['role'] as String?)?.trim().toLowerCase();
      if (mounted) {
        setState(() => _isAdmin = role == 'admin');
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      if (mounted) setState(() => _isAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Waqf Manager'),
        ),
        body: const Center(
          child: Text('Access Denied: Admin role required'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waqf Projects Manager'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<WaqfProject>>(
        stream: _projectService.getAllProjectsStream(),
        builder: (context, snapshot) {
          // Log connection status for debugging
          FirestoreDebug.printConnectionLog('AdminWaqfManager', snapshot, _isAdmin);

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
                    screenName: 'AdminWaqfManager',
                    snapshot: snapshot,
                    isAdmin: _isAdmin,
                  ),
                ],
              ),
            );
          }

          // Error state with detailed debugging
          if (snapshot.hasError) {
            debugPrint('🔴 ADMIN SNAPSHOT ERROR: ${snapshot.error}');
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
                      screenName: 'AdminWaqfManager',
                      snapshot: snapshot,
                      isAdmin: _isAdmin,
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
                      'No projects created yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    // Debug info for empty state
                    FirestoreDebug.buildDiagnosticWidget(
                      screenName: 'AdminWaqfManager',
                      snapshot: snapshot,
                      isAdmin: _isAdmin,
                    ),
                  ],
                ),
              ),
            );
          }

          // Display projects list
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectTile(context, project);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProjectDialog(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  /// Build project list tile
  Widget _buildProjectTile(BuildContext context, WaqfProject project) {
    final isCompleted = project.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          project.titleEn,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(project.raised)} / ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(project.target)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progressPercentage,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? const Color(0xFF10B981) : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  project.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${project.stages.length} stages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') {
              _showEditProjectDialog(context, project);
            } else if (action == 'delete') {
              _deleteProject(context, project.id);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to add new project
  void _showAddProjectDialog(BuildContext context) {
    final titleEnController = TextEditingController();
    final titleArController = TextEditingController();
    final descEnController = TextEditingController();
    final descArController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Waqf Project'),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleEnController,
                decoration: const InputDecoration(
                  labelText: 'Title (English)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleArController,
                decoration: const InputDecoration(
                  labelText: 'Title (Arabic)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descEnController,
                decoration: const InputDecoration(
                  labelText: 'Description (English)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descArController,
                decoration: const InputDecoration(
                  labelText: 'Description (Arabic)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (\$)',
                  border: OutlineInputBorder(),
                  hintText: '10000',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleEnController.text.isEmpty ||
                  targetController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              try {
                final project = WaqfProject(
                  id: '',
                  titleEn: titleEnController.text,
                  titleAr: titleArController.text,
                  descEn: descEnController.text,
                  descAr: descArController.text,
                  target: double.parse(targetController.text),
                  raised: 0.0,
                  status: 'Active',
                );

                await _projectService.createProject(project);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Project created successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    titleEnController.dispose();
    titleArController.dispose();
    descEnController.dispose();
    descArController.dispose();
    targetController.dispose();
  }

  /// Show dialog to edit project
  void _showEditProjectDialog(BuildContext context, WaqfProject project) {
    final titleEnController = TextEditingController(text: project.titleEn);
    final titleArController = TextEditingController(text: project.titleAr);
    final descEnController = TextEditingController(text: project.descEn);
    final descArController = TextEditingController(text: project.descAr);
    final raisedController =
        TextEditingController(text: project.raised.toString());
    final targetController =
        TextEditingController(text: project.target.toString());
    String selectedStatus = project.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Waqf Project'),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleEnController,
                decoration: const InputDecoration(
                  labelText: 'Title (English)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleArController,
                decoration: const InputDecoration(
                  labelText: 'Title (Arabic)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descEnController,
                decoration: const InputDecoration(
                  labelText: 'Description (English)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descArController,
                decoration: const InputDecoration(
                  labelText: 'Description (Arabic)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: raisedController,
                decoration: const InputDecoration(
                  labelText: 'Raised Amount (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Paused', child: Text('Paused')),
                  DropdownMenuItem(
                      value: 'Completed', child: Text('Completed')),
                ]
                    .map((e) => DropdownMenuItem(value: e.value, child: e.child))
                    .toList(),
                onChanged: (value) {
                  selectedStatus = value ?? 'Active';
                },
              ),
              const SizedBox(height: 16),
              _buildStagesManager(context, project),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _projectService.updateProject(project.id, {
                  'titleEn': titleEnController.text,
                  'titleAr': titleArController.text,
                  'descEn': descEnController.text,
                  'descAr': descArController.text,
                  'target': double.parse(targetController.text),
                  'raised': double.parse(raisedController.text),
                  'status': selectedStatus,
                });

                if (mounted && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Project updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    titleEnController.dispose();
    titleArController.dispose();
    descEnController.dispose();
    descArController.dispose();
    raisedController.dispose();
    targetController.dispose();
  }

  /// Build stages manager widget
  Widget _buildStagesManager(BuildContext context, WaqfProject project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stages (${project.stages.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () =>
                  _showAddStageDialog(context, project.id, project.stages),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (project.stages.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No stages added yet',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            children: project.stages
                .map(
                  (stage) => Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stage.titleEn,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                stage.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteStage(context, project.id, stage.id),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  /// Show dialog to add new stage
  void _showAddStageDialog(
    BuildContext context,
    String projectId,
    List<Stage> existingStages,
  ) {
    final titleEnController = TextEditingController();
    final titleArController = TextEditingController();
    final descEnController = TextEditingController();
    final descArController = TextEditingController();
    final dateEnController = TextEditingController();
    final dateArController = TextEditingController();
    String selectedStatus = 'Pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stage'),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleEnController,
                decoration: const InputDecoration(
                  labelText: 'Title (English)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleArController,
                decoration: const InputDecoration(
                  labelText: 'Title (Arabic)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descEnController,
                decoration: const InputDecoration(
                  labelText: 'Description (English)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descArController,
                decoration: const InputDecoration(
                  labelText: 'Description (Arabic)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateEnController,
                decoration: const InputDecoration(
                  labelText: 'Date (English)',
                  border: OutlineInputBorder(),
                  hintText: '15 May 2026',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateArController,
                decoration: const InputDecoration(
                  labelText: 'Date (Arabic)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(
                      value: 'Completed', child: Text('Completed')),
                ]
                    .map((e) => DropdownMenuItem(value: e.value, child: e.child))
                    .toList(),
                onChanged: (value) {
                  selectedStatus = value ?? 'Pending';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final stage = Stage(
                  id: '',
                  titleEn: titleEnController.text,
                  titleAr: titleArController.text,
                  dateEn: dateEnController.text,
                  dateAr: dateArController.text,
                  descriptionEn: descEnController.text,
                  descriptionAr: descArController.text,
                  status: selectedStatus,
                  iconName: 'info_rounded',
                );

                await _projectService.createStage(projectId, stage);

                if (mounted && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Stage added successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    titleEnController.dispose();
    titleArController.dispose();
    descEnController.dispose();
    descArController.dispose();
    dateEnController.dispose();
    dateArController.dispose();
  }

  /// Delete project
  Future<void> _deleteProject(BuildContext context, String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text(
          'This action cannot be undone. All stages will be deleted as well.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteProject(projectId);
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Project deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  /// Delete stage
  Future<void> _deleteStage(
    BuildContext context,
    String projectId,
    String stageId,
  ) async {
    try {
      await _projectService.deleteStage(projectId, stageId);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stage deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }
}
