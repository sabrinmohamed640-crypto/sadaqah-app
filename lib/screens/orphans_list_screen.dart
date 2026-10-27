import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orphan.dart';
import '../services/orphan_service.dart';
import '../utils/theme.dart';

class OrphansListScreen extends StatefulWidget {
  const OrphansListScreen({super.key});

  @override
  State<OrphansListScreen> createState() => _OrphansListScreenState();
}

class _OrphansListScreenState extends State<OrphansListScreen> {
  final OrphanService _orphanService = OrphanService();
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  /// Get current user information
  Future<void> _getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _currentUserId = user.uid;
            _currentUserName =
                userDoc.data()?['name'] ?? user.email ?? 'Sponsor';
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
  }

  /// Handle sponsorship donation
  Future<void> _sponsorOrphan(Orphan orphan) async {
    if (_currentUserId == null || _currentUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to sponsor an orphan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Check if orphan is already sponsored
      if (orphan.status == 'sponsored') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This orphan is already sponsored'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Update orphan status
      await _orphanService.sponsorOrphan(
        orphan.id,
        _currentUserId!,
        _currentUserName!,
      );

      // Log donation to database
      await FirebaseFirestore.instance.collection('donations').add({
        'orphanId': orphan.id,
        'orphanName': orphan.name,
        'donorId': _currentUserId,
        'donorName': _currentUserName,
        'amount': orphan.sponsorshipAmount,
        'type': 'Orphan Sponsorship',
        'paymentMethod': 'In-App',
        'status': 'Completed',
        'timestamp': Timestamp.now(),
        'notes': 'Orphan sponsorship for ${orphan.name}',
      });

      if (!mounted) return;

      // Show success feedback
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text(
            'Sponsorship Confirmed',
            style: TextStyle(color: Colors.green),
          ),
          content: Text(
            'Thank you for your generous donation! You have successfully sponsored ${orphan.name}.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Okay'),
            ),
          ],
        ),
      );

      debugPrint('Orphan ${orphan.name} sponsored successfully');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sponsoring orphan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint('Error sponsoring orphan: $e');
    }
  }

  /// Show orphan details dialog
  void _showOrphanDetails(Orphan orphan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(orphan.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  orphan.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Age: ${orphan.age} years old',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${orphan.status}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: orphan.status == 'available' ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'About:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(orphan.bio),
              const SizedBox(height: 16),
              if (orphan.sponsorName != null)
                Text(
                  'Current Sponsor: ${orphan.sponsorName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (orphan.status == 'available')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sponsorOrphan(orphan);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Sponsor Now'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orphan Sponsorship'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<Orphan>>(
        stream: _orphanService.getOrphansStream(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading orphans: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // No data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No orphans available at this time'),
            );
          }

          final orphans = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: orphans.length,
              itemBuilder: (context, index) {
                final orphan = orphans[index];
                final isSponsor = orphan.sponsorId == _currentUserId;

                return GestureDetector(
                  onTap: () => _showOrphanDetails(orphan),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Image.network(
                                  orphan.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                                ),
                                // Status badge
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: orphan.status == 'available'
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      orphan.status == 'available'
                                          ? 'Available'
                                          : 'Sponsored',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orphan.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Age: ${orphan.age}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${orphan.sponsorshipAmount}/month',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: orphan.status == 'available'
                                        ? () => _sponsorOrphan(orphan)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSponsor
                                          ? Colors.grey
                                          : AppTheme.primaryColor,
                                      disabledBackgroundColor: Colors.grey[400],
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      isSponsor
                                          ? 'Your Orphan'
                                          : orphan.status == 'available'
                                              ? 'Sponsor'
                                              : 'Sponsored',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
