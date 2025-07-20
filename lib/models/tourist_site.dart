import 'package:cloud_firestore/cloud_firestore.dart';

class TouristSite {
  final String id;
  final String name;
  final String description;
  final String city;
  final String address;
  final String phone;
  final String website;
  final String category;
  final double price;
  final double rating;
  final double latitude;
  final double longitude;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  TouristSite({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    required this.phone,
    required this.website,
    required this.category,
    required this.price,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TouristSite.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TouristSite(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      website: data['website'] ?? '',
      category: data['category'] ?? 'all',
      price: (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'city': city,
      'address': address,
      'phone': phone,
      'website': website,
      'category': category,
      'price': price,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TouristSite copyWith({
    String? id,
    String? name,
    String? description,
    String? city,
    String? address,
    String? phone,
    String? website,
    String? category,
    double? price,
    double? rating,
    double? latitude,
    double? longitude,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TouristSite(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      category: category ?? this.category,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
