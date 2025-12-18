import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../models/user_preferences.dart'; // ДОДАНО
import '../services/nhl_api_service.dart';
import '../services/favorites_service.dart';
import '../services/preferences_service.dart'; // ДОДАНО
import '../services/notification_service.dart'; // ДОДАНО
import '../shared/services/logger.dart'; // ДОДАНО
import '../widgets/game_tabs/timeline_tab.dart';
import '../widgets/game_tabs/goals_tab.dart';
import '../widgets/game_tabs/penalties_tab.dart';
import '../widgets/game_tabs/boxscore_tab.dart';
import '../widgets/game_tabs/recap_tab.dart';
import '../../utils/game_data_parser.dart';
import 'outcome_studio_screen.dart';

/// Game Hub (Game Center) - детальна інформація про матч
class GameHubScreen extends StatefulWidget {
  final Game game;

  const GameHubScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NHLApiService _apiService = NHLApiService();
  final FavoritesService _favoritesService = FavoritesService();
  final PreferencesService _preferencesService = PreferencesService(); // ДОДАНО

  Map<String, dynamic>? _gameData;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _hasAlerts = false; // ДОДАНО: Стан сповіщень
  UserPreferences _userPrefs = const UserPreferences(); // ДОДАНО
  bool _favoritesChanged = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData(); // Оновлено для завантаження всього відразу
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Об'єднаний метод завантаження даних
  Future<void> _loadInitialData() async {
    await _checkStatus(); // Перевіряємо зірки та дзвіночки
    await _loadGameData(); // Завантажуємо API дані
  }

