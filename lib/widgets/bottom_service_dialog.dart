import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bottom_service.dart';
import '../models/personalized_recommendation.dart';
import '../constants/app_constants.dart';

class BottomServiceDialog extends StatefulWidget {
  final BottomService? service;
  final String? serviceType;

  const BottomServiceDialog({super.key, this.service, this.serviceType});

  @override
  State<BottomServiceDialog> createState() => _BottomServiceDialogState();
}

class _BottomServiceDialogState extends State<BottomServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleArController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _routeController = TextEditingController();
  final _iconController = TextEditingController();
  final _colorController = TextEditingController();
  final _displayOrderController = TextEditingController();

  String _selectedServiceType = '';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.service != null) {
      // Edit mode
      final service = widget.service!;
      _titleArController.text = service.title.ar;
      _titleEnController.text = service.title.en;
      _descriptionArController.text = service.description.ar;
      _descriptionEnController.text = service.description.en;
      _routeController.text = service.route;
      _iconController.text = service.icon;
      _colorController.text = service.color;
      _displayOrderController.text = service.displayOrder.toString();
      _selectedServiceType = service.serviceType;
      _isActive = service.isActive;
    } else {
      // Add mode
      _selectedServiceType = widget.serviceType ?? 'transportation';
      _displayOrderController.text = '1';
      _iconController.text = 'directions_car';
      _colorController.text = 'blue';
    }
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _routeController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final serviceData = {
        'title': {
          'ar': _titleArController.text.trim(),
          'en': _titleEnController.text.trim(),
        },
        'description': {
          'ar': _descriptionArController.text.trim(),
          'en': _descriptionEnController.text.trim(),
        },
        'route': _routeController.text.trim(),
        'icon': _iconController.text.trim(),
        'color': _colorController.text.trim(),
        'serviceType': _selectedServiceType,
        'displayOrder': int.tryParse(_displayOrderController.text) ?? 1,
        'isActive': _isActive,
        'clicks': widget.service?.clicks ?? 0,
        'createdAt': widget.service?.createdAt ?? Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      if (widget.service != null) {
        // Update existing service
        await FirebaseFirestore.instance
            .collection(AppConstants.bottomServicesCollection)
            .doc(widget.service!.id)
            .update(serviceData);
      } else {
        // Add new service
        await FirebaseFirestore.instance
            .collection(AppConstants.bottomServicesCollection)
            .add(serviceData);
      }

      if (mounted) {
        Navigator.of(context).pop(
          widget.service?.copyWith(
                title: LocalizedText(
                  ar: _titleArController.text.trim(),
                  en: _titleEnController.text.trim(),
                  tr: '',
                  fr: '',
                  ru: '',
                  zh: '',
                ),
                description: LocalizedText(
                  ar: _descriptionArController.text.trim(),
                  en: _descriptionEnController.text.trim(),
                  tr: '',
                  fr: '',
                  ru: '',
                  zh: '',
                ),
                route: _routeController.text.trim(),
                icon: _iconController.text.trim(),
                color: _colorController.text.trim(),
                serviceType: _selectedServiceType,
                displayOrder: int.tryParse(_displayOrderController.text) ?? 1,
                isActive: _isActive,
              ) ??
              BottomService(
                id: '',
                title: LocalizedText(
                  ar: _titleArController.text.trim(),
                  en: _titleEnController.text.trim(),
                  tr: '',
                  fr: '',
                  ru: '',
                  zh: '',
                ),
                description: LocalizedText(
                  ar: _descriptionArController.text.trim(),
                  en: _descriptionEnController.text.trim(),
                  tr: '',
                  fr: '',
                  ru: '',
                  zh: '',
                ),
                route: _routeController.text.trim(),
                externalUrl: '',
                customAction: '',
                icon: _iconController.text.trim(),
                color: _colorController.text.trim(),
                serviceType: _selectedServiceType,
                displayOrder: int.tryParse(_displayOrderController.text) ?? 1,
                isActive: _isActive,
                clicks: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service != null ? 'تعديل الخدمة' : 'إضافة خدمة جديدة'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service Type
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'نوع الخدمة',
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                      {'type': 'transportation', 'title': 'النقل'},
                      {'type': 'events', 'title': 'الأحداث'},
                      {'type': 'news', 'title': 'الأخبار'},
                      {'type': 'opportunities', 'title': 'الفرص'},
                      {'type': 'accommodation', 'title': 'الإقامة'},
                      {'type': 'restaurants', 'title': 'المطاعم'},
                      {'type': 'facilities', 'title': 'المرافق'},
                      {'type': 'announcements', 'title': 'الإعلانات'},
                    ].map((item) {
                      return DropdownMenuItem(
                        value: item['type'],
                        child: Text(item['title']!),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى اختيار نوع الخدمة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title Arabic
              TextFormField(
                controller: _titleArController,
                decoration: const InputDecoration(
                  labelText: 'العنوان (عربي)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال العنوان بالعربية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title English
              TextFormField(
                controller: _titleEnController,
                decoration: const InputDecoration(
                  labelText: 'العنوان (إنجليزي)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال العنوان بالإنجليزية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Arabic
              TextFormField(
                controller: _descriptionArController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (عربي)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Description English
              TextFormField(
                controller: _descriptionEnController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (إنجليزي)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Route
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(
                  labelText: 'المسار',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال المسار';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Icon
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(
                  labelText: 'الأيقونة',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال الأيقونة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'اللون',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اللون';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Display Order
              TextFormField(
                controller: _displayOrderController,
                decoration: const InputDecoration(
                  labelText: 'ترتيب العرض',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال ترتيب العرض';
                  }
                  if (int.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Is Active
              SwitchListTile(
                title: const Text('نشط'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveService,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.service != null ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }
}
