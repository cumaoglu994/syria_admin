import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/personalized_recommendation.dart';
import '../constants/app_constants.dart';

class PersonalizedRecommendationsScreen extends StatefulWidget {
  const PersonalizedRecommendationsScreen({super.key});

  @override
  State<PersonalizedRecommendationsScreen> createState() =>
      _PersonalizedRecommendationsScreenState();
}

class _PersonalizedRecommendationsScreenState
    extends State<PersonalizedRecommendationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PersonalizedRecommendation> _recommendations = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'
  String _sortBy = 'displayOrder'; // 'displayOrder', 'createdAt', 'rating'

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Query query = _firestore.collection(
        AppConstants.personalizedRecommendationsCollection,
      );

      // Apply filters
      if (_filterStatus == 'active') {
        query = query.where('isActive', isEqualTo: true);
      } else if (_filterStatus == 'inactive') {
        query = query.where('isActive', isEqualTo: false);
      }

      // Apply sorting
      switch (_sortBy) {
        case 'createdAt':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'rating':
          query = query.orderBy('rating', descending: true);
          break;
        default:
          query = query.orderBy('displayOrder', descending: false);
      }

      final snapshot = await query.get();

      _recommendations = snapshot.docs
          .map((doc) => PersonalizedRecommendation.fromFirestore(doc))
          .toList();

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _recommendations = _recommendations.where((rec) {
          return rec.title.ar.contains(_searchQuery) ||
              rec.title.en.contains(_searchQuery) ||
              rec.location.ar.contains(_searchQuery) ||
              rec.location.en.contains(_searchQuery);
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'فشل في تحميل التوصيات: $e';
      });
    }
  }

  Future<void> _addRecommendation() async {
    final result = await showDialog<PersonalizedRecommendation>(
      context: context,
      builder: (context) => const RecommendationDialog(),
    );

    if (result != null) {
      await _loadRecommendations();
    }
  }

  Future<void> _editRecommendation(
    PersonalizedRecommendation recommendation,
  ) async {
    final result = await showDialog<PersonalizedRecommendation>(
      context: context,
      builder: (context) =>
          RecommendationDialog(recommendation: recommendation),
    );

    if (result != null) {
      await _loadRecommendations();
    }
  }

  Future<void> _deleteRecommendation(
    PersonalizedRecommendation recommendation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${recommendation.title.ar}"؟'),
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
            .collection(AppConstants.personalizedRecommendationsCollection)
            .doc(recommendation.id)
            .delete();

        await _loadRecommendations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف التوصية بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف التوصية: $e'),
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
        title: const Text('إدارة التوصيات الشخصية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        actions: [
          IconButton(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(),

          // Statistics
          _buildStatistics(),

          // Recommendations List
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
                          onPressed: _loadRecommendations,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _recommendations.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد توصيات',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      final recommendation = _recommendations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorFromString(
                              recommendation.color,
                            ),
                            child: Icon(
                              _getIconFromString(recommendation.icon),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(recommendation.title.ar),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(recommendation.location.ar),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(recommendation.rating.toString()),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.sort,
                                    size: 16,
                                    color: Colors.blue[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${recommendation.displayOrder}'),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: recommendation.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      recommendation.isActive
                                          ? 'نشط'
                                          : 'غير نشط',
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
                                _editRecommendation(recommendation);
                              } else if (value == 'delete') {
                                _deleteRecommendation(recommendation);
                              }
                            },
                          ),
                          onTap: () => _editRecommendation(recommendation),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecommendation,
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
              hintText: 'ابحث بالعنوان أو الموقع',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadRecommendations();
            },
          ),
          const SizedBox(height: 16),

          // Filter and Sort Row
          Row(
            children: [
              // Filter Dropdown
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
                    _loadRecommendations();
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
                    DropdownMenuItem(value: 'rating', child: Text('التقييم')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _loadRecommendations();
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
    final totalCount = _recommendations.length;
    final activeCount = _recommendations.where((r) => r.isActive).length;
    final inactiveCount = totalCount - activeCount;
    final avgRating = _recommendations.isEmpty
        ? 0.0
        : _recommendations.map((r) => r.rating).reduce((a, b) => a + b) /
              totalCount;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي التوصيات',
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
              'متوسط التقييم',
              avgRating.toStringAsFixed(1),
              Icons.star,
              Colors.amber,
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
      case 'syrianGold':
        return const Color(0xFFD4AF37);
      case 'syrianRed':
        return const Color(0xFFCE1126);
      case 'primaryColor':
        return const Color(0xFF1976D2);
      case 'secondaryColor':
        return const Color(0xFF424242);
      case 'accentColor':
        return const Color(0xFFFF5722);
      case 'syrianGreen':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'mosque':
        return Icons.mosque;
      case 'castle':
        return Icons.castle;
      case 'landscape':
        return Icons.landscape;
      case 'museum':
        return Icons.museum;
      case 'park':
        return Icons.park;
      case 'beach_access':
        return Icons.beach_access;
      case 'store':
        return Icons.store;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'route':
        return Icons.route;
      default:
        return Icons.place;
    }
  }
}

