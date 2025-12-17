import 'package:flutter/material.dart';
import '../../utils/game_data_parser.dart';

/// Goals Tab - список голів
class GoalsTab extends StatefulWidget {
  final Map<String, dynamic>? gameData;

  const GoalsTab({
    super.key,
    required this.gameData,
  });

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  String _selectedTeam = 'Both';

  @override
  Widget build(BuildContext context) {
    final goals = _getFilteredGoals();

    return Column(
      children: [
        // Team filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              _buildTeamFilter('Both'),
              const SizedBox(width: 8),
              _buildTeamFilter('Home'),
              const SizedBox(width: 8),
              _buildTeamFilter('Away'),
            ],
          ),
        ),

        // Goals list
        Expanded(
          child: goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              return _buildGoalItem(goals[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamFilter(String label) {
    final isSelected = _selectedTeam == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTeam = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
            isSelected ? const Color(0xFF0F265C) : const Color(0xFFE8F4F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal) {
    final time = goal['time'] as String;
    final scorer = goal['scorer'] as String;
    final assists = goal['assists'] as String?;
    final type = goal['type'] as String; // PP, EV, SH
    final team = goal['team'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                    fontFamily: 'Lato',
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Type badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(type),
                    fontFamily: 'Lato',
                  ),
                ),
              ),

              const Spacer(),

              // Team
              Text(
                team,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scorer
          Row(
            children: [
              const Icon(
                Icons.sports_hockey,
                size: 20,
                color: Color(0xFF0F265C),
              ),
              const SizedBox(width: 8),
              Text(
                scorer,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),

          // Assists
          if (assists != null && assists.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                'Assists: $assists',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B9EB8),
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PP':
        return Colors.orange;
      case 'SH':
        return Colors.red;
      case 'EV':
      default:
        return const Color(0xFF0F265C);
    }
  }

  List<Map<String, dynamic>> _getFilteredGoals() {
    if (widget.gameData == null) {
      return [];
    }

    try {
      final parser = GameDataParser(widget.gameData!);
      final allGoals = parser.getGoals();

      if (_selectedTeam == 'Both') {
        return allGoals;
      }

      final filterHome = _selectedTeam == 'Home';
      return allGoals
          .where((goal) => goal['isHome'] == filterHome)
          .toList();
    } catch (e) {
      print('Error filtering goals: $e');
      return [];
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_hockey,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No goals scored yet',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }
}