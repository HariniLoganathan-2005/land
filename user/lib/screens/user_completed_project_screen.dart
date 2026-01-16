import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserCompletedProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project; // from WelcomeScreen

  const UserCompletedProjectScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<UserCompletedProjectScreen> createState() =>
      _UserCompletedProjectScreenState();
}

class _UserCompletedProjectScreenState
    extends State<UserCompletedProjectScreen> {
  static const Color primaryMaroon = Color(0xFF6D1B1B);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color backgroundCream = Color(0xFFFFF7E8);
  static const Color darkMaroonText = Color(0xFF4A1010);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Map<String, dynamic> project;
  late String projectId;

  List<Map<String, dynamic>> works = [];
  bool loadingWorks = true;

  String s(dynamic v) => v?.toString() ?? '';
  num n(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  DateTime? toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return DateTime.tryParse(v.toString());
  }

  String fmtDate(dynamic v) {
    final d = toDate(v);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  @override
  void initState() {
    super.initState();
    project = Map<String, dynamic>.from(widget.project);
    projectId = (project['projectId'] ?? project['id'] ?? '').toString();
    debugPrint('USER COMPLETED: projectId from project map = $projectId');
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    if (projectId.isEmpty) {
      debugPrint('USER COMPLETED: projectId is EMPTY, no query run.');
      setState(() {
        loadingWorks = false;
        works = [];
      });
      return;
    }

    setState(() => loadingWorks = true);
    try {
      debugPrint(
          'USER COMPLETED: querying project_tasks for projectId = $projectId');

      final snap = await _firestore
          .collection('project_tasks')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .get();

      debugPrint('USER COMPLETED: found ${snap.docs.length} completed tasks');

      works = snap.docs.map<Map<String, dynamic>>((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['taskName'] ?? '',
          'description': data['description'] ?? '',
          'date': data['completedAt'] ??
              data['startedAt'] ??
              data['createdAt'],
          'amountDonated': n(data['amountDonated']),
          'status': data['status'] ?? 'completed',
          'imageUrls': (data['endImages'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading completed tasks for user: $e');
      works = [];
    } finally {
      if (mounted) setState(() => loadingWorks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = s(project['place']);
    final taluk = s(project['taluk']);
    final district = s(project['district']);
    final completedDate = fmtDate(project['completedDate']);

    return Scaffold(
      backgroundColor: backgroundCream,
      appBar: AppBar(
        backgroundColor: primaryMaroon,
        elevation: 0,
        title: const Text(
          'Completed Project',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryMaroon, primaryGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.isEmpty ? 'Temple Project' : place,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$taluk, $district',
                  style: const TextStyle(color: primaryGold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded,
                              size: 14, color: Colors.green.shade800),
                          const SizedBox(width: 5),
                          const Text(
                            'COMPLETED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (completedDate.isNotEmpty)
                      Text(
                        'Completed on $completedDate',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildWorksCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final num totalDonated = n(project['donatedAmount']);
    final num totalBillsAmount = n(project['totalBillsAmount']);
    final num totalTransactionsAmount = n(project['totalTransactionsAmount']);
    final num netRemaining = totalDonated - totalBillsAmount;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFFFF2D5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Summary',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkMaroonText),
            ),
            const SizedBox(height: 6),
            Text('Total donations: ₹$totalDonated'),
            Text('Total transactions: ₹$totalTransactionsAmount'),
            Text('Total bills: ₹$totalBillsAmount'),
            Text('Net remaining: ₹$netRemaining'),
          ],
        ),
      ),
    );
  }

  Widget _buildWorksCard() {
    if (loadingWorks) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFFFF7E8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Works Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkMaroonText,
              ),
            ),
            const SizedBox(height: 8),
            if (works.isEmpty)
              const Text(
                'No works recorded.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...works.map((w) {
                final images =
                    (w['imageUrls'] as List? ?? []).cast<String>();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB6862C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s(w['name']),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (s(w['description']).isNotEmpty)
                        Text(s(w['description'])),
                      if (fmtDate(w['date']).isNotEmpty)
                        Text('Date: ${fmtDate(w['date'])}'),
                      Text('Amount spent: ₹${n(w['amountDonated'])}'),
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 70,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: images
                                .map(
                                  (url) => Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => _showFullImage(url),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(url),
          ),
        ),
      ),
    );
  }
}
