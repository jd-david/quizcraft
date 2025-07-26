// lib/screens/profile_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// --- UI Color Constants ---
const kPrimaryColor = Color(0xFF78249d);
const kBackgroundColor = Color(0xFFF4F7FE);
const kTextColor = Color(0xFF1E293B);
const kTextLightColor = Color(0xFF64748B);
const kBorderColor = Color(0xFFE2E8F0);
const kDangerColor = Color(0xFFDC3545);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- State Variables ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  String? _photoURL;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _nameController.text = _user.displayName ?? '';
      _photoURL = _user.photoURL;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- Firebase Actions ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? newPhotoURL;
      // 1. Upload new image if one was selected
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_pictures/${_user!.uid}',
        );
        await ref.putFile(_imageFile!);
        newPhotoURL = await ref.getDownloadURL();
      }

      // 2. Update display name if it changed
      if (_nameController.text != _user!.displayName) {
        await _user.updateDisplayName(_nameController.text);
      }

      // 3. Update photo URL if it changed
      if (newPhotoURL != null && newPhotoURL != _photoURL) {
        await _user.updatePhotoURL(newPhotoURL);
        setState(() => _photoURL = newPhotoURL);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: kDangerColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (_user?.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to ${_user.email!}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send email: $e'),
          backgroundColor: kDangerColor,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 32),
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildActionsCard(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
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
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: kBorderColor,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (_photoURL != null ? NetworkImage(_photoURL!) : null)
                    as ImageProvider?,
          child: _imageFile == null && _photoURL == null
              ? const Icon(Icons.person, size: 60, color: kTextLightColor)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: kPrimaryColor,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: _pickImage,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Full Name', Icons.person_outline),
                validator: (value) =>
                    value!.isEmpty ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _user?.email ?? 'No email associated',
                readOnly: true,
                decoration: _inputDecoration('Email', Icons.email_outlined),
                style: const TextStyle(color: kTextLightColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline, color: kTextColor),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _changePassword,
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: kDangerColor),
              title: const Text(
                'Log Out',
                style: TextStyle(color: kDangerColor),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
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
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
    );
  }
}
