import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/campaign.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import 'donation_details_screen.dart';
import 'add_campaign_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  late List<Campaign> campaigns = [];
  bool isLoading = false;
  String? errorMessage;
  bool? _isAdmin; // Null until checked, then true/false

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _checkAdminStatus();
  }

  /// Check if current user is an admin by querying the users collection
  Future<bool> _checkAdminStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isAdmin = false);
        return false;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        setState(() => _isAdmin = false);
        return false;
      }

      // Get role and trim whitespace to handle inconsistencies
      final role = (userDoc.data()?['role'] as String?)?.trim().toLowerCase();
      final isAdmin = role == 'admin';

      if (mounted) {
        setState(() => _isAdmin = isAdmin);
      }
      return isAdmin;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error checking admin status: ${e.message}');
      if (mounted) {
        setState(() => _isAdmin = false);
      }
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      if (mounted) {
        setState(() => _isAdmin = false);
      }
      return false;
    }
  }

  /// Fetch campaigns from Firestore
  void _loadCampaigns() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch campaigns from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('status', isEqualTo: 'active')
          .get();

      if (mounted) {
        setState(() {
          // Map Firestore documents to Campaign objects
          campaigns = querySnapshot.docs
              .map((doc) => Campaign.fromFirestore(doc))
              .toList();
          isLoading = false;
        });
      }
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      if (mounted) {
        setState(() {
          errorMessage =
              'Firebase Error: ${e.message ?? 'Unable to fetch campaigns'}';
          isLoading = false;
        });
      }
    } catch (e) {
      // Handle general errors
      if (mounted) {
        setState(() {
          errorMessage =
              'Error loading campaigns: ${e.toString().replaceAll('Exception: ', '')}';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('service_campaigns_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : errorMessage != null
          ? _buildErrorState(errorMessage!, loc)
          : campaigns.isEmpty
          ? _buildEmptyState(loc)
          : _buildCampaignsList(loc),
      floatingActionButton: _isAdmin == true
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCampaignScreen(),
                  ),
                );
                // Refresh campaigns list after adding new campaign
                if (result == true || result != false) {
                  _loadCampaigns();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Campaign'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }

  Widget _buildErrorState(String error, AppLocalization loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: Colors.red.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _loadCampaigns,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalization loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'No Active Campaigns',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'There are currently no active campaigns available. Please check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsList(AppLocalization loc) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: AppConstants.screenPadding,
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        return _buildCampaignCard(context, campaigns[index], loc);
      },
    );
  }

  Widget _buildCampaignCard(
    BuildContext context,
    Campaign campaign,
    AppLocalization loc,
  ) {
    return GestureDetector(
      onTap: () {
        // Show completion dialog if campaign is completed
        if (campaign.isCompleted) {
          _showCampaignCompletedDialog(context);
          return;
        }
        // Otherwise navigate to donation details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationDetailsScreen(
              serviceName: 'Campaigns',
              campaign: campaign,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Image or Placeholder
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.3),
                    AppTheme.accentColor.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.campaign_rounded,
                      size: 80,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: campaign.isCompleted
                            ? Colors.green
                            : campaign.hasEnded
                            ? Colors.grey
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        campaign.isCompleted
                            ? 'Completed'
                            : campaign.hasEnded
                            ? 'Ended'
                            : 'Active',
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

            // Campaign Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campaign Name
                  Text(
                    campaign.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Campaign Description
                  Text(
                    campaign.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: campaign.progressPercentage / 100,
                          minHeight: 8,
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.12,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            campaign.isCompleted
                                ? Colors.green
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Progress Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${campaign.currentAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / \$${campaign.targetAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${campaign.progressPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: campaign.isCompleted
                                  ? Colors.green
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Donate Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: campaign.isCompleted
                          ? () => _showCampaignCompletedDialog(context)
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DonationDetailsScreen(
                                    serviceName: 'Campaigns',
                                    campaign: campaign,
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: campaign.isCompleted
                            ? Colors.grey
                            : AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        campaign.isCompleted
                            ? 'Campaign Completed'
                            : 'Donate Now',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a friendly AlertDialog when user clicks on a completed campaign
  void _showCampaignCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Thank You! 🎉',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Thank you for your generosity! This campaign has reached its goal. Your support helps many others — please consider checking out our other active campaigns.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadCampaigns(); // Refresh to show active campaigns
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('View Other Campaigns'),
          ),
        ],
      ),
    );
  }
}
