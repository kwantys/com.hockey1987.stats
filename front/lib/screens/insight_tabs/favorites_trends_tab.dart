import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ← ДОДАНО
import '../../services/insights_service.dart';
import '../../services/favorites_service.dart';
import '../../services/nhl_api_service.dart';
import '../../models/team_insight.dart';
import '../team_profile_screen.dart';
import '../../models/team_models.dart';

/// Tab 3: Favorites Trends - статистика обраних команд
class FavoritesTrendsTab extends StatefulWidget {
  const FavoritesTrendsTab({super.key});

  @override
  State<FavoritesTrendsTab> createState() => _FavoritesTrendsTabState();
}

class _FavoritesTrendsTabState extends State<FavoritesTrendsTab> {
  final InsightsService _insightsService = InsightsService();
  final FavoritesService _favoritesService = FavoritesService();
  final NHLApiService _apiService = NHLApiService();

  List<TeamInsight> _favoriteInsights = [];
  List<Map<String, dynamic>> _allTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final teams = await _apiService.getAllTeams();
      final favoriteIds = await _favoritesService.getFavoriteTeams();

      if (favoriteIds.isEmpty) {
        if (mounted) {
          setState(() {
            _allTeams = teams;
            _favoriteInsights = [];
            _isLoading = false;
          });
        }
        return;
      }

      final insights = await _insightsService.getFavoritesInsights(favoriteIds);

      if (mounted) {
        setState(() {
          _allTeams = teams;
          _favoriteInsights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _navigateToLeagueTables() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteInsights.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteInsights.length,
        itemBuilder: (context, index) {
          return _buildFavoriteCard(_favoriteInsights[index]);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(TeamInsight insight) {
    final teamData = _allTeams.cast<Map<String, dynamic>>().firstWhere(
          (t) => t['id'] == insight.teamId,
      orElse: () => <String, dynamic>{},
    );

    final String division = teamData['division']?.toString() ?? teamData['divisionName']?.toString() ?? 'NHL Team';

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
          child: Column(
            children: [
              Row(
                children: [
                  // ✅ ВИПРАВЛЕННЯ: Logo з підтримкою SVG і PNG
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
                        const SizedBox(height: 2),
                        Text(
                          division,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.star,
                    color: Color(0xFF0F265C),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: 'Last 10',
                      value: insight.record,
                      color: const Color(0xFF0F265C),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Goal diff',
                      value: insight.goalDiffFormatted,
                      color: _getGoalDiffColor(insight.goalDifferential),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      label: 'PP%',
                      value: '${insight.powerPlayPercent.toStringAsFixed(0)}%',
                      color: const Color(0xFF0F265C),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      label: 'PK%',
                      value: '${insight.penaltyKillPercent.toStringAsFixed(0)}%',
                      color: const Color(0xFF0F265C),
                    ),
                  ),
                ],
              ),
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

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Lato',
          ),
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No teams followed yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add teams to your favorites to track their trends',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _navigateToLeagueTables,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F265C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Go to Standings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}