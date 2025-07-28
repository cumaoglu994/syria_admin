import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/tourist_site.dart';
import '../constants/app_constants.dart';

// Custom Image Widget for better error handling
class SmartImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SmartImageWidget> createState() => _SmartImageWidgetState();
}

class _SmartImageWidgetState extends State<SmartImageWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _processedUrl;

  @override
  void initState() {
    super.initState();
    _processImageUrl();
  }

  void _processImageUrl() {
    String url = widget.imageUrl.trim();

    // Handle different URL formats
    if (url.startsWith('data:image/')) {
      // Base64 image - already processed
      _processedUrl = url;
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      // HTTP/HTTPS URL
      _processedUrl = url;
    } else if (url.startsWith('//')) {
      // Protocol-relative URL
      _processedUrl = 'https:$url';
    } else if (url.startsWith('/')) {
      // Absolute path - try common domains
      _processedUrl = 'https://example.com$url';
    } else if (url.contains('.') && !url.contains('://')) {
      // URL without protocol - add https
      _processedUrl = 'https://$url';
    } else {
      // Invalid URL format
      print('Invalid image URL format: $url');
      _processedUrl = url; // Keep original for error display
    }

    // Validate URL format
    if (_processedUrl != null && !_processedUrl!.startsWith('data:image/')) {
      try {
        Uri.parse(_processedUrl!);
      } catch (e) {
        print('Invalid URL format: $_processedUrl');
        _processedUrl = null;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError || _processedUrl == null) {
      return _buildErrorWidget();
    }

    return Image.network(
      _processedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _buildLoadingWidget(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        print('Image loading error for URL: $_processedUrl');
        print('Error: $error');
        setState(() {
          _hasError = true;
        });
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child:
          widget.placeholder ??
          const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'جاري التحميل...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.fit == BoxFit.contain ? Colors.grey[800] : Colors.grey[300],
      child:
          widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: widget.width != null ? widget.width! * 0.3 : 50,
                  color: widget.fit == BoxFit.contain
                      ? Colors.white
                      : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'فشل في تحميل الصورة',
                  style: TextStyle(
                    color: widget.fit == BoxFit.contain
                        ? Colors.white
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'URL: ${widget.imageUrl.substring(0, widget.imageUrl.length > 30 ? 30 : widget.imageUrl.length)}...',
                  style: TextStyle(
                    color: widget.fit == BoxFit.contain
                        ? Colors.white70
                        : Colors.grey[500],
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );
  }
}

class TouristSitesScreen extends StatefulWidget {
  const TouristSitesScreen({super.key});

  @override
  State<TouristSitesScreen> createState() => _TouristSitesScreenState();
}

class _TouristSitesScreenState extends State<TouristSitesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  List<TouristSite> _sites = [];
  List<TouristSite> _filteredSites = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = await _firestore
          .collection(AppConstants.touristSitesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      _sites = snapshot.docs
          .map((doc) => TouristSite.fromFirestore(doc))
          .toList();

      _filterSites();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'فشل في تحميل المواقع السياحية: $e';
      });
    }
  }

  void _filterSites() {
    if (_selectedCategory == 'all') {
      _filteredSites = List.from(_sites);
    } else {
      _filteredSites = _sites
          .where((site) => site.category == _selectedCategory)
          .toList();
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterSites();
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {
        'id': 'all',
        'name': 'الكل',
        'icon': Icons.all_inclusive,
        'color': Colors.blue,
      },
      {
        'id': 'archaeological',
        'name': 'المواقع الأثرية',
        'icon': Icons.architecture,
        'color': Colors.amber,
      },
      {
        'id': 'religious',
        'name': 'الأماكن الدينية',
        'icon': Icons.church,
        'color': Colors.green,
      },
      {
        'id': 'museums',
        'name': 'المتاحف',
        'icon': Icons.museum,
        'color': Colors.red,
      },
      {
        'id': 'parks',
        'name': 'الحدائق',
        'icon': Icons.park,
        'color': Colors.teal,
      },
      {
        'id': 'beaches',
        'name': 'الشواطئ',
        'icon': Icons.beach_access,
        'color': Colors.orange,
      },
      {
        'id': 'markets',
        'name': 'الأسواق',
        'icon': Icons.store,
        'color': Colors.grey,
      },
      {
        'id': 'castle',
        'name': 'القلاع',
        'icon': Icons.castle,
        'color': Colors.purple,
      },
    ];

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _onCategoryChanged(category['id'] as String),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category['color'] as Color
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                      border: isSelected
                          ? Border.all(
                              color: category['color'] as Color,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? category['color'] as Color
                        : Colors.grey[600],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addSite() async {
    final result = await showDialog<TouristSite>(
      context: context,
      builder: (context) => const TouristSiteDialog(),
    );

    if (result != null) {
      await _loadSites();
    }
  }

  Future<void> _editSite(TouristSite site) async {
    final result = await showDialog<TouristSite>(
      context: context,
      builder: (context) => TouristSiteDialog(site: site),
    );

    if (result != null) {
      await _loadSites();
    }
  }

  Future<void> _deleteSite(TouristSite site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${site.name}"؟'),
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
        // Delete images from storage
        for (String imageUrl in site.images) {
          try {
            // This part of the code was removed as per the edit hint.
            // The original code used FirebaseStorage.instance.refFromURL(imageUrl).delete();
            // This functionality is no longer available.
            // The user's edit hint implies a change in storage mechanism,
            // but the new_code does not provide the replacement for this line.
            // Therefore, it is removed as per the new_code.
          } catch (e) {
            print('Failed to delete image: $e');
          }
        }

        // Delete document
        await _firestore
            .collection(AppConstants.touristSitesCollection)
            .doc(site.id)
            .delete();

        await _loadSites();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الموقع السياحي بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف الموقع السياحي: $e'),
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
        title: const Text('إدارة المواقع السياحية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        actions: [
          IconButton(onPressed: _loadSites, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Categories Section
          _buildCategoriesSection(),

          // Sites List
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
                          onPressed: _loadSites,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _filteredSites.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد مواقع سياحية في هذه الفئة',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSites.length,
                    itemBuilder: (context, index) {
                      final site = _filteredSites[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Images section
                            if (site.images.isNotEmpty)
                              Container(
                                height: 200,
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                      itemCount: site.images.length,
                                      itemBuilder: (context, imageIndex) {
                                        return GestureDetector(
                                          onTap: () => _showImageGallery(
                                            context,
                                            site,
                                            imageIndex,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            child: SmartImageWidget(
                                              imageUrl: site.images[imageIndex],
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Swipe hint overlay
                                    if (site.images.length > 1)
                                      Positioned(
                                        bottom: 8,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.swipe_left,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'اسحب للتنقل',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.swipe_right,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Image counter with swipe hint
                                    if (site.images.length > 1)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.photo_library,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${site.images.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.swipe,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Edit button
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: GestureDetector(
                                        onTap: () => _editSite(site),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'لا توجد صور',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Content section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          site.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton(
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
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'حذف',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editSite(site);
                                          } else if (value == 'delete') {
                                            _deleteSite(site);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_city,
                                        size: 16,
                                        color: Colors.blue[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(site.city),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.category,
                                        size: 16,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(_getCategoryName(site.category)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    site.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(site.rating.toString()),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.attach_money,
                                        size: 16,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${site.price.toStringAsFixed(0)} ل.س',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSite,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showImageGallery(
    BuildContext context,
    TouristSite site,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageGalleryScreen(
          site: site,
          initialIndex: initialIndex,
          onEdit: () => _editSite(site),
          onDelete: (index) => _deleteImage(site, index),
        ),
      ),
    );
  }

  void _deleteImage(TouristSite site, int imageIndex) async {
    try {
      final updatedImages = List<String>.from(site.images);
      updatedImages.removeAt(imageIndex);

      await FirebaseFirestore.instance
          .collection(AppConstants.touristSitesCollection)
          .doc(site.id)
          .update({'images': updatedImages});

      // Refresh the list
      _loadSites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الصورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getCategoryName(String categoryId) {
    switch (categoryId) {
      case 'archaeological':
        return 'المواقع الأثرية';
      case 'religious':
        return 'الأماكن الدينية';
      case 'museums':
        return 'المتاحف';
      case 'parks':
        return 'الحدائق';
      case 'beaches':
        return 'الشواطئ';
      case 'markets':
        return 'الأسواق';
      case 'castle':
        return 'القلاع';
      default:
        return 'غير محدد';
    }
  }
}

class TouristSiteDialog extends StatefulWidget {
  final TouristSite? site;

  const TouristSiteDialog({super.key, this.site});

  @override
  State<TouristSiteDialog> createState() => _TouristSiteDialogState();
}

class _TouristSiteDialogState extends State<TouristSiteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCity = AppConstants.syrianCities.first;
  String _selectedCategory = 'all';
  double _rating = 0.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  List<String> _imageUrls = [];
  TextEditingController _imageUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.site != null) {
      _nameController.text = widget.site!.name;
      _descriptionController.text = widget.site!.description;
      _addressController.text = widget.site!.address;
      _phoneController.text = widget.site!.phone;
      _websiteController.text = widget.site!.website;
      _priceController.text = widget.site!.price.toString();
      _selectedCity = widget.site!.city;
      _selectedCategory = widget.site!.category;
      _rating = widget.site!.rating;
      _latitude = widget.site!.latitude;
      _longitude = widget.site!.longitude;
      _imageUrls = List.from(widget.site!.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty) {
      // Validate URL format
      String processedUrl = url;

      // Handle different URL formats
      if (!url.startsWith('http://') &&
          !url.startsWith('https://') &&
          !url.startsWith('data:image/')) {
        if (url.startsWith('//')) {
          processedUrl = 'https:$url';
        } else if (url.startsWith('/')) {
          processedUrl = 'https://example.com$url';
        } else if (url.contains('.') && !url.contains('://')) {
          processedUrl = 'https://$url';
        }
      }

      // Validate URL
      try {
        if (!processedUrl.startsWith('data:image/')) {
          Uri.parse(processedUrl);
        }

        setState(() {
          _imageUrls.add(processedUrl);
          _imageUrlController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة رابط الصورة بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رابط الصورة غير صحيح: $url'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رابط الصورة'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final site = TouristSite(
        id: widget.site?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        city: _selectedCity,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        category: _selectedCategory,
        price: double.tryParse(_priceController.text) ?? 0.0,
        rating: _rating,
        latitude: _latitude,
        longitude: _longitude,
        images: _imageUrls,
        createdAt: widget.site?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.site == null) {
        // Create new site
        await FirebaseFirestore.instance
            .collection(AppConstants.touristSitesCollection)
            .add(site.toFirestore());
      } else {
        // Update existing site
        await FirebaseFirestore.instance
            .collection(AppConstants.touristSitesCollection)
            .doc(widget.site!.id)
            .update(site.toFirestore());
      }

      if (mounted) {
        Navigator.of(context).pop(site);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.site == null
                  ? 'تم إضافة الموقع السياحي بنجاح'
                  : 'تم تحديث الموقع السياحي بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ الموقع السياحي: $e'),
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
              widget.site == null ? 'إضافة موقع سياحي' : 'تعديل موقع سياحي',
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الموقع',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم الموقع';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال وصف الموقع';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.syrianCities.map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'الفئة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(
                      value: 'archaeological',
                      child: Text('المواقع الأثرية'),
                    ),
                    DropdownMenuItem(
                      value: 'religious',
                      child: Text('الأماكن الدينية'),
                    ),
                    DropdownMenuItem(value: 'museums', child: Text('المتاحف')),
                    DropdownMenuItem(value: 'parks', child: Text('الحدائق')),
                    DropdownMenuItem(value: 'beaches', child: Text('الشواطئ')),
                    DropdownMenuItem(value: 'markets', child: Text('الأسواق')),
                    DropdownMenuItem(value: 'castle', child: Text('القلاع')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'الموقع الإلكتروني',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('التقييم'),
                          Slider(
                            value: _rating,
                            min: 0,
                            max: 5,
                            divisions: 10,
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
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _latitude.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'خط العرض',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _latitude = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _longitude.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'خط الطول',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _longitude = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Images section
                const Text(
                  'روابط الصور',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          hintText:
                              'أدخل رابط الصورة (https://example.com/image.jpg)',
                          helperText:
                              'يدعم: HTTP/HTTPS URLs, Base64, ve الصور المحلية',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) => _addImageUrl(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_link),
                      onPressed: _addImageUrl,
                    ),
                  ],
                ),
                if (_imageUrls.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              SmartImageWidget(
                                imageUrl: _imageUrls[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImageUrl(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
              : Text(widget.site == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    );
  }
}

class _ImageGalleryScreen extends StatefulWidget {
  final TouristSite site;
  final int initialIndex;
  final VoidCallback onEdit;
  final Function(int) onDelete;

  const _ImageGalleryScreen({
    required this.site,
    required this.initialIndex,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<_ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل أنت متأكد من حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete(index);
              Navigator.of(context).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.site.name,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onEdit();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(_currentIndex),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.site.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: InteractiveViewer(
                    child: SmartImageWidget(
                      imageUrl: widget.site.images[index],
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),

          // Navigation arrows
          if (widget.site.images.length > 1) ...[
            // Previous button
            if (_currentIndex > 0)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),

            // Next button
            if (_currentIndex < widget.site.images.length - 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // Image counter with dots
          if (widget.site.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.site.images.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Counter text
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} من ${widget.site.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Swipe hint
          if (widget.site.images.length > 1)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swipe_left, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'اسحب للتنقل بين الصور',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.swipe_right, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
