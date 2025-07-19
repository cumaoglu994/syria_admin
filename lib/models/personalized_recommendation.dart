import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocalizedText {
  final String ar;
  final String en;
  final String tr;
  final String fr;
  final String ru;
  final String zh;

  LocalizedText({
    required this.ar,
    required this.en,
    required this.tr,
    required this.fr,
    required this.ru,
    required this.zh,
  });

  Map<String, dynamic> toMap() {
    return {'ar': ar, 'en': en, 'tr': tr, 'fr': fr, 'ru': ru, 'zh': zh};
  }

  factory LocalizedText.fromMap(Map<String, dynamic> map) {
    return LocalizedText(
      ar: map['ar'] ?? '',
      en: map['en'] ?? '',
      tr: map['tr'] ?? '',
      fr: map['fr'] ?? '',
      ru: map['ru'] ?? '',
      zh: map['zh'] ?? '',
    );
  }

  String getText(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return ar;
      case 'en':
        return en;
      case 'tr':
        return tr;
      case 'fr':
        return fr;
      case 'ru':
        return ru;
      case 'zh':
        return zh;
      default:
        return ar; // Default to Arabic
    }
  }
}

class PersonalizedRecommendation {
  final String id;
  final LocalizedText title;
  final LocalizedText location;
  final LocalizedText description;
  final String icon;
  final String color;
  final double rating;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalizedRecommendation({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.icon,
    required this.color,
    required this.rating,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.toMap(),
      'location': location.toMap(),
      'description': description.toMap(),
      'icon': icon,
      'color': color,
      'rating': rating,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PersonalizedRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonalizedRecommendation(
      id: doc.id,
      title: LocalizedText.fromMap(data['title'] ?? {}),
      location: LocalizedText.fromMap(data['location'] ?? {}),
      description: LocalizedText.fromMap(data['description'] ?? {}),
      icon: data['icon'] ?? '',
      color: data['color'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      displayOrder: data['displayOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  PersonalizedRecommendation copyWith({
    String? id,
    LocalizedText? title,
    LocalizedText? location,
    LocalizedText? description,
    String? icon,
    String? color,
    double? rating,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalizedRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      rating: rating ?? this.rating,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Constants for icons and colors
class RecommendationConstants {
  static const List<Map<String, String>> availableIcons = [
    {'value': 'mosque', 'label': 'مسجد', 'icon': 'mosque'},
    {'value': 'castle', 'label': 'قلعة', 'icon': 'castle'},
    {'value': 'landscape', 'label': 'منظر طبيعي', 'icon': 'landscape'},
    {'value': 'museum', 'label': 'متحف', 'icon': 'museum'},
    {'value': 'park', 'label': 'حديقة', 'icon': 'park'},
    {'value': 'beach_access', 'label': 'شاطئ', 'icon': 'beach_access'},
    {'value': 'store', 'label': 'سوق', 'icon': 'store'},
    {'value': 'restaurant', 'label': 'مطعم', 'icon': 'restaurant'},
    {'value': 'hotel', 'label': 'فندق', 'icon': 'hotel'},
    {'value': 'route', 'label': 'مسار', 'icon': 'route'},
  ];

  static const List<Map<String, dynamic>> availableColors = [
    {
      'value': 'syrianGold',
      'label': 'الذهبي السوري',
      'color': Color(0xFFD4AF37),
    },
    {
      'value': 'syrianRed',
      'label': 'الأحمر السوري',
      'color': Color(0xFFCE1126),
    },
    {
      'value': 'primaryColor',
      'label': 'اللون الأساسي',
      'color': Color(0xFF1976D2),
    },
    {
      'value': 'secondaryColor',
      'label': 'اللون الثانوي',
      'color': Color(0xFF424242),
    },
    {
      'value': 'accentColor',
      'label': 'اللون المميز',
      'color': Color(0xFFFF5722),
    },
    {
      'value': 'syrianGreen',
      'label': 'الأخضر السوري',
      'color': Color(0xFF4CAF50),
    },
  ];

  static const List<String> supportedLanguages = [
    'ar',
    'en',
    'tr',
    'fr',
    'ru',
    'zh',
  ];
  static const List<String> languageNames = [
    'العربية',
    'English',
    'Türkçe',
    'Français',
    'Русский',
    '中文',
  ];
}
