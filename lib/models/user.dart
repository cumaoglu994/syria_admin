import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin, // مسؤول
  moderator, // مشرف
  user, // مستخدم عادي
}

enum UserStatus {
  active, // نشط
  suspended, // معلق
  banned, // محظور
}

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? profileImage;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic> preferences;
  final List<String> favoriteSites;
  final List<String> bookedEvents;
  final int totalBookings;
  final double averageRating;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.profileImage,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences = const {},
    this.favoriteSites = const [],
    this.bookedEvents = const [],
    this.totalBookings = 0,
    this.averageRating = 0.0,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return User(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      profileImage: data['profileImage'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == 'UserStatus.${data['status']}',
        orElse: () => UserStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      favoriteSites: List<String>.from(data['favoriteSites'] ?? []),
      bookedEvents: List<String>.from(data['bookedEvents'] ?? []),
      totalBookings: data['totalBookings'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferences': preferences,
      'favoriteSites': favoriteSites,
      'bookedEvents': bookedEvents,
      'totalBookings': totalBookings,
      'averageRating': averageRating,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? profileImage,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    List<String>? favoriteSites,
    List<String>? bookedEvents,
    int? totalBookings,
    double? averageRating,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      favoriteSites: favoriteSites ?? this.favoriteSites,
      bookedEvents: bookedEvents ?? this.bookedEvents,
      totalBookings: totalBookings ?? this.totalBookings,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  String getRoleName(String language) {
    switch (role) {
      case UserRole.admin:
        return language == 'ar' ? 'مسؤول' : 'Admin';
      case UserRole.moderator:
        return language == 'ar' ? 'مشرف' : 'Moderator';
      case UserRole.user:
        return language == 'ar' ? 'مستخدم' : 'User';
    }
  }

  String getStatusName(String language) {
    switch (status) {
      case UserStatus.active:
        return language == 'ar' ? 'نشط' : 'Active';
      case UserStatus.suspended:
        return language == 'ar' ? 'معلق' : 'Suspended';
      case UserStatus.banned:
        return language == 'ar' ? 'محظور' : 'Banned';
    }
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator || role == UserRole.admin;
  bool get isActive => status == UserStatus.active;
  bool get canAccessAdminPanel =>
      role == UserRole.admin || role == UserRole.moderator;
}
