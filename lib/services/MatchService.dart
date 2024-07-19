// match_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> findMatch(String userId) async {
    try {
      final queueSnapshot = await _firestore
          .collection('matchQueue')
          .where('userId', isNotEqualTo: userId)
          .get();

      if (queueSnapshot.docs.isEmpty) {
        print('No other users in the match queue.');
        return null;
      }

      // Simply choose the first available user in the queue
      final matchedUser = queueSnapshot.docs.first;
      final matchedUserId = matchedUser['userId'] as String?;
      final matchedDocId = matchedUser.id;

      if (matchedUserId != null) {
        // Calculate score for logging purposes, but don't use it for matching
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};
        double score = calculateMatchScore(userData, matchedUser.data());

        await _removeFromQueue(userId, matchedUserId, matchedDocId);
        await _createMatch(userId, matchedUserId, score);
        print('Match found with user: $matchedUserId, score: $score');
        return matchedUserId;
      }

      print('No suitable match found at this time.');
      return null;
    } catch (e) {
      print("Error finding match: $e");
      return null;
    }
  }

  double calculateMatchScore(
      Map<String, dynamic> user1, Map<String, dynamic> user2) {
    double score = 0;
    int factorsConsidered = 0;

    // Location-based matching
    if (user1['latitude'] != null &&
        user1['longitude'] != null &&
        user2['latitude'] != null &&
        user2['longitude'] != null) {
      double distance = Geolocator.distanceBetween(
        user1['latitude'],
        user1['longitude'],
        user2['latitude'],
        user2['longitude'],
      );
      score += 50 * (1 - (distance / 100000)); // Assumes 100km as max distance
      factorsConsidered++;
    }

    // Age-based matching
    if (user1['birthdate'] != null && user2['birthdate'] != null) {
      Timestamp birthdate1 = user1['birthdate'];
      Timestamp birthdate2 = user2['birthdate'];
      int age1 = calculateAgeFromTimestamp(birthdate1);
      int age2 = calculateAgeFromTimestamp(birthdate2);
      int ageDifference = (age1 - age2).abs();
      score += 50 *
          (1 - (ageDifference / 10)); // Assumes 10 years as max age difference
      factorsConsidered++;
    }

    // Gender matching (optional)
    if (user1['gender'] != null && user2['gender'] != null) {
      if (user1['gender'] != user2['gender']) {
        score += 50;
      }
      factorsConsidered++;
    }

    // Calculate average score based on factors considered
    return factorsConsidered > 0 ? score / factorsConsidered : 0;
  }

  Future<void> _removeFromQueue(
      String userId, String matchedUserId, String matchedDocId) async {
    await _firestore.collection('matchQueue').doc(matchedDocId).delete();
    await _firestore
        .collection('matchQueue')
        .where('userId', isEqualTo: userId)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
  }

  Future<void> _createMatch(
      String userId, String matchedUserId, double score) async {
    final matchRef = _firestore.collection('matches').doc();
    final matchId = matchRef.id;

    await matchRef.set({
      'users': [userId, matchedUserId],
      'timestamp': FieldValue.serverTimestamp(),
      'score': score,
    });

    await _firestore
        .collection('matches')
        .doc(userId)
        .collection('userMatches')
        .doc(matchId)
        .set({
      'matchedUserId': matchedUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'score': score,
    });

    await _firestore
        .collection('matches')
        .doc(matchedUserId)
        .collection('userMatches')
        .doc(matchId)
        .set({
      'matchedUserId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'score': score,
    });
  }

  int calculateAgeFromTimestamp(Timestamp birthdate) {
    DateTime currentDate = DateTime.now();
    DateTime birthdateDateTime = birthdate.toDate();
    int age = currentDate.year - birthdateDateTime.year;
    int month1 = currentDate.month;
    int month2 = birthdateDateTime.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthdateDateTime.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }
}
