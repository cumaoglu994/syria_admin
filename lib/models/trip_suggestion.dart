import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'personalized_recommendation.dart';

class TripPrice {
  final double syp;
  final double usd;
  final double eur;

  TripPrice({required this.syp, required this.usd, required this.eur});

  Map<String, dynamic> toMap() {
    return {'syp': syp, 'usd': usd, 'eur': eur};
  }

  factory TripPrice.fromMap(Map<String, dynamic> map) {
    return TripPrice(
      syp: (map['syp'] ?? 0.0).toDouble(),
      usd: (map['usd'] ?? 0.0).toDouble(),
      eur: (map['eur'] ?? 0.0).toDouble(),
    );
  }
}

class TripSuggestion {
  final String id;
  final LocalizedText title;
  final LocalizedText duration;
  final LocalizedText description;
  final List<String> cities;
  final String tripType;
  final String difficultyLevel;
  final TripPrice price;
  final String bestTimeToVisit;
  final String icon;
  final String color;
  final int displayOrder;
  final bool isActive;
  final int clicks;
  final int viewTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripSuggestion({
    required this.id,
    required this.title,
    required this.duration,
    required this.description,
    required this.cities,
    required this.tripType,
    required this.difficultyLevel,
    required this.price,
    required this.bestTimeToVisit,
    required this.icon,
    required this.color,
    required this.displayOrder,
    required this.isActive,
    required this.clicks,
    required this.viewTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.toMap(),
      'duration': duration.toMap(),
      'description': description.toMap(),
      'cities': cities,
      'tripType': tripType,
      'difficultyLevel': difficultyLevel,
      'price': price.toMap(),
      'bestTimeToVisit': bestTimeToVisit,
      'icon': icon,
      'color': color,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'clicks': clicks,
      'viewTime': viewTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TripSuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripSuggestion(
      id: doc.id,
      title: LocalizedText.fromMap(data['title'] ?? {}),
      duration: LocalizedText.fromMap(data['duration'] ?? {}),
      description: LocalizedText.fromMap(data['description'] ?? {}),
      cities: List<String>.from(data['cities'] ?? []),
      tripType: data['tripType'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? '',
      price: TripPrice.fromMap(data['price'] ?? {}),
      bestTimeToVisit: data['bestTimeToVisit'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '',
      displayOrder: data['displayOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      clicks: data['clicks'] ?? 0,
      viewTime: data['viewTime'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  TripSuggestion copyWith({
    String? id,
    LocalizedText? title,
    LocalizedText? duration,
    LocalizedText? description,
    List<String>? cities,
    String? tripType,
    String? difficultyLevel,
    TripPrice? price,
    String? bestTimeToVisit,
    String? icon,
    String? color,
    int? displayOrder,
    bool? isActive,
    int? clicks,
    int? viewTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripSuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      cities: cities ?? this.cities,
      tripType: tripType ?? this.tripType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      price: price ?? this.price,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      clicks: clicks ?? this.clicks,
      viewTime: viewTime ?? this.viewTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Constants for trip suggestions
class TripSuggestionConstants {
  static const List<Map<String, String>> availableIcons = [
    {'value': 'route', 'label': 'مسار', 'icon': 'route'},
    {'value': 'castle', 'label': 'قلعة', 'icon': 'castle'},
    {'value': 'beach_access', 'label': 'شاطئ', 'icon': 'beach_access'},
    {'value': 'landscape', 'label': 'جبل', 'icon': 'landscape'},
    {'value': 'museum', 'label': 'متحف', 'icon': 'museum'},
    {'value': 'mosque', 'label': 'مسجد', 'icon': 'mosque'},
    {'value': 'store', 'label': 'سوق', 'icon': 'store'},
    {'value': 'restaurant', 'label': 'مطعم', 'icon': 'restaurant'},
    {'value': 'hotel', 'label': 'فندق', 'icon': 'hotel'},
    {'value': 'directions_car', 'label': 'سيارة', 'icon': 'directions_car'},
  ];

  static const List<Map<String, dynamic>> availableColors = [
    {
      'value': 'primaryColor',
      'label': 'اللون الأساسي',
      'color': Color(0xFF1976D2),
    },
    {
      'value': 'syrianRed',
      'label': 'الأحمر السوري',
      'color': Color(0xFFCE1126),
    },
    {
      'value': 'accentColor',
      'label': 'اللون المميز',
      'color': Color(0xFFFF5722),
    },
    {
      'value': 'syrianGold',
      'label': 'الذهبي السوري',
      'color': Color(0xFFD4AF37),
    },
    {
      'value': 'syrianGreen',
      'label': 'الأخضر السوري',
      'color': Color(0xFF4CAF50),
    },
    {
      'value': 'secondaryColor',
      'label': 'اللون الثانوي',
      'color': Color(0xFF424242),
    },
  ];

  static const List<String> tripTypes = [
    'رحلة ثقافية',
    'رحلة تاريخية',
    'رحلة ساحلية',
    'رحلة جبلية',
    'رحلة دينية',
    'رحلة تجارية',
  ];

  static const List<String> difficultyLevels = ['سهل', 'متوسط', 'صعب'];

  static const List<String> bestTimeToVisit = [
    'الربيع (مارس - مايو)',
    'الصيف (يونيو - أغسطس)',
    'الخريف (سبتمبر - نوفمبر)',
    'الشتاء (ديسمبر - فبراير)',
    'على مدار السنة',
  ];

  static const List<String> syrianCities = [
    'دمشق',
    'حلب',
    'تدمر',
    'اللاذقية',
    'حمص',
    'حماة',
    'إدلب',
    'درعا',
    'القنيطرة',
    'الحسكة',
  ];
}
