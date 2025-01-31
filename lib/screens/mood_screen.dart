import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mood_service.dart';

class EmotionTrackerScreen extends StatefulWidget {
  const EmotionTrackerScreen({super.key});

  @override
  State<EmotionTrackerScreen> createState() => _EmotionTrackerScreenState();
}

class _EmotionTrackerScreenState extends State<EmotionTrackerScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final MoodService _moodService = MoodService();
  String? _selectedMood;
  bool _isLoading = false;
  String? partnerUID;

  final List<String> _moods = ['😡', '😟', '😐', '🙂', '😃'];
  
  get title => null;

  @override
  void initState() {
    super.initState();
    _fetchPartnerUID();
  }

  Future<void> _fetchPartnerUID() async {
    final uid = await _moodService.fetchPartnerUID();
    setState(() => partnerUID = uid);
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecione um mood e justifique!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _moodService.saveMood(_selectedMood!, _reasonController.text.trim());
      _reasonController.clear();
      setState(() => _selectedMood = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood salvo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar mood: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mood do momento',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMoodSelector(),
                const SizedBox(height: 24),
                _buildReasonInput(),
                const SizedBox(height: 16),
                _buildSaveButton(),
                const SizedBox(height: 32),
                _buildMoodSections(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      children: [
        const Text(
          'Como você se sente?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _moods.map((mood) => _buildMoodButton(mood)).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodButton(String mood) {
    final isSelected = _selectedMood == mood;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Text(
          mood,
          style: TextStyle(
            fontSize: 28,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonInput() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Porque você está assim?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading
        ? null
        : () {
            FocusScope.of(context).unfocus();
            _saveMood();
          },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Salvar Mood', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildMoodSections() {
    return Expanded(
      child: Column(
        children: [
          _buildMoodListSection('Meus Moods', _moodService.getCurrentUserMoodsStream()),
          const SizedBox(height: 32),
          _buildMoodListSection(
            'Mood do seu parceiro',
            partnerUID != null ? _moodService.getPartnerMoodsStream(partnerUID) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodListSection(String title, Stream<QuerySnapshot>? stream) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: stream != null
                ? _buildMoodList(stream)
                : const Center(
                    child: Text('Parceiro não disponível.', style: TextStyle(color: Colors.white)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodList(Stream<QuerySnapshot> stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              title == 'Meus Moods' 
                ? 'Nenhum mood registrado hoje.' 
                : 'Nenhum mood registrado hoje pelo parceiro.',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final moodDocs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: moodDocs.length,
          itemBuilder: (context, index) {
            final moodData = moodDocs[index].data() as Map<String, dynamic>;
            final timestamp = moodData['timestamp'] as Timestamp?;
            
            return ListTile(
              leading: Text(moodData['mood'] ?? '🤷', style: const TextStyle(fontSize: 28, color: Colors.white)),
              title: Text(moodData['reason'] ?? 'Sem motivo', style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                timestamp != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                  : 'Sem data',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          },
        );
      },
    );
  }
}