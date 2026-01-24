import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:landdevelop/screens/project_chat_section.dart';

class PendingProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const PendingProjectScreen({super.key, required this.project});

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

  // FIXED: Use the document ID directly
  String _getProjectId() {
    // Priority: docId > id > projectId > projectNumber
    final id = widget.project['docId']?.toString() ?? 
               widget.project['id']?.toString() ?? 
               widget.project['projectId']?.toString() ?? 
               widget.project['projectNumber']?.toString() ?? '';
    
    print("🔵 USER SIDE - Project Document ID: '$id'");
    print("🔵 USER SIDE - Available fields: ${widget.project.keys.toList()}");
    
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        title: Text(
          'Pending Project',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            fontSize: 15,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Project Info',
            ),
            Tab(
              icon: Icon(Icons.chat_bubble_outline),
              text: 'Chat',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjectInfoTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildProjectInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Text(
                  'UNDER REVIEW',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Project Name
          Text(
            widget.project['place'] ?? 'Unnamed Temple',
            style: GoogleFonts.cinzel(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFF8D6E63)),
              const SizedBox(width: 6),
              Text(
                "${widget.project['taluk'] ?? 'N/A'}, ${widget.project['district'] ?? 'N/A'}",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Project Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Details',
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInfoRow('Project ID', widget.project['projectNumber']?.toString() ?? widget.project['projectId']?.toString() ?? 'N/A'),
                
                if (widget.project['userName'] != null || widget.project['name'] != null) ...[
                  const Divider(height: 32),
                  _buildInfoRow('Submitted By', widget.project['userName'] ?? widget.project['name'] ?? 'N/A'),
                ],

                if (widget.project['userPhone'] != null || widget.project['phone'] != null) ...[
                  const Divider(height: 32),
                  _buildInfoRow('Contact', widget.project['userPhone'] ?? widget.project['phone'] ?? 'N/A'),
                ],

                if (widget.project['contactName'] != null) ...[
                  const Divider(height: 32),
                  _buildInfoRow('Local Contact', widget.project['contactName'] ?? 'N/A'),
                ],

                if (widget.project['estimatedAmount'] != null) ...[
                  const Divider(height: 32),
                  _buildInfoRow('Estimated Budget', '₹${widget.project['estimatedAmount']}'),
                ],

                if (widget.project['mapLocation'] != null) ...[
                  const Divider(height: 32),
                  _buildInfoRow('Map Location', widget.project['mapLocation'] ?? 'Not provided'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Features Section (if available)
          if (widget.project['features'] != null && widget.project['features'] is List)
            _buildFeaturesCard(),

          const SizedBox(height: 24),

          // Info Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Under Review',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your proposal is currently being reviewed by our team. You can use the Chat tab to communicate with the admin about this project.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final raw = widget.project['features'];
    List<Map<String, dynamic>> features = [];
    
    if (raw is List) {
      features = raw
          .map((e) => (e as Map).map(
                (k, v) => MapEntry(k.toString(), v),
              ))
          .toList();
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF8D6E63), size: 20),
              const SizedBox(width: 8),
              Text(
                'Requested Features',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3E2723),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...features.map((f) {
            final label = (f['label'] ?? f['key'] ?? 'Feature').toString();
            final condition = (f['condition'] ?? 'old').toString().toLowerCase();
            final dimension = (f['dimension'] ?? '').toString();
            final amount = (f['amount'] ?? '').toString();
            final customSize = (f['customSize'] ?? '').toString();

            final isNew = condition == 'new';
            final statusText = isNew ? 'New' : 'Old / Existing';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNew ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isNew ? Colors.green.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isNew ? Icons.fiber_new_rounded : Icons.history_rounded,
                    size: 18,
                    color: isNew ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isNew ? Colors.green.shade700 : Colors.grey,
                          ),
                        ),
                        if (isNew && dimension.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${dimension == 'custom' && customSize.isNotEmpty ? customSize : dimension}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                        if (isNew && amount.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Amount: ₹$amount',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final projectId = _getProjectId();
    
    if (projectId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No project ID available for chat',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Project data: ${widget.project.toString()}',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      color: Colors.grey.shade50,
      child: ProjectChatSection(
        projectId: projectId,
        currentRole: 'user',
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8D6E63),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: const Color(0xFF3E2723),
          ),
        ),
      ],
    );
  }
}