  Future<void> _checkStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.game.gameId);
    final hasAlerts = await _favoritesService.hasAlerts(widget.game.gameId);
    final prefs = await _preferencesService.loadPreferences();

    setState(() {
      _isFavorite = isFav;
      _hasAlerts = hasAlerts;
      _userPrefs = prefs;
    });
  }

  Future<void> _loadGameData() async {
    if (!widget.game.isLive && !widget.game.isFinal) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      AppLogger.d('=== LOADING GAME DATA FOR HUB ===');
      final landingData = await _apiService.getGameDetails(widget.game.gameId);
      final playByPlayData = await _apiService.getGamePlayByPlay(widget.game.gameId);
      final boxscoreData = await _apiService.getGameBoxscore(widget.game.gameId);

      final combinedData = {
        ...landingData,
        'plays': playByPlayData['plays'],
        'playerByGameStats': boxscoreData['playerByGameStats'],
        'boxscore': boxscoreData,
        'teamGameStats': boxscoreData['teamGameStats'],
      };

      if (mounted) {
        setState(() {
          _gameData = combinedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error loading game data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load game details';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    await _favoritesService.toggleFavoriteGame(widget.game.gameId);
    final isFav = await _favoritesService.isFavorite(widget.game.gameId);
    setState(() {
      _isFavorite = isFav;
      _favoritesChanged = true;
    });
  }

  Future<void> _toggleAlerts() async {
    try {
      // 1. Змінюємо статус у базі
      await _favoritesService.toggleAlertsForGame(widget.game.gameId);
      final hasAlerts = await _favoritesService.hasAlerts(widget.game.gameId);

      setState(() {
        _hasAlerts = hasAlerts;
        _favoritesChanged = true;
      });

      if (hasAlerts) {
        // ПЕРЕВІРКА: чи дозволені сповіщення взагалі в Settings
        if (!_userPrefs.goalAlerts) {
          AppLogger.w('Alerts are disabled in global settings');
          // Можна показати SnackBar, що сповіщення вимкнені в налаштуваннях
          return;
        }

        AppLogger.i('Enabling alerts from GameHub: ${widget.game.gameId}');

        // Плануємо початок матчу
        await NotificationService.scheduleMatchAlert(
          gameId: widget.game.gameId,
          teamNames: '${widget.game.awayTeamName} @ ${widget.game.homeTeamName}',
          startTime: widget.game.dateTime,
        );

        // Плануємо фінал за умови налаштувань
        if (_userPrefs.finalScoreAlerts) {
          await NotificationService.scheduleMatchAlert(
            gameId: widget.game.gameId + 1000000,
            teamNames: 'Final Result: ${widget.game.awayTeamName} vs ${widget.game.homeTeamName}',
            startTime: widget.game.dateTime.add(const Duration(hours: 3)),
          );
        }
      } else {
        // ЯКЩО ВИМКНУЛИ: обов'язково видаляємо заплановані завдання
        AppLogger.d('Alerts disabled from GameHub: ${widget.game.gameId}');
        await NotificationService.cancelMatchAlert(widget.game.gameId);
      }
    } catch (e, stack) {
      AppLogger.e('Error toggling alerts in Hub', e, stack);
    }
  }

  void _openPredict() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutcomeStudioScreen(prefilledGame: widget.game),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _favoritesChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F4F8),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildScoreboard(),
              _buildTabs(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF8ACEF2),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, _favoritesChanged),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F265C)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_outline,
              color: const Color(0xFF0F265C),
            ),
          ),
          // ОНОВЛЕНО: Кнопка сповіщень тепер функціональна
          IconButton(
            onPressed: _toggleAlerts,
            icon: Icon(
              _hasAlerts ? Icons.notifications : Icons.notifications_outlined,
              color: _hasAlerts ? const Color(0xFFFFA500) : const Color(0xFF0F265C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildTeam(
                  widget.game.awayTeamName,
                  widget.game.awayTeamLogo,
                  false,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              Expanded(
                child: _buildTeam(
                  widget.game.homeTeamName,
                  widget.game.homeTeamLogo,
                  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openPredict,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.track_changes, color: Colors.white),
              label: const Text(
                'Predict',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ),
          if (widget.game.isFinal || widget.game.isLive) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Score',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B9EB8),
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${widget.game.awayTeamScore ?? 0} – ${widget.game.homeTeamScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickStats(),
          ],
          if (widget.game.isUpcoming)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                widget.game.upcomingTimeDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B9EB8),
                  fontFamily: 'Lato',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeam(String name, String? logo, bool isHome) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4F8),
            shape: BoxShape.circle,
          ),
          child: logo != null
              ? Image.network(logo, errorBuilder: (_, __, ___) => _buildLogoFallback())
              : _buildLogoFallback(),
        ),
        const SizedBox(height: 8),
        Text(
          name.split(' ').last,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F265C),
            fontFamily: 'Lato',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogoFallback() {
    return const Icon(
      Icons.sports_hockey,
      size: 30,
      color: Color(0xFF6B9EB8),
    );
  }

  String _getStatusText() {
    if (widget.game.isFinal) {
      return 'Final';
    } else if (widget.game.isLive) {
      return '${widget.game.periodText} • ${widget.game.timeRemaining ?? ""}';
    } else {
      return 'Upcoming';
    }
  }

  Widget _buildQuickStats() {
    if (_gameData == null) {
      return const SizedBox.shrink();
    }
    try {
      final parser = GameDataParser(_gameData!);
      final stats = parser.getTeamStats();
      final homeSog = stats['shots']?['home'] ?? 0;
      final awaySog = stats['shots']?['away'] ?? 0;
      final homePPRaw = stats['powerPlay']?['home']?.toString() ?? '0/0';
      final awayPPRaw = stats['powerPlay']?['away']?.toString() ?? '0/0';

      String formatPP(String raw) {
        try {
          final parts = raw.split('/');
          if (parts.length != 2) return '$raw (0%)';
          final goals = int.tryParse(parts[0]) ?? 0;
          final opps = int.tryParse(parts[1]) ?? 0;
          final pct = opps > 0 ? ((goals / opps) * 100).toStringAsFixed(0) : '0';
          return '$raw ($pct%)';
        } catch (e) {
          return '0/0 (0%)';
        }
      }

      return Row(
        children: [
          Expanded(child: _buildStatItem('Shots on goal', '$awaySog – $homeSog')),
          Container(width: 1, height: 30, color: const Color(0xFFE8F4F8)),
          Expanded(child: _buildStatItem('Power play', '${formatPP(awayPPRaw)} – ${formatPP(homePPRaw)}')),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildStatItem(String label, String value) {
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F265C),
            fontFamily: 'Lato',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF0F265C),
        unselectedLabelColor: const Color(0xFF6B9EB8),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Lato'),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Lato'),
        indicatorColor: const Color(0xFF0F265C),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'TIMELINE'),
          Tab(text: 'GOALS'),
          Tab(text: 'PENALTIES'),
          Tab(text: 'BOXSCORE'),
          Tab(text: 'RECAP'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (!widget.game.isLive && !widget.game.isFinal) return _buildEmptyState();
    if (_errorMessage != null) return _buildErrorState();
    return TabBarView(
      controller: _tabController,
      children: [
        TimelineTab(gameData: _gameData),
        GoalsTab(gameData: _gameData),
        PenaltiesTab(gameData: _gameData),
        BoxscoreTab(gameData: _gameData),
        RecapTab(gameData: _gameData),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_hockey, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Game details are not available yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6B9EB8), fontFamily: 'Lato'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check again closer to puck drop.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B9EB8), fontFamily: 'Lato'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 16, color: Colors.red, fontFamily: 'Lato'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGameData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F265C)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}