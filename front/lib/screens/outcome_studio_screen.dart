import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../services/nhl_api_service.dart';
import '../services/predictor_service.dart';
import '../widgets/custom_date_picker.dart';
import 'prediction_stats_screen.dart';

/// Outcome Studio - gamified match predictions
class OutcomeStudioScreen extends StatefulWidget {
  final Game? prefilledGame; // If opened from specific match

  const OutcomeStudioScreen({
    super.key,
    this.prefilledGame,
  });

  @override
  State<OutcomeStudioScreen> createState() => _OutcomeStudioScreenState();
}

class _OutcomeStudioScreenState extends State<OutcomeStudioScreen> {
  final NHLApiService _apiService = NHLApiService();
  final PredictorService _predictorService = PredictorService();

  // Form state
  DateTime _selectedDate = DateTime.now();
  Game? _selectedGame;
  List<Game> _availableGames = [];
  bool _isLoadingGames = false;

  // Prediction fields
  String? _winner; // 'home', 'away', 'tie'
  bool? _overtimeNeeded;
  int _totalGoals = 6;
  int? _homeScore;
  int? _awayScore;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    if (widget.prefilledGame != null) {
      _selectedGame = widget.prefilledGame;
    } else {
      _loadGamesForDate();
    }
  }

  Future<void> _loadGamesForDate() async {
    setState(() {
      _isLoadingGames = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final games = await _apiService.getScheduleByDate(dateStr);

      // Filter only upcoming games
      final upcomingGames = games.where((g) => g.isUpcoming).toList();

      setState(() {
        _availableGames = upcomingGames;
        _isLoadingGames = false;

        // Auto-select first game if available
        if (upcomingGames.isNotEmpty && _selectedGame == null) {
          _selectedGame = upcomingGames.first;
        }
      });
    } catch (e) {
      print('Error loading games: $e');
      setState(() {
        _errorMessage = 'Failed to load games';
        _isLoadingGames = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await CustomDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedGame = null;
      });
      _loadGamesForDate();
    }
  }

  void _clearForm() {
    setState(() {
      _winner = null;
      _overtimeNeeded = null;
      _totalGoals = 6;
      _homeScore = null;
      _awayScore = null;
      _errorMessage = null;
    });
  }

  Future<void> _submitPrediction() async {
    print('=== SUBMIT PREDICTION DEBUG ===');

    // Validation
    if (_selectedGame == null) {
      print('❌ No game selected');
      setState(() {
        _errorMessage = 'Please select a game';
      });
      return;
    }

    print('✅ Game selected: ${_selectedGame!.gameId}');

    if (_winner == null) {
      print('❌ No winner selected');
      setState(() {
        _errorMessage = 'Please select a winner';
      });
      return;
    }

    print('✅ Winner selected: $_winner');

    if (_overtimeNeeded == null) {
      print('❌ Overtime not selected');
      setState(() {
        _errorMessage = 'Please indicate if overtime is needed';
      });
      return;
    }

    print('✅ Overtime selected: $_overtimeNeeded');

    // Check if game is still upcoming
    if (!_selectedGame!.isUpcoming) {
      print('❌ Game is not upcoming: status=${_selectedGame!.status}');
      setState(() {
        _errorMessage = 'Predictions are closed for this game';
      });
      return;
    }

    print('✅ Game is upcoming');

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Check if prediction already exists
      print('🔍 Checking for existing prediction...');
      final existingPrediction =
      await _predictorService.getPredictionForGame(_selectedGame!.gameId);

      print('Result: $existingPrediction');

      if (existingPrediction != null) {
        print('❌ Prediction already exists!');
        print('Existing prediction ID: ${existingPrediction['id']}');
        print('Created at: ${existingPrediction['createdAt']}');

        setState(() {
          _errorMessage = 'You already submitted a prediction for this game';
          _isSubmitting = false;
        });
        return;
      }

      print('✅ No existing prediction found, creating new one...');

      // Create prediction
      final prediction = {
        'gamePk': _selectedGame!.gameId,
        'winner': _winner,
        'overtimeNeeded': _overtimeNeeded,
        'totalGoals': _totalGoals,
        'homeScore': _homeScore,
        'awayScore': _awayScore,
      };

      print('Prediction data: $prediction');

      final saved = await _predictorService.savePrediction(prediction);

      if (!saved) {
        print('❌ Failed to save prediction');
        setState(() {
          _errorMessage = 'Failed to save prediction';
          _isSubmitting = false;
        });
        return;
      }

      print('✅ Prediction saved successfully!');

      if (!mounted) return;

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prediction submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _clearForm();

      setState(() {
        _isSubmitting = false;
      });

      print('=== SUBMIT COMPLETE ===');
    } catch (e) {
      print('❌ Exception during submit: $e');
      print('Stack trace: ${StackTrace.current}');

      setState(() {
        _errorMessage = 'Failed to submit prediction: $e';
        _isSubmitting = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8ACEF2),
        title: const Text(
          'Outcome Studio',
          style: TextStyle(
            color: Color(0xFF0F265C),
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PredictionStatsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart, color: Color(0xFF0F265C)),
            tooltip: 'View my stats',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Make your call on tonight\'s games',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B9EB8),
                  fontFamily: 'Lato',
                ),
              ),

              const SizedBox(height: 24),

              // Game selector (if not prefilled)
              if (widget.prefilledGame == null) ...[
                _buildGameSelector(),
                const SizedBox(height: 24),
              ],

              // Selected game display
              if (_selectedGame != null) ...[
                _buildGameDisplay(),
                const SizedBox(height: 24),
              ],

              // Prediction form
              if (_selectedGame != null) ...[
                _buildPredictionForm(),
                const SizedBox(height: 24),
              ],

              // Rules card
              _buildRulesCard(),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              if (_selectedGame != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPrediction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Submit prediction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: _clearForm,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F265C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF0F265C)),
                      ),
                    ),
                    child: const Text(
                      'Clear form',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameSelector() {
    return Container(
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
            'Select Game',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),

          // Date picker
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Color(0xFF0F265C), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat('EEE, MMM d').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF0F265C)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Game dropdown
          if (_isLoadingGames)
            const Center(child: CircularProgressIndicator())
          else if (_availableGames.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No upcoming games on this date',
                style: TextStyle(
                  color: Color(0xFF6B9EB8),
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            DropdownButtonFormField<Game>(
              value: _selectedGame,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE8F4F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              hint: const Text('Pick a game'),
              items: _availableGames.map((game) {
                return DropdownMenuItem<Game>(
                  value: game,
                  child: Text(
                    '${game.awayTeamName} @ ${game.homeTeamName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                );
              }).toList(),
              onChanged: (game) {
                setState(() {
                  _selectedGame = game;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGameDisplay() {
    if (_selectedGame == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, MMM d • h:mm a').format(_selectedGame!.dateTime),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _selectedGame!.awayTeamName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Away',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B9EB8),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'vs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B9EB8),
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _selectedGame!.homeTeamName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B9EB8),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Winner
          const Text(
            'Winner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          _buildWinnerSelector(),

          const SizedBox(height: 24),

          // Overtime needed
          const Text(
            'Overtime needed?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          _buildOvertimeSelector(),

          const SizedBox(height: 24),

          // Total goals
          const Text(
            'Total goals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          _buildTotalGoalsSelector(),

          const SizedBox(height: 24),

          // Exact score (optional)
          const Text(
            'Exact score (optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          _buildExactScoreInputs(),
        ],
      ),
    );
  }

  Widget _buildWinnerSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            label: 'Home team',
            isSelected: _winner == 'home',
            onTap: () => setState(() => _winner = 'home'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOptionButton(
            label: 'Away team',
            isSelected: _winner == 'away',
            onTap: () => setState(() => _winner = 'away'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOptionButton(
            label: 'Tie after regulation',
            isSelected: _winner == 'tie',
            onTap: () => setState(() => _winner = 'tie'),
          ),
        ),
      ],
    );
  }

  Widget _buildOvertimeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            label: 'Yes',
            isSelected: _overtimeNeeded == true,
            onTap: () => setState(() => _overtimeNeeded = true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOptionButton(
            label: 'No',
            isSelected: _overtimeNeeded == false,
            onTap: () => setState(() => _overtimeNeeded = false),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F265C) : const Color(0xFFE8F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
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

  Widget _buildTotalGoalsSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _totalGoals > 0
                ? () => setState(() => _totalGoals--)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: const Color(0xFF0F265C),
          ),
          Text(
            _totalGoals.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          IconButton(
            onPressed: _totalGoals < 12
                ? () => setState(() => _totalGoals++)
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF0F265C),
          ),
        ],
      ),
    );
  }

  Widget _buildExactScoreInputs() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE8F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              hintText: 'Home',
            ),
            onChanged: (value) {
              setState(() {
                _homeScore = int.tryParse(value);
              });
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '–',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE8F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              hintText: 'Away',
            ),
            onChanged: (value) {
              setState(() {
                _awayScore = int.tryParse(value);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8ACEF2).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8ACEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 12),
          _buildRuleItem('+5 points', 'correct winner'),
          const SizedBox(height: 8),
          _buildRuleItem('+3 points', 'correct OT flag'),
          const SizedBox(height: 8),
          _buildRuleItem('+5 points', 'correct total goals'),
          const SizedBox(height: 8),
          _buildRuleItem('+10 points', 'exact score'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String points, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F265C),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            points,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Lato',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '— $description',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F265C),
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }
}