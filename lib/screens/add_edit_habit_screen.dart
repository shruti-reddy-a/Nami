import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_recurrence.dart';
import '../providers/habit_provider.dart';
import '../constants/app_strings.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late HabitRecurrence _recurrence;
  late String _timeOfDay;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _recurrence = widget.habit?.recurrence ?? HabitRecurrence(frequency: RecurrenceFrequency.daily);
    _timeOfDay = widget.habit?.timeOfDay ?? 'Anytime';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (widget.habit == null) {
        final newHabit = Habit(
          title: _titleController.text.trim(),
          recurrence: _recurrence,
          timeOfDay: _timeOfDay,
        );
        ref.read(habitProvider.notifier).addHabit(newHabit);
      } else {
        final updatedHabit = widget.habit!.copyWith(
          title: _titleController.text.trim(),
          recurrence: _recurrence,
          timeOfDay: _timeOfDay,
        );
        ref.read(habitProvider.notifier).updateHabit(updatedHabit);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.targetUpdateNotice),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      Navigator.pop(context);
    }
  }

  void _showCustomRecurrenceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomRecurrenceSheet(
        initialRecurrence: _recurrence,
        onSave: (newRecurrence) {
          setState(() {
            _recurrence = newRecurrence;
          });
        },
      ),
    );
  }

  void _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        final hours = time.hour.toString().padLeft(2, '0');
        final mins = time.minute.toString().padLeft(2, '0');
        _timeOfDay = '$hours:$mins';
      });
    }
  }

  String _getFrequencyDropdownValue() {
    final str = _recurrence.toReadableString();
    if (str == 'Daily') return 'Daily';
    if (str == 'Weekly on ${_dayName(DateTime.now().weekday)}') return 'Weekly on ${_dayName(DateTime.now().weekday)}';
    if (str == 'Every weekday') return 'Every weekday (Mon-Fri)';
    return 'Custom...';
  }

  String _dayName(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.habit != null;
    
    // Frequency Options
    final currentDayStr = 'Weekly on ${_dayName(DateTime.now().weekday)}';
    final freqOptions = ['Daily', currentDayStr, 'Every weekday (Mon-Fri)', 'Custom...'];
    String currentFreqValue = _getFrequencyDropdownValue();
    if (!freqOptions.contains(currentFreqValue)) currentFreqValue = 'Custom...';

    // Time Options
    final isCustomTime = _timeOfDay.contains(':');
    final timeOptions = ['Anytime', 'Morning', 'Afternoon', 'Evening'];
    if (isCustomTime) {
      timeOptions.add(_timeOfDay);
    } else {
      timeOptions.add('Custom time...');
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editHabit : AppStrings.newHabit, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.habitTitleQuestion, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: AppStrings.habitTitleHint,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? AppStrings.habitTitleError : null,
              ),
              const SizedBox(height: 32),

              // Time Picker
              Text(AppStrings.habitTimeQuestion, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: isCustomTime ? _timeOfDay : _timeOfDay,
                    isExpanded: true,
                    items: timeOptions.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == 'Custom time...') {
                        _pickTime();
                      } else if (val != null) {
                        setState(() {
                          _timeOfDay = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Frequency Picker
              Text(AppStrings.habitFrequencyQuestion, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentFreqValue,
                    isExpanded: true,
                    items: freqOptions.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == 'Custom...') {
                        _showCustomRecurrenceSheet();
                      } else if (val != null) {
                        setState(() {
                          if (val == 'Daily') {
                            _recurrence = HabitRecurrence(frequency: RecurrenceFrequency.daily);
                          } else if (val == currentDayStr) {
                            _recurrence = HabitRecurrence(frequency: RecurrenceFrequency.weekly, daysOfWeek: [DateTime.now().weekday]);
                          } else if (val == 'Every weekday (Mon-Fri)') {
                            _recurrence = HabitRecurrence(frequency: RecurrenceFrequency.weekly, daysOfWeek: [1, 2, 3, 4, 5]);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              
              if (currentFreqValue == 'Custom...') ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showCustomRecurrenceSheet,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_calendar, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recurrence.toReadableString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.targetPreview(_recurrence.toReadableString()),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(isEditing ? AppStrings.saveChanges : AppStrings.createHabit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomRecurrenceSheet extends StatefulWidget {
  final HabitRecurrence initialRecurrence;
  final Function(HabitRecurrence) onSave;

  const _CustomRecurrenceSheet({required this.initialRecurrence, required this.onSave});

  @override
  State<_CustomRecurrenceSheet> createState() => _CustomRecurrenceSheetState();
}

class _CustomRecurrenceSheetState extends State<_CustomRecurrenceSheet> {
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
              RadioListTile<String>(
                title: const Text('Never'),
                value: 'never',
                groupValue: _endsMode,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  if (val != null) setState(() => _endsMode = val);
                },
              ),
              
              // On Date
              Row(
                children: [
                  Radio<String>(
                    value: 'on',
                    groupValue: _endsMode,
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
                  Radio<String>(
                    value: 'after',
                    groupValue: _endsMode,
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
