import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'temple_detail_screen.dart';

class PlaceTemplesScreen extends StatefulWidget {
  final String placeId;

  const PlaceTemplesScreen({
    super.key,
    required this.placeId,
  });

  @override
  State<PlaceTemplesScreen> createState() => _PlaceTemplesScreenState();
}

class _PlaceTemplesScreenState extends State<PlaceTemplesScreen> {
  // --- Aranpani Theme Tokens ---
  static const Color primaryMaroon = Color(0xFF6D1B1B);
  static const Color primaryAccentGold = Color(0xFFD4AF37);
  static const Color secondaryGold = Color(0xFFB8962E);
  static const Color backgroundCream = Color(0xFFFFF7E8);
  static const Color softParchment = Color(0xFFFFFBF2);
  static const Color darkMaroonText = Color(0xFF4A1010);
  static const Color lightGoldText = Color(0xFFFFF4D6);

  bool isLoading = true;
  String placeName = '';
  String districtName = '';
  List<Map<String, dynamic>> temples = [];
  int statusTab = 0;
  
  // Search State
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // Filter Logic
  List<Map<String, dynamic>> get currentList {
    // 1. Filter by Status
    List<Map<String, dynamic>> list;
    if (statusTab == 0) {
      list = temples.where((t) => t['status'] == 'pending').toList();
    } else if (statusTab == 1) {
      list = temples.where((t) => t['status'] == 'ongoing').toList();
    } else {
      list = temples.where((t) => t['status'] == 'completed').toList();
    }

    // 2. Filter by Search Query
    if (searchQuery.trim().isEmpty) return list;

    final query = searchQuery.toLowerCase().trim();
    return list.where((t) {
      // Added toString() to ensure we never check null
      final projectId = (t['projectId'] ?? '').toString().toLowerCase();
      final userName = (t['userName'] ?? '').toString().toLowerCase();
      final userId = (t['userId'] ?? '').toString().toLowerCase();
      
      return projectId.contains(query) || 
             userName.contains(query) || 
             userId.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTemples();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemples() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      final snap = await FirebaseFirestore.instance
          .collection('projects')
          .where('taluk', isEqualTo: widget.placeId)
          .get();

      if (!mounted) return;

      placeName = widget.placeId;

      if (snap.docs.isNotEmpty) {
        // Safe access to district
        final firstData = snap.docs.first.data();
        districtName = (firstData['district'] ?? '').toString();
      }

      // Fetch Users
      final Set<String> userIds = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = (data['userId'] ?? '').toString();
        if (uid.isNotEmpty) userIds.add(uid);
      }

      final Map<String, Map<String, dynamic>> usersById = {};
      if (userIds.isNotEmpty) {
        // Firestore 'whereIn' supports max 10 items. 
        // If you have > 10, this needs chunking. Assuming < 10 for now.
        // Or simply fetching individually if list is small.
        // Here we keep it simple but safe.
        final List<String> idList = userIds.toList();
        
        // Chunking logic to prevent crash if > 10 users
        for (var i = 0; i < idList.length; i += 10) {
          final end = (i + 10 < idList.length) ? i + 10 : idList.length;
          final chunk = idList.sublist(i, end);
          
          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (final u in userSnap.docs) {
            usersById[u.id] = u.data();
          }
        }
      }

      temples = snap.docs.map((doc) {
        final data = doc.data();
        final uid = (data['userId'] ?? '').toString();
        final userData = usersById[uid] ?? {};

        final bool isSanctioned = data['isSanctioned'] == true;
        
        // FIX: Safer number parsing (handles String "50" vs Number 50)
        int progress = 0;
        if (data['progress'] != null) {
          progress = int.tryParse(data['progress'].toString()) ?? 0;
        }

        final String rawStatus = (data['status'] ?? 'pending').toString().toLowerCase();

        String status;
        if (rawStatus == 'rejected') {
          status = 'rejected';
        } else if (!isSanctioned) {
          status = 'pending';
        } else if (progress >= 100) {
          status = 'completed';
        } else {
          status = 'ongoing';
        }

        return <String, dynamic>{
          'id': doc.id,
          // FIX: Ensure Fallback values are present
          'projectId': (data['projectId'] ?? 'No ID').toString(), 
          'userId': uid,
          'district': (data['district'] ?? '').toString(),
          'taluk': (data['taluk'] ?? '').toString(),
          'place': (data['place'] ?? '').toString(),
          'feature': (data['feature'] ?? '').toString(),
          'status': status,
          'progress': progress,
          'isSanctioned': isSanctioned,
          // Fallback logic for name
          'userName': (userData['name'] ?? data['contactName'] ?? 'Unknown User').toString(),
          'userEmail': (userData['email'] ?? '').toString(),
          'userPhone': (userData['phoneNumber'] ?? data['contactPhone'] ?? '').toString(),
          // Safe List casting
          'imageUrls': List<String>.from(data['imageUrls'] ?? []),
          'raw': data,
        };
      }).toList();

      temples.removeWhere((t) => t['status'] == 'rejected');
      
    } catch (e) {
      debugPrint('Error loading temples: $e');
      temples = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate counts safely
    final pendingCount = temples.where((t) => t['status'] == 'pending').length;
    final ongoingCount = temples.where((t) => t['status'] == 'ongoing').length;
    final completedCount = temples.where((t) => t['status'] == 'completed').length;

    return Scaffold(
      backgroundColor: backgroundCream,
      body: Column(
        children: [
          // Header with Search
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryMaroon, Color(0xFF4A1010)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: lightGoldText),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                placeName.isEmpty ? 'Loading...' : placeName,
                                style: const TextStyle(
                                  color: lightGoldText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                districtName.isEmpty ? 'Temple Projects' : '$districtName District',
                                style: const TextStyle(color: primaryAccentGold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    TextField(
                      controller: searchController,
                      onChanged: (val) => setState(() => searchQuery = val),
                      style: const TextStyle(color: darkMaroonText),
                      decoration: InputDecoration(
                        hintText: 'Search Project ID or User ID...',
                        hintStyle: TextStyle(color: darkMaroonText.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: primaryMaroon),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: primaryMaroon),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: softParchment,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Tabs
                    Row(
                      children: [
                        _buildStatusTab('Pending ($pendingCount)', 0),
                        _buildStatusTab('Ongoing ($ongoingCount)', 1),
                        _buildStatusTab('Done ($completedCount)', 2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // List Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryMaroon))
                : currentList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: darkMaroonText.withOpacity(0.3)),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isNotEmpty 
                                  ? 'No matching projects found' 
                                  : 'No projects in this category',
                              style: const TextStyle(fontSize: 16, color: darkMaroonText),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final temple = currentList[index];
                          return _buildTempleCard(temple);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String label, int index) {
    final isActive = statusTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => statusTab = index),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryAccentGold : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? primaryAccentGold : lightGoldText.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? primaryMaroon : lightGoldText,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTempleCard(Map<String, dynamic> temple) {
    // Extra safety: Ensure map keys exist before accessing, though _loadTemples handles this now.
    final projectId = temple['projectId'] ?? 'No ID';
    final userName = temple['userName'] ?? 'Unknown User';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: primaryAccentGold, width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          projectId, // Displaying Project ID
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: darkMaroonText,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              const Icon(Icons.person, size: 14, color: secondaryGold),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userName, // Displaying User Name
                  style: TextStyle(color: darkMaroonText.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: primaryMaroon),
        onTap: () async {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (_) => TempleDetailScreen(
                templeId: temple['id'],
                initialTempleData: temple,
              ),
            ),
          );

          if (result == 'deleted' || result == 'removed') {
            setState(() {
              temples.removeWhere((t) => t['id'] == temple['id']);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Project removed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (result is Map<String, dynamic>) {
            final idx = temples.indexWhere((t) => t['id'] == result['id']);
            if (idx != -1) {
              setState(() {
                temples[idx] = result;
              });
            }
          }
        },
      ),
    );
  }
}