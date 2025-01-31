import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/signup_screen_service.dart';  // Import the service file

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _partnerController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  XFile? _profileImage; // To store the profile image

  final SignUpScreenService _signUpService = SignUpScreenService();

  // Function to pick image
  Future<void> _pickImage() async {
    final image = await _signUpService.pickImage();
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _profileImage == null) { // Check if the profile image is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos e adicione uma foto de perfil.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final errorMessage = await _signUpService.registerUser(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      username: _usernameController.text,
      status: _statusController.text,
      partner: _partnerController.text,
      age: _ageController.text,
      profileImage: _profileImage!,
    );

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      Navigator.pop(context);
    }

    setState(() {
      _isLoading = false;
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Cadastro',
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
                const Text(
                  'Crie sua conta',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Profile Picture Section
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null
                        ? FileImage(File(_profileImage!.path))
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.black)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildTextField(_nameController, 'Nome Completo'),
                      _buildTextField(_usernameController, 'Usuário', hasPrefix: true),
                      _buildTextField(_emailController, 'Email'),
                      _buildTextField(_passwordController, 'Senha',
                          obscureText: _obscurePassword),
                      _buildTextField(_ageController, 'Idade',
                          keyboardType: TextInputType.number),
                      _buildTextField(_statusController, 'Status'),
                      _buildTextField(
                          _partnerController, 'Parceiro (Nome/Usuário)'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      bool hasPrefix = false}) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixText: hasPrefix ? '@' : null,  // Add the prefix '@'
            suffixIcon: label == 'Senha'
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
        ),
      ),
    );
  }
}
