import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ← ДОДАНО
import '../../services/insights_service.dart';
import '../../services/nhl_api_service.dart';
import '../../models/team_insight.dart';
import '../team_profile_screen.dart';
import '../../models/team_models.dart';

/// Tab 1: Hot Streaks - найгарячіші та найхолодніші команди
class HotStreaksTab extends StatefulWidget {
  const HotStreaksTab({super.key});

  @override
  State<HotStreaksTab> createState() => _HotStreaksTabState();
}

class _HotStreaksTabState extends State<HotStreaksTab> {
  final InsightsService _insightsService = InsightsService();
  final NHLApiService _apiService = NHLApiService();

  int _selectedRange = 10;
  List<TeamInsight> _insights = [];
  List<Map<String, dynamic>> _allTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final teams = await _apiService.getAllTeams();
      final insights = await _insightsService.getHotStreaks(gamesRange: _selectedRange);

      insights.sort((a, b) {
        final aTotal = (a.wins + a.losses + a.otLosses);
        final bTotal = (b.wins + b.losses + b.otLosses);

        final aWinRate = aTotal > 0 ? a.wins / aTotal : 0.0;
        final bWinRate = bTotal > 0 ? b.wins / bTotal : 0.0;

        return bWinRate.compareTo(aWinRate);
      });

      if (mounted) {
        setState(() {
          _allTeams = teams;
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading hot streaks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeRange(int newRange) {
    if (_selectedRange == newRange) return;
    setState(() {
      _selectedRange = newRange;
    });
    _loadInsights();
  }

  void _openTeamProfile(TeamInsight insight) {
    final teamData = _allTeams.cast<Map<String, dynamic>>().firstWhere(
          (t) => t['id'] == insight.teamId,
      orElse: () => <String, dynamic>{},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamProfileScreen(
          teamId: insight.teamId,
          team: Team(
            teamId: insight.teamId,
            teamName: insight.teamName,
            teamAbbrev: insight.teamAbbrev,
            teamLogo: insight.teamLogo,
            divisionName: teamData['division']?.toString() ?? teamData['divisionName']?.toString() ?? '',
            conferenceName: teamData['conference']?.toString() ?? teamData['conferenceName']?.toString() ?? '',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRangeFilter(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _insights.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh: _loadInsights,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _insights.length,
              itemBuilder: (context, index) {
                return _buildTeamCard(_insights[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildRangeChip('Last 5', 5),
          const SizedBox(width: 8),
          _buildRangeChip('Last 10', 10),
          const SizedBox(width: 8),
          _buildRangeChip('Last 20', 20),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, int range) {
    final isSelected = _selectedRange == range;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeRange(range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8ACEF2) : const Color(0xFFE8F4F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF0F265C) : const Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _openTeamProfile(insight),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ✅ ВИПРАВЛЕННЯ: Team logo з підтримкою SVG і PNG
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildTeamLogo(insight.teamLogo),
              ),

              const SizedBox(width: 12),

              // Team info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.teamName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Record: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontFamily: 'Lato',
                          ),
                        ),
                        Text(
                          insight.record,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F265C),
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Goal diff: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  insight.goalDiffFormatted,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _getGoalDiffColor(insight.goalDifferential),
                                    fontFamily: 'Lato',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Streak chip
              _buildStreakChip(insight.streakLabel),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ НОВИЙ МЕТОД: Відображення логотипу з підтримкою SVG і PNG
  Widget _buildTeamLogo(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return _buildLogoFallback();
    }

    // Очищаємо URL від query параметрів
    String cleanUrl = logoUrl;
    if (cleanUrl.contains('?')) {
      cleanUrl = cleanUrl.split('?').first;
    }

    // Визначаємо формат
    final isSVG = cleanUrl.toLowerCase().endsWith('.svg');
    final isPNG = cleanUrl.toLowerCase().endsWith('.png');

    if (isSVG) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.network(
          cleanUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (isPNG) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          cleanUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
          errorBuilder: (_, __, ___) => _buildLogoFallback(),
        ),
      );
    }

    return _buildLogoFallback();
  }

  Widget _buildStreakChip(String label) {
    Color color;
    switch (label) {
      case 'On fire':
        color = const Color(0xFFE74C3C);
        break;
      case 'Heating up':
        color = const Color(0xFFF39C12);
        break;
      case 'Cooling down':
        color = const Color(0xFF3498DB);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Lato',
        ),
      ),
    );
  }

  Color _getGoalDiffColor(int diff) {
    if (diff > 0) return Colors.green;
    if (diff < 0) return Colors.red;
    return Colors.grey;
  }

  Widget _buildLogoFallback() {
    return const Icon(
      Icons.sports_hockey,
      size: 25,
      color: Color(0xFF6B9EB8),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No team data available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }
}