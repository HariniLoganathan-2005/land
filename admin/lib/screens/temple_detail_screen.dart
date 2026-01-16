import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pending_temple_detail_screen.dart';
import 'ongoing_temple_detail_screen.dart';
import 'completed_temple_detail_screen.dart';

class TempleDetailScreen extends StatefulWidget {
  final String templeId;
  final Map initialTempleData;

  const TempleDetailScreen({
    super.key,
    required this.templeId,
    required this.initialTempleData,
  });

  @override
  State createState() => _TempleDetailScreenState();
}

class _TempleDetailScreenState extends State<TempleDetailScreen> {
  static const Color primaryMaroon = Color(0xFF6D1B1B);
  static const Color backgroundCream = Color(0xFFFFF7E8);
  static const Color primaryGold = Color(0xFFD4AF37);

  Map? temple;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemple();
  }

  Future _loadTemple() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    temple = Map.from(widget.initialTempleData);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.templeId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        temple!.addAll(data);

        // Ensure both id and projectId are set to the project document id
        temple!['id'] = widget.templeId;
        temple!['projectId'] = widget.templeId;
      }
    } catch (e) {
      debugPrint('Error loading temple: $e');
    }

    _normalizeTempleFields();

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _normalizeTempleFields() {
    if (temple == null) return;
    final t = temple!;

    // 1. Status Logic
    final String currentStatus =
        (t['status'] ?? 'pending').toString().toLowerCase();
    final bool isSanctioned = t['isSanctioned'] == true;
    final int progress = ((t['progress'] ?? 0) as num).toInt();

    if (currentStatus == 'rejected') {
      t['status'] = 'rejected';
    } else if (!isSanctioned) {
      t['status'] = 'pending';
    } else if (progress >= 100) {
      t['status'] = 'completed';
    } else {
      t['status'] = 'ongoing';
    }

    // 2. Remove aadhar-related fields
    t.remove('aadhar');
    t.remove('userAadhar');
    t.remove('aadharNumber');

    // 3. Site images normalization
    if (t['imageUrls'] != null) {
      if (t['imageUrls'] is List) {
        t['imageUrls'] = (t['imageUrls'] as List)
            .map((e) => e.toString())
            .where((url) => url.startsWith('http'))
            .toList();
      } else if (t['imageUrls'] is String &&
          t['imageUrls'].toString().startsWith('http')) {
        t['imageUrls'] = [t['imageUrls'].toString()];
      } else {
        t['imageUrls'] = [];
      }
    } else if (t['siteImages'] != null && t['siteImages'] is List) {
      t['imageUrls'] = (t['siteImages'] as List)
          .map((e) => e.toString())
          .where((url) => url.startsWith('http'))
          .toList();
    } else {
      t['imageUrls'] = [];
    }

    // 4. User info fallback
    t['userName'] = (t['userName'] ?? t['name'] ?? 'User').toString();
    t['userEmail'] = (t['userEmail'] ?? t['email'] ?? '').toString();
    t['userPhone'] = (t['userPhone'] ?? t['phone'] ?? '').toString();

    // 5. Project number for display; projectId is the actual Firestore id
    t['projectNumber'] =
        (t['projectNumber'] ?? t['projectId'] ?? 'P000').toString();

    // 6. Display name fallback
    t['name'] = (t['name'] ??
            (t['feature'] != null && t['feature'] != ''
                ? '${t['feature']} Project'
                : 'Temple Project'))
        .toString();
  }

  @override
  @override
Widget build(BuildContext context) {
  if (isLoading || temple == null) {
    return Scaffold(
      backgroundColor: backgroundCream,
      appBar: AppBar(
        backgroundColor: primaryMaroon,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Loading Details...',
          style: TextStyle(color: Color(0xFFFFF4D6), fontSize: 18),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: primaryMaroon),
      ),
    );
  }

  final String status = (temple!['status'] ?? 'pending').toString();

  // FIX: strongly typed map
  final Map<String, dynamic> displayData =
      Map<String, dynamic>.from(temple! as Map);

  switch (status) {
    case 'pending':
      return PendingTempleDetailScreen(
        temple: displayData,
        onUpdated: (updated) => Navigator.pop(context, updated),
        onDeleted: () => _markAsRejected(),
      );
    case 'ongoing':
      return OngoingTempleDetailScreen(
        temple: displayData,
        onUpdated: (updated) => Navigator.pop(context, updated),
      );
    case 'completed':
      return CompletedTempleDetailScreen(
        temple: displayData,
        onUpdated: (updated) => Navigator.pop(context, updated),
      );
    case 'rejected':
      return Scaffold(
        backgroundColor: backgroundCream,
        appBar: AppBar(
          backgroundColor: Colors.red[900],
          title: const Text("Rejected Project"),
        ),
        body: const Center(
          child: Text("This project has been rejected."),
        ),
      );
    default:
      return const Scaffold(
        body: Center(child: Text('Unknown Status')),
      );
  }
}


  void _markAsRejected() async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.templeId)
        .update({'status': 'rejected', 'isSanctioned': false});
    if (mounted) Navigator.pop(context, null);
  }
}
