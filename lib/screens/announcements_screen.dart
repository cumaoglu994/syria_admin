import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bottom_service.dart';
import '../constants/app_constants.dart';
import '../widgets/bottom_service_dialog.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BottomService> _services = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading announcements services from Firebase...');

      final snapshot = await _firestore
          .collection(AppConstants.bottomServicesCollection)
          .where('serviceType', isEqualTo: 'announcements')
          .orderBy('displayOrder')
          .get();

      print('Firebase response: ${snapshot.docs.length} announcements found');

      List<BottomService> allServices = [];

      for (var doc in snapshot.docs) {
        try {
          final service = BottomService.fromFirestore(doc);
          allServices.add(service);
          print('Loaded announcement: ${service.title.ar}');
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        allServices = allServices.where((service) {
          return service.title.ar.contains(_searchQuery) ||
              service.title.en.contains(_searchQuery) ||
              service.route.contains(_searchQuery);
        }).toList();
      }

      setState(() {
        _services = allServices;
        _isLoading = false;
      });

      print(
        'Announcements loaded successfully: ${_services.length} announcements',
      );
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() {
        _isLoading = false;
        _error = 'فشل في تحميل الإعلانات: $e';
      });
    }
  }

  Future<void> _addService() async {
    final result = await showDialog<BottomService>(
      context: context,
      builder: (context) =>
          const BottomServiceDialog(serviceType: 'announcements'),
    );

    if (result != null) {
      await _loadServices();
    }
  }

  Future<void> _editService(BottomService service) async {
    final result = await showDialog<BottomService>(
      context: context,
      builder: (context) => BottomServiceDialog(service: service),
    );

    if (result != null) {
      await _loadServices();
    }
  }

  Future<void> _deleteService(BottomService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${service.title.ar}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection(AppConstants.bottomServicesCollection)
            .doc(service.id)
            .delete();

        await _loadServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الإعلان بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف الإعلان: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleActiveStatus(BottomService service) async {
    try {
      await _firestore
          .collection(AppConstants.bottomServicesCollection)
          .doc(service.id)
          .update({'isActive': !service.isActive});

      await _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service.isActive ? 'تم إلغاء تفعيل الإعلان' : 'تم تفعيل الإعلان',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث حالة الإعلان: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإعلانات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _loadServices,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'البحث في الإعلانات...',
                hintText: 'ابحث بالعنوان أو الوصف',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _loadServices();
              },
            ),
          ),

          // Statistics
          _buildStatistics(),

          // Services List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadServices,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _services.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد إعلانات',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return _buildServiceCard(service);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatistics() {
    final totalAnnouncements = _services.length;
    final activeAnnouncements = _services.where((s) => s.isActive).length;
    final totalClicks = _services.fold<int>(0, (sum, s) => sum + s.clicks);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الإعلانات',
              totalAnnouncements.toString(),
              Icons.announcement,
              Colors.indigo,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'الإعلانات النشطة',
              activeAnnouncements.toString(),
              Icons.check_circle,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'إجمالي النقرات',
              totalClicks.toString(),
              Icons.touch_app,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BottomService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorFromString(service.color),
          child: Icon(_getIconFromString(service.icon), color: Colors.white),
        ),
        title: Text(service.title.ar),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (service.description.ar.isNotEmpty)
              Text(
                service.description.ar,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'النقرات: ${service.clicks}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: service.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.isActive ? 'نشط' : 'غير نشط',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _toggleActiveStatus(service),
              icon: Icon(
                service.isActive ? Icons.visibility : Icons.visibility_off,
                color: service.isActive ? Colors.green : Colors.grey,
              ),
              tooltip: service.isActive ? 'إلغاء التفعيل' : 'تفعيل',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editService(service);
                    break;
                  case 'delete':
                    _deleteService(service);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'amber':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString.toLowerCase()) {
      case 'announcement':
        return Icons.announcement;
      case 'campaign':
        return Icons.campaign;
      case 'notifications':
        return Icons.notifications;
      case 'info':
        return Icons.info;
      default:
        return Icons.announcement;
    }
  }
}
