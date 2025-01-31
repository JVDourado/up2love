import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/planner_service.dart'; // Import the service

class DatePlannerScreen extends StatefulWidget {
  const DatePlannerScreen({super.key});

  @override
  State<DatePlannerScreen> createState() => _DatePlannerScreenState();
}

class _DatePlannerScreenState extends State<DatePlannerScreen> {
  final TextEditingController _eventController = TextEditingController();
  late DateTime _selectedDate;
  late String _formattedDate;
  String? userId;
  late String _eventIdToEdit;
  bool _isLoading = false;
  final PlannerService _plannerService = PlannerService(); // Create an instance of the service

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _formattedDate = DateFormat('dd-MM-yyyy').format(_selectedDate);
    _eventIdToEdit = '';
    _getUserId();
  }

  void _getUserId() async {
    try {
      final userId = await _plannerService.getUserId();
      if (userId != null) {
        setState(() {
          this.userId = userId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao obter usuário: $e')),
      );
    }
  }

  Future<void> _saveEvent() async {
    if (_eventController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor insira um evento')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await _plannerService.saveEvent(
        userId!,
        _eventController.text,
        _formattedDate,
        _eventIdToEdit,
      );

      setState(() {
        _isLoading = false;
      });

      _eventController.clear();
      _eventIdToEdit = '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento salvo!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar evento: $e')),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _formattedDate = DateFormat('dd-MM-yyyy').format(selectedDay);
    });
  }

  Future<void> _deleteEvent(String eventId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    try {
      await _plannerService.deleteEvent(userId!, eventId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao excluir evento: $e')),
      );
    }
  }

  void _editEvent(String eventId, String eventText) {
    setState(() {
      _eventController.text = eventText;
      _eventIdToEdit = eventId;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Planejador de Dates',
        style: TextStyle(color: Colors.black),
      ),
    ),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Calendar Section
            const Text(
              'Escolha uma Data',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TableCalendar(
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: _onDaySelected,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Color.fromARGB(255, 228, 127, 212)),
                selectedTextStyle: const TextStyle(color: Colors.white),
                todayTextStyle: const TextStyle(color: Colors.pinkAccent),
                weekendTextStyle: const TextStyle(color: Colors.white),
                selectedDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 24),

            // Event Input Section
            Card(
              color: Colors.white.withOpacity(0.9),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _eventController,
                  decoration: const InputDecoration(
                    labelText: 'O que você planeja?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save Event Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEvent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvar Evento', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 32),

            // Event List Section
            const Text(
              'Meus Eventos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            userId == null
                ? const Center(child: Text('Usuário não autenticado', style: TextStyle(color: Colors.white)))
                : StreamBuilder<QuerySnapshot>(
                    stream: _plannerService.getEventsForDate(userId!, _formattedDate),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('Não há eventos para esta data.', style: TextStyle(color: Colors.white)));
                      } else {
                        final events = snapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: events.map((event) {
                            final eventText = event['event'];
                            final eventId = event.id;
                            return ListTile(
                              title: Text(eventText, style: const TextStyle(color: Colors.white)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: () => _editEvent(eventId, eventText),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    onPressed: () => _deleteEvent(eventId),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
          ],
        ),
      ),
    ),
  );
}
}