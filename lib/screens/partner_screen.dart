import 'package:flutter/material.dart';
import '../services/partner_service.dart';

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  _PartnerScreenState createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _partnerController = TextEditingController();

  final PartnerService _partnerService = PartnerService(); // Service instance
  String? _profilePictureUrl; // Stores profile picture URL
  bool _isLoading = true; // Loading state
  bool _hasError = false; // Error state

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  Future<void> _loadPartnerData() async {
    try {
      final data = await _partnerService.getPartnerData();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? "Anônimo";
          _usernameController.text = data['username'] ?? "Não fornecido";
          _emailController.text = data['email'] ?? "Não fornecido";
          _ageController.text = (data['age']?.toString()) ?? "Não fornecido";
          _statusController.text = data['status'] ?? "Não fornecido";
          _partnerController.text = data['partner'] ?? "Não fornecido";
          _profilePictureUrl = data['profile_picture'];
          _hasError = false;
        });
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching partner data: $e");
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _statusController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Perfil do Parceiro',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator()) // Show loading
                : _hasError
                    ? const Center(
                        child: Text(
                          'Erro ao carregar dados do parceiro ou parceiro não encontrado.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _buildProfileContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: _profilePictureUrl != null
                ? NetworkImage(_profilePictureUrl!)
                : null,
            child: _profilePictureUrl == null
                ? const Icon(Icons.person, size: 70)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _usernameController.text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileCard('Email', _emailController),
          _buildProfileCard('Idade', _ageController),
          _buildProfileCard('Status', _statusController),
          _buildProfileCard('Parceiro', _partnerController),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String label, TextEditingController controller) {
    return Card(
      color: Colors.white.withOpacity(0.8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: Text(
                controller.text,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}