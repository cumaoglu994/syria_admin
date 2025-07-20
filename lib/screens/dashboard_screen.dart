import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final analyticsData = await _firebaseService.getAnalyticsData();

      setState(() {
        _analyticsData = analyticsData;
        _recentActivity = List<Map<String, dynamic>>.from(
          analyticsData['recentActivity'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(),

          // Main Content
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'لوحة التحكم',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1976D2),
      elevation: 0,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: [
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Show notifications
          },
        ),

        // User Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle),
          onSelected: (value) {
            _handleUserMenuSelection(value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('الملف الشخصي'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('الإعدادات'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('تسجيل الخروج'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // User Info
          _buildUserInfo(),

          // Navigation Menu
          Expanded(child: _buildNavigationMenu()),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userData;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF1976D2),
                child: user?.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profileImage!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'مستخدم',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      user?.getRoleName('ar') ?? 'مستخدم',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationMenu() {
    final menuItems = [
      {'title': 'الرئيسية', 'icon': Icons.dashboard, 'route': '/dashboard'},
      {
        'title': 'المواقع السياحية',
        'icon': Icons.location_on,
        'route': '/sites',
      },
      {'title': 'الأحداث', 'icon': Icons.event, 'route': '/events'},
      {'title': 'المستخدمين', 'icon': Icons.people, 'route': '/users'},
      {
        'title': 'التوصيات الشخصية',
        'icon': Icons.recommend,
        'route': '/recommendations',
      },
      {
        'title': 'اقتراحات الرحلات',
        'icon': Icons.route,
        'route': '/trip-suggestions',
      },
      {'title': 'الخدمات ', 'icon': Icons.list, 'route': '/bottom-services'},
      {'title': 'الحجوزات', 'icon': Icons.book_online, 'route': '/bookings'},
      {'title': 'المراجعات', 'icon': Icons.rate_review, 'route': '/reviews'},
      {
        'title': 'الإعلانات',
        'icon': Icons.announcement,
        'route': '/announcements',
      },
      {'title': 'المحتوى', 'icon': Icons.article, 'route': '/content'},

      {'title': 'الإحصائيات', 'icon': Icons.analytics, 'route': '/analytics'},
      {'title': 'الإعدادات', 'icon': Icons.settings, 'route': '/settings'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isSelected = _selectedIndex == index;

        return ListTile(
          leading: Icon(
            item['icon'] as IconData,
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade600,
          ),
          title: Text(
            item['title'] as String,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF1976D2)
                  : Colors.grey.shade800,
            ),
          ),
          selected: isSelected,
          selectedTileColor: const Color(0xFF1976D2).withOpacity(0.1),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            _navigateToRoute(item['route'] as String);
          },
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            _buildWelcomeMessage(),
            const SizedBox(height: 24),

            // Statistics Cards
            _buildStatisticsCards(),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userData;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، ${user?.displayName ?? 'مستخدم'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً بك في لوحة إدارة التراث السوري',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.waving_hand, size: 48, color: Colors.white),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = [
      {
        'title': 'المواقع السياحية',
        'value': '${_analyticsData['totalSites'] ?? 0}',
        'icon': Icons.location_on,
        'color': Colors.blue,
        'change': '+12%',
        'changeColor': Colors.green,
      },
      {
        'title': 'الأحداث النشطة',
        'value': '${_analyticsData['totalEvents'] ?? 0}',
        'icon': Icons.event,
        'color': Colors.orange,
        'change': '+5%',
        'changeColor': Colors.green,
      },
      {
        'title': 'المستخدمين النشطين',
        'value': '${_analyticsData['totalUsers'] ?? 0}',
        'icon': Icons.people,
        'color': Colors.green,
        'change': '+8%',
        'changeColor': Colors.green,
      },
      {
        'title': 'التوصيات',
        'value': '${_analyticsData['totalRecommendations'] ?? 0}',
        'icon': Icons.recommend,
        'color': Colors.purple,
        'change': '+15%',
        'changeColor': Colors.green,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(stat);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: (stat['color'] as Color).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and change indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 24,
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: (stat['changeColor'] as Color).withOpacity(0.15),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(
              //       color: (stat['changeColor'] as Color).withOpacity(0.3),
              //       width: 1,
              //     ),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(
              //         Icons.trending_up,
              //         size: 12,
              //         color: stat['changeColor'] as Color,
              //       ),
              //       const SizedBox(width: 2),
              //       Text(
              //         stat['change'] as String,
              //         style: TextStyle(
              //           color: stat['changeColor'] as Color,
              //           fontSize: 11,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  height: 1.1,
                ),
              ),
            ],
          ),

          // Value
          const SizedBox(height: 16),

          // Title
          Text(
            stat['title'] as String,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Progress indicator
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.7, // 70% progress
              child: Container(
                decoration: BoxDecoration(
                  color: stat['color'] as Color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'إضافة موقع جديد',
        'icon': Icons.add_location,
        'color': Colors.blue,
        'route': '/sites',
      },
      {
        'title': 'إنشاء حدث',
        'icon': Icons.event,
        'color': Colors.orange,
        'route': '/events',
      },
      {
        'title': 'التوصيات',
        'icon': Icons.recommend,
        'color': Colors.green,
        'route': '/recommendations',
      },
      {
        'title': 'إدارة المستخدمين',
        'icon': Icons.people_alt,
        'color': Colors.purple,
        'route': '/users',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return InkWell(
      onTap: () {
        _navigateToRoute(action['route'] as String);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: (action['color'] as Color).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                action['icon'] as IconData,
                color: action['color'] as Color,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              action['title'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'انقر للوصول',
                style: TextStyle(
                  fontSize: 10,
                  color: action['color'] as Color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'النشاط الأخير',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _recentActivity.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لا يوجد نشاط حديث',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: _recentActivity.take(5).map((activity) {
                    return _buildActivityItem(
                      activity['title'] as String,
                      _formatTime(activity['time'] as DateTime),
                      _getActivityIcon(activity['icon'] as String),
                      _getActivityColor(activity['color'] as String),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleUserMenuSelection(String value) {
    switch (value) {
      case 'profile':
        // TODO: Navigate to profile
        break;
      case 'settings':
        // TODO: Navigate to settings
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _navigateToRoute(String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return 'منذ ${difference.inDays ~/ 7} أسبوع';
    }
  }

  IconData _getActivityIcon(String icon) {
    switch (icon) {
      case 'add_location':
        return Icons.add_location;
      case 'event':
        return Icons.event;
      case 'person_add':
        return Icons.person_add;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String color) {
    switch (color) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
