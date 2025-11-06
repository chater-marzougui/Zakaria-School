import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/structs.dart' as structs;
import '../services/db_service.dart';

class AddSessionScreen extends StatefulWidget {
  final structs.Session? session;

  const AddSessionScreen({super.key, this.session});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedCandidateId;
  String? _selectedInstructorId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedStatus = 'scheduled';
  String _selectedPaymentStatus = 'unpaid';
  final _noteController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _selectedCandidateId = widget.session!.candidateId;
      _selectedInstructorId = widget.session!.instructorId;
      _selectedDate = widget.session!.date;
      _startTime = _parseTimeString(widget.session!.startTime);
      _endTime = _parseTimeString(widget.session!.endTime);
      _selectedStatus = widget.session!.status;
      _selectedPaymentStatus = widget.session!.paymentStatus;
      _noteController.text = widget.session!.note;
    }
  }

  TimeOfDay _parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<TimeOfDay?> _showCustomTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    required String title,
  }) async {
    final t = AppLocalizations.of(context)!;
    
    // Round to nearest 15-minute interval
    int roundedMinute = ((initialTime.minute / 15).round() * 15) % 60;
    int roundedHour = initialTime.hour + (((initialTime.minute / 15).round() * 15) ~/ 60);
    
    TimeOfDay selectedTime = TimeOfDay(hour: roundedHour % 24, minute: roundedMinute);
    
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hour selection
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.hour),
                        ),
                        DropdownButton<int>(
                          value: selectedTime.hour,
                          items: List.generate(24, (index) => index)
                              .map((hour) => DropdownMenuItem(
                                    value: hour,
                                    child: Text(hour.toString().padLeft(2, '0')),
                                  ))
                              .toList(),
                          onChanged: (hour) {
                            if (hour != null) {
                              setState(() {
                                selectedTime = TimeOfDay(hour: hour, minute: selectedTime.minute);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Minute selection (15-minute intervals)
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Minute'),
                        ),
                        DropdownButton<int>(
                          value: selectedTime.minute,
                          items: [0, 15, 30, 45]
                              .map((minute) => DropdownMenuItem(
                                    value: minute,
                                    child: Text(minute.toString().padLeft(2, '0')),
                                  ))
                              .toList(),
                          onChanged: (minute) {
                            if (minute != null) {
                              setState(() {
                                selectedTime = TimeOfDay(hour: selectedTime.hour, minute: minute);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Preview
                    Text(
                      _formatTimeOfDay(selectedTime),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '15-minute intervals',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedTime),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? t.addSessionTitle : t.editSession),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Candidate Selection
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('candidates')
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final candidates = snapshot.data!.docs
                            .map((doc) => structs.Candidate.fromFirestore(doc))
                            .toList();

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCandidateId,
                          decoration: InputDecoration(
                            labelText: t.selectCandidate,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
                          ),
                          items: candidates.map((candidate) {
                            return DropdownMenuItem(
                              value: candidate.id,
                              child: Text(candidate.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCandidateId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return t.selectCandidate;
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Instructor Selection
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('displayName')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final instructors = snapshot.data!.docs
                            .map((doc) => structs.User.fromFirestore(doc))
                            .toList();

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedInstructorId,
                          decoration: InputDecoration(
                            labelText: t.selectInstructor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.school, color: theme.colorScheme.primary),
                          ),
                          items: instructors.map((instructor) {
                            return DropdownMenuItem(
                              value: instructor.uid,
                              child: Text(instructor.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedInstructorId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return t.selectInstructor;
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Selection
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                      title: Text(t.selectDate),
                      subtitle: Text(DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate)),
                      trailing: const Icon(Icons.chevron_right),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.primary.withAlpha(75)),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
                            title: Text(t.startTime),
                            subtitle: Text(_formatTimeOfDay(_startTime)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.primary.withAlpha(75)),
                            ),
                            onTap: () async {
                              final time = await _showCustomTimePicker(
                                context: context,
                                initialTime: _startTime,
                                title: t.startTime,
                              );
                              if (time != null) {
                                setState(() {
                                  _startTime = time;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
                            title: Text(t.endTime),
                            subtitle: Text(_formatTimeOfDay(_endTime)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.primary.withAlpha(75)),
                            ),
                            onTap: () async {
                              final time = await _showCustomTimePicker(
                                context: context,
                                initialTime: _endTime,
                                title: t.endTime,
                              );
                              if (time != null) {
                                setState(() {
                                  _endTime = time;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: t.sessionStatus,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      ),
                      items: [
                        DropdownMenuItem(value: 'scheduled', child: Text(t.scheduled)),
                        DropdownMenuItem(value: 'done', child: Text(t.done)),
                        DropdownMenuItem(value: 'missed', child: Text(t.missed)),
                        DropdownMenuItem(value: 'rescheduled', child: Text(t.rescheduled)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Status Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPaymentStatus,
                      decoration: InputDecoration(
                        labelText: t.paymentStatus,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.payment, color: theme.colorScheme.primary),
                      ),
                      items: [
                        DropdownMenuItem(value: 'paid', child: Text(t.paid)),
                        DropdownMenuItem(value: 'unpaid', child: Text(t.unpaid)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Note Field
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '${t.sessionNote} (${t.optional})',
                        hintText: t.notes,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.note, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveSession,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t.save,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Delete Button (only for editing)
                    if (widget.session != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _deleteSession,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        child: Text(
                          t.deleteSession,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
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

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final session = structs.Session(
        id: widget.session?.id ?? '',
        candidateId: _selectedCandidateId!,
        instructorId: _selectedInstructorId!,
        date: _selectedDate,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        status: _selectedStatus,
        note: _noteController.text,
        paymentStatus: _selectedPaymentStatus,
      );

      if (widget.session == null) {
        // Create new session with overlap validation
        await DatabaseService.createSession(session, checkOverlap: true);
      } else {
        // Update existing session with overlap validation
        await DatabaseService.updateSession(
          widget.session!.id,
          session.toFirestore(),
          checkOverlap: true,
        );
      }

      // Update candidate hours if session is done
      if (_selectedStatus == 'done') {
        final duration = _calculateDuration(_startTime, _endTime);
        await _updateCandidateHours(duration);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return (endMinutes - startMinutes) / 60.0;
  }

  Future<void> _updateCandidateHours(double hours) async {
    if (_selectedCandidateId == null) return;

    final candidateDoc = await FirebaseFirestore.instance
        .collection('candidates')
        .doc(_selectedCandidateId)
        .get();

    if (candidateDoc.exists) {
      final candidate = structs.Candidate.fromFirestore(candidateDoc);
      await candidateDoc.reference.update({
        'total_taken_hours': candidate.totalTakenHours + hours,
      });
    }
  }

  Future<void> _deleteSession() async {
    final t = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.confirmDelete),
        content: Text(t.deleteSessionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(t.yes),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.session != null) {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.session!.id)
          .delete();

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
