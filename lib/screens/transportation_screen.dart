import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bottom_service.dart';
import '../constants/app_constants.dart';
import '../widgets/bottom_service_dialog.dart';

class TransportationScreen extends StatefulWidget {
  const TransportationScreen({super.key});

  @override
  State<TransportationScreen> createState() => _TransportationScreenState();
}

class _TransportationScreenState extends State<TransportationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BottomService> _services = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransportationServices();
  }

  Future<void> _loadTransportationServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = await _firestore
          .collection(AppConstants.bottomServicesCollection)
          .where('serviceType', isEqualTo: 'transportation')
          .orderBy('displayOrder')
          .get();

      _services = snapshot.docs
          .map((doc) => BottomService.fromFirestore(doc))
          .toList();

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _services = _services.where((service) {
          return service.title.ar.contains(_searchQuery) ||
              service.title.en.contains(_searchQuery);
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'فشل في تحميل خدمات النقل: $e';
      });
    }
  }

  Future<void> _addTransportationService() async {
    final result = await showDialog<BottomService>(
      context: context,
      builder: (context) =>
          const BottomServiceDialog(serviceType: 'transportation'),
    );

    if (result != null) {
      await _loadTransportationServices();
    }
  }

  Future<void> _editService(BottomService service) async {
    final result = await showDialog<BottomService>(
      context: context,
      builder: (context) => BottomServiceDialog(service: service),
    );

    if (result != null) {
      await _loadTransportationServices();
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

        await _loadTransportationServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف خدمة النقل بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف خدمة النقل: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة خدمات النقل'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _loadTransportationServices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

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
                          onPressed: _loadTransportationServices,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _services.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد خدمات نقل',
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
        onPressed: _addTransportationService,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'البحث في خدمات النقل...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _loadTransportationServices();
        },
      ),
    );
  }

  Widget _buildStatistics() {
    final totalServices = _services.length;
    final activeServices = _services.where((s) => s.isActive).length;
    final totalClicks = _services.fold<int>(0, (sum, s) => sum + s.clicks);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الخدمات',
              totalServices.toString(),
              Icons.directions_car,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'الخدمات النشطة',
              activeServices.toString(),
              Icons.check_circle,
              Colors.green,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: service.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.isActive ? 'نشط' : 'غير نشط',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'النقرات: ${service.clicks}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editService(service);
                break;
              case 'delete':
                _deleteService(service);
                break;
              case 'toggle':
                _toggleServiceStatus(service);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            const PopupMenuItem(value: 'toggle', child: Text('تفعيل/إلغاء')),
            const PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleServiceStatus(BottomService service) async {
    try {
      final updatedService = service.copyWith(isActive: !service.isActive);
      await _firestore
          .collection(AppConstants.bottomServicesCollection)
          .doc(service.id)
          .update(updatedService.toFirestore());

      await _loadTransportationServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedService.isActive
                  ? 'تم تفعيل الخدمة'
                  : 'تم إلغاء تفعيل الخدمة',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث حالة الخدمة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      case 'directions_car':
        return Icons.directions_car;
      case 'event':
        return Icons.event;
      case 'newspaper':
        return Icons.newspaper;
      case 'lightbulb_outline':
        return Icons.lightbulb_outline;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }
}
