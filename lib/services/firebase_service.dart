import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tourist_site.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/personalized_recommendation.dart';
import '../models/trip_suggestion.dart';
import '../models/bottom_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tourist Sites
  Future<List<TouristSite>> getTouristSites() async {
    try {
      final snapshot = await _firestore.collection('tourist_sites').get();
      return snapshot.docs
          .map((doc) => TouristSite.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting tourist sites: $e');
      return [];
    }
  }

  Future<void> addTouristSite(TouristSite site) async {
    try {
      await _firestore.collection('tourist_sites').add(site.toFirestore());
    } catch (e) {
      print('Error adding tourist site: $e');
      rethrow;
    }
  }

  Future<void> updateTouristSite(String id, TouristSite site) async {
    try {
      await _firestore
          .collection('tourist_sites')
          .doc(id)
          .update(site.toFirestore());
    } catch (e) {
      print('Error updating tourist site: $e');
      rethrow;
    }
  }

  Future<void> deleteTouristSite(String id) async {
    try {
      await _firestore.collection('tourist_sites').doc(id).delete();
    } catch (e) {
      print('Error deleting tourist site: $e');
      rethrow;
    }
  }

  // Events
  Future<List<Event>> getEvents() async {
    try {
      final snapshot = await _firestore.collection('events').get();
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      await _firestore.collection('events').add(event.toFirestore());
    } catch (e) {
      print('Error adding event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(String id, Event event) async {
    try {
      await _firestore.collection('events').doc(id).update(event.toFirestore());
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _firestore.collection('events').doc(id).delete();
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // Users
  Future<List<User>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<void> addUser(User user) async {
    try {
      await _firestore.collection('users').add(user.toFirestore());
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String id, User user) async {
    try {
      await _firestore.collection('users').doc(id).update(user.toFirestore());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection('users').doc(id).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Personalized Recommendations
  Future<List<PersonalizedRecommendation>>
  getPersonalizedRecommendations() async {
    try {
      final snapshot = await _firestore
          .collection('personalized_recommendations')
          .get();
      return snapshot.docs
          .map((doc) => PersonalizedRecommendation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      return [];
    }
  }

  Future<void> addPersonalizedRecommendation(
    PersonalizedRecommendation recommendation,
  ) async {
    try {
      await _firestore
          .collection('personalized_recommendations')
          .add(recommendation.toFirestore());
    } catch (e) {
      print('Error adding personalized recommendation: $e');
      rethrow;
    }
  }

  Future<void> updatePersonalizedRecommendation(
    String id,
    PersonalizedRecommendation recommendation,
  ) async {
    try {
      await _firestore
          .collection('personalized_recommendations')
          .doc(id)
          .update(recommendation.toFirestore());
    } catch (e) {
      print('Error updating personalized recommendation: $e');
      rethrow;
    }
  }

  Future<void> deletePersonalizedRecommendation(String id) async {
    try {
      await _firestore
          .collection('personalized_recommendations')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting personalized recommendation: $e');
      rethrow;
    }
  }

  // Trip Suggestions
  Future<List<TripSuggestion>> getTripSuggestions() async {
    try {
      final snapshot = await _firestore.collection('trip_suggestions').get();
      return snapshot.docs
          .map((doc) => TripSuggestion.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting trip suggestions: $e');
      return [];
    }
  }

  Future<void> addTripSuggestion(TripSuggestion suggestion) async {
    try {
      await _firestore
          .collection('trip_suggestions')
          .add(suggestion.toFirestore());
    } catch (e) {
      print('Error adding trip suggestion: $e');
      rethrow;
    }
  }

  Future<void> updateTripSuggestion(
    String id,
    TripSuggestion suggestion,
  ) async {
    try {
      await _firestore
          .collection('trip_suggestions')
          .doc(id)
          .update(suggestion.toFirestore());
    } catch (e) {
      print('Error updating trip suggestion: $e');
      rethrow;
    }
  }

  Future<void> deleteTripSuggestion(String id) async {
    try {
      await _firestore.collection('trip_suggestions').doc(id).delete();
    } catch (e) {
      print('Error deleting trip suggestion: $e');
      rethrow;
    }
  }

  // Bottom Services
  Future<List<BottomService>> getBottomServices() async {
    try {
      final snapshot = await _firestore.collection('bottom_services').get();
      return snapshot.docs
          .map((doc) => BottomService.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting bottom services: $e');
      return [];
    }
  }

  Future<void> addBottomService(BottomService service) async {
    try {
      await _firestore.collection('bottom_services').add(service.toFirestore());
    } catch (e) {
      print('Error adding bottom service: $e');
      rethrow;
    }
  }

  Future<void> updateBottomService(String id, BottomService service) async {
    try {
      await _firestore
          .collection('bottom_services')
          .doc(id)
          .update(service.toFirestore());
    } catch (e) {
      print('Error updating bottom service: $e');
      rethrow;
    }
  }

  Future<void> deleteBottomService(String id) async {
    try {
      await _firestore.collection('bottom_services').doc(id).delete();
    } catch (e) {
      print('Error deleting bottom service: $e');
      rethrow;
    }
  }

  // Analytics Data
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      // Get counts from different collections
      final sitesSnapshot = await _firestore.collection('tourist_sites').get();
      final eventsSnapshot = await _firestore.collection('events').get();
      final usersSnapshot = await _firestore.collection('users').get();
      final recommendationsSnapshot = await _firestore
          .collection('personalized_recommendations')
          .get();

      return {
        'totalSites': sitesSnapshot.docs.length,
        'totalEvents': eventsSnapshot.docs.length,
        'totalUsers': usersSnapshot.docs.length,
        'totalRecommendations': recommendationsSnapshot.docs.length,
        'recentActivity': await _getRecentActivity(),
      };
    } catch (e) {
      print('Error getting analytics data: $e');
      return {
        'totalSites': 0,
        'totalEvents': 0,
        'totalUsers': 0,
        'totalRecommendations': 0,
        'recentActivity': [],
      };
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    try {
      // Get recent documents from all collections
      final sitesSnapshot = await _firestore
          .collection('tourist_sites')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final eventsSnapshot = await _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> activities = [];

      // Add recent sites
      for (var doc in sitesSnapshot.docs) {
        final createdAt = doc.data()['createdAt'];
        activities.add({
          'type': 'site',
          'title':
              'تم إضافة موقع جديد: ${doc.data()['nameAr'] ?? doc.data()['nameEn']}',
          'time': createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
          'icon': 'add_location',
          'color': 'blue',
        });
      }

      // Add recent events
      for (var doc in eventsSnapshot.docs) {
        final createdAt = doc.data()['createdAt'];
        activities.add({
          'type': 'event',
          'title':
              'تم إنشاء حدث: ${doc.data()['titleAr'] ?? doc.data()['titleEn']}',
          'time': createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
          'icon': 'event',
          'color': 'orange',
        });
      }

      // Add recent users
      for (var doc in usersSnapshot.docs) {
        final createdAt = doc.data()['createdAt'];
        activities.add({
          'type': 'user',
          'title':
              'تم تسجيل مستخدم جديد: ${doc.data()['displayName'] ?? 'مستخدم'}',
          'time': createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
          'icon': 'person_add',
          'color': 'green',
        });
      }

      // Sort by time and return top 10
      activities.sort(
        (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
      );
      return activities.take(10).toList();
    } catch (e) {
      print('Error getting recent activity: $e');
      return [];
    }
  }
}
