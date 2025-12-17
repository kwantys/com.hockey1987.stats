import 'package:flutter/material.dart';
import '../../utils/game_data_parser.dart';

/// Timeline Tab - лента подій гри
class TimelineTab extends StatefulWidget {
  final Map<String, dynamic>? gameData;

  const TimelineTab({
    super.key,
    required this.gameData,
  });

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Goals',
    'Shots',
    'Hits',
    'Penalties',
    'Faceoffs',
  ];

  @override
  Widget build(BuildContext context) {
    final events = _getFilteredEvents();

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(filter),
                );
              }).toList(),
            ),
          ),
        ),

        // Events list
        Expanded(
          child: events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventItem(events[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F265C) : const Color(0xFFE8F4F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF0F265C),
            fontFamily: 'Lato',
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final eventType = event['type'] as String;
    final time = event['time'] as String;
    final description = event['description'] as String;
    final player = event['player'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getEventColor(eventType).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEventIcon(eventType),
              size: 20,
              color: _getEventColor(eventType),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eventType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getEventColor(eventType),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B9EB8),
                    fontFamily: 'Lato',
                  ),
                ),
                if (player != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    player,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F265C),
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Icons.sports_hockey;
      case 'shot':
        return Icons.sports_score;
      case 'hit':
        return Icons.support;
      case 'penalty':
        return Icons.warning;
      case 'faceoff':
        return Icons.album;
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Colors.green;
      case 'shot':
        return Colors.blue;
      case 'hit':
        return Colors.orange;
      case 'penalty':
        return Colors.red;
      case 'faceoff':
        return Colors.purple;
      default:
        return const Color(0xFF6B9EB8);
    }
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    if (widget.gameData == null) {
      return [];
    }

    try {
      final parser = GameDataParser(widget.gameData!);
      final allEvents = parser.getTimelineEvents();

      if (_selectedFilter == 'All') {
        return allEvents;
      }

      // Визначаємо правильну назву типу події для фільтрації
      String targetType;
      switch (_selectedFilter) {
        case 'Goals':
          targetType = 'Goal';
          break;
        case 'Shots':
          targetType = 'Shot';
          break;
        case 'Hits':
          targetType = 'Hit';
          break;
        case 'Penalties':
          targetType = 'Penalty'; // Правильна однина (не Penaltie)
          break;
        case 'Faceoffs':
          targetType = 'Faceoff';
          break;
        default:
        // Для інших випадків (якщо будуть) пробуємо прибрати 's'
          targetType = _selectedFilter.endsWith('s')
              ? _selectedFilter.substring(0, _selectedFilter.length - 1)
              : _selectedFilter;
      }

      return allEvents.where((event) {
        final eventType = event['type'].toString();
        return eventType.toLowerCase() == targetType.toLowerCase();
      }).toList();

    } catch (e) {
      print('Error filtering events: $e');
      return [];
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedFilter.toLowerCase()} events yet',
            style: const TextStyle(
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