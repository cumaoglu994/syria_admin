import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  festival, // مهرجان
  exhibition, // معرض
  tour, // جولة
  workshop, // ورشة عمل
}

enum EventStatus {
  upcoming, // مقبل
  active, // نشط
  completed, // منتهي
  cancelled, // ملغي
}

class Event {
  final String id;
  final Map<String, String> title; // متعدد اللغات
  final Map<String, String> description; // متعدد اللغات
  final DateTime dateTime;
  final String location;
  final EventType type;
  final double? ticketPrice;
  final int availableSeats;
  final List<String> images;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final int bookedSeats;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.type,
    this.ticketPrice,
    required this.availableSeats,
    required this.images,
    this.status = EventStatus.upcoming,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.bookedSeats = 0,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Event(
      id: doc.id,
      title: Map<String, String>.from(data['title'] ?? {}),
      description: Map<String, String>.from(data['description'] ?? {}),
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.toString() == 'EventType.${data['type']}',
        orElse: () => EventType.festival,
      ),
      ticketPrice: data['ticketPrice']?.toDouble(),
      availableSeats: data['availableSeats'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == 'EventStatus.${data['status']}',
        orElse: () => EventStatus.upcoming,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      bookedSeats: data['bookedSeats'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'type': type.toString().split('.').last,
      'ticketPrice': ticketPrice,
      'availableSeats': availableSeats,
      'images': images,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'bookedSeats': bookedSeats,
    };
  }

  Event copyWith({
    String? id,
    Map<String, String>? title,
    Map<String, String>? description,
    DateTime? dateTime,
    String? location,
    EventType? type,
    double? ticketPrice,
    int? availableSeats,
    List<String>? images,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? bookedSeats,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      type: type ?? this.type,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      availableSeats: availableSeats ?? this.availableSeats,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      bookedSeats: bookedSeats ?? this.bookedSeats,
    );
  }

  String getTypeName(String language) {
    switch (type) {
      case EventType.festival:
        return language == 'ar' ? 'مهرجان' : 'Festival';
      case EventType.exhibition:
        return language == 'ar' ? 'معرض' : 'Exhibition';
      case EventType.tour:
        return language == 'ar' ? 'جولة' : 'Tour';
      case EventType.workshop:
        return language == 'ar' ? 'ورشة عمل' : 'Workshop';
    }
  }

  String getStatusName(String language) {
    switch (status) {
      case EventStatus.upcoming:
        return language == 'ar' ? 'مقبل' : 'Upcoming';
      case EventStatus.active:
        return language == 'ar' ? 'نشط' : 'Active';
      case EventStatus.completed:
        return language == 'ar' ? 'منتهي' : 'Completed';
      case EventStatus.cancelled:
        return language == 'ar' ? 'ملغي' : 'Cancelled';
    }
  }

  int get remainingSeats => availableSeats - bookedSeats;
  double get bookingRate =>
      availableSeats > 0 ? (bookedSeats / availableSeats) * 100 : 0;
  bool get isFullyBooked => remainingSeats <= 0;
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  bool get isActive =>
      dateTime.isBefore(DateTime.now()) && status == EventStatus.active;
}
