import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Кастомний date picker з кольорами додатку
class CustomDatePicker {
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return await showDialog<DateTime>(
      context: context,
      builder: (context) => _CustomDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
}

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const _CustomDatePickerDialog({
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<_CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  bool _isDateSelectable(DateTime date) {
    if (widget.firstDate != null && date.isBefore(widget.firstDate!)) {
      return false;
    }
    if (widget.lastDate != null && date.isAfter(widget.lastDate!)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF8ACEF2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                'SELECT DATE',
                style: TextStyle(
                  color: Color(0xFF0F265C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(height: 12),

              // Month navigation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left, color: Color(0xFF0F265C), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_displayedMonth),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F265C),
                          fontFamily: 'Lato',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right, color: Color(0xFF0F265C), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Calendar grid
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Weekday headers (M T W T F S S)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                          .map((day) => SizedBox(
                        width: 32,
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B9EB8),
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 4),

                    // Calendar days
                    ..._buildCalendarRows(),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Selected date display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F265C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0F265C), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF0F265C),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        color: Color(0xFF0F265C),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedDate);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F265C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'SELECT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                        fontSize: 14,
                      ),
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

  List<Widget> _buildCalendarRows() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday - 1; // Monday = 0 (was Sunday = 0)

    final List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Add empty cells for days before month starts
    for (int i = 0; i < startWeekday; i++) {
      currentRow.add(const SizedBox(width: 32, height: 32));
    }

    // Add days of month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      final isSelectable = _isDateSelectable(date);

      currentRow.add(_buildDayCell(day, isSelected, isToday, isSelectable, date));

      // Start new row after Sunday
      if (currentRow.length == 7) {
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: currentRow,
          ),
        ));
        currentRow = [];
      }
    }

    // Add empty cells to complete last row
    while (currentRow.length < 7) {
      currentRow.add(const SizedBox(width: 32, height: 32));
    }
    if (currentRow.isNotEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: currentRow,
        ),
      ));
    }

    return rows;
  }

  Widget _buildDayCell(
      int day, bool isSelected, bool isToday, bool isSelectable, DateTime date) {
    return InkWell(
      onTap: isSelectable
          ? () {
        setState(() {
          _selectedDate = date;
        });
      }
          : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F265C)
              : isToday
              ? const Color(0xFF93C3DD)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isToday && !isSelected
              ? Border.all(color: const Color(0xFF0F265C), width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isSelectable
                  ? const Color(0xFF0F265C)
                  : const Color(0xFF6B9EB8).withOpacity(0.3),
              fontFamily: 'Lato',
            ),
          ),
        ),
      ),
    );
  }
}