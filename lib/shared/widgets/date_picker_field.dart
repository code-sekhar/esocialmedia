import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;

  const DatePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Select date',
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(1996, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your date of birth',
      cancelText: 'Cancel',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9C27B0),
              onPrimary: Colors.white,
              surface: Color(0xFF24104A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  value != null
                      ? _monthName(value!.month)
                      : 'Month',
                  style: TextStyle(
                    color: value != null
                        ? Colors.white
                        : Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            const Text(
              '/',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),

            Expanded(
              child: Center(
                child: Text(
                  value != null
                      ? value!.day.toString().padLeft(2, '0')
                      : 'DD',
                  style: TextStyle(
                    color: value != null
                        ? Colors.white
                        : Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            const Text(
              '/',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),

            Expanded(
              child: Center(
                child: Text(
                  value != null
                      ? value!.year.toString()
                      : 'YYYY',
                  style: TextStyle(
                    color: value != null
                        ? Colors.white
                        : Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white70,
              size: 16,
            ),

            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}