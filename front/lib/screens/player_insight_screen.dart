import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/team_models.dart';
import '../models/game.dart';
import '../services/nhl_api_service.dart';
import '../services/favorites_service.dart';
import 'game_hub_screen.dart';

class PlayerInsightScreen extends StatefulWidget {
  final int playerId;
  final String playerName;

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

  // Категорія для розділу Splits
  String _selectedSplitCategory = 'Last 10';

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

    final metaParts = [position, shoots, teamAbbrev, age].where((s) => s.isNotEmpty).join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      color: _headerColor,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: _textColor),
              ),
              const Spacer(),
            ],
          ),
          Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: headshotUrl != null
                      ? DecorationImage(image: NetworkImage(headshotUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: headshotUrl == null ? Icon(Icons.person, size: 40, color: Colors.grey[400]) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor, fontFamily: 'Lato')),
                    Text('#$jersey', style: TextStyle(fontSize: 18, color: _textColor.withOpacity(0.8), fontFamily: 'Lato')),
                    Text(metaParts, style: TextStyle(fontSize: 14, color: _textColor.withOpacity(0.7), fontFamily: 'Lato')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: _buildActionButton(
              icon: _isFavorite ? Icons.star : Icons.star_outline,
              label: _isFavorite ? 'In Favorites' : 'Add to Favorites',
              isActive: _isFavorite,
              onTap: _toggleFavorite,
              isWide: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false, bool isWide = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: isWide ? 32 : 16),
        decoration: BoxDecoration(
          color: isActive ? _textColor : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isActive ? Colors.white : _textColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? Colors.white : _textColor, fontFamily: 'Lato')),
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
        children: [
          GridView.count(
            crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.2,
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
            ],
          ),
          const SizedBox(height: 24),
          _buildSparklineSection(isGoalie ? 'Saves Trend' : 'Points Trend', isGoalie ? 'saves' : 'points'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, {bool isHighlighted = false}) {
    return Container(
      decoration: BoxDecoration(color: isHighlighted ? _textColor : Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isHighlighted ? Colors.white70 : Colors.grey, fontFamily: 'Lato')),
          Text(value?.toString() ?? '-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.white : _textColor)),
        ],
      ),
    );
  }

  Widget _buildSparklineSection(String title, String key) {
    // Виправлено: Явне перетворення типів для Sparkline
    List<double> data = _gameLog
        .take(10)
        .map<double>((game) => (game[key] ?? 0).toDouble())
        .toList()
        .reversed
        .toList();

    if (data.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(height: 40, child: CustomPaint(size: const Size(double.infinity, 40), painter: SimpleSparklinePainter(data: data, color: _textColor))),
        ],
      ),
    );
  }

  // === TAB 2: SPLITS (INTERACTIVE) ===

  Widget _buildSplitsTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip('Last 10'),
              const SizedBox(width: 8),
              _buildFilterChip('Home/Away'),
              const SizedBox(width: 8),
              _buildFilterChip('By Month'),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: _buildSplitsTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedSplitCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSplitCategory = label),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? _textColor : Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : _textColor, fontFamily: 'Lato'),
        side: BorderSide(color: isSelected ? _textColor : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildSplitsTable() {
    if (_gameLog.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No data'));

    List<Map<String, dynamic>> rows = [];
    String headerLabel = 'Split';

    if (_selectedSplitCategory == 'Last 10') {
      headerLabel = 'Last 10 Games';
      rows = _gameLog.take(10).map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (_selectedSplitCategory == 'Home/Away') {
      headerLabel = 'Location';
      final homeGames = _gameLog.where((g) => g['homeRoadFlag'] == 'H');
      final roadGames = _gameLog.where((g) => g['homeRoadFlag'] == 'R');
      rows = [
        _aggregateStats(homeGames, 'Home'),
        _aggregateStats(roadGames, 'Away'),
      ];
    } else if (_selectedSplitCategory == 'By Month') {
      headerLabel = 'Month';
      Map<String, List<dynamic>> monthlyGroup = {};
      for (var game in _gameLog) {
        final date = DateTime.parse(game['gameDate']);
        final monthName = DateFormat('MMMM').format(date);
        monthlyGroup.putIfAbsent(monthName, () => []).add(game);
      }
      rows = monthlyGroup.entries.map((e) => _aggregateStats(e.value, e.key)).toList();
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(headerLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato'))),
            const Text('G', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('A', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('P', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('S', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        ...rows.map((data) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _selectedSplitCategory == 'Last 10'
                      ? 'vs ${data['opponentAbbrev']}'
                      : data['label'].toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'Lato'),
                ),
              ),
              _buildSparkBarCell(data['goals'] ?? 0),
              _buildSparkBarCell(data['assists'] ?? 0),
              _buildSparkBarCell(data['points'] ?? 0, isBold: true),
              _buildSparkBarCell(data['shots'] ?? 0),
            ],
          );
        }),
      ],
    );
  }

  Map<String, dynamic> _aggregateStats(Iterable<dynamic> games, String label) {
    int g = 0, a = 0, p = 0, s = 0;
    for (var game in games) {
      g += (game['goals'] as int? ?? 0);
      a += (game['assists'] as int? ?? 0);
      p += (game['points'] as int? ?? 0);
      s += (game['shots'] as int? ?? 0);
    }
    return {'label': label, 'goals': g, 'assists': a, 'points': p, 'shots': s};
  }

  Widget _buildSparkBarCell(int value, {bool isBold = false}) {
    return Text(value.toString(), textAlign: TextAlign.center, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: _textColor));
  }

  // === TAB 3: GAME LOG ===

  Widget _buildGameLogTab() {
    final last10 = _gameLog.take(10).toList();
    if (last10.isEmpty) return Center(child: Text('No game logs available', style: TextStyle(color: Colors.grey[600])));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: last10.length,
      itemBuilder: (context, index) => _buildGameLogItem(last10[index]),
    );
  }

  Widget _buildGameLogItem(Map<String, dynamic> game) {
    final opponent = game['opponentAbbrev'] ?? 'UNK';
    final isHome = game['homeRoadFlag'] == 'H';
    final gameId = game['gameId'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _openGameHub(gameId),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(opponent, style: TextStyle(fontWeight: FontWeight.bold, color: _textColor, fontFamily: 'Lato')),
                Text(isHome ? 'Home' : 'Away', style: const TextStyle(fontSize: 10, fontFamily: 'Lato')),
              ]),
              const Spacer(),
              Text('${game['goals']}-${game['assists']}-${game['points']}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato')),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _openGameHub(int? gameId) async {
    if (gameId == null) return;
    try {
      final game = await _apiService.getGameById(gameId);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => GameHubScreen(game: game)));
    } catch (_) {}
  }
}

// Sparkline Painter
class SimpleSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  SimpleSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final path = Path();
    final maxVal = data.reduce((c, n) => c > n ? c : n);
    final range = maxVal == 0 ? 1.0 : maxVal;
    final stepX = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / range * size.height);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}