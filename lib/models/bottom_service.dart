import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'personalized_recommendation.dart';

class BottomService {
  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final String serviceType; // 'internal', 'external', 'custom'
  final String route;
  final String externalUrl;
  final String customAction;
  final String icon;
  final String color;
  final int displayOrder;
  final bool isActive;
  final int clicks;
  final DateTime createdAt;
  final DateTime updatedAt;

  BottomService({
    required this.id,
    required this.title,
    required this.description,
    required this.serviceType,
    required this.route,
    required this.externalUrl,
    required this.customAction,
    required this.icon,
    required this.color,
    required this.displayOrder,
    required this.isActive,
    required this.clicks,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.toMap(),
      'description': description.toMap(),
      'serviceType': serviceType,
      'route': route,
      'externalUrl': externalUrl,
      'customAction': customAction,
      'icon': icon,
      'color': color,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'clicks': clicks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BottomService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BottomService(
      id: doc.id,
      title: LocalizedText.fromMap(data['title'] ?? {}),
      description: LocalizedText.fromMap(data['description'] ?? {}),
      serviceType: data['serviceType'] ?? 'internal',
      route: data['route'] ?? '',
      externalUrl: data['externalUrl'] ?? '',
      customAction: data['customAction'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '',
      displayOrder: data['displayOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      clicks: data['clicks'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  BottomService copyWith({
    String? id,
    LocalizedText? title,
    LocalizedText? description,
    String? serviceType,
    String? route,
    String? externalUrl,
    String? customAction,
    String? icon,
    String? color,
    int? displayOrder,
    bool? isActive,
    int? clicks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BottomService(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      serviceType: serviceType ?? this.serviceType,
      route: route ?? this.route,
      externalUrl: externalUrl ?? this.externalUrl,
      customAction: customAction ?? this.customAction,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      clicks: clicks ?? this.clicks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Constants for bottom services
class BottomServiceConstants {
  static const List<Map<String, String>> availableIcons = [
    {'value': 'directions_car', 'label': 'سيارة', 'icon': 'directions_car'},
    {'value': 'event', 'label': 'حدث', 'icon': 'event'},
    {'value': 'newspaper', 'label': 'صحيفة', 'icon': 'newspaper'},
    {
      'value': 'lightbulb_outline',
      'label': 'فكرة',
      'icon': 'lightbulb_outline',
    },
    {'value': 'hotel', 'label': 'فندق', 'icon': 'hotel'},
    {'value': 'restaurant', 'label': 'مطعم', 'icon': 'restaurant'},
    {'value': 'local_hospital', 'label': 'مستشفى', 'icon': 'local_hospital'},
    {'value': 'notifications', 'label': 'إشعارات', 'icon': 'notifications'},
    {'value': 'map', 'label': 'خريطة', 'icon': 'map'},
    {'value': 'camera_alt', 'label': 'كاميرا', 'icon': 'camera_alt'},
    {'value': 'shopping_cart', 'label': 'تسوق', 'icon': 'shopping_cart'},
    {'value': 'support', 'label': 'دعم', 'icon': 'support'},
    {'value': 'settings', 'label': 'إعدادات', 'icon': 'settings'},
    {'value': 'info', 'label': 'معلومات', 'icon': 'info'},
    {'value': 'contact_support', 'label': 'اتصال', 'icon': 'contact_support'},
  ];

  static const List<Map<String, dynamic>> availableColors = [
    {
      'value': 'primaryColor',
      'label': 'اللون الأساسي',
      'color': Color(0xFF1976D2),
    },
    {
      'value': 'syrianGreen',
      'label': 'الأخضر السوري',
      'color': Color(0xFF4CAF50),
    },
    {
      'value': 'accentColor',
      'label': 'اللون المميز',
      'color': Color(0xFFFF5722),
    },
    {
      'value': 'secondaryColor',
      'label': 'اللون الثانوي',
      'color': Color(0xFF424242),
    },
    {
      'value': 'syrianGold',
      'label': 'الذهبي السوري',
      'color': Color(0xFFD4AF37),
    },
    {
      'value': 'warningColor',
      'label': 'اللون التحذيري',
      'color': Color(0xFFFF9800),
    },
    {
      'value': 'syrianRed',
      'label': 'الأحمر السوري',
      'color': Color(0xFFCE1126),
    },
  ];

  static const List<Map<String, String>> serviceTypes = [
    {'value': 'internal', 'label': 'خدمة داخلية (تطبيق)'},
    {'value': 'external', 'label': 'خدمة خارجية (رابط)'},
    {'value': 'custom', 'label': 'إجراء مخصص'},
  ];

  static const List<String> commonRoutes = [
    '/transportation',
    '/events',
    '/news',
    '/opportunities',
    '/accommodation',
    '/restaurants',
    '/facilities',
    '/announcements',
    '/tourism-sites',
    '/trip-suggestions',
    '/personalized-recommendations',
    '/bookings',
    '/reviews',
    '/contact',
    '/about',
    '/help',
    '/settings',
  ];
}
