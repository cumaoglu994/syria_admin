import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bottom_service.dart';
import '../models/personalized_recommendation.dart';
import '../constants/app_constants.dart';
import '../widgets/bottom_service_dialog.dart';

class BottomServicesScreen extends StatefulWidget {
  const BottomServicesScreen({super.key});

  @override
  State<BottomServicesScreen> createState() => _BottomServicesScreenState();
}

class _BottomServicesScreenState extends State<BottomServicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BottomService> _services = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterServiceType = 'all';
  String _sortBy = 'displayOrder';

  // 8 farklı servis türü
  final List<Map<String, dynamic>> _serviceTypes = [
    {
      'type': 'transportation',
      'title': 'النقل',
      'icon': Icons.directions_car,
      'color': Colors.blue,
      'route': '/transportation',
    },
    {
      'type': 'events',
      'title': 'الأحداث',
      'icon': Icons.event,
      'color': Colors.green,
      'route': '/events',
    },
    {
      'type': 'news',
      'title': 'الأخبار',
      'icon': Icons.newspaper,
      'color': Colors.orange,
      'route': '/news',
    },
    {
      'type': 'opportunities',
      'title': 'الفرص',
      'icon': Icons.lightbulb_outline,
      'color': Colors.purple,
      'route': '/opportunities',
    },
    {
      'type': 'accommodation',
      'title': 'الإقامة',
      'icon': Icons.hotel,
      'color': Colors.amber,
      'route': '/accommodation',
    },
    {
      'type': 'restaurants',
      'title': 'المطاعم',
      'icon': Icons.restaurant,
      'color': Colors.red,
      'route': '/restaurants',
    },
    {
      'type': 'facilities',
      'title': 'المرافق',
      'icon': Icons.local_hospital,
      'color': Colors.teal,
      'route': '/facilities',
    },
    {
      'type': 'announcements',
      'title': 'الإعلانات',
      'icon': Icons.notifications,
      'color': Colors.indigo,
      'route': '/announcements',
    },
  ];

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

      final snapshot = await _firestore
          .collection(AppConstants.bottomServicesCollection)
          .get();

      List<BottomService> allServices = snapshot.docs
          .map((doc) => BottomService.fromFirestore(doc))
          .toList();

      // Filtreleme işlemleri
      List<BottomService> filteredServices = allServices;

      if (_filterStatus == 'active') {
        filteredServices = filteredServices.where((s) => s.isActive).toList();
      } else if (_filterStatus == 'inactive') {
        filteredServices = filteredServices.where((s) => !s.isActive).toList();
      }

      if (_filterServiceType != 'all') {
        filteredServices = filteredServices
            .where((s) => s.serviceType == _filterServiceType)
            .toList();
      }

      if (_searchQuery.isNotEmpty) {
        filteredServices = filteredServices.where((service) {
          return service.title.ar.contains(_searchQuery) ||
              service.title.en.contains(_searchQuery) ||
              service.route.contains(_searchQuery);
        }).toList();
      }

      switch (_sortBy) {
        case 'createdAt':
          filteredServices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'clicks':
          filteredServices.sort((a, b) => b.clicks.compareTo(a.clicks));
          break;
        default:
          filteredServices.sort(
            (a, b) => a.displayOrder.compareTo(b.displayOrder),
          );
      }

      setState(() {
        _services = filteredServices;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading services: $e');
      setState(() {
        _isLoading = false;
        _error = 'فشل في تحميل الخدمات: $e';
      });
    }
  }

  Future<void> _addService() async {
    final result = await showDialog<BottomService>(
      context: context,
      builder: (context) => const BottomServiceDialog(),
    );

    if (result != null) {
      await _loadServices();
    }
  }

  Future<void> _addSampleData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sampleServices = [
        {
          'title': {
            'ar': 'سيارات الأجرة',
            'en': 'Taxis',
            'tr': '',
            'fr': '',
            'ru': '',
            'zh': '',
          },
          'description': {
            'ar': 'خدمات النقل بالسيارات الأجرة',
            'en': 'Taxi transportation services',
            'tr': '',
            'fr': '',
            'ru': '',
            'zh': '',
          },
          'serviceType': 'transportation',
          'route': '/transportation',
          'externalUrl': '',
          'customAction': '',
          'icon': 'directions_car',
          'color': 'blue',
          'displayOrder': 1,
          'isActive': true,
          'clicks': 15,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'title': {
            'ar': 'مهرجان التراث',
            'en': 'Heritage Festival',
            'tr': '',
            'fr': '',
            'ru': '',
            'zh': '',
          },
          'description': {
            'ar': 'مهرجان التراث السوري السنوي',
            'en': 'Annual Syrian Heritage Festival',
            'tr': '',
            'fr': '',
            'ru': '',
            'zh': '',
          },
          'serviceType': 'events',
          'route': '/events',
          'externalUrl': '',
          'customAction': '',
          'icon': 'event',
          'color': 'green',
          'displayOrder': 1,
          'isActive': true,
          'clicks': 25,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'title': {
            'ar': 'أخبار السياحة',
            'en': 'Tourism News',
            'tr': '',
            'fr': '',
            'ru': '',
            'zh': '',
          },
          'description': {
            'ar': 'أحدث أخبار السياحة في سوريا',
            'en': 'Latest tourism news in Syria',
            'tr': '',
            'fr': '',
            'ru': '',
            'zh': '',
          },
          'serviceType': 'news',
          'route': '/news',
          'externalUrl': '',
          'customAction': '',
          'icon': 'newspaper',
          'color': 'orange',
          'displayOrder': 1,
          'isActive': true,
          'clicks': 12,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      for (final serviceData in sampleServices) {
        await _firestore
            .collection(AppConstants.bottomServicesCollection)
            .add(serviceData);
      }

      await _loadServices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة البيانات التجريبية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding sample data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة البيانات التجريبية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الخدمات السفلية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        actions: [
          IconButton(
            onPressed: _addSampleData,
            icon: const Icon(Icons.add_chart),
            tooltip: 'إضافة بيانات تجريبية',
          ),
          IconButton(
            onPressed: _loadServices,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchAndFilterBar(),
            _buildServiceTypesGrid(),
            _buildStatistics(),
            _buildServicesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'البحث',
              hintText: 'ابحث بالعنوان أو المسار',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                    _loadServices();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'displayOrder',
                      child: Text('ترتيب العرض'),
                    ),
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('تاريخ الإنشاء'),
                    ),
                    DropdownMenuItem(
                      value: 'clicks',
                      child: Text('عدد النقرات'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _loadServices();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أنواع الخدمات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _serviceTypes.length,
            itemBuilder: (context, index) {
              final serviceType = _serviceTypes[index];
              return _buildServiceTypeCard(serviceType);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeCard(Map<String, dynamic> serviceType) {
    final servicesCount = _services
        .where((s) => s.serviceType == serviceType['type'])
        .length;
    final activeServicesCount = _services
        .where((s) => s.serviceType == serviceType['type'] && s.isActive)
        .length;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(serviceType['route']);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _filterServiceType == serviceType['type']
                  ? serviceType['color']
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(serviceType['icon'], size: 32, color: serviceType['color']),
              const SizedBox(height: 8),
              Text(
                serviceType['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$activeServicesCount/$servicesCount نشط',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
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
              Icons.list,
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

  Widget _buildServicesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    if (_services.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('لا توجد خدمات', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return Column(
      children: _services.map((service) => _buildServiceCard(service)).toList(),
    );
  }

  Widget _buildServiceCard(BottomService service) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    color: _getServiceTypeColor(service.serviceType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getServiceTypeLabel(service.serviceType),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                // TODO: Implement edit
                break;
              case 'delete':
                // TODO: Implement delete
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            const PopupMenuItem(value: 'delete', child: Text('حذف')),
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

  Color _getServiceTypeColor(String serviceType) {
    switch (serviceType) {
      case 'transportation':
        return Colors.blue;
      case 'events':
        return Colors.green;
      case 'news':
        return Colors.orange;
      case 'opportunities':
        return Colors.purple;
      case 'accommodation':
        return Colors.amber;
      case 'restaurants':
        return Colors.red;
      case 'facilities':
        return Colors.teal;
      case 'announcements':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getServiceTypeLabel(String serviceType) {
    switch (serviceType) {
      case 'transportation':
        return 'النقل';
      case 'events':
        return 'الأحداث';
      case 'news':
        return 'الأخبار';
      case 'opportunities':
        return 'الفرص';
      case 'accommodation':
        return 'الإقامة';
      case 'restaurants':
        return 'المطاعم';
      case 'facilities':
        return 'المرافق';
      case 'announcements':
        return 'الإعلانات';
      default:
        return 'غير محدد';
    }
  }
}
