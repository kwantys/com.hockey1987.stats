import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/predictor_service.dart';
import '../services/nhl_api_service.dart';
import '../models/game.dart';

/// Prediction Stats Screen - detailed statistics and history
class PredictionStatsScreen extends StatefulWidget {
  const PredictionStatsScreen({super.key});

  @override
  State<PredictionStatsScreen> createState() => _PredictionStatsScreenState();
}

class _PredictionStatsScreenState extends State<PredictionStatsScreen> {
  final PredictorService _predictorService = PredictorService();
  final NHLApiService _apiService = NHLApiService();

  int _totalPoints = 0;
  int _totalPredictions = 0;
  int _correctWinners = 0;
  int _bestStreak = 0;
  int _perfectNights = 0;

  // Store game details for display
  Map<int, Map<String, dynamic>> _gameDetails = {};

  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;
  bool _isScoring = false;

  // Filters
  String _selectedPeriod = 'All'; // Last 7, Last 30, Season, All
  String _selectedMonth = 'Nov'; // For "By month" filter
  String _sortBy = 'Date'; // Date, Points, Accuracy impact

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final predictions = await _predictorService.loadPredictions();
      final stats = await _predictorService.getStats();
      final totalPoints = await _predictorService.getTotalPoints();

      // Load game details for each prediction
      for (var pred in predictions) {
        final gamePk = pred['gamePk'] as int;
        if (!_gameDetails.containsKey(gamePk)) {
          try {
            final game = await _apiService.getGameById(gamePk);
            _gameDetails[gamePk] = {
              'homeTeam': game.homeTeamName ?? 'HOME',
              'awayTeam': game.awayTeamName ?? 'AWAY',
              'homeScore': game.homeTeamScore,
              'awayScore': game.awayTeamScore,
            };
          } catch (e) {
            _gameDetails[gamePk] = {
              'homeTeam': 'HOME',
              'awayTeam': 'AWAY',
              'homeScore': null,
              'awayScore': null,
            };
          }
        }
      }

      // Sort by date (newest first)
      predictions.sort((a, b) {
        final aDate = DateTime.parse(a['createdAt']);
        final bDate = DateTime.parse(b['createdAt']);
        return bDate.compareTo(aDate);
      });

      // Calculate best streak
      int currentStreak = 0;
      int maxStreak = 0;
      for (var pred in predictions.reversed) {
        if (pred['status'] == 'scored') {
          final result = pred['result'] as Map<String, dynamic>?;
          if (result?['winner'] == true) {
            currentStreak++;
            if (currentStreak > maxStreak) maxStreak = currentStreak;
          } else {
            currentStreak = 0;
          }
        }
      }

      // Calculate perfect nights (23 points = all correct)
      int perfectCount = 0;
      for (var pred in predictions) {
        if (pred['points'] == 23) perfectCount++;
      }

