// ✅ COMPLETE FIXED - Clean description + Perfect features naming

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:landdevelop/screens/project_chat_section.dart'; 

class PendingProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final String currentUserId;

  const PendingProjectScreen({
    super.key,
    required this.project,
    required this.currentUserId,
  });

  @override
  State<PendingProjectScreen> createState() => _PendingProjectScreenState();
}

class _PendingProjectScreenState extends State<PendingProjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return timestamp.toString().split(' ')[0];
    } catch (e) {
      return 'N/A';
    }
  }

  List<String> _parseFeatures(dynamic features) {
    if (features == null) return [];
    if (features is List) {
      return features.map((f) => f.toString()).toList();
    } else if (features is String) {
      return features.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
    }
    return [features.toString()];
  }

  bool _hasImages() {
    final imageFields = ['imageUrl', 'images', 'photoUrl', 'imageUrls'];
    for (var field in imageFields) {
      if (widget.project[field] != null) return true;
    }
    return false;
  }

  List<String> _getAllImages() {
    List<String> images = [];
    if (widget.project['imageUrl'] != null) images.add(widget.project['imageUrl']);
    if (widget.project['images'] != null) {
      final imgs = widget.project['images'] as List?;
      if (imgs != null) images.addAll(imgs.cast<String>());
    }
    if (widget.project['imageUrls'] != null) {
      final urls = widget.project['imageUrls'] as List?;
      if (urls != null) images.addAll(urls.cast<String>());
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        title: Text(
          'Project Details',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFD4AF37),
          tabs: const [
            Tab(text: '📋 Details'),
            Tab(text: '💬 Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildMainProjectCard(),
                    const SizedBox(height: 24),
                    if (_hasImages()) ...[
                      _buildImageGallery(),
                      const SizedBox(height: 24),
                    ],
                    _buildTimelineSection(),
                    const SizedBox(height: 24),
                    _buildOtherDetails(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
          ProjectChatSection(
            projectId: widget.project['id'].toString(),
            currentRole: 'user',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8962E)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.project['place']?.toString() ?? 'Unnamed Project',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.project['taluk']?.toString() ?? ''}, ${widget.project['district']?.toString() ?? ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = (widget.project['status'] ?? 'pending').toString().toLowerCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: status == 'pending' ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status == 'pending' ? Colors.orange : Colors.green, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(status == 'pending' ? Icons.hourglass_empty : Icons.check_circle,
              color: status == 'pending' ? Colors.orange : Colors.green, size: 40),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(status.toUpperCase(),
                  style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold,
                      color: status == 'pending' ? Colors.orange.shade800 : Colors.green.shade800)),
              Text('Waiting for Admin Approval',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildMainProjectCard() {
    // 1. Safely cast the features list from Firestore
    List<dynamic> rawFeatures = widget.project['features'] ?? [];
    
    // 2. Filter out any invalid data
    List<Map<String, dynamic>> featuresList = [];
    if (rawFeatures is List) {
      for (var f in rawFeatures) {
        if (f is Map) {
          featuresList.add(Map<String, dynamic>.from(f));
        }
      }
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Description Header ---
            if (widget.project['description']?.toString().trim().isNotEmpty == true) ...[
              Text(
                "About Project",
                style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037)),
              ),
              const SizedBox(height: 12),
              Text(
                widget.project['description'].toString().trim(),
                style: GoogleFonts.poppins(fontSize: 15, height: 1.6, color: const Color(0xFF4E342E)),
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFF5E6CA), thickness: 1),
              const SizedBox(height: 24),
            ],

            // --- Features Header ---
            Row(
              children: [
                const Icon(Icons.temple_buddhist, color: Color(0xFFD4AF37), size: 24), // Temple icon suitable for context
                const SizedBox(width: 8),
                Text(
                  'Structure Details',
                  style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 4 Feature Grid ---
            if (featuresList.isNotEmpty)
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: featuresList.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final feature = featuresList[index];
                  return _buildDetailedFeatureCard(feature);
                },
              )
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedFeatureCard(Map<String, dynamic> data) {
    final String label = data['label'] ?? 'Unknown';
    final String condition = (data['condition'] ?? 'old').toString().toLowerCase();
    final bool isNew = condition == 'new';
    
    // Extract details if new
    final String dimension = data['dimension'] == 'custom' 
        ? (data['customSize'] ?? 'Custom') 
        : (data['dimension'] ?? '-');
    final String amount = data['amount'] ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFFFFDF5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew ? const Color(0xFFD4AF37) : Colors.grey.shade300, 
          width: isNew ? 1.5 : 1
        ),
        boxShadow: isNew 
          ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))] 
          : [],
      ),
      child: Column(
        children: [
          // Top Section: Icon + Name + Condition Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isNew ? const Color(0xFF5D4037) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    // Assign specific icons based on key if possible, else generic
                    _getIconForFeature(data['key']), 
                    color: isNew ? Colors.white : Colors.grey.shade600, 
                    size: 20
                  ),
                ),
                const SizedBox(width: 16),
                
                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.cinzel(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: isNew ? const Color(0xFF3E2723) : Colors.grey.shade700
                        ),
                      ),
                      Text(
                        isNew ? 'New Construction' : 'Existing Structure',
                        style: GoogleFonts.poppins(
                          fontSize: 12, 
                          color: isNew ? Colors.green.shade700 : Colors.grey.shade500,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Indicator
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  ),
              ],
            ),
          ),

          // Bottom Section (Only for New): Details
          if (isNew) 
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6CA).withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15), 
                  bottomRight: Radius.circular(15)
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(Icons.straighten, 'Size', dimension),
                  Container(width: 1, height: 24, color: const Color(0xFFD4AF37)),
                  _buildDetailItem(Icons.currency_rupee, 'Est. Cost', '₹$amount'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF5D4037)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
            Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3E2723))),
          ],
        )
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(child: Text("No features data available", style: GoogleFonts.poppins(color: Colors.grey))),
    );
  }

  IconData _getIconForFeature(String? key) {
    switch (key) {
      case 'lingam': return Icons.circle; // Abstract rep for Lingam
      case 'nandhi': return Icons.pets; // Closest for animal/bull
      case 'avudai': return Icons.layers; // Represents base
      case 'shed': return Icons.roofing; // Represents Shed
      default: return Icons.category;
    }
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6CA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF5D4037), size: 24),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _getAllImages();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: const Color(0xFF5D4037), size: 28),
            const SizedBox(width: 12),
            Text('Project Images (${images.length})',
                style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(right: 12),
              width: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage(images[index]), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Timeline',
                style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
            const SizedBox(height: 20),
            _buildTimelineItem('📝 Project Created', _formatTimestamp(widget.project['dateCreated'])),
            if (widget.project['visitDate'] != null)
              _buildTimelineItem('👀 Last Visited', _formatTimestamp(widget.project['visitDate'])),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String event, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(date, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherDetails() {
    final otherFields = <MapEntry<String, dynamic>>[];
    widget.project.forEach((key, value) {
      if (!['id', 'projectId', 'place', 'taluk', 'district', 'description', 'status', 
            'dateCreated', 'visitDate', 'userId', 'imageUrl', 'images', 'imageUrls', 'features'].contains(key)) {
        otherFields.add(MapEntry(key, value));
      }
    });

    if (otherFields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Details',
            style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
        const SizedBox(height: 16),
        ...otherFields.map((entry) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6CA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, size: 20, color: Color(0xFF5D4037)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key.toString().toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(entry.value.toString(),
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
