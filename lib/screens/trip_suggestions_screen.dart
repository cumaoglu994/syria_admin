import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_suggestion.dart';
import '../models/personalized_recommendation.dart';
import '../constants/app_constants.dart';

class TripSuggestionsScreen extends StatefulWidget {
  const TripSuggestionsScreen({super.key});

  @override
  State<TripSuggestionsScreen> createState() => _TripSuggestionsScreenState();
}

class _TripSuggestionsScreenState extends State<TripSuggestionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TripSuggestion> _suggestions = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'
  String _filterTripType = 'all';
  String _sortBy = 'displayOrder'; // 'displayOrder', 'createdAt', 'price'

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Query query = _firestore.collection(
        AppConstants.tripSuggestionsCollection,
      );

      // Apply filters
      if (_filterStatus == 'active') {
        query = query.where('isActive', isEqualTo: true);
      } else if (_filterStatus == 'inactive') {
        query = query.where('isActive', isEqualTo: false);
      }

      if (_filterTripType != 'all') {
        query = query.where('tripType', isEqualTo: _filterTripType);
      }

      // Apply sorting
      switch (_sortBy) {
        case 'createdAt':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'price':
          query = query.orderBy('price.usd', descending: true);
          break;
        default:
          query = query.orderBy('displayOrder', descending: false);
      }

      final snapshot = await query.get();

      _suggestions = snapshot.docs
          .map((doc) => TripSuggestion.fromFirestore(doc))
          .toList();

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _suggestions = _suggestions.where((suggestion) {
          return suggestion.title.ar.contains(_searchQuery) ||
              suggestion.title.en.contains(_searchQuery) ||
              suggestion.cities.any((city) => city.contains(_searchQuery));
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'فشل في تحميل اقتراحات الرحلات: $e';
      });
    }
  }

  Future<void> _addSuggestion() async {
    final result = await showDialog<TripSuggestion>(
      context: context,
      builder: (context) => const TripSuggestionDialog(),
    );

    if (result != null) {
      await _loadSuggestions();
    }
  }

  Future<void> _editSuggestion(TripSuggestion suggestion) async {
    final result = await showDialog<TripSuggestion>(
      context: context,
      builder: (context) => TripSuggestionDialog(suggestion: suggestion),
    );

    if (result != null) {
      await _loadSuggestions();
    }
  }

  Future<void> _deleteSuggestion(TripSuggestion suggestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${suggestion.title.ar}"؟'),
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
            .collection(AppConstants.tripSuggestionsCollection)
            .doc(suggestion.id)
            .delete();

        await _loadSuggestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف اقتراح الرحلة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف اقتراح الرحلة: $e'),
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
        title: const Text('إدارة اقتراحات الرحلات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        actions: [
          IconButton(
            onPressed: _loadSuggestions,
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

          // Suggestions List
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
                          onPressed: _loadSuggestions,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _suggestions.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد اقتراحات رحلات',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorFromString(
                              suggestion.color,
                            ),
                            child: Icon(
                              _getIconFromString(suggestion.icon),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(suggestion.title.ar),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(suggestion.duration.ar),
                              Text(
                                suggestion.cities.join('، '),
                                style: const TextStyle(fontSize: 12),
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
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      suggestion.tripType,
                                      style: TextStyle(
                                        color: Colors.blue[800],
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
                                      color: _getDifficultyColor(
                                        suggestion.difficultyLevel,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      suggestion.difficultyLevel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text('\$${suggestion.price.usd}'),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: suggestion.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      suggestion.isActive ? 'نشط' : 'غير نشط',
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
                                _editSuggestion(suggestion);
                              } else if (value == 'delete') {
                                _deleteSuggestion(suggestion);
                              }
                            },
                          ),
                          onTap: () => _editSuggestion(suggestion),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSuggestion,
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
              hintText: 'ابحث بالعنوان أو المدن',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadSuggestions();
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
                    _loadSuggestions();
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Trip Type Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterTripType,
                  decoration: const InputDecoration(
                    labelText: 'نوع الرحلة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('الكل')),
                    ...TripSuggestionConstants.tripTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterTripType = value!;
                    });
                    _loadSuggestions();
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
                    DropdownMenuItem(value: 'price', child: Text('السعر')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _loadSuggestions();
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
    final totalCount = _suggestions.length;
    final activeCount = _suggestions.where((s) => s.isActive).length;
    final inactiveCount = totalCount - activeCount;
    final avgPrice = _suggestions.isEmpty
        ? 0.0
        : _suggestions.map((s) => s.price.usd).reduce((a, b) => a + b) /
              totalCount;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الاقتراحات',
              totalCount.toString(),
              Icons.route,
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
              'متوسط السعر',
              '\$${avgPrice.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
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
      case 'syrianRed':
        return const Color(0xFFCE1126);
      case 'accentColor':
        return const Color(0xFFFF5722);
      case 'syrianGold':
        return const Color(0xFFD4AF37);
      case 'syrianGreen':
        return const Color(0xFF4CAF50);
      case 'secondaryColor':
        return const Color(0xFF424242);
      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'route':
        return Icons.route;
      case 'castle':
        return Icons.castle;
      case 'beach_access':
        return Icons.beach_access;
      case 'landscape':
        return Icons.landscape;
      case 'museum':
        return Icons.museum;
      case 'mosque':
        return Icons.mosque;
      case 'store':
        return Icons.store;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.route;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'سهل':
        return Colors.green;
      case 'متوسط':
        return Colors.orange;
      case 'صعب':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class TripSuggestionDialog extends StatefulWidget {
  final TripSuggestion? suggestion;

  const TripSuggestionDialog({super.key, this.suggestion});

  @override
  State<TripSuggestionDialog> createState() => _TripSuggestionDialogState();
}

class _TripSuggestionDialogState extends State<TripSuggestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _durationControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};

  List<String> _selectedCities = [];
  String _selectedTripType = TripSuggestionConstants.tripTypes.first;
  String _selectedDifficultyLevel =
      TripSuggestionConstants.difficultyLevels.first;
  String _selectedBestTimeToVisit =
      TripSuggestionConstants.bestTimeToVisit.first;
  String _selectedIcon = 'route';
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
      _durationControllers[lang] = TextEditingController();
      _descriptionControllers[lang] = TextEditingController();
    }

    _priceControllers['syp'] = TextEditingController();
    _priceControllers['usd'] = TextEditingController();
    _priceControllers['eur'] = TextEditingController();

    if (widget.suggestion != null) {
      final suggestion = widget.suggestion!;
      _selectedCities = List.from(suggestion.cities);
      _selectedTripType = suggestion.tripType;
      _selectedDifficultyLevel = suggestion.difficultyLevel;
      _selectedBestTimeToVisit = suggestion.bestTimeToVisit;
      _selectedIcon = suggestion.icon;
      _selectedColor = suggestion.color;
      _displayOrder = suggestion.displayOrder;
      _isActive = suggestion.isActive;

      // Set values for all languages
      for (String lang in RecommendationConstants.supportedLanguages) {
        _titleControllers[lang]!.text = suggestion.title.getText(lang);
        _durationControllers[lang]!.text = suggestion.duration.getText(lang);
        _descriptionControllers[lang]!.text = suggestion.description.getText(
          lang,
        );
      }

      _priceControllers['syp']!.text = suggestion.price.syp.toString();
      _priceControllers['usd']!.text = suggestion.price.usd.toString();
      _priceControllers['eur']!.text = suggestion.price.eur.toString();
    }
  }

  @override
  void dispose() {
    for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    for (var controller in _durationControllers.values) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مدينة واحدة على الأقل'),
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

      final duration = LocalizedText(
        ar: _durationControllers['ar']!.text.trim(),
        en: _durationControllers['en']!.text.trim(),
        tr: _durationControllers['tr']!.text.trim(),
        fr: _durationControllers['fr']!.text.trim(),
        ru: _durationControllers['ru']!.text.trim(),
        zh: _durationControllers['zh']!.text.trim(),
      );

      final description = LocalizedText(
        ar: _descriptionControllers['ar']!.text.trim(),
        en: _descriptionControllers['en']!.text.trim(),
        tr: _descriptionControllers['tr']!.text.trim(),
        fr: _descriptionControllers['fr']!.text.trim(),
        ru: _descriptionControllers['ru']!.text.trim(),
        zh: _descriptionControllers['zh']!.text.trim(),
      );

      final price = TripPrice(
        syp: double.tryParse(_priceControllers['syp']!.text) ?? 0.0,
        usd: double.tryParse(_priceControllers['usd']!.text) ?? 0.0,
        eur: double.tryParse(_priceControllers['eur']!.text) ?? 0.0,
      );

      final suggestion = TripSuggestion(
        id: widget.suggestion?.id ?? '',
        title: title,
        duration: duration,
        description: description,
        cities: _selectedCities,
        tripType: _selectedTripType,
        difficultyLevel: _selectedDifficultyLevel,
        price: price,
        bestTimeToVisit: _selectedBestTimeToVisit,
        icon: _selectedIcon,
        color: _selectedColor,
        displayOrder: _displayOrder,
        isActive: _isActive,
        clicks: widget.suggestion?.clicks ?? 0,
        viewTime: widget.suggestion?.viewTime ?? 0,
        createdAt: widget.suggestion?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.suggestion == null) {
        // Create new suggestion
        await FirebaseFirestore.instance
            .collection(AppConstants.tripSuggestionsCollection)
            .add(suggestion.toFirestore());
      } else {
        // Update existing suggestion
        await FirebaseFirestore.instance
            .collection(AppConstants.tripSuggestionsCollection)
            .doc(widget.suggestion!.id)
            .update(suggestion.toFirestore());
      }

      if (mounted) {
        Navigator.of(context).pop(suggestion);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.suggestion == null
                  ? 'تم إضافة اقتراح الرحلة بنجاح'
                  : 'تم تحديث اقتراح الرحلة بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ اقتراح الرحلة: $e'),
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
              widget.suggestion == null
                  ? 'إضافة اقتراح رحلة جديدة'
                  : 'تعديل اقتراح الرحلة',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
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
                        height: 250,
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

                // Cities Selection
                _buildCitiesSelection(),

                const SizedBox(height: 16),

                // Trip Details
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTripType,
                        decoration: const InputDecoration(
                          labelText: 'نوع الرحلة',
                          border: OutlineInputBorder(),
                        ),
                        items: TripSuggestionConstants.tripTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTripType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDifficultyLevel,
                        decoration: const InputDecoration(
                          labelText: 'مستوى الصعوبة',
                          border: OutlineInputBorder(),
                        ),
                        items: TripSuggestionConstants.difficultyLevels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficultyLevel = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Price and Best Time
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceControllers['usd'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر (دولار)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBestTimeToVisit,
                        decoration: const InputDecoration(
                          labelText: 'أفضل وقت للزيارة',
                          border: OutlineInputBorder(),
                        ),
                        items: TripSuggestionConstants.bestTimeToVisit
                            .map(
                              (time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBestTimeToVisit = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

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
                        items: TripSuggestionConstants.availableIcons
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
                        items: TripSuggestionConstants.availableColors
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
              labelText: 'عنوان الرحلة ($languageName)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال عنوان الرحلة';
              }
              if (value.length > 60) {
                return 'الحد الأقصى 60 حرف';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _durationControllers[languageCode],
            decoration: InputDecoration(
              labelText: 'مدة الرحلة ($languageName)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال مدة الرحلة';
              }
              if (value.length > 40) {
                return 'الحد الأقصى 40 حرف';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionControllers[languageCode],
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'وصف الرحلة ($languageName)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال وصف الرحلة';
              }
              if (value.length > 120) {
                return 'الحد الأقصى 120 حرف';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCitiesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المدن المدرجة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TripSuggestionConstants.syrianCities.map((city) {
            final isSelected = _selectedCities.contains(city);
            return FilterChip(
              label: Text(city),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCities.add(city);
                  } else {
                    _selectedCities.remove(city);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedCities.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'المدن المختارة: ${_selectedCities.join('، ')}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'route':
        return Icons.route;
      case 'castle':
        return Icons.castle;
      case 'beach_access':
        return Icons.beach_access;
      case 'landscape':
        return Icons.landscape;
      case 'museum':
        return Icons.museum;
      case 'mosque':
        return Icons.mosque;
      case 'store':
        return Icons.store;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.route;
    }
  }
}
