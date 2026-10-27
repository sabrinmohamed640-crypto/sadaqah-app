import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/orphan.dart';
import '../services/orphan_service.dart';
import '../utils/theme.dart';

class AdminOrphanScreen extends StatefulWidget {
  const AdminOrphanScreen({super.key});

  @override
  State<AdminOrphanScreen> createState() => _AdminOrphanScreenState();
}

class _AdminOrphanScreenState extends State<AdminOrphanScreen> {
  final OrphanService _orphanService = OrphanService();
  bool _isAdmin = false;
  bool _isSeeding = false;

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

  /// Seed dummy orphan data
  Future<void> _seedDummyData() async {
    if (!mounted) return;

    setState(() => _isSeeding = true);

    try {
      await _orphanService.seedDummyOrphans();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully seeded 3 dummy orphan profiles!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error seeding data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  /// Show dialog to add/edit orphan
  void _showOrphanDialog({Orphan? orphan}) {
    final isEdit = orphan != null;

    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: orphan?.name);
        final ageController = TextEditingController(text: orphan?.age.toString());
        final bioController = TextEditingController(text: orphan?.bio);
        final imageUrlController =
            TextEditingController(text: orphan?.imageUrl);
        final amountController = TextEditingController(
          text: orphan?.sponsorshipAmount.toString(),
        );

        return AlertDialog(
          title: Text(isEdit ? 'Edit Orphan' : 'Add New Orphan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter orphan name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    hintText: 'Enter age',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'Biography',
                    hintText: 'Enter bio/description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'Enter image URL',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Sponsorship Amount',
                    hintText: 'Enter amount',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                ageController.dispose();
                bioController.dispose();
                imageUrlController.dispose();
                amountController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text) ?? 0;
                final bio = bioController.text.trim();
                final imageUrl = imageUrlController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0.0;

                if (name.isEmpty ||
                    age <= 0 ||
                    bio.isEmpty ||
                    imageUrl.isEmpty ||
                    amount <= 0) {
                  if (!mounted) {
                    nameController.dispose();
                    ageController.dispose();
                    bioController.dispose();
                    imageUrlController.dispose();
                    amountController.dispose();
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields with valid data'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await _orphanService.updateOrphan(
                      orphan!.id,
                      {
                        'name': name,
                        'age': age,
                        'bio': bio,
                        'imageUrl': imageUrl,
                        'sponsorshipAmount': amount,
                      },
                    );
                  } else {
                    await _orphanService.addOrphan(
                      Orphan(
                        id: '',
                        name: name,
                        age: age,
                        bio: bio,
                        imageUrl: imageUrl,
                        sponsorshipAmount: amount,
                        status: 'available',
                        createdAt: DateTime.now(),
                      ),
                    );
                  }

                  // CRITICAL: Check mounted immediately after async operation
                  if (!mounted) {
                    nameController.dispose();
                    ageController.dispose();
                    bioController.dispose();
                    imageUrlController.dispose();
                    amountController.dispose();
                    return;
                  }

                  // Dispose controllers
                  nameController.dispose();
                  ageController.dispose();
                  bioController.dispose();
                  imageUrlController.dispose();
                  amountController.dispose();

                  // Close the dialog FIRST
                  if (!mounted) return;
                  Navigator.of(context).pop();

                  // Show success message AFTER dialog is closed
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Orphan updated successfully' : 'Orphan added successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  nameController.dispose();
                  ageController.dispose();
                  bioController.dispose();
                  imageUrlController.dispose();
                  amountController.dispose();

                  // Only show error if widget is still mounted
                  if (!mounted) return;
                  
                  // Pop dialog if still mounted
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }

                  // Show error message
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(Orphan orphan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Orphan'),
        content: Text(
          'Are you sure you want to delete "${orphan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _orphanService.deleteOrphan(orphan.id);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Orphan deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Orphan Management'),
        ),
        body: const Center(
          child: Text('Access Denied: Admin role required'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orphan Sponsorship Manager'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<Orphan>>(
        stream: _orphanService.getOrphansStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final orphans = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSeeding
                          ? null
                          : _seedDummyData,
                      icon: const Icon(Icons.cloud_download),
                      label: _isSeeding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Seed Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showOrphanDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Orphan'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: orphans.isEmpty
                    ? const Center(
                        child: Text('No orphans found. Click "Seed Data" or "Add Orphan" to get started.'),
                      )
                    : ListView.builder(
                        itemCount: orphans.length,
                        itemBuilder: (context, index) {
                          final orphan = orphans[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(orphan.imageUrl),
                                onBackgroundImageError: (_, __) {},
                                child: orphan.imageUrl.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(orphan.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Age: ${orphan.age} | Status: ${orphan.status}'),
                                  Text('Sponsorship: \$${orphan.sponsorshipAmount}/month'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    onTap: () => _showOrphanDialog(orphan: orphan),
                                    child: const Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    onTap: () => _showDeleteDialog(orphan),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrphanDialog(),
        tooltip: 'Add New Orphan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
