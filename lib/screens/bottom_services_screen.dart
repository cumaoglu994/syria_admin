import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bottom_service.dart';
import '../models/personalized_recommendation.dart';
import '../constants/app_constants.dart';

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
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'
  String _filterServiceType = 'all';
  String _sortBy = 'displayOrder'; // 'displayOrder', 'createdAt', 'clicks'

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

      Query query = _firestore.collection(
        AppConstants.bottomServicesCollection,
      );

      // Apply filters
      if (_filterStatus == 'active') {
        query = query.where('isActive', isEqualTo: true);
      } else if (_filterStatus == 'inactive') {
        query = query.where('isActive', isEqualTo: false);
      }

      if (_filterServiceType != 'all') {
        query = query.where('serviceType', isEqualTo: _filterServiceType);
      }

      // Apply sorting
      switch (_sortBy) {
        case 'createdAt':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'clicks':
          query = query.orderBy('clicks', descending: true);
          break;
        default:
          query = query.orderBy('displayOrder', descending: false);
      }

      final snapshot = await query.get();

      _services = snapshot.docs
          .map((doc) => BottomService.fromFirestore(doc))
          .toList();

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _services = _services.where((service) {
          return service.title.ar.contains(_searchQuery) ||
              service.title.en.contains(_searchQuery) ||
              service.route.contains(_searchQuery);
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
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
              content: Text('تم حذف الخدمة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف الخدمة: $e'),
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
        title: const Text('إدارة الخدمات السفلية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        actions: [
          IconButton(onPressed: _loadServices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(),

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
                      'لا توجد خدمات',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorFromString(service.color),
                            child: Icon(
                              _getIconFromString(service.icon),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(service.title.ar),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (service.description.ar.isNotEmpty)
                                Text(
                                  service.description.ar,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getServiceTypeColor(
                                        service.serviceType,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getServiceTypeLabel(service.serviceType),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      service.serviceType == 'internal'
                                          ? service.route
                                          : service.serviceType == 'external'
                                          ? service.externalUrl
                                          : service.customAction,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.touch_app,
                                    size: 16,
                                    color: Colors.blue[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${service.clicks}'),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: service.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      service.isActive ? 'نشط' : 'غير نشط',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('تعديل'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'حذف',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editService(service);
                              } else if (value == 'delete') {
                                _deleteService(service);
                              }
                            },
                          ),
                          onTap: () => _editService(service),
                        ),
                      );
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

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
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

          // Filter and Sort Row
          Row(
            children: [
              // Status Filter
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

              // Service Type Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterServiceType,
                  decoration: const InputDecoration(
                    labelText: 'نوع الخدمة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('الكل')),
                    ...BottomServiceConstants.serviceTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label']!),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterServiceType = value!;
                    });
                    _loadServices();
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Sort Dropdown
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

  Widget _buildStatistics() {
    final totalCount = _services.length;
    final activeCount = _services.where((s) => s.isActive).length;
    final inactiveCount = totalCount - activeCount;
    final totalClicks = _services.fold(
      0,
      (sum, service) => sum + service.clicks,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الخدمات',
              totalCount.toString(),
              Icons.list,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'نشط',
              activeCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'غير نشط',
              inactiveCount.toString(),
              Icons.cancel,
              Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'إجمالي النقرات',
              totalClicks.toString(),
              Icons.touch_app,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString) {
      case 'primaryColor':
        return const Color(0xFF1976D2);
      case 'syrianGreen':
        return const Color(0xFF4CAF50);
      case 'accentColor':
        return const Color(0xFFFF5722);
      case 'secondaryColor':
        return const Color(0xFF424242);
      case 'syrianGold':
        return const Color(0xFFD4AF37);
      case 'warningColor':
        return const Color(0xFFFF9800);
      case 'syrianRed':
        return const Color(0xFFCE1126);
      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
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
      case 'map':
        return Icons.map;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'support':
        return Icons.support;
      case 'settings':
        return Icons.settings;
      case 'info':
        return Icons.info;
      case 'contact_support':
        return Icons.contact_support;
      default:
        return Icons.link;
    }
  }

  Color _getServiceTypeColor(String serviceType) {
    switch (serviceType) {
      case 'internal':
        return Colors.blue;
      case 'external':
        return Colors.green;
      case 'custom':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getServiceTypeLabel(String serviceType) {
    switch (serviceType) {
      case 'internal':
        return 'داخلي';
      case 'external':
        return 'خارجي';
      case 'custom':
        return 'مخصص';
      default:
        return 'غير محدد';
    }
  }
}

class BottomServiceDialog extends StatefulWidget {
  final BottomService? service;

  const BottomServiceDialog({super.key, this.service});

  @override
  State<BottomServiceDialog> createState() => _BottomServiceDialogState();
}

class _BottomServiceDialogState extends State<BottomServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};
  final _routeController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _customActionController = TextEditingController();

  String _selectedServiceType = 'internal';
  String _selectedIcon = 'directions_car';
  String _selectedColor = 'primaryColor';
  int _displayOrder = 0;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers for all languages
    for (String lang in RecommendationConstants.supportedLanguages) {
      _titleControllers[lang] = TextEditingController();
      _descriptionControllers[lang] = TextEditingController();
    }

    if (widget.service != null) {
      final service = widget.service!;
      _selectedServiceType = service.serviceType;
      _selectedIcon = service.icon;
      _selectedColor = service.color;
      _displayOrder = service.displayOrder;
      _isActive = service.isActive;
      _routeController.text = service.route;
      _externalUrlController.text = service.externalUrl;
      _customActionController.text = service.customAction;

      // Set values for all languages
      for (String lang in RecommendationConstants.supportedLanguages) {
        _titleControllers[lang]!.text = service.title.getText(lang);
        _descriptionControllers[lang]!.text = service.description.getText(lang);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers.values) {
      controller.dispose();
    }
    _routeController.dispose();
    _externalUrlController.dispose();
    _customActionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate based on service type
    if (_selectedServiceType == 'internal' &&
        _routeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال المسار للخدمة الداخلية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedServiceType == 'external' &&
        _externalUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال الرابط الخارجي'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedServiceType == 'custom' &&
        _customActionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال الإجراء المخصص'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = LocalizedText(
        ar: _titleControllers['ar']!.text.trim(),
        en: _titleControllers['en']!.text.trim(),
        tr: _titleControllers['tr']!.text.trim(),
        fr: _titleControllers['fr']!.text.trim(),
        ru: _titleControllers['ru']!.text.trim(),
        zh: _titleControllers['zh']!.text.trim(),
      );

      final description = LocalizedText(
        ar: _descriptionControllers['ar']!.text.trim(),
        en: _descriptionControllers['en']!.text.trim(),
        tr: _descriptionControllers['tr']!.text.trim(),
        fr: _descriptionControllers['fr']!.text.trim(),
        ru: _descriptionControllers['ru']!.text.trim(),
        zh: _descriptionControllers['zh']!.text.trim(),
      );

      final service = BottomService(
        id: widget.service?.id ?? '',
        title: title,
        description: description,
        serviceType: _selectedServiceType,
        route: _routeController.text.trim(),
        externalUrl: _externalUrlController.text.trim(),
        customAction: _customActionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        displayOrder: _displayOrder,
        isActive: _isActive,
        clicks: widget.service?.clicks ?? 0,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.service == null) {
        // Create new service
        await FirebaseFirestore.instance
            .collection(AppConstants.bottomServicesCollection)
            .add(service.toFirestore());
      } else {
        // Update existing service
        await FirebaseFirestore.instance
            .collection(AppConstants.bottomServicesCollection)
            .doc(widget.service!.id)
            .update(service.toFirestore());
      }

      if (mounted) {
        Navigator.of(context).pop(service);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service == null
                  ? 'تم إضافة الخدمة بنجاح'
                  : 'تم تحديث الخدمة بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ الخدمة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.service == null ? 'إضافة خدمة جديدة' : 'تعديل الخدمة',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language Tabs
                DefaultTabController(
                  length: RecommendationConstants.supportedLanguages.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabs: RecommendationConstants.languageNames
                            .map((name) => Tab(text: name))
                            .toList(),
                      ),
                      SizedBox(
                        height: 200,
                        child: TabBarView(
                          children: RecommendationConstants.supportedLanguages
                              .map((lang) => _buildLanguageForm(lang))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Service Type
                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  decoration: const InputDecoration(
                    labelText: 'نوع الخدمة',
                    border: OutlineInputBorder(),
                  ),
                  items: BottomServiceConstants.serviceTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedServiceType = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Route/URL/Action based on service type
                _buildServiceTypeSpecificField(),

                const SizedBox(height: 16),

                // Icon, Color, and Display Order
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedIcon,
                        decoration: const InputDecoration(
                          labelText: 'الأيقونة',
                          border: OutlineInputBorder(),
                        ),
                        items: BottomServiceConstants.availableIcons
                            .map(
                              (icon) => DropdownMenuItem(
                                value: icon['value'],
                                child: Row(
                                  children: [
                                    Icon(_getIconFromString(icon['value']!)),
                                    const SizedBox(width: 8),
                                    Text(icon['label']!),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIcon = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedColor,
                        decoration: const InputDecoration(
                          labelText: 'اللون',
                          border: OutlineInputBorder(),
                        ),
                        items: BottomServiceConstants.availableColors
                            .map(
                              (color) => DropdownMenuItem<String>(
                                value: color['value'] as String,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: color['color'] as Color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(color['label'] as String),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedColor = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _displayOrder.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ترتيب العرض',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _displayOrder = int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Active Status
                Row(
                  children: [
                    const Text('الحالة:'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value!;
                              });
                            },
                          ),
                          const Text('نشط'),
                          const SizedBox(width: 16),
                          Radio<bool>(
                            value: false,
                            groupValue: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value!;
                              });
                            },
                          ),
                          const Text('غير نشط'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }

  Widget _buildLanguageForm(String languageCode) {
    final languageName =
        RecommendationConstants.languageNames[RecommendationConstants
            .supportedLanguages
            .indexOf(languageCode)];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            languageName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _titleControllers[languageCode],
            decoration: InputDecoration(
              labelText: 'عنوان الخدمة ($languageName)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال عنوان الخدمة';
              }
              if (value.length > 50) {
                return 'الحد الأقصى 50 حرف';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionControllers[languageCode],
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'الوصف ($languageName) - اختياري',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.length > 100) {
                return 'الحد الأقصى 100 حرف';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeSpecificField() {
    switch (_selectedServiceType) {
      case 'internal':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المسار',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _routeController.text.isEmpty
                  ? null
                  : _routeController.text,
              decoration: const InputDecoration(
                labelText: 'اختر مساراً أو أدخل مساراً مخصصاً',
                border: OutlineInputBorder(),
              ),
              items: [
                ...BottomServiceConstants.commonRoutes
                    .map(
                      (route) =>
                          DropdownMenuItem(value: route, child: Text(route)),
                    )
                    .toList(),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Text('مسار مخصص'),
                ),
              ],
              onChanged: (value) {
                if (value == 'custom') {
                  _routeController.text = '';
                } else if (value != null) {
                  _routeController.text = value;
                }
              },
            ),
            if (_routeController.text.isEmpty ||
                !BottomServiceConstants.commonRoutes.contains(
                  _routeController.text,
                ))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: _routeController,
                  decoration: const InputDecoration(
                    labelText: 'المسار المخصص',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: /custom-page',
                  ),
                ),
              ),
          ],
        );
      case 'external':
        return TextFormField(
          controller: _externalUrlController,
          decoration: const InputDecoration(
            labelText: 'الرابط الخارجي',
            border: OutlineInputBorder(),
            hintText: 'https://example.com',
          ),
        );
      case 'custom':
        return TextFormField(
          controller: _customActionController,
          decoration: const InputDecoration(
            labelText: 'الإجراء المخصص',
            border: OutlineInputBorder(),
            hintText: 'مثال: open_settings, show_notifications',
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
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
      case 'map':
        return Icons.map;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'support':
        return Icons.support;
      case 'settings':
        return Icons.settings;
      case 'info':
        return Icons.info;
      case 'contact_support':
        return Icons.contact_support;
      default:
        return Icons.link;
    }
  }
}
