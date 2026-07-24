import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nami/features/habit/presentation/widgets/custom_recurrence_sheet.dart';
import 'package:nami/core/constants/app_strings.dart';
import 'package:nami/features/habit/data/habit.dart';
import 'package:nami/features/habit/data/habit_recurrence.dart';
import 'package:nami/features/habit/providers/habit_provider.dart';

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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Habit created! You can check it in the planner.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
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
      builder: (context) => CustomRecurrenceSheet(
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

