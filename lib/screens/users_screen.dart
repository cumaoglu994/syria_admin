import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final users = await _firebaseService.getUsers();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch =
          user.displayName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true ||
          user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
              true;
      final matchesRole = _selectedRole == 'all' || user.role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddUserDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'البحث عن مستخدم...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: 'all',
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('جميع الأدوار')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير')),
                    DropdownMenuItem(value: 'moderator', child: Text('مشرف')),
                    DropdownMenuItem(value: 'user', child: Text('مستخدم')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'لا يوجد مستخدمين',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(
                              user.role.toString().split('.').last,
                            ),
                            child: Text(
                              user.displayName?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(user.displayName ?? 'مستخدم'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(
                                        user.role.toString().split('.').last,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.getRoleName('ar'),
                                      style: TextStyle(
                                        color: _getRoleColor(
                                          user.role.toString().split('.').last,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.getStatusName('ar'),
                                      style: TextStyle(
                                        color: user.isActive
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleUserAction(value, user),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('تعديل'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                              const PopupMenuItem(
                                value: 'block',
                                child: Text('حظر'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'moderator':
        return 'مشرف';
      case 'user':
        return 'مستخدم';
      default:
        return 'غير محدد';
    }
  }

  void _handleUserAction(String action, User user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
      case 'block':
        _showBlockUserDialog(user);
        break;
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مستخدم جديد'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'الاسم')),
            TextField(
              decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'كلمة المرور'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إضافة المستخدم بنجاح')),
              );
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المستخدم'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'الاسم')),
            TextField(
              decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث المستخدم بنجاح')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text(
          'هل أنت متأكد من حذف المستخدم ${user.displayName ?? 'مستخدم'}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: Text(
          'هل أنت متأكد من حظر المستخدم ${user.displayName ?? 'مستخدم'}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حظر المستخدم بنجاح')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('حظر'),
          ),
        ],
      ),
    );
  }
}
