import 'package:flutter/material.dart';
import 'package:nami/features/habit/data/habit_recurrence.dart';
import 'package:nami/core/constants/app_strings.dart';
class CustomRecurrenceSheet extends StatefulWidget {
  final HabitRecurrence initialRecurrence;
  final ValueChanged<HabitRecurrence> onSave;

  const CustomRecurrenceSheet({super.key, required this.initialRecurrence, required this.onSave});

  @override
  State<CustomRecurrenceSheet> createState() => CustomRecurrenceSheetState();
}

class CustomRecurrenceSheetState extends State<CustomRecurrenceSheet> {
  late RecurrenceFrequency _frequency;
  late int _interval;
  late List<int> _daysOfWeek;
  int? _dayOfMonth;
  
  DateTime? _endDate;
  int? _endOccurrences;
  String _endsMode = 'never'; // never, on, after

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialRecurrence.frequency;
    _interval = widget.initialRecurrence.interval;
    _daysOfWeek = List.from(widget.initialRecurrence.daysOfWeek);
    _dayOfMonth = widget.initialRecurrence.dayOfMonth;
    
    _endDate = widget.initialRecurrence.endDate;
    _endOccurrences = widget.initialRecurrence.endOccurrences;
    if (_endDate != null) {
      _endsMode = 'on';
    } else if (_endOccurrences != null) {
      _endsMode = 'after';
    } else {
      _endsMode = 'never';
    }
  }

  void _save() {
    widget.onSave(HabitRecurrence(
      frequency: _frequency,
      interval: _interval,
      daysOfWeek: _frequency == RecurrenceFrequency.weekly ? _daysOfWeek : [],
      dayOfMonth: _frequency == RecurrenceFrequency.monthly ? (_dayOfMonth ?? 1) : null,
      endDate: _endsMode == 'on' ? _endDate : null,
      endOccurrences: _endsMode == 'after' ? (_endOccurrences ?? 13) : null,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Custom recurrence', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(AppStrings.repeatEvery, style: theme.textTheme.bodyLarge),
                  const SizedBox(width: 16),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      initialValue: _interval.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: InputBorder.none),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) setState(() => _interval = parsed);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RecurrenceFrequency>(
                          value: _frequency,
                          isExpanded: true,
                          items: RecurrenceFrequency.values.map((f) {
                            String label = '';
                            if (f == RecurrenceFrequency.daily) label = AppStrings.days;
                            if (f == RecurrenceFrequency.weekly) label = AppStrings.weeks;
                            if (f == RecurrenceFrequency.monthly) label = AppStrings.months;
                            return DropdownMenuItem(value: f, child: Text(label));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _frequency = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_frequency == RecurrenceFrequency.weekly) ...[
                const SizedBox(height: 24),
                Text(AppStrings.repeatOn, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                    final isSelected = _daysOfWeek.contains(day);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _daysOfWeek.remove(day);
                          } else {
                            _daysOfWeek.add(day);
                            _daysOfWeek.sort();
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day - 1],
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (_frequency == RecurrenceFrequency.monthly) ...[
                 const SizedBox(height: 24),
                 Row(
                   children: [
                     Text('On day', style: theme.textTheme.bodyLarge),
                     const SizedBox(width: 16),
                     Container(
                       width: 80,
                       padding: const EdgeInsets.symmetric(horizontal: 12),
                       decoration: BoxDecoration(
                         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: TextFormField(
                         initialValue: (_dayOfMonth ?? 1).toString(),
                         keyboardType: TextInputType.number,
                         textAlign: TextAlign.center,
                         decoration: const InputDecoration(border: InputBorder.none),
                         onChanged: (val) {
                           final parsed = int.tryParse(val);
                           if (parsed != null && parsed >= 1 && parsed <= 31) setState(() => _dayOfMonth = parsed);
                         },
                       ),
                     ),
                   ]
                 )
              ],
              
              const SizedBox(height: 32),
              Text('Ends', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Never
              // ignore: deprecated_member_use
              RadioListTile<String>(
                title: const Text('Never'),
                value: 'never',
                // ignore: deprecated_member_use
                groupValue: _endsMode,
                contentPadding: EdgeInsets.zero,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  if (val != null) setState(() => _endsMode = val);
                },
              ),
              
              // On Date
              Row(
                children: [
                  // ignore: deprecated_member_use
                  Radio<String>(
                    value: 'on',
                    // ignore: deprecated_member_use
                    groupValue: _endsMode,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _endsMode = val;
                          _endDate ??= DateTime.now().add(const Duration(days: 30));
                        });
                      }
                    },
                  ),
                  Text('On', style: theme.textTheme.bodyLarge),
                  const SizedBox(width: 16),
                  if (_endsMode == 'on') ...[
                     GestureDetector(
                       onTap: () async {
                         final date = await showDatePicker(
                           context: context,
                           initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                           firstDate: DateTime.now(),
                           lastDate: DateTime.now().add(const Duration(days: 3650)),
                         );
                         if (date != null) setState(() => _endDate = date);
                       },
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Text(_endDate != null ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}' : 'Select Date', style: theme.textTheme.bodyMedium),
                       ),
                     ),
                  ] else ...[
                     Opacity(
                       opacity: 0.5,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Text(_endDate != null ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}' : 'Select Date'),
                       ),
                     ),
                  ],
                ],
              ),
              
              // After Occurrences
              Row(
                children: [
                  // ignore: deprecated_member_use
                  Radio<String>(
                    value: 'after',
                    // ignore: deprecated_member_use
                    groupValue: _endsMode,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _endsMode = val;
                          _endOccurrences ??= 13;
                        });
                      }
                    },
                  ),
                  Text('After', style: theme.textTheme.bodyLarge),
                  const SizedBox(width: 16),
                  if (_endsMode == 'after') ...[
                     Container(
                       width: 80,
                       padding: const EdgeInsets.symmetric(horizontal: 12),
                       decoration: BoxDecoration(
                         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: TextFormField(
                         initialValue: (_endOccurrences ?? 13).toString(),
                         keyboardType: TextInputType.number,
                         textAlign: TextAlign.center,
                         decoration: const InputDecoration(border: InputBorder.none),
                         onChanged: (val) {
                           final parsed = int.tryParse(val);
                           if (parsed != null && parsed > 0) setState(() => _endOccurrences = parsed);
                         },
                       ),
                     ),
                     const SizedBox(width: 8),
                     const Text('occurrences'),
                  ] else ...[
                     Opacity(
                       opacity: 0.5,
                       child: Row(
                         children: [
                           Container(
                             width: 80,
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                             decoration: BoxDecoration(
                               color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text((_endOccurrences ?? 13).toString(), textAlign: TextAlign.center),
                           ),
                           const SizedBox(width: 8),
                           const Text('occurrences'),
                         ],
                       ),
                     ),
                  ],
                ],
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: theme.colorScheme.outline)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
