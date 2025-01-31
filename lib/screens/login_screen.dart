import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../services/login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final LoginScreenService _loginService = LoginScreenService();

  // FocusNodes to manage keyboard behavior
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    await _loginService.loginUser(
      email: _emailController.text,
      password: _passwordController.text,
      emailController: _emailController,
      passwordController: _passwordController,
      context: context,
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resetPassword() async {
    await _loginService.resetPassword(
      email: _emailController.text,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate screen height available after keyboard shows up
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,  // Keep this as false
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Login',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
          child: GestureDetector(
            // Dismiss keyboard when tapping outside input fields
            onTap: () {
              _emailFocusNode.unfocus();
              _passwordFocusNode.unfocus();
            },
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: keyboardHeight > 0 ? keyboardHeight : 16.0,
              ),
              children: [
                Image.asset(
                  'assets/logo2.png',
                  height: 200,
                ),
                const SizedBox(height: 32),
                Card(
                  color: Colors.white.withOpacity(0.95),
                  elevation: 16,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Email Input
                        _buildTextField(_emailController, 'Email', _emailFocusNode),
                        const SizedBox(height: 16),
                        // Password Input
                        _buildTextField(
                          _passwordController,
                          'Senha',
                          _passwordFocusNode,
                          obscureText: !_isPasswordVisible,
                        ),
                        const SizedBox(height: 16),
                        // Forgot Password
                        TextButton(
                          onPressed: _resetPassword,
                          child: const Text(
                            'Esqueceu sua senha?',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(150, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Create Account Button
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Criar Conta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, FocusNode focusNode,
      {bool obscureText = false}) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: label == 'Senha'
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
          ),
          obscureText: obscureText,
        ),
      ),
    );
  }
}
