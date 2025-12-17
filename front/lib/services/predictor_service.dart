import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing game predictions
class PredictorService {
  static const String _predictionsKey = 'predictor_history';

  /// Load all predictions
  Future<List<Map<String, dynamic>>> loadPredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_predictionsKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error loading predictions: $e');
      return [];
    }
  }

  /// Save a new prediction
  Future<bool> savePrediction(Map<String, dynamic> picks) async {
    try {
      final predictions = await loadPredictions();

      // Create prediction record
      final prediction = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'gamePk': picks['gamePk'],
        'createdAt': DateTime.now().toIso8601String(),
        'picks': picks,
        'result': null,
        'points': null,
        'status': 'pending', // 'pending', 'scored'
      };

      predictions.add(prediction);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(predictions);
      return await prefs.setString(_predictionsKey, jsonString);
    } catch (e) {
      print('Error saving prediction: $e');
      return false;
    }
  }

  /// Get prediction for specific game - ВИПРАВЛЕНО
  Future<Map<String, dynamic>?> getPredictionForGame(int gamePk) async {
    try {
      final predictions = await loadPredictions();

      // ВИПРАВЛЕННЯ: Шукаємо прогноз
      for (var prediction in predictions) {
        if (prediction['gamePk'] == gamePk) {
          return prediction; // Знайшли - повертаємо
        }
      }

      // Не знайшли - повертаємо null
      return null;
    } catch (e) {
      print('Error getting prediction for game: $e');
      return null;
    }
  }

  /// Update prediction with result
  Future<bool> updatePredictionResult(
      String predictionId,
      Map<String, dynamic> result,
      int points,
      ) async {
    try {
      final predictions = await loadPredictions();

      final index = predictions.indexWhere((p) => p['id'] == predictionId);
      if (index == -1) return false;

      predictions[index]['result'] = result;
      predictions[index]['points'] = points;
      predictions[index]['status'] = 'scored';

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(predictions);
      return await prefs.setString(_predictionsKey, jsonString);
    } catch (e) {
      print('Error updating prediction: $e');
      return false;
    }
  }

  /// Get pending predictions (games not yet finished)
  Future<List<Map<String, dynamic>>> getPendingPredictions() async {
    final predictions = await loadPredictions();
    return predictions
        .where((p) => p['status'] == 'pending')
        .toList();
  }

  /// Get scored predictions
  Future<List<Map<String, dynamic>>> getScoredPredictions() async {
    final predictions = await loadPredictions();
    return predictions
        .where((p) => p['status'] == 'scored')
        .toList();
  }

  /// Calculate total points
  Future<int> getTotalPoints() async {
    final predictions = await getScoredPredictions();
    return predictions.fold<int>(
      0,
          (sum, p) => sum + ((p['points'] as int?) ?? 0),
    );
  }

  /// Calculate statistics
  Future<Map<String, int>> getStats() async {
    final scored = await getScoredPredictions();

    int totalPredictions = scored.length;
    int correctWinners = 0;
    int correctOT = 0;
    int correctTotalGoals = 0;
    int exactScores = 0;

    for (var prediction in scored) {
      final result = prediction['result'] as Map<String, dynamic>?;
      if (result == null) continue;

      if (result['winner'] == true) correctWinners++;
      if (result['overtime'] == true) correctOT++;
      if (result['totalGoals'] == true) correctTotalGoals++;
      if (result['exactScore'] == true) exactScores++;
    }

    return {
      'total': totalPredictions,
      'correctWinners': correctWinners,
      'correctOT': correctOT,
      'correctTotalGoals': correctTotalGoals,
      'exactScores': exactScores,
    };
  }

  /// Calculate points for a prediction
  /// Called after game finishes
  Map<String, dynamic> scorePrediction(
      Map<String, dynamic> picks,
      Map<String, dynamic> gameResult,
      ) {
    int points = 0;
    final result = {
      'winner': false,
      'overtime': false,
      'totalGoals': false,
      'exactScore': false,
    };

    // Check winner
    final predictedWinner = picks['winner'];
    final actualWinner = gameResult['winner']; // 'home', 'away', 'tie'

    if (predictedWinner == actualWinner) {
      points += 5;
      result['winner'] = true;
    }

    // Check overtime
    final predictedOT = picks['overtimeNeeded'] as bool?;
    final actualOT = gameResult['overtimeNeeded'] as bool?;

    if (predictedOT == actualOT) {
      points += 3;
      result['overtime'] = true;
    }

    // Check total goals
    final predictedTotal = picks['totalGoals'] as int?;
    final actualTotal = gameResult['totalGoals'] as int?;

    if (predictedTotal == actualTotal) {
      points += 5;
      result['totalGoals'] = true;
    }

    // Check exact score
    final predictedHome = picks['homeScore'] as int?;
    final predictedAway = picks['awayScore'] as int?;
    final actualHome = gameResult['homeScore'] as int?;
    final actualAway = gameResult['awayScore'] as int?;

    if (predictedHome != null &&
        predictedAway != null &&
        predictedHome == actualHome &&
        predictedAway == actualAway) {
      points += 10;
      result['exactScore'] = true;
    }

    return {
      'points': points,
      'result': result,
    };
  }

  /// Clear all predictions
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_predictionsKey);
    } catch (e) {
      return false;
    }
  }
}