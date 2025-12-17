import 'package:flutter/material.dart';
import '../../utils/game_data_parser.dart';

/// Boxscore Tab - статистика команд і гравців
class BoxscoreTab extends StatefulWidget {
  final Map<String, dynamic>? gameData;

  const BoxscoreTab({
    super.key,
    required this.gameData,
  });

  @override
  State<BoxscoreTab> createState() => _BoxscoreTabState();
}

class _BoxscoreTabState extends State<BoxscoreTab> {
  String _selectedPlayerType = 'Skaters';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team stats
          _buildTeamStats(),

          const SizedBox(height: 16),

          // Player type selector
          _buildPlayerTypeSelector(),

          // Player stats
          _selectedPlayerType == 'Skaters'
              ? _buildSkatersStats()
              : _buildGoaliesStats(),
        ],
      ),
    );
  }

  Widget _buildTeamStats() {
    if (widget.gameData == null) {
      return const SizedBox.shrink();
    }

    try {
      final parser = GameDataParser(widget.gameData!);
      final stats = parser.getTeamStats();

      return Container(
        margin: const EdgeInsets.all(16),
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
              'Team Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Shots',
              stats['shots']?['home']?.toString() ?? '0',
              stats['shots']?['away']?.toString() ?? '0',
            ),
            _buildStatRow(
              'Hits',
              stats['hits']?['home']?.toString() ?? '0',
              stats['hits']?['away']?.toString() ?? '0',
            ),
            _buildStatRow(
              'Faceoff %',
              '${stats['faceoffPct']?['home']?.toString() ?? '0'}%',
              '${stats['faceoffPct']?['away']?.toString() ?? '0'}%',
            ),
            _buildStatRow(
              'Blocks',
              stats['blocks']?['home']?.toString() ?? '0',
              stats['blocks']?['away']?.toString() ?? '0',
            ),
            _buildStatRow(
              'PIM',
              stats['pim']?['home']?.toString() ?? '0',
              stats['pim']?['away']?.toString() ?? '0',
            ),
            _buildStatRow(
              'PP',
              stats['powerPlay']?['home']?.toString() ?? '0/0',
              stats['powerPlay']?['away']?.toString() ?? '0/0',
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building team stats: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildStatRow(String label, String homeValue, String awayValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Home value
          SizedBox(
            width: 60,
            child: Text(
              homeValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B9EB8),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Away value
          SizedBox(
            width: 60,
            child: Text(
              awayValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildPlayerTypeButton('Skaters'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPlayerTypeButton('Goalies'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTypeButton(String type) {
    final isSelected = _selectedPlayerType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlayerType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
          isSelected ? const Color(0xFF0F265C) : const Color(0xFFE8F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF0F265C),
            fontFamily: 'Lato',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSkatersStats() {
    final players = _getSkaters();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),

          // Header
          _buildPlayerHeader(),

          const Divider(height: 16),

          // Players
          ...players.map((player) => _buildPlayerRow(player)),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: Text(
            'Player',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ),
        _buildStatHeader('G'),
        _buildStatHeader('A'),
        _buildStatHeader('P'),
        _buildStatHeader('+/-'),
        _buildStatHeader('SOG'),
      ],
    );
  }

  Widget _buildStatHeader(String label) {
    return SizedBox(
      width: 35,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B9EB8),
          fontFamily: 'Lato',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              player['name'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
          ),
          _buildStatValue(player['goals'].toString()),
          _buildStatValue(player['assists'].toString()),
          _buildStatValue(player['points'].toString()),
          _buildStatValue(player['plusMinus']),
          _buildStatValue(player['shots'].toString()),
        ],
      ),
    );
  }

  Widget _buildStatValue(String value) {
    return SizedBox(
      width: 35,
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F265C),
          fontFamily: 'Lato',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGoaliesStats() {
    final goalies = _getGoalies();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goalie Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),

          ...goalies.map((goalie) => _buildGoalieRow(goalie)),
        ],
      ),
    );
  }

  Widget _buildGoalieRow(Map<String, dynamic> goalie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goalie['name'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGoalieStat('Saves', goalie['saves'].toString()),
              _buildGoalieStat('SV%', goalie['savePercent']),
              _buildGoalieStat('TOI', goalie['toi']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalieStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B9EB8),
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F265C),
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getSkaters() {
    if (widget.gameData == null) {
      return [];
    }

    try {
      final parser = GameDataParser(widget.gameData!);
      return parser.getSkaters();
    } catch (e) {
      print('Error getting skaters: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _getGoalies() {
    if (widget.gameData == null) {
      return [];
    }

    try {
      final parser = GameDataParser(widget.gameData!);
      return parser.getGoalies();
    } catch (e) {
      print('Error getting goalies: $e');
      return [];
    }
  }
}