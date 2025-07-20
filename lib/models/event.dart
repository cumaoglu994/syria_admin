import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final double price;
  final int capacity;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.price,
    required this.capacity,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      startTime: _timeFromString(data['startTime'] ?? '09:00'),
      endTime: _timeFromString(data['endTime'] ?? '18:00'),
      location: data['location'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      capacity: data['capacity'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  static TimeOfDay _timeFromString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'startTime':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'location': location,
      'price': price,
      'capacity': capacity,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
    double? price,
    int? capacity,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
