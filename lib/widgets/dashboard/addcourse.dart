import 'package:flutter/material.dart';

Future<void> showAddCourseModal({
  required BuildContext context,
  required void Function(String name, String? code) onSubmit,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Crucial for keyboard handling
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddCourseContent(onSubmit: onSubmit),
      );
    },
  );
}

/// The private widget that contains the state and UI for the modal content.
class _AddCourseContent extends StatefulWidget {
  const _AddCourseContent({required this.onSubmit});

  final void Function(String name, String? code) onSubmit;

  @override
  State<_AddCourseContent> createState() => _AddCourseContentState();
}

class _AddCourseContentState extends State<_AddCourseContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // Validate the form. If it's not valid, do nothing.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit(
      _nameController.text.trim(),
      _courseCodeController.text.trim().isEmpty
          ? null
          : _courseCodeController.text.trim(),
    );
    Navigator.of(context).pop(); // Close the modal on success
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take up only necessary space
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildFormFields(),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // --- Builder methods for cleaner structure ---

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Add a New Course',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Course Name*'),
            // decoration: _inputDecoration(''),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Course Name cannot be empty.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _courseCodeController,
            decoration: InputDecoration(labelText: 'Course Code (e.g., CS101)'),

            // decoration: _inputDecoration('Course Code (e.g., CS101)'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }


  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        // color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('Add Course'),
        ),
      ),
    );
  }
}
