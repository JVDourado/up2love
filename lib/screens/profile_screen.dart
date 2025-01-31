import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/profile_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController? _nameController;
  TextEditingController? _usernameController;
  TextEditingController? _emailController;
  TextEditingController? _ageController;
  TextEditingController? _statusController;
  TextEditingController? _partnerController;

  bool _isEditing = false;
  final ProfileService _profileService = ProfileService();

  @override
  void dispose() {
    _nameController?.dispose();
    _usernameController?.dispose();
    _emailController?.dispose();
    _ageController?.dispose();
    _statusController?.dispose();
    _partnerController?.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      String userUID = FirebaseAuth.instance.currentUser!.uid;

      try {
        var userProfileRef = FirebaseFirestore.instance.collection('users').doc(userUID);
        DocumentSnapshot userProfileSnapshot = await userProfileRef.get();
        String? currentProfilePicUrl = userProfileSnapshot.get('profile_picture');

        if (currentProfilePicUrl != null && currentProfilePicUrl.isNotEmpty) {
          await _profileService.deleteOldProfilePicture(userUID, currentProfilePicUrl);
        }

        String? newImageUrl = await _profileService.uploadProfilePicture(imageFile, userUID);
        if (newImageUrl != null) {
          await userProfileRef.update({'profile_picture': newImageUrl});
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao carregar a imagem. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

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
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.black)),
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
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _profileService.getUserProfile(user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar os dados'));
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('Usuário não encontrado'));
                }

                var profileData = snapshot.data!;

                _nameController ??= TextEditingController(text: profileData['name']);
                _usernameController ??= TextEditingController(text: profileData['username']);
                _emailController ??= TextEditingController(text: profileData['email']);
                _ageController ??= TextEditingController(text: profileData['age']?.toString() ?? "");
                _statusController ??= TextEditingController(text: profileData['status']);
                _partnerController ??= TextEditingController(text: profileData['partner']);

                bool hasPartner = profileData['partnerUID'] != null;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickAndUploadProfilePicture : null, // Enable only when editing
                          child: CircleAvatar(
                            radius: 70,
                            backgroundImage: profileData['profile_picture'] != null
                                ? NetworkImage(profileData['profile_picture'])
                                : null,
                            child: profileData['profile_picture'] == null
                                ? const Icon(Icons.person, size: 70)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double maxWidth = constraints.maxWidth;
                            double fontSize = maxWidth * 0.1;
                            fontSize = fontSize > 30 ? 30 : fontSize;

                            return Text(
                              profileData['name'] ?? "Usuário Anônimo",
                              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profileData['username'] ?? "Nome de usuário não fornecido",
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        _buildProfileCard('Email', _emailController),
                        _buildProfileCard('Idade', _ageController),
                        _buildProfileCard('Status', _statusController),
                        _buildProfileCard('Parceiro', _partnerController),
                        const SizedBox(height: 24),

                        if (!_isEditing) ...[
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = true; // Enable editing mode
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                            child: const Text('Editar Perfil'),
                          ),
                        ] else ...[
                          ElevatedButton(
                            onPressed: () async {
                              await _profileService.updateUserProfile(user?.uid ?? '', {
                                'name': _nameController?.text,
                                'username': _usernameController?.text,
                                'email': _emailController?.text,
                                'age': _ageController?.text,
                                'status': _statusController?.text,
                                'partner': _partnerController?.text,
                              });
                              setState(() {
                                _isEditing = false; // Disable editing mode
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Perfil atualizado com sucesso!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                            child: const Text('Salvar mudanças'),
                          ),
                        ],

                        const SizedBox(height: 24),

                        if (!hasPartner) ...[
                          ElevatedButton(
                            onPressed: () async {
                              _showSyncDialog(context);
                            },
                            style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                            child: const Text('Sincronizar com parceiro', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                        const SizedBox(height: 32),

                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              _showLogoutConfirmationDialog(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                            child: const Text('Logout', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String label, TextEditingController? controller) {
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
            ),
            Expanded(
              child: _isEditing
                  ? TextField(controller: controller, decoration: InputDecoration(border: OutlineInputBorder(), labelText: label))
                  : Text(controller?.text ?? 'Não fornecido', style: const TextStyle(fontSize: 18, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSyncDialog(BuildContext context) async {
    final partnerUsernameController = TextEditingController();
    final partnerEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sincronizar com parceiro'),
          content: Column(
            children: [
              TextField(
                controller: partnerUsernameController,
                decoration: const InputDecoration(labelText: 'Nome de usuário'),
              ),
              TextField(
                controller: partnerEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String? partnerUID = await _profileService.syncWithPartner(
                  partnerUsernameController.text,
                  partnerEmailController.text,
                );

                if (partnerUID != null) {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({'partnerUID': partnerUID});
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Parceiro não encontrado')),
                  );
                }
              },
              child: const Text('Sincronizar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deseja sair?'),
          content: const Text('Se você sair, perderá sua sessão atual.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: const Text('Sair'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}