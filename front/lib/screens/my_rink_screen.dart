import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ← ДОДАНО
import 'package:intl/intl.dart';
import '../models/team_models.dart';
import '../models/game.dart';
import '../models/user_preferences.dart';
import '../services/nhl_api_service.dart';
import '../services/favorites_service.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import '../shared/services/logger.dart';
import 'team_profile_screen.dart';
import 'game_hub_screen.dart';
import 'player_insight_screen.dart';
import 'standings_screen.dart';

class MyRinkScreen extends StatefulWidget {
  const MyRinkScreen({super.key});

  @override
  State<MyRinkScreen> createState() => _MyRinkScreenState();
}

class _MyRinkScreenState extends State<MyRinkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NHLApiService _apiService = NHLApiService();
  final FavoritesService _favoritesService = FavoritesService();
  final PreferencesService _preferencesService = PreferencesService();

  // Data
  List<Team> _favoriteTeams = [];
  List<Game> _favoriteGames = [];
  List<Map<String, dynamic>> _favoritePlayersData = [];
  UserPreferences _userPrefs = const UserPreferences();

  bool _isLoading = true;
  List<int> _gamesWithAlerts = [];

  // Styles
  final Color _textColor = const Color(0xFF0F265C);
  final Color _headerColor = const Color(0xFF8ACEF2);
  final Color _detailsButtonColor = const Color(0xFF8ACEF2);

  late final TextStyle _appBarTitleStyle = TextStyle(
      fontFamily: 'Lato',
      fontWeight: FontWeight.bold,
      color: _textColor
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites(showLoading: true);
    FavoritesService.updateNotifier.addListener(_onFavoritesUpdated);
  }

  @override
  void dispose() {
    FavoritesService.updateNotifier.removeListener(_onFavoritesUpdated);
    _tabController.dispose();
    super.dispose();
  }

  void _onFavoritesUpdated() {
    _loadFavorites(showLoading: false);
  }

  Future<void> _loadFavorites({bool showLoading = false}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isLoading = true);

    try {
      final favTeamsIds = await _favoritesService.getFavoriteTeams();
      final favGamesIds = await _favoritesService.getFavoriteGames();
      final favPlayersIds = await _favoritesService.getFavoritePlayers();
      final alerts = await _favoritesService.getGamesWithAlerts();
      final prefs = await _preferencesService.loadPreferences();

      // --- TEAMS ---
      final teams = <Team>[];
      for (var id in favTeamsIds) {
        if (id <= 0 || id > 1000) {
          AppLogger.d('Skipping suspicious team ID: $id');
          continue;
        }

        try {
          final data = await _apiService.getTeamInfo(id);

          if (data.isEmpty) continue;

          // ✅ ВИПРАВЛЕННЯ: Додаємо fallback для логотипу
          String? abbrev;
          final abbrevData = data['teamAbbrev'];
          abbrev = abbrevData is Map ? abbrevData['default'] : abbrevData?.toString();

          print('📊 Team data for ID $id:');
          print('   Name: ${data['teamName']}');
          print('   Abbrev: $abbrev');
          print('   Logo (before): ${data['teamLogo']}');

          if (data['teamLogo'] == null && abbrev != null && abbrev.isNotEmpty) {
            data['teamLogo'] = 'https://assets.nhle.com/logos/nhl/svg/${abbrev}_light.svg';
          }

          // Очищаємо URL від query параметрів
          if (data['teamLogo'] != null && data['teamLogo'].toString().contains('?')) {
            data['teamLogo'] = data['teamLogo'].toString().split('?').first;
          }

          print('   Logo (after): ${data['teamLogo']}');

          teams.add(Team.fromJson(data));
          AppLogger.d('✅ Loaded team ${data['teamName']} with logo: ${data['teamLogo']}');
        } catch (e) {
          AppLogger.w('Could not load team info for ID $id: $e');
        }
      }

      // --- GAMES ---
      final games = <Game>[];
      for (var id in favGamesIds) {
        try {
          final game = await _apiService.getGameById(id);
          games.add(game);
        } catch (e) {
          AppLogger.e('Error loading game $id: $e');
        }
      }
      games.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      // --- PLAYERS ---
      final players = <Map<String, dynamic>>[];
      for (var id in favPlayersIds) {
        try {
          final data = await _apiService.getPlayerLanding(id);
          data['id'] = id;
          players.add(data);
        } catch (e) {
          AppLogger.e('Error loading player $id: $e');
        }
      }

      if (mounted) {
        setState(() {
          _favoriteTeams = teams;
          _favoriteGames = games;
          _favoritePlayersData = players;
          _gamesWithAlerts = alerts;
          _userPrefs = prefs;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('CRITICAL Error loading favorites', e, stack);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  Future<void> _toggleGameAlert(Game game) async {
    try {
      await _favoritesService.toggleAlertsForGame(game.gameId);
      final currentAlerts = await _favoritesService.getGamesWithAlerts();

      final bool isEnabledNow = currentAlerts.contains(game.gameId);

      if (isEnabledNow) {
        AppLogger.i('💡 Scheduling alerts from MyRink for: ${game.gameId}');

        await NotificationService.scheduleMatchAlert(
          gameId: game.gameId,
          teamNames: '${game.awayTeamName} @ ${game.homeTeamName}',
          startTime: game.dateTime,
        );

        if (_userPrefs.finalScoreAlerts) {
          await NotificationService.scheduleMatchAlert(
            gameId: game.gameId + 1000000,
            teamNames: 'Final Score: ${game.awayTeamName} vs ${game.homeTeamName}',
            startTime: game.dateTime.add(const Duration(hours: 3)),
          );
        }
      } else {
        AppLogger.d('🐛 Alerts disabled from MyRink for: ${game.gameId}');
        await NotificationService.cancelMatchAlert(game.gameId);
      }

      if (mounted) {
        setState(() {
          _gamesWithAlerts = currentAlerts;
        });
      }
    } catch (e, stack) {
      AppLogger.e('Failed to toggle alert in MyRink', e, stack);
    }
  }

  Future<void> _removeTeam(int teamId) async {
    await _favoritesService.toggleFavoriteTeam(teamId);
  }

  Future<void> _removeGame(int gameId) async {
    await _favoritesService.toggleFavoriteGame(gameId);
  }

  Future<void> _removePlayer(int playerId) async {
    await _favoritesService.toggleFavoritePlayer(playerId);
  }

  String _getPlayerName(Map<String, dynamic> data) {
    String extract(dynamic val) {
      if (val == null) return '';
      if (val is Map) return val['default']?.toString() ?? '';
      return val.toString();
    }
    try {
      if (data.containsKey('hero')) {
        final hero = data['hero'];
        final f = extract(hero['firstName']);
        final l = extract(hero['lastName']);
        if (f.isNotEmpty || l.isNotEmpty) return '$f $l'.trim();
      }
      final fTop = extract(data['firstName']);
      final lTop = extract(data['lastName']);
      if (fTop.isNotEmpty || lTop.isNotEmpty) return '$fTop $lTop'.trim();
      final common = extract(data['commonName']);
      if (common.isNotEmpty) return common;
      return 'Player';
    } catch (e) {
      return 'Player';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      appBar: AppBar(
        title: Text('My Rink', style: _appBarTitleStyle),
        backgroundColor: _headerColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              labelColor: _textColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _textColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato'),
              tabs: const [
                Tab(text: 'TEAMS'),
                Tab(text: 'GAMES'),
                Tab(text: 'PLAYERS'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildTeamsTab(),
                _buildGamesTab(),
                _buildPlayersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    if (_favoriteTeams.isEmpty) {
      return _buildEmptyState(
        'No teams tracked yet.',
        'Open league tables',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StandingsScreen())),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _favoriteTeams.length,
      itemBuilder: (context, index) {
        final team = _favoriteTeams[index];

        // ✅ ВИПРАВЛЕННЯ: Очищаємо URL від query параметрів
        String? cleanLogo = team.teamLogo;
        if (cleanLogo != null && cleanLogo.contains('?')) {
          cleanLogo = cleanLogo.split('?').first;
          print('🧹 Team logo cleaned: ${team.teamLogo} -> $cleanLogo');
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TeamProfileScreen(teamId: team.teamId, team: team)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ ВИПРАВЛЕННЯ: Підтримка як SVG так і PNG
                  Expanded(
                    child: _buildTeamLogoWidget(cleanLogo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.teamName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato', fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    team.divisionName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => _removeTeam(team.teamId),
                      child: const Icon(Icons.favorite, color: Colors.red, size: 24),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ НОВИЙ МЕТОД: Визначає тип файлу та використовує відповідний віджет
  Widget _buildTeamLogoWidget(String? logoUrl) {
    print('🖼️ Building logo widget for: $logoUrl');

    if (logoUrl == null || logoUrl.isEmpty) {
      print('❌ Logo URL is null or empty');
      return const Icon(Icons.shield, size: 50, color: Colors.grey);
    }

    // Перевіряємо розширення файлу
    final isPNG = logoUrl.toLowerCase().endsWith('.png');
    final isSVG = logoUrl.toLowerCase().endsWith('.svg');

    print('   isPNG: $isPNG, isSVG: $isSVG');

    if (isPNG) {
      print('✅ Loading as PNG');
      // PNG - використовуємо Image.network
      return Image.network(
        logoUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ PNG loaded successfully');
            return child;
          }
          print('⏳ Loading PNG... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ PNG load error: $error');
          return const Icon(Icons.shield, size: 50, color: Colors.grey);
        },
      );
    } else if (isSVG) {
      print('✅ Loading as SVG');
      // SVG - використовуємо SvgPicture.network
      return SvgPicture.network(
        logoUrl,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      print('❌ Unknown format');
      // Невідомий формат
      return const Icon(Icons.shield, size: 50, color: Colors.grey);
    }
  }

  Widget _buildGamesTab() {
    if (_favoriteGames.isEmpty) {
      return _buildEmptyState('No games tracked yet.', null, null);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteGames.length,
      itemBuilder: (context, index) {
        final game = _favoriteGames[index];
        final alertsEnabled = _gamesWithAlerts.contains(game.gameId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: game.isLive ? Colors.red.shade100 : const Color(0xFFE8F4F8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        game.isLive ? 'LIVE • ${game.liveTimeDisplay}' : (game.isFinal ? 'FINAL' : DateFormat('MMM d, HH:mm').format(game.dateTime)),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: game.isLive ? Colors.red : _textColor,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _removeGame(game.gameId),
                      child: const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTeamRow(game.awayTeamName, game.awayTeamLogo, game.awayTeamScore)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('vs', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: _buildTeamRow(game.homeTeamName, game.homeTeamLogo, game.homeTeamScore)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: alertsEnabled,
                          onChanged: (val) => _toggleGameAlert(game),
                          activeColor: _textColor,
                        ),
                        const Text('Alerts', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameHubScreen(game: game))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _detailsButtonColor,
                        minimumSize: const Size(100, 36),
                      ),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ ВИПРАВЛЕННЯ: Очищаємо URL від query параметрів
  Widget _buildTeamRow(String name, String? logo, int? score) {
    // Видаляємо query параметри типу ?season=20252026
    String? cleanLogo = logo;
    if (logo != null && logo.contains('?')) {
      cleanLogo = logo.split('?').first;
      print('🧹 Cleaned: $logo -> $cleanLogo');
    }

    return Column(
      children: [
        if (cleanLogo != null && cleanLogo.isNotEmpty)
          SvgPicture.network(
            cleanLogo,
            width: 40,
            height: 40,
            placeholderBuilder: (context) => const SizedBox(
              width: 40,
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            fit: BoxFit.contain,
          )
        else
          const Icon(Icons.sports_hockey, size: 40, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (score != null)
          Text(
            score.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildPlayersTab() {
    if (_favoritePlayersData.isEmpty) return _buildEmptyState('No players tracked yet.', null, null);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritePlayersData.length,
      itemBuilder: (context, index) {
        final data = _favoritePlayersData[index];
        final id = data['id'] as int;
        final name = _getPlayerName(data);
        final hero = data['hero'];
        final headshot = hero?['headshot'];
        final team = data['currentTeamAbbrev'] ?? 'UNK';
        final position = data['position'] ?? '-';
        final stats = data['featuredStats']?['regularSeason']?['subSeason'];
        final gp = stats?['gamesPlayed'] ?? 0;
        final points = stats?['points'] ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: headshot != null
                ? CircleAvatar(backgroundImage: NetworkImage(headshot))
                : const CircleAvatar(child: Icon(Icons.person)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$position • $team\n$points P in $gp GP'),
            trailing: IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: () => _removePlayer(id)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerInsightScreen(playerId: id, playerName: name))),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg, String? btnLabel, VoidCallback? onBtn) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          if (btnLabel != null && onBtn != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBtn,
              style: ElevatedButton.styleFrom(
                backgroundColor: _headerColor,
                foregroundColor: _textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(btnLabel),
            ),
          ]
        ],
      ),
    );
  }
}