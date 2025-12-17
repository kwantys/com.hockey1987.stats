import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/team_models.dart';
import '../models/game.dart';
import '../services/nhl_api_service.dart';
import '../services/favorites_service.dart';
import 'game_hub_screen.dart';

class PlayerInsightScreen extends StatefulWidget {
  final int playerId;
  final String playerName; // Ім'я, яке передається з попереднього екрану

  const PlayerInsightScreen({
    super.key,
    required this.playerId,
    this.playerName = 'Player Details',
  });

  @override
  State<PlayerInsightScreen> createState() => _PlayerInsightScreenState();
}

class _PlayerInsightScreenState extends State<PlayerInsightScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NHLApiService _apiService = NHLApiService();
  final FavoritesService _favoritesService = FavoritesService();

  bool _isLoading = true;
  bool _isFavorite = false;
  Map<String, dynamic>? _playerData;
  List<dynamic> _gameLog = [];
  String? _errorMessage;

  // Стилі (як на інших екранах)
  final Color _headerColor = const Color(0xFF8ACEF2);
  final Color _bgColor = const Color(0xFFE8F4F8);
  final Color _textColor = const Color(0xFF0F265C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _checkFavorite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final landing = await _apiService.getPlayerLanding(widget.playerId);
      final logData = await _apiService.getPlayerGameLog(widget.playerId);

      if (mounted) {
        setState(() {
          _playerData = landing;
          _gameLog = logData['gameLog'] as List? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading player data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load player data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favoritesService.isFavoritePlayer(widget.playerId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _favoritesService.toggleFavoritePlayer(widget.playerId);
    await _checkFavorite();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _textColor))
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  // === HEADER ===

  Widget _buildHeader() {
    // Логіка визначення імені:
    // 1. Починаємо з того, що передали в конструктор (widget.playerName)
    // 2. Якщо завантажились деталі, пробуємо взяти ім'я звідти
    String displayName = widget.playerName;
    String? headshotUrl;
    String jersey = '#';
    String position = '';
    String shoots = '';
    String teamAbbrev = '';
    String age = '';

    if (_playerData != null) {
      final hero = _playerData!['hero'];
      if (hero != null) {
        final fName = hero['firstName']?['default']?.toString() ?? '';
        final lName = hero['lastName']?['default']?.toString() ?? '';

        if (fName.isNotEmpty || lName.isNotEmpty) {
          // Якщо є дані з API, формуємо повне ім'я без зайвих пробілів
          displayName = '$fName $lName'.trim();
        }

        jersey = hero['sweaterNumber']?.toString() ?? '#';
        headshotUrl = hero['headshot'];
      }

      position = _playerData!['position']?.toString() ?? '';
      shoots = _playerData!['shootsCatches']?.toString() ?? '';
      teamAbbrev = _playerData!['currentTeamAbbrev']?.toString() ?? '';

      if (_playerData!['birthDate'] != null) {
        try {
          final dob = DateTime.parse(_playerData!['birthDate']);
          final now = DateTime.now();
          final years = (now.difference(dob).inDays / 365.25).floor();
          age = '$years y.o.';
        } catch (_) {}
      }
    }

    // Рядок метаданих (Position • Team • Age)
    final metaParts = [position, shoots, teamAbbrev, age].where((s) => s.isNotEmpty).join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Більше відступу знизу
      color: _headerColor,
      child: Column(
        children: [
          // Back button row
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: _textColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 8),

          // Player Info Row
          Row(
            children: [
              // Headshot
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: headshotUrl != null
                      ? DecorationImage(image: NetworkImage(headshotUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: headshotUrl == null
                    ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                        fontFamily: 'Lato',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '#$jersey',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _textColor.withOpacity(0.8),
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metaParts,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textColor.withOpacity(0.7),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Button Row (Тільки Favorites)
          Center(
            child: _buildActionButton(
              icon: _isFavorite ? Icons.star : Icons.star_outline,
              label: _isFavorite ? 'In Favorites' : 'Add to Favorites',
              isActive: _isFavorite,
              onTap: _toggleFavorite,
              isWide: true, // Робимо кнопку трохи ширшою
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isWide = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: isWide ? 32 : 16),
        decoration: BoxDecoration(
          color: isActive ? _textColor : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _textColor.withOpacity(0.2)),
        ),
        child: Row( // Row для центрування іконки і тексту
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : _textColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : _textColor,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === TABS ===

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _textColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _textColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato'),
        tabs: const [
          Tab(text: 'SNAPSHOT'),
          Tab(text: 'SPLITS'),
          Tab(text: 'GAME LOG'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildSnapshotTab(),
        _buildSplitsTab(),
        _buildGameLogTab(),
      ],
    );
  }

  // === TAB 1: SNAPSHOT ===

  Widget _buildSnapshotTab() {
    final stats = _playerData?['featuredStats']?['regularSeason']?['subSeason'] ?? {};
    final isGoalie = _playerData?['position'] == 'G';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Cards (Grid)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: isGoalie
                ? [
              _buildStatCard('GP', stats['gamesPlayed']),
              _buildStatCard('W', stats['wins']),
              _buildStatCard('SV%', (stats['savePctg'] ?? 0.0).toStringAsFixed(3)),
              _buildStatCard('GAA', (stats['goalsAgainstAvg'] ?? 0.0).toStringAsFixed(2)),
            ]
                : [
              _buildStatCard('GP', stats['gamesPlayed']),
              _buildStatCard('G', stats['goals']),
              _buildStatCard('A', stats['assists']),
              _buildStatCard('P', stats['points'], isHighlighted: true),
              _buildStatCard('+/-', stats['plusMinus'], showPlus: true),
              _buildStatCard('PIM', stats['pim']),
              _buildStatCard('SOG', stats['shots']),
              _buildStatCard('TOI', '~${(stats['toi'] ?? 0) ~/ (stats['gamesPlayed'] ?? 1)}:00'),
            ],
          ),

          const SizedBox(height: 24),

          // Micro Charts (Last 10 Games Sparklines)
          if (!isGoalie) ...[
            _buildSparklineSection('Points Trend (Last 10)', 'points'),
            const SizedBox(height: 16),
            _buildSparklineSection('Shots Trend (Last 10)', 'shots'),
          ] else ...[
            _buildSparklineSection('Saves Trend (Last 10)', 'saves'),
          ],

          const SizedBox(height: 24),

          // Roles Chips
          const Text(
            'Role & Usage',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Lato'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _calculateRoles(stats, isGoalie),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, {bool isHighlighted = false, bool showPlus = false}) {
    String displayValue = value?.toString() ?? '-';
    if (showPlus && value is int && value > 0) displayValue = '+$value';

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted ? _textColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? Colors.white70 : Colors.grey,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : _textColor,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparklineSection(String title, String key) {
    List<double> data = [];
    int count = 0;
    for (var game in _gameLog) {
      if (count >= 10) break;
      data.add((game[key] ?? 0).toDouble());
      count++;
    }
    data = data.reversed.toList();

    if (data.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Lato')),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: SimpleSparklinePainter(data: data, color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _calculateRoles(Map<String, dynamic> stats, bool isGoalie) {
    List<String> roles = [];
    if (!isGoalie) {
      final ppGoals = stats['powerPlayGoals'] ?? 0;
      final shGoals = stats['shorthandedGoals'] ?? 0;
      final faceoff = stats['faceoffWinningPctg'] ?? 0.0;

      roles.add('Regular Shift');
      if (ppGoals > 2) roles.add('PP Unit');
      if (shGoals > 0) roles.add('PK Usage');
      if (faceoff > 0.55) roles.add('Faceoff Heavy');
    } else {
      roles.add('Starting Goalie');
    }

    return roles.map((role) => Chip(
      label: Text(role, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.grey),
    )).toList();
  }

  // === TAB 2: SPLITS ===

  Widget _buildSplitsTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip('Last 10', true),
              const SizedBox(width: 8),
              _buildFilterChip('Home/Away', false),
              const SizedBox(width: 8),
              _buildFilterChip('By Month', false),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildSplitsTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Chip(
      label: Text(label),
      backgroundColor: isSelected ? _textColor : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : _textColor),
      side: BorderSide(color: isSelected ? _textColor : Colors.grey.shade300),
    );
  }

  Widget _buildSplitsTable() {
    if (_gameLog.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No data'));

    final recentGames = _gameLog.take(5).toList();

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            Padding(padding: EdgeInsets.all(12), child: Text('Last 5', style: TextStyle(fontWeight: FontWeight.bold))),
            Text('G', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('A', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('P', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('S', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        ...recentGames.map((game) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'vs ${game['opponentAbbrev'] ?? 'OPP'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              _buildSparkBarCell(game['goals'] ?? 0),
              _buildSparkBarCell(game['assists'] ?? 0),
              _buildSparkBarCell(game['points'] ?? 0, isBold: true),
              _buildSparkBarCell(game['shots'] ?? 0),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSparkBarCell(int value, {bool isBold = false}) {
    return Text(
      value.toString(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: _textColor,
      ),
    );
  }

  // === TAB 3: GAME LOG ===

  Widget _buildGameLogTab() {
    final last10 = _gameLog.take(10).toList();

    if (last10.isEmpty) {
      return Center(child: Text('No game logs available', style: TextStyle(color: Colors.grey[600])));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: last10.length,
      itemBuilder: (context, index) {
        final game = last10[index];
        return _buildGameLogItem(game);
      },
    );
  }

  Widget _buildGameLogItem(Map<String, dynamic> game) {
    final date = game['gameDate'] ?? '';
    final opponent = game['opponentAbbrev'] ?? 'UNK';
    final isHome = game['homeRoadFlag'] == 'H';
    final goals = game['goals'] ?? 0;
    final assists = game['assists'] ?? 0;
    final points = game['points'] ?? 0;
    final shots = game['shots'] ?? 0;
    final toi = game['toi'] ?? '00:00';
    final gameId = game['gameId'];

    String dateStr = date;
    try {
      final dt = DateTime.parse(date);
      dateStr = DateFormat('MMM d').format(dt);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _openGameHub(gameId, date),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '${isHome ? 'vs' : '@'} $opponent',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLogStat('$goals-$assists-$points', 'G-A-P'),
                    _buildLogStat('$shots', 'SOG'),
                    _buildLogStat(toi, 'TOI'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _openGameHub(int? gameId, String dateStr) async {
    if (gameId == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading game...'), duration: Duration(seconds: 1)),
      );
      final game = await _apiService.getGameById(gameId);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameHubScreen(game: game)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load game details')),
        );
      }
    }
  }
}

// === Custom Painter ===
class SimpleSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SimpleSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;

    final maxVal = data.reduce((curr, next) => curr > next ? curr : next);
    final minVal = data.reduce((curr, next) => curr < next ? curr : next);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final stepX = width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minVal) / range;
      final y = height - (normalizedY * height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minVal) / range;
      final y = height - (normalizedY * height);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}