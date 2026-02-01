import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Ensure you add intl to pubspec.yaml for currency formatting
import 'project_chat_section.dart';

class PendingTempleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> temple;
  final void Function(Map<String, dynamic>?) onUpdated;
  final VoidCallback onDeleted;

  const PendingTempleDetailScreen({
    Key? key,
    required this.temple,
    required this.onUpdated,
    required this.onDeleted,
  }) : super(key: key);

  @override
  State<PendingTempleDetailScreen> createState() =>
      _PendingTempleDetailScreenState();
}

class _PendingTempleDetailScreenState extends State<PendingTempleDetailScreen> {
  // --- Theme Colors ---
  static const Color maroonDeep = Color(0xFF6A1B1A);
  static const Color maroonLight = Color(0xFF8E3D2C);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color creamBg = Color(0xFFFFFBF2);
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color successGreen = Color(0xFF2D6A4F);

  final TextEditingController _amountController = TextEditingController();
  bool _isEditingAmount = false;

  @override
  void initState() {
    super.initState();
    final amount = widget.temple['estimatedAmount']?.toString() ?? '0';
    _amountController.text = amount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _getProjectId() {
    final id = widget.temple['docId']?.toString() ??
        widget.temple['id']?.toString() ??
        widget.temple['projectId']?.toString() ??
        widget.temple['projectNumber']?.toString() ??
        '';
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.temple['status'] ?? 'pending').toString();

    return DefaultTabController(
      length: 2,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          widget.onUpdated(widget.temple);
          Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: creamBg,
          body: Column(
            children: [
              _buildHeader(context, status),
              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: maroonDeep,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: maroonDeep,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Project Details'),
                    Tab(text: 'Chat'),
                  ],
                ),
              ),
              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildDetailsTab(status),
                    _buildChatTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(String status) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // 1. Budget Tracker (Only visible if Ongoing or Completed)
        if (status == 'ongoing' || status == 'completed') ...[
          _buildBudgetTracker(),
          const SizedBox(height: 16),
        ],

        // 2. User Info
        _buildSectionCard(
          icon: Icons.person_outline_rounded,
          title: 'User Information',
          child: Column(
            children: [
              _buildInfoRow(
                'Name',
                (widget.temple['userName'] ??
                        widget.temple['name'] ??
                        'N/A')
                    .toString(),
              ),
              _buildInfoRow(
                'Phone',
                (widget.temple['userPhone'] ??
                        widget.temple['phone'] ??
                        'N/A')
                    .toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Site Images
        _buildSiteImagesCard(context),
        const SizedBox(height: 16),

        // 4. Location
        _buildSectionCard(
          icon: Icons.location_on_outlined,
          title: 'Location Details',
          child: Column(
            children: [
              _buildInfoRow('Place', (widget.temple['place'] ?? '').toString()),
              _buildInfoRow(
                  'District', (widget.temple['district'] ?? '').toString()),
              _buildInfoRow('Taluk', (widget.temple['taluk'] ?? '').toString()),
              _buildInfoRow(
                'Map Link',
                (widget.temple['mapLocation'] ?? 'Not provided').toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Features
        _buildFeaturesCard(),
        const SizedBox(height: 16),

        // 6. Contact & Budget (Editable Estimate)
        _buildContactBudgetCard(),
        const SizedBox(height: 24),

        // 7. Action Buttons
        if (status == 'pending') _buildPendingActions(context),
        if (status == 'ongoing') _buildCompletionAction(context),

        const SizedBox(height: 40),
      ],
    );
  }

  // --- NEW: Budget Tracker Widget ---
  Widget _buildBudgetTracker() {
    final projectId = _getProjectId();
    final double estimated = double.tryParse(
            widget.temple['estimatedAmount']?.toString() ?? '0') ?? 0.0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        double totalSpent = 0.0;
        final expenses = snapshot.data!.docs;
        for (var doc in expenses) {
          totalSpent += (doc['amount'] as num).toDouble();
        }

        double percentage = estimated > 0 ? (totalSpent / estimated) : 0.0;
        if (percentage > 1.0) percentage = 1.0;

        // Color logic: Green if under budget, Orange if close, Red if over
        Color progressColor = successGreen;
        if (totalSpent > estimated) progressColor = Colors.red;
        else if (percentage > 0.8) progressColor = Colors.orange;

        return _buildSectionCard(
          icon: Icons.pie_chart_outline,
          title: 'Budget Utilization',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 8),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utilized: ₹${totalSpent.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: progressColor),
                  ),
                  Text(
                    'Total: ₹${estimated.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Recent Transactions List
              if (expenses.isNotEmpty) ...[
                Text(
                  'Recent Expenses',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length > 3 ? 3 : expenses.length, // Show max 3
                  itemBuilder: (context, index) {
                    final data = expenses[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['description'] ?? 'Expense',
                              style: GoogleFonts.poppins(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '- ₹${data['amount']}',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 12),
              // Add Expense Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddExpenseDialog(context, projectId),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Payment Record'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: maroonDeep,
                    side: const BorderSide(color: maroonDeep),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, String projectId) {
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Expense', style: GoogleFonts.philosopher(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (e.g. Cement, Labor)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: maroonDeep),
            onPressed: () async {
              if (descController.text.isNotEmpty && amountController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('projects')
                    .doc(projectId)
                    .collection('expenses')
                    .add({
                  'description': descController.text,
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'date': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // --- NEW: Completion Action Button ---
  Widget _buildCompletionAction(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFF4E285)], // Gold Gradient
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleCompletion(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFB8860B), // Dark Gold
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 28, color: Color(0xFFB8860B)),
            const SizedBox(width: 12),
            Text(
              'MARK PROJECT AS COMPLETED',
              style: GoogleFonts.philosopher(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: const Color(0xFFB8860B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCompletion(BuildContext context) async {
    final confirm = await _showDialog(
      context,
      'Complete Project',
      'Are you sure you want to mark this project as fully completed? This will archive the project.',
      const Color(0xFFB8860B),
    );

    if (confirm == true) {
      final docId = _getProjectId();
      if (docId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(docId)
          .update({'status': 'completed', 'completedDate': FieldValue.serverTimestamp()});

      setState(() {
        widget.temple['status'] = 'completed';
      });
      widget.onUpdated(widget.temple);
      
      // Show celebration snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Project marked as Completed!'),
          backgroundColor: Color(0xFFB8860B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- EXISTING: Chat Tab ---
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
                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 16),
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
        currentRole: 'admin',
      ),
    );
  }

  // --- EXISTING: Header ---
  Widget _buildHeader(BuildContext context, String status) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [maroonDeep, maroonLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: goldAccent, size: 20),
                onPressed: () => widget.onUpdated(widget.temple),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.temple['name'] ?? widget.temple['place'] ?? 'Temple Project').toString(),
                      style: GoogleFonts.philosopher(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.temple['projectNumber']?.toString() ?? widget.temple['projectId']?.toString() ?? 'P000'} • ${status.toUpperCase()}',
                      style: GoogleFonts.poppins(
                        color: goldAccent.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EXISTING: Helper Widgets ---
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: maroonDeep.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: maroonLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.philosopher(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: maroonDeep,
                  ),
                ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final raw = widget.temple['features'];
    List<Map<String, dynamic>> features = [];
    if (raw is List) {
      features = raw
          .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    return _buildSectionCard(
      icon: Icons.list_alt,
      title: 'Requested Features',
      child: features.isEmpty
          ? const Text('No feature details submitted.', style: TextStyle(color: Colors.grey))
          : Column(
              children: features.map((f) {
                final label = (f['label'] ?? f['key'] ?? 'Feature').toString();
                final condition = (f['condition'] ?? 'old').toString().toLowerCase();
                final dimension = (f['dimension'] ?? '').toString();
                final amount = (f['amount'] ?? '').toString();
                final customSize = (f['customSize'] ?? '').toString();

                final isNew = condition == 'new';
                final statusText = isNew ? 'New' : 'Old / Existing';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: maroonDeep.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isNew ? const Color(0xFF2D6A4F) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isNew ? Icons.fiber_new_rounded : Icons.history_rounded,
                        size: 18,
                        color: isNew ? const Color(0xFF2D6A4F) : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: maroonDeep,
                              ),
                            ),
                            Text(
                              statusText,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isNew ? const Color(0xFF2D6A4F) : Colors.grey,
                              ),
                            ),
                            if (isNew && dimension.isNotEmpty)
                              Text(
                                'Size: ${dimension == 'custom' && customSize.isNotEmpty ? customSize : dimension}',
                                style: GoogleFonts.poppins(fontSize: 12, color: textDark),
                              ),
                            if (isNew && amount.isNotEmpty)
                              Text(
                                'Required amount: ₹$amount',
                                style: GoogleFonts.poppins(fontSize: 12, color: textDark),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSiteImagesCard(BuildContext context) {
    List<String> imageData = [];
    final rawData = widget.temple['imageUrls'] ?? widget.temple['images'] ?? widget.temple['siteImages'];

    if (rawData != null) {
      if (rawData is List) {
        imageData = rawData.map((e) => e.toString()).toList();
      } else if (rawData is String) {
        imageData = [rawData];
      }
    }

    return _buildSectionCard(
      icon: Icons.camera_alt_outlined,
      title: 'Site Gallery',
      child: imageData.isEmpty
          ? const Center(child: Text('No site images found', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
          : SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageData.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final String source = imageData[index];
                  final bool isUrl = source.startsWith('http');
                  final bool isDataUri = source.startsWith('data:image');

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FullscreenImageViewer(source: source),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 280,
                        color: Colors.grey[200],
                        child: isUrl
                            ? _buildNetworkImage(source)
                            : _buildBase64Image(source, isDataUri: isDataUri),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildBase64Image(String base64String, {bool isDataUri = false}) {
    try {
      String cleanHash = base64String;
      if (isDataUri || base64String.contains(',')) {
        cleanHash = base64String.split(',').last;
      }
      cleanHash = cleanHash.replaceAll('\n', '').replaceAll('\r', '').trim();
      final Uint8List bytes = base64Decode(cleanHash);
      return Image.memory(bytes, fit: BoxFit.cover, width: 280, height: 200, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)));
    } catch (e) {
      return const Center(child: Icon(Icons.error_outline, color: Colors.red));
    }
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: 280,
      height: 200,
      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  Widget _buildContactBudgetCard() {
    final double amount = double.tryParse((widget.temple['estimatedAmount'] ?? '0').toString()) ?? 0.0;

    return _buildSectionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Budget & Contact',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Local POC',
            (widget.temple['contactName'] ?? widget.temple['userName'] ?? 'N/A').toString(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTIMATED BUDGET',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, letterSpacing: 1.2),
              ),
              IconButton(
                icon: Icon(_isEditingAmount ? Icons.close : Icons.edit, size: 18, color: maroonDeep),
                onPressed: () {
                  setState(() {
                    _isEditingAmount = !_isEditingAmount;
                    if (!_isEditingAmount) {
                      _amountController.text = widget.temple['estimatedAmount']?.toString() ?? '0';
                    }
                  });
                },
              ),
            ],
          ),
          if (_isEditingAmount)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: maroonDeep),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: maroonDeep),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: maroonLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: maroonDeep, width: 2)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _updateEstimatedAmount,
                  style: ElevatedButton.styleFrom(backgroundColor: maroonDeep, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('Update Amount', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            )
          else
            Text('₹${amount.toStringAsFixed(0)}', style: GoogleFonts.philosopher(fontSize: 32, fontWeight: FontWeight.bold, color: maroonDeep)),
        ],
      ),
    );
  }

  void _updateEstimatedAmount() async {
    final newAmount = _amountController.text.trim();
    if (newAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    try {
      final docId = _getProjectId();
      if (docId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project ID not found')));
        return;
      }

      await FirebaseFirestore.instance.collection('projects').doc(docId).update({'estimatedAmount': newAmount});

      setState(() {
        widget.temple['estimatedAmount'] = newAmount;
        _isEditingAmount = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estimated amount updated successfully'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating amount: $e')));
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13, color: textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleSanction(context),
            style: ElevatedButton.styleFrom(backgroundColor: successGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('SANCTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => widget.onDeleted(),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ),
      ],
    );
  }

  void _handleSanction(BuildContext context) async {
    final confirm = await _showDialog(context, 'Sanction Project', 'Move this project to the ongoing phase?', Colors.green);
    if (confirm == true) {
      final docId = _getProjectId();
      if (docId.isEmpty) return;
      await FirebaseFirestore.instance.collection('projects').doc(docId).update({'isSanctioned': true, 'status': 'ongoing'});
      widget.temple['isSanctioned'] = true;
      widget.temple['status'] = 'ongoing';
      widget.onUpdated(widget.temple);
    }
  }

  Future<bool?> _showDialog(BuildContext context, String title, String msg, Color color) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.philosopher(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: color), child: const Text('Confirm')),
        ],
      ),
    );
  }
}

// ---------------- FULLSCREEN IMAGE VIEWER ----------------
class FullscreenImageViewer extends StatelessWidget {
  final String source;
  const FullscreenImageViewer({Key? key, required this.source}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUrl = source.startsWith('http');
    final bool isDataUri = source.startsWith('data:image');
    Widget child;

    if (isUrl) {
      child = InteractiveViewer(child: Image.network(source, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white))));
    } else {
      String clean = source;
      if (isDataUri || source.contains(',')) {
        clean = source.split(',').last;
      }
      clean = clean.replaceAll('\n', '').replaceAll('\r', '').trim();
      try {
        final bytes = base64Decode(clean);
        child = InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white))));
      } catch (_) {
        child = const Center(child: Icon(Icons.error_outline, color: Colors.white));
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: child),
    );
  }
}