      setState(() {
        _predictions = predictions;
        _totalPoints = totalPoints;
        _totalPredictions = stats['total'] ?? 0;
        _correctWinners = stats['correctWinners'] ?? 0;
        _bestStreak = maxStreak;
        _perfectNights = perfectCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scorePendingPredictions() async {
    setState(() => _isScoring = true);

    try {
      final pending = await _predictorService.getPendingPredictions();

      if (pending.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pending predictions to score')),
          );
        }
        setState(() => _isScoring = false);
        return;
      }

      int scoredCount = 0;

      for (var prediction in pending) {
        final gamePk = prediction['gamePk'] as int;
        final predictionId = prediction['id'] as String;
        final picks = prediction['picks'] as Map<String, dynamic>;

        try {
          final game = await _apiService.getGameById(gamePk);
          if (!game.isFinal) continue;

          final gameResult = _prepareGameResult(game);
          final scoring = _predictorService.scorePrediction(picks, gameResult);

          await _predictorService.updatePredictionResult(
            predictionId,
            scoring['result'] as Map<String, dynamic>,
            scoring['points'] as int,
          );

          scoredCount++;
        } catch (e) {
          continue;
        }
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(scoredCount > 0
                ? 'Scored $scoredCount predictions!'
                : 'All games still in progress'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() => _isScoring = false);
    } catch (e) {
      setState(() => _isScoring = false);
    }
  }

  Map<String, dynamic> _prepareGameResult(Game game) {
    String winner;
    if (game.homeTeamScore != null && game.awayTeamScore != null) {
      if (game.homeTeamScore! > game.awayTeamScore!) {
        winner = 'home';
      } else if (game.awayTeamScore! > game.homeTeamScore!) {
        winner = 'away';
      } else {
        winner = 'tie';
      }
    } else {
      winner = 'unknown';
    }

    final overtimeNeeded = game.period != null && game.period! > 3;
    final totalGoals = (game.homeTeamScore ?? 0) + (game.awayTeamScore ?? 0);

    return {
      'winner': winner,
      'overtimeNeeded': overtimeNeeded,
      'totalGoals': totalGoals,
      'homeScore': game.homeTeamScore ?? 0,
      'awayScore': game.awayTeamScore ?? 0,
    };
  }

  Future<void> _resetStats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset stats'),
        content: const Text(
          'This will delete all your predictions and stats. '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _predictorService.clearAll();
      setState(() {
        _gameDetails.clear();
      });
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All stats cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPredictions {
    // Show ALL predictions (both pending and scored)
    var filtered = List<Map<String, dynamic>>.from(_predictions);

    // Apply period filter
    if (_selectedPeriod != 'All') {
      final now = DateTime.now();
      DateTime cutoffDate;

      if (_selectedPeriod == 'Last 7') {
        cutoffDate = now.subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'Last 30') {
        cutoffDate = now.subtract(const Duration(days: 30));
      } else {
        // Season - from October 1st
        cutoffDate = DateTime(now.year, 10, 1);
      }

      filtered = filtered.where((p) {
        final date = DateTime.parse(p['createdAt']);
        return date.isAfter(cutoffDate);
      }).toList();
    }

    // Apply sorting
    if (_sortBy == 'Points') {
      filtered.sort((a, b) {
        final aPoints = a['points'] as int? ?? 0;
        final bPoints = b['points'] as int? ?? 0;
        return bPoints.compareTo(aPoints);
      });
    } else if (_sortBy == 'Accuracy impact') {
      // Sort by how much the prediction affected accuracy
      // High impact = correct winner with high confidence (more points)
      filtered.sort((a, b) {
        final aResult = a['result'] as Map<String, dynamic>?;
        final bResult = b['result'] as Map<String, dynamic>?;

        final aWinner = aResult?['winner'] == true ? 1 : 0;
        final bWinner = bResult?['winner'] == true ? 1 : 0;

        // First by winner correctness, then by points
        if (aWinner != bWinner) {
          return bWinner.compareTo(aWinner);
        }

        final aPoints = a['points'] as int? ?? 0;
        final bPoints = b['points'] as int? ?? 0;
        return bPoints.compareTo(aPoints);
      });
    } else {
      // Sort by date
      filtered.sort((a, b) {
        final aDate = DateTime.parse(a['createdAt']);
        final bDate = DateTime.parse(b['createdAt']);
        return bDate.compareTo(aDate);
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8ACEF2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F265C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prediction Stats',
          style: TextStyle(
            color: Color(0xFF0F265C),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Lato',
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _predictions.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildStatsGrid(),
            _buildFilters(),
            _filteredPredictions.isEmpty
                ? _buildNoFilteredResults()
                : _buildPredictionsList(),
            _buildResetButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final accuracy = _totalPredictions > 0
        ? ((_correctWinners / _totalPredictions) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total points', _totalPoints.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Accuracy', '$accuracy%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Best streak', '$_bestStreak in a row'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Perfect nights', _perfectNights.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8ACEF2).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8ACEF2).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Period filters
          Row(
            children: [
              _buildFilterChip('Last 7'),
              const SizedBox(width: 8),
              _buildFilterChip('Last 30'),
              const SizedBox(width: 8),
              _buildFilterChip('Season'),
              const SizedBox(width: 8),
              _buildFilterChip('All'),
            ],
          ),
          const SizedBox(height: 12),
          // Month and Sort
          Row(
            children: [
              const Text(
                'By month:',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdown(_selectedMonth, ['Oct', 'Nov', 'Dec', 'Jan'], (val) {
                setState(() => _selectedMonth = val!);
              }),
              const Spacer(),
              const Text(
                'Sort by:',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdown(_sortBy, ['Date', 'Points', 'Accuracy impact'], (val) {
                setState(() => _sortBy = val!);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedPeriod == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F265C) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F265C) : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF0F265C)),
      ),
    );
  }

  Widget _buildPredictionsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 50,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B9EB8),
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Match',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B9EB8),
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Your pick',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B9EB8),
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Outcome',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B9EB8),
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'Points',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B9EB8),
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Predictions list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredPredictions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildPredictionRow(_filteredPredictions[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(Map<String, dynamic> prediction) {
    final picks = prediction['picks'] as Map<String, dynamic>;
    final result = prediction['result'] as Map<String, dynamic>?;
    final points = prediction['points'] as int? ?? 0;
    final status = prediction['status'] as String;
    final createdAt = DateTime.parse(prediction['createdAt']);
    final gamePk = picks['gamePk'] as int;

    // Get game details
    final gameInfo = _gameDetails[gamePk];
    final homeTeam = gameInfo?['homeTeam'] ?? 'HOME';
    final awayTeam = gameInfo?['awayTeam'] ?? 'AWAY';

    // Format pick
    final winner = picks['winner'];
    final overtimeNeeded = picks['overtimeNeeded'];
    final totalGoals = picks['totalGoals'];
    final homeScore = picks['homeScore'];
    final awayScore = picks['awayScore'];

    String pickText = _formatPick(winner, overtimeNeeded, totalGoals, homeScore, awayScore);

    // Format outcome
    String outcomeText = status == 'pending' ? 'Pending' : _formatOutcome(result, points);
    Color outcomeColor = status == 'pending'
        ? const Color(0xFFFFA500) // Orange for pending
        : _getOutcomeColor(outcomeText, points);

    // Row background for alternating colors
    final isEven = _filteredPredictions.indexOf(prediction) % 2 == 0;

    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('MMM d').format(createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$awayTeam vs $homeTeam',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pickText,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (status == 'pending')
                  const Icon(
                    Icons.schedule,
                    size: 12,
                    color: Color(0xFFFFA500),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    outcomeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: outcomeColor,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              status == 'pending' ? '-' : '+$points',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: status == 'pending'
                    ? const Color(0xFF6B9EB8)
                    : const Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPick(String? winner, bool? ot, int? goals, int? homeScore, int? awayScore) {
    String winnerText;
    if (winner == 'home') {
      winnerText = 'Home';
    } else if (winner == 'away') {
      winnerText = 'Away';
    } else {
      winnerText = 'TIE';
    }

    final otText = ot == true ? 'OT' : 'No OT';

    if (homeScore != null && awayScore != null) {
      return '$winnerText, $otText, $homeScore-$awayScore';
    } else {
      return '$winnerText, $otText, $goals goals';
    }
  }

  String _formatOutcome(Map<String, dynamic>? result, int points) {
    if (result == null) return 'Pending';

    if (points == 23) return 'Exact score!';
    if (points >= 18) return 'Winner + OT correct';
    if (points >= 13) return 'Winner + goals correct';
    if (points >= 10) return 'Winner correct';
    if (points >= 8) return '+ OT correct';
    if (points >= 5) return '+ goals correct';
    if (points > 0) return 'Some correct';
    return 'Closed early';
  }

  Color _getOutcomeColor(String outcome, int points) {
    if (outcome == 'Exact score!') return const Color(0xFF4CAF50);
    if (points >= 13) return const Color(0xFF4CAF50);
    if (points >= 5) return const Color(0xFFFFA500);
    if (outcome == 'Closed early') return const Color(0xFFE53935);
    return const Color(0xFF757575);
  }

  Widget _buildResetButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Back to studio button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Go back, or navigate to Outcome Studio
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text(
                'Back to studio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F265C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Reset stats button
          TextButton.icon(
            onPressed: _resetStats,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            label: const Text(
              'Reset stats',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilteredResults() {
    return Container(
      margin: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.filter_list_off,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No predictions match your filters.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No predictions yet.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B9EB8),
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make your first call from the scoreboard.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B9EB8),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}