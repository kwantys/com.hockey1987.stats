import 'package:flutter/material.dart';
import '../services/nhl_api_service.dart';
import '../services/favorites_service.dart';
import '../models/favorites_store.dart';
import 'team_profile_screen.dart';

/// Teams Screen - shows all NHL teams grouped by division
class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final NHLApiService _apiService = NHLApiService();
  final FavoritesService _favoritesService = FavoritesService();

  FavoritesStore _favorites = const FavoritesStore();
  Map<String, List<Map<String, dynamic>>> _teamsByDivision = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load favorites
      final favorites = await _favoritesService.loadFavorites();

      // Load all teams
      final teams = await _apiService.getAllTeams();

      // Group teams by division
      final Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var team in teams) {
        final division = team['division'] ?? 'Unknown Division';
        if (!grouped.containsKey(division)) {
          grouped[division] = [];
        }
        grouped[division]!.add(team);
      }

      // Sort teams within each division by name
      for (var division in grouped.keys) {
        grouped[division]!.sort((a, b) =>
            (a['name'] as String).compareTo(b['name'] as String));
      }

      setState(() {
        _favorites = favorites;
        _teamsByDivision = grouped;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading teams: $e');
      setState(() {
        _errorMessage = 'Failed to load teams';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(int teamId) async {
    await _favoritesService.toggleFavoriteTeam(teamId);
    final favorites = await _favoritesService.loadFavorites();
    setState(() {
      _favorites = favorites;
    });
  }

  void _openTeamProfile(Map<String, dynamic> team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamProfileScreen(
          teamId: team['id'] as int,
        ),
      ),
    ).then((_) {
      // Reload favorites when returning
      _loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8ACEF2),
        automaticallyImplyLeading: false, // No back button - has bottom nav
        title: const Text(
          'Teams',
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
          : _errorMessage != null
          ? _buildErrorState()
          : _buildTeamsList(),
    );
  }

  Widget _buildTeamsList() {
    if (_teamsByDivision.isEmpty) {
      return _buildEmptyState();
    }

    // Sort divisions alphabetically
    final sortedDivisions = _teamsByDivision.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadTeams,
      color: const Color(0xFF0F265C),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDivisions.length,
        itemBuilder: (context, index) {
          final division = sortedDivisions[index];
          final teams = _teamsByDivision[division]!;
          return _buildDivisionSection(division, teams);
        },
      ),
    );
  }

  Widget _buildDivisionSection(String division, List<Map<String, dynamic>> teams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (division != 'Unknown Division')
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
            child: Text(
              division,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B9EB8),
                fontFamily: 'Lato',
              ),
            ),
          ),
        ...teams.map((team) => _buildTeamTile(team)).toList(),
      ],
    );
  }

  Widget _buildTeamTile(Map<String, dynamic> team) {
    final teamId = team['id'] as int;
    final teamName = team['name'] as String;
    final division = team['division'] as String?;
    final isFavorite = _favorites.isFavoriteTeam(teamId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTeamProfile(team),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Team logo placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      teamName.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F265C),
                          fontFamily: 'Lato',
                        ),
                      ),
                      if (division != null)
                        Text(
                          division,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B9EB8),
                            fontFamily: 'Lato',
                          ),
                        ),
                    ],
                  ),
                ),
                // Favorite button
                IconButton(
                  onPressed: () => _toggleFavorite(teamId),
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_outline,
                    color: isFavorite
                        ? const Color(0xFF0F265C)
                        : const Color(0xFF6B9EB8),
                  ),
                  tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                ),
                // Open profile button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Open profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFFFA500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_hockey,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No teams found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTeams,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F265C),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}