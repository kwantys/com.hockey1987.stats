import 'package:flutter/material.dart';
import '../../utils/game_data_parser.dart';

/// Penalties Tab - список штрафів
class PenaltiesTab extends StatelessWidget {
  final Map<String, dynamic>? gameData;

  const PenaltiesTab({
    super.key,
    required this.gameData,
  });

  @override
  Widget build(BuildContext context) {
    final penalties = _getPenalties();

    if (penalties.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: penalties.length,
      itemBuilder: (context, index) {
        return _buildPenaltyItem(penalties[index]);
      },
    );
  }

  Widget _buildPenaltyItem(Map<String, dynamic> penalty) {
    final time = penalty['time'] as String;
    final team = penalty['team'] as String;
    final player = penalty['player'] as String;
    final type = penalty['type'] as String;
    final minutes = penalty['minutes'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Time
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    fontFamily: 'Lato',
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Team
              Text(
                team,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),

              const Spacer(),

              // Minutes
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$minutes min',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Type
          Text(
            type,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),

          const SizedBox(height: 4),

          // Player
          Text(
            player,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getPenalties() {
    if (gameData == null) {
      return [];
    }

    try {
      final parser = GameDataParser(gameData!);
      return parser.getPenalties();
    } catch (e) {
      print('Error getting penalties: $e');
      return [];
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No penalties yet',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clean game so far!',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }
}