class RecommendationDialog extends StatefulWidget {
  final PersonalizedRecommendation? recommendation;

  const RecommendationDialog({super.key, this.recommendation});

  @override
  State<RecommendationDialog> createState() => _RecommendationDialogState();
}

class _RecommendationDialogState extends State<RecommendationDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _locationControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};

  String _selectedIcon = 'mosque';
  String _selectedColor = 'primaryColor';
  double _rating = 4.0;
  int _displayOrder = 0;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers for all languages
    for (String lang in RecommendationConstants.supportedLanguages) {
      _titleControllers[lang] = TextEditingController();
      _locationControllers[lang] = TextEditingController();
      _descriptionControllers[lang] = TextEditingController();
    }

    if (widget.recommendation != null) {
      final rec = widget.recommendation!;
      _selectedIcon = rec.icon;
      _selectedColor = rec.color;
      _rating = rec.rating;
      _displayOrder = rec.displayOrder;
      _isActive = rec.isActive;

      // Set values for all languages
      for (String lang in RecommendationConstants.supportedLanguages) {
        _titleControllers[lang]!.text = rec.title.getText(lang);
        _locationControllers[lang]!.text = rec.location.getText(lang);
        _descriptionControllers[lang]!.text = rec.description.getText(lang);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    for (var controller in _locationControllers.values) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

      final location = LocalizedText(
        ar: _locationControllers['ar']!.text.trim(),
        en: _locationControllers['en']!.text.trim(),
        tr: _locationControllers['tr']!.text.trim(),
        fr: _locationControllers['fr']!.text.trim(),
        ru: _locationControllers['ru']!.text.trim(),
        zh: _locationControllers['zh']!.text.trim(),
      );

      final description = LocalizedText(
        ar: _descriptionControllers['ar']!.text.trim(),
        en: _descriptionControllers['en']!.text.trim(),
        tr: _descriptionControllers['tr']!.text.trim(),
        fr: _descriptionControllers['fr']!.text.trim(),
        ru: _descriptionControllers['ru']!.text.trim(),
        zh: _descriptionControllers['zh']!.text.trim(),
      );

      final recommendation = PersonalizedRecommendation(
        id: widget.recommendation?.id ?? '',
        title: title,
        location: location,
        description: description,
        icon: _selectedIcon,
        color: _selectedColor,
        rating: _rating,
        displayOrder: _displayOrder,
        isActive: _isActive,
        createdAt: widget.recommendation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.recommendation == null) {
        // Create new recommendation
        await FirebaseFirestore.instance
            .collection(AppConstants.personalizedRecommendationsCollection)
            .add(recommendation.toFirestore());
      } else {
        // Update existing recommendation
        await FirebaseFirestore.instance
            .collection(AppConstants.personalizedRecommendationsCollection)
            .doc(widget.recommendation!.id)
            .update(recommendation.toFirestore());
      }

      if (mounted) {
        Navigator.of(context).pop(recommendation);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.recommendation == null
                  ? 'تم إضافة التوصية بنجاح'
                  : 'تم تحديث التوصية بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ التوصية: $e'),
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
              widget.recommendation == null
                  ? 'إضافة توصية جديدة'
                  : 'تعديل التوصية',
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
                        height: 300,
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

                // Icon and Color Selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedIcon,
                        decoration: const InputDecoration(
                          labelText: 'الأيقونة',
                          border: OutlineInputBorder(),
                        ),
                        items: RecommendationConstants.availableIcons
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
                        items: RecommendationConstants.availableColors
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
                  ],
                ),

                const SizedBox(height: 16),

                // Rating and Display Order
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('التقييم'),
                          Slider(
                            value: _rating,
                            min: 1.0,
                            max: 5.0,
                            divisions: 40,
                            label: _rating.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() {
                                _rating = value;
                              });
                            },
                          ),
                        ],
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
              labelText: 'العنوان ($languageName)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال العنوان';
              }
              if (value.length > 50) {
                return 'الحد الأقصى 50 حرف';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _locationControllers[languageCode],
            decoration: InputDecoration(
              labelText: 'الموقع ($languageName)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال الموقع';
              }
              if (value.length > 30) {
                return 'الحد الأقصى 30 حرف';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionControllers[languageCode],
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'الوصف ($languageName)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال الوصف';
              }
              if (value.length > 100) {
                return 'الحد الأقصى 100 حرف';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'mosque':
        return Icons.mosque;
      case 'castle':
        return Icons.castle;
      case 'landscape':
        return Icons.landscape;
      case 'museum':
        return Icons.museum;
      case 'park':
        return Icons.park;
      case 'beach_access':
        return Icons.beach_access;
      case 'store':
        return Icons.store;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'route':
        return Icons.route;
      default:
        return Icons.place;
    }
  }
}
