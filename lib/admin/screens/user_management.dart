import 'dart:async';
import 'package:keke_fairshare/index.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserManagementService _userService = UserManagementService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  DocumentSnapshot? _lastDocument;
  List<DocumentSnapshot> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _users = [];
        _lastDocument = null;
        _hasMore = true;
      }
    });

    try {
      final snapshot = await _userService.getUsers(
        lastDocument: _lastDocument,
        searchQuery: _searchController.text,
        sortBy: _sortBy,
        descending: _sortDescending,
      );

      setState(() {
        _users.addAll(snapshot);
        _lastDocument = snapshot.isNotEmpty ? snapshot.last : null;
        _hasMore = snapshot.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadUsers();
    }
  }

  Future<void> _showUserDetails(String userId) async {
    final userDetails = await _userService.getUserDetails(userId);
    final userStats = await _userService.getUserStats(userId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailsSheet(
        userDetails: userDetails,
        userStats: userStats,
        onDelete: () async {
          Navigator.pop(context);
          await _confirmAndDeleteUser(userId);
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.deleteUser(userId);
        _loadUsers(refresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4776E6), // Rich blue
                Color(0xFF8E54E9), // Purple
              ],
            ),
          ),
          child: AppBar(
            title: Text(
              'User Management',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color:
                    const Color(0xFF2C3E50), // Dark blue-gray from your scheme
              ),
            ),
            backgroundColor:
                Colors.transparent, // Important for gradient effect
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadUsers(refresh: true),
              child: _buildUserList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4776E6).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF6B7280),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FF),
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                _loadUsers(refresh: true);
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Recent',
                  _sortBy == 'createdAt' && _sortDescending,
                  () => _updateSort('createdAt', true),
                ),
                _buildFilterChip(
                  'Points ↑',
                  _sortBy == 'points' && !_sortDescending,
                  () => _updateSort('points', false),
                ),
                _buildFilterChip(
                  'Points ↓',
                  _sortBy == 'points' && _sortDescending,
                  () => _updateSort('points', true),
                ),
                _buildFilterChip(
                  'Submissions',
                  _sortBy == 'totalSubmissions',
                  () => _updateSort('totalSubmissions', true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: const Color(0xFFF8F9FF),
        selectedColor: const Color(0xFF4776E6),
        labelStyle: GoogleFonts.poppins(
          color: selected ? Colors.white : const Color(0xFF2C3E50),
        ),
      ),
    );
  }

  void _updateSort(String sortBy, bool descending) {
    setState(() {
      _sortBy = sortBy;
      _sortDescending = descending;
    });
    _loadUsers(refresh: true);
  }

  Widget _buildUserList() {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _users.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _users.length) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const SizedBox.shrink();
          }
        }

        final user = _users[index].data() as Map<String, dynamic>;
        final userId = _users[index].id;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFDB300),
              child: Text(
                (user['fullName'] as String).isNotEmpty
                    ? (user['fullName'] as String)[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user['fullName'] ?? 'Unknown',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Phone: ${user['phoneNumber'] ?? 'Not available'}',
              style: GoogleFonts.poppins(),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showUserDetails(userId),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _UserDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> userDetails;
  final Map<String, dynamic> userStats;
  final VoidCallback onDelete;

  const _UserDetailsSheet({
    required this.userDetails,
    required this.userStats,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStats(),
                  const Divider(),
                  _buildSubmissions(),
                  const SizedBox(height: 16),
                  _buildDeleteButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF8E54E9), // Purple from gradient
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF4776E6),
                child: Text(
                  ((userDetails['fullName'] as String?) ?? 'U')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (userDetails['fullName'] as String?) ?? 'Unknown User',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      (userDetails['phoneNumber'] as String?) ?? 'No Phone',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Points', userStats['points']?.toString() ?? '0'),
                  _buildStatItem('Submissions',
                      userStats['totalSubmissions']?.toString() ?? '0'),
                  _buildStatItem('Approved',
                      userStats['ApprovedSubmissions']?.toString() ?? '0'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4776E6),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissions() {
    final submissions = (userDetails['submissions'] as List<dynamic>?) ?? [];

    if (submissions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No submissions yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Recent Submissions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: submissions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final submission = submissions[index] as Map<String, dynamic>;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: submission['status'] == 'Approved'
                    ? Colors.green[100]
                    : submission['status'] == 'Rejected'
                        ? Colors.red[100]
                        : Colors.orange[100],
                child: Icon(
                  submission['status'] == 'Approved'
                      ? Icons.check_circle
                      : submission['status'] == 'Rejected'
                          ? Icons.cancel
                          : Icons.pending,
                  color: submission['status'] == 'Approved'
                      ? Colors.green
                      : submission['status'] == 'Rejected'
                          ? Colors.red
                          : Colors.orange,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    'Points: ${submission['points'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: submission['status'] == 'Approved'
                          ? Colors.green[100]
                          : submission['status'] == 'Rejected'
                              ? Colors.red[100]
                              : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      submission['status']?.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: submission['status'] == 'Approved'
                            ? Colors.green[700]
                            : submission['status'] == 'Rejected'
                                ? Colors.red[700]
                                : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Submitted: ${submission['formattedDate'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: onDelete,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Delete User',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Timer? _debounce;
