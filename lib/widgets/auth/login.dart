import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizcraft/widgets/dashboard/home.dart'; 

const kBackgroundColor = Color(0xFFF4F7FE);
const kTextColor = Color(0xFF1E293B);
const kTextLightColor = Color(0xFF64748B);
const kBorderColor = Color(0xFFE2E8F0);
const kDangerColor = Color(0xFFDC3545);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- UI State Variables ---
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Firebase Actions ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        await userCredential.user?.updateDisplayName(
          _nameController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
              'createdAt': FieldValue.serverTimestamp(),
              'email': _emailController.text.trim(),
              'displayName': userCredential.user?.displayName ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_mapFirebaseAuthException(e));
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 24),

                const SizedBox(height: 32),
                _buildBottomLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/icon.png', width: 100),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            _isLogin ? 'Welcome Back!' : 'Create Account',
            key: ValueKey(_isLogin),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Enter your details to log in'
              : 'Fill in the details to get started',
          style: const TextStyle(fontSize: 16, color: kTextLightColor),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Full Name', Icons.person_outline),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration('Email', Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => !(value?.contains('@') ?? false)
                ? 'Please enter a valid email'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: _inputDecoration('Password', Icons.lock_outline)
                .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),
            validator: (value) => (value?.length ?? 0) < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isPasswordVisible,
              decoration: _inputDecoration(
                'Confirm Password',
                Icons.lock_outline,
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Passwords do not match'
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                _isLogin ? 'Log In' : 'Sign Up',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildBottomLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account?" : "Already have an account?",
          style: const TextStyle(color: kTextLightColor),
        ),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(_isLogin ? 'Sign Up' : 'Log In'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kTextLightColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: kDangerColor),
    );
  }

  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
