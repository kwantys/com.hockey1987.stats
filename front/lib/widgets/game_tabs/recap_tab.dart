import 'package:flutter/material.dart';
import '../../utils/game_data_parser.dart';

/// Recap Tab - підсумок гри
class RecapTab extends StatelessWidget {
  final Map<String, dynamic>? gameData;

  const RecapTab({
    super.key,
    required this.gameData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodScores(),
          const SizedBox(height: 20),
          _buildKeyMoments(),
          const SizedBox(height: 20),
          _buildBroadcastInfo(),
        ],
      ),
    );
  }

  Widget _buildPeriodScores() {
    final periods = _getPeriodScores();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score by periods',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              const SizedBox(width: 60),
              ...periods.keys.map((period) {
                return Expanded(
                  child: Text(
                    period,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B9EB8),
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
              const SizedBox(
                width: 40,
                child: Text(
                  'T',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B9EB8),
                    fontFamily: 'Lato',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Home team
          _buildPeriodRow('TOR', periods, 4),

          const SizedBox(height: 8),

          // Away team
          _buildPeriodRow('BOS', periods, 3),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(
      String team, Map<String, List<int>> periods, int total) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            team,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
        ),
        ...periods.values.map((scores) {
          final score = team == 'TOR' ? scores[0] : scores[1];
          return Expanded(
            child: Text(
              score.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
          );
        }),
        SizedBox(
          width: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F265C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              total.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMoments() {
    final moments = _getKeyMoments();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key moments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          ...moments.map((moment) => _buildMomentItem(moment)),
        ],
      ),
    );
  }

  Widget _buildMomentItem(String moment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            size: 20,
            color: Color(0xFFFFA500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              moment,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Broadcast info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          _buildBroadcastItem('TV', 'Sportsnet, ESPN+'),
          const SizedBox(height: 8),
          _buildBroadcastItem('Radio', 'TSN 1050'),
        ],
      ),
    );
  }

  Widget _buildBroadcastItem(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<int>> _getPeriodScores() {
    if (gameData == null) {
      return {};
    }

    try {
      final parser = GameDataParser(gameData!);
      return parser.getPeriodScores();
    } catch (e) {
      print('Error getting period scores: $e');
      return {};
    }
  }

  List<String> _getKeyMoments() {
    if (gameData == null) {
      return [];
    }

    try {
      final parser = GameDataParser(gameData!);
      return parser.getKeyMoments();
    } catch (e) {
      print('Error getting key moments: $e');
      return [];
    }
  }
}