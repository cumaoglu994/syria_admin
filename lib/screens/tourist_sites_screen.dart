import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/tourist_site.dart';
import '../constants/app_constants.dart';

class TouristSitesScreen extends StatefulWidget {
  const TouristSitesScreen({super.key});

  @override
  State<TouristSitesScreen> createState() => _TouristSitesScreenState();
}

class _TouristSitesScreenState extends State<TouristSitesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  List<TouristSite> _sites = [];
  bool _isLoading = true;
  String? _error;

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
      body: _isLoading
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
          : _sites.isEmpty
          ? const Center(
              child: Text(
                'لا توجد مواقع سياحية',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sites.length,
              itemBuilder: (context, index) {
                final site = _sites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: site.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              site.images.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                    title: Text(site.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.city),
                        Text(
                          site.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                              Icons.location_on,
                              size: 16,
                              color: Colors.red[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
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
                              Text('حذف', style: TextStyle(color: Colors.red)),
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
                    onTap: () => _editSite(site),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSite,
        child: const Icon(Icons.add),
      ),
    );
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
  double _rating = 0.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  List<File> _selectedImages = [];
  List<String> _existingImages = [];
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
      _rating = widget.site!.rating;
      _latitude = widget.site!.latitude;
      _longitude = widget.site!.longitude;
      _existingImages = List.from(widget.site!.images);
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

  Future<void> _pickImages() async {
    final List<XFile> images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      if (index < _existingImages.length) {
        _existingImages.removeAt(index);
      } else {
        _selectedImages.removeAt(index - _existingImages.length);
      }
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    for (File image in _selectedImages) {
      try {
        // Convert image to base64
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrls.add('data:image/jpeg;base64,$base64String');
      } catch (e) {
        print('Failed to convert image to base64: $e');
      }
    }

    return imageUrls;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newImageUrls = await _uploadImages();
      final allImages = [..._existingImages, ...newImageUrls];

      final site = TouristSite(
        id: widget.site?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        city: _selectedCity,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        rating: _rating,
        latitude: _latitude,
        longitude: _longitude,
        images: allImages,
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
        width: double.maxFinite,
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
                  'الصور',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Existing images
                if (_existingImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Image.network(
                                _existingImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
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

                // New images
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Image.file(
                                _selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(
                                    _existingImages.length + index,
                                  ),
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

                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('إضافة صور'),
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
