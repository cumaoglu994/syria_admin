import 'package:cloud_firestore/cloud_firestore.dart';

enum SiteCategory {
  archaeological, // أثري
  religious, // ديني
  museum, // متحف
  park, // حديقة
  beach, // شاطئ
  market, // سوق
  castle, // قلعة
}

enum SiteStatus {
  active, // نشط
  inactive, // غير نشط
}

class TouristSite {
  final String id;
  final Map<String, String> name; // متعدد اللغات
  final Map<String, String> description; // متعدد اللغات
  final SiteCategory category;
  final String city;
  final double latitude;
  final double longitude;
  final String workingHours;
  final double? entryFee;
  final List<String> images;
  final double defaultRating;
  final SiteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  TouristSite({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.workingHours,
    this.entryFee,
    required this.images,
    this.defaultRating = 0.0,
    this.status = SiteStatus.active,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory TouristSite.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TouristSite(
      id: doc.id,
      name: Map<String, String>.from(data['name'] ?? {}),
      description: Map<String, String>.from(data['description'] ?? {}),
      category: SiteCategory.values.firstWhere(
        (e) => e.toString() == 'SiteCategory.${data['category']}',
        orElse: () => SiteCategory.archaeological,
      ),
      city: data['city'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      workingHours: data['workingHours'] ?? '',
      entryFee: data['entryFee']?.toDouble(),
      images: List<String>.from(data['images'] ?? []),
      defaultRating: (data['defaultRating'] ?? 0.0).toDouble(),
      status: SiteStatus.values.firstWhere(
        (e) => e.toString() == 'SiteStatus.${data['status']}',
        orElse: () => SiteStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'workingHours': workingHours,
      'entryFee': entryFee,
      'images': images,
      'defaultRating': defaultRating,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  TouristSite copyWith({
    String? id,
    Map<String, String>? name,
    Map<String, String>? description,
    SiteCategory? category,
    String? city,
    double? latitude,
    double? longitude,
    String? workingHours,
    double? entryFee,
    List<String>? images,
    double? defaultRating,
    SiteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return TouristSite(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workingHours: workingHours ?? this.workingHours,
      entryFee: entryFee ?? this.entryFee,
      images: images ?? this.images,
      defaultRating: defaultRating ?? this.defaultRating,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String getCategoryName(String language) {
    switch (category) {
      case SiteCategory.archaeological:
        return language == 'ar' ? 'أثري' : 'Archaeological';
      case SiteCategory.religious:
        return language == 'ar' ? 'ديني' : 'Religious';
      case SiteCategory.museum:
        return language == 'ar' ? 'متحف' : 'Museum';
      case SiteCategory.park:
        return language == 'ar' ? 'حديقة' : 'Park';
      case SiteCategory.beach:
        return language == 'ar' ? 'شاطئ' : 'Beach';
      case SiteCategory.market:
        return language == 'ar' ? 'سوق' : 'Market';
      case SiteCategory.castle:
        return language == 'ar' ? 'قلعة' : 'Castle';
    }
  }

  String getStatusName(String language) {
    switch (status) {
      case SiteStatus.active:
        return language == 'ar' ? 'نشط' : 'Active';
      case SiteStatus.inactive:
        return language == 'ar' ? 'غير نشط' : 'Inactive';
    }
  }
}
