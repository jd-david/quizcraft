// Add these imports to your file if they aren't there already
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:quizcraft/models/quiz_generation_config.dart';
import 'package:quizcraft/models/lecture_materials.dart';

const kTextLightColor = Color(0xFF64748B);
const kBorderColor = Color(0xFFE2E8F0);

Future<void> showQuizGenerationModal({
  required BuildContext context,
  required String courseId,
  required List<LectureMaterial> coursematerials,
  required void Function(QuizGenerationConfig config) onSubmit,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return _ModalContent(
            scrollController: controller,
            courseId: courseId,
            coursematerials: coursematerials,
            onSubmit: onSubmit,
          );
        },
      );
    },
  );
}

/// The main stateful widget that holds the modal's content and state.
class _ModalContent extends StatefulWidget {
  const _ModalContent({
    required this.scrollController,
    required this.courseId,
    required this.coursematerials,
    required this.onSubmit,
  });

  final ScrollController scrollController;
  final String courseId;
  final List<LectureMaterial> coursematerials;
  final void Function(QuizGenerationConfig config) onSubmit;

  @override
  State<_ModalContent> createState() => _ModalContentState();
}

class _ModalContentState extends State<_ModalContent> {
  final _promptController = TextEditingController();
  String _difficulty = 'medium';
  int _questionCount = 5;
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedMaterials = {};

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one source material.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final config = QuizGenerationConfig(
      materials: _selectedMaterials.toList(),
      numQuestions: _questionCount,
      difficultyLevel: _difficulty,
      prompt: _promptController.text.trim().isEmpty
          ? null
          : _promptController.text.trim(),
      targetQuestionTypes: _selectedTypes.isEmpty
          ? null
          : _selectedTypes.toList(),
      courseId: widget.courseId,
    );
    widget.onSubmit(config);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> questionTypes = {
      'multiple-choice': 'Multiple Choice',
      'true-false': 'True or False',
      'short-answer': 'Short Answer',
      'fill-in-the-blank': 'Fill in the Blank',
    };

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSection(
                  icon: Icons.source_outlined,
                  title: 'Source Materials',
                  child: _buildMaterialsList(),
                ),
                _buildSection(
                  icon: Icons.format_list_numbered,
                  title: 'Number of Questions',
                  child: _buildNumberStepper(),
                ),
                _buildSection(
                  icon: Icons.speed_outlined,
                  title: 'Difficulty Level',
                  child: _buildDifficultyChips(),
                ),
                _buildSection(
                  icon: Icons.quiz_outlined,
                  title: 'Question Types (Optional)',
                  child: _buildQuestionTypeChips(questionTypes),
                ),
                _buildSection(
                  icon: Icons.edit_note_outlined,
                  title: 'Custom Prompt (Optional)',
                  child: _buildPromptField(),
                ),
                const SizedBox(height: 80), // Space for the floating button
              ],
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
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
            'Generate New Quiz',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kTextLightColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    if (widget.coursematerials.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor),
        ),
        child: const Center(
          child: Text(
            'No materials available.',
            style: TextStyle(color: kTextLightColor),
          ),
        ),
      );
    }
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.coursematerials.length,
        itemBuilder: (context, index) {
          final material = widget.coursematerials[index];
          final isSelected = _selectedMaterials.contains(
            material.processedTextContentUrl,
          );
          return CheckboxListTile(
            title: Text(
              material.fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedMaterials.add(material.processedTextContentUrl);
                } else {
                  _selectedMaterials.remove(material.processedTextContentUrl);
                }
              });
            },
            activeColor: Theme.of(context).primaryColor,
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }

  Widget _buildNumberStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepperButton(
            icon: Icons.remove,
            onPressed: _questionCount > 1
                ? () => setState(() => _questionCount--)
                : null,
          ),
          Text(
            '$_questionCount',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _buildStepperButton(
            icon: Icons.add,
            onPressed: _questionCount < 20
                ? () => setState(() => _questionCount++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onPressed != null
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onPressed != null
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDifficultyChips() {
    return Wrap(
      spacing: 8.0,
      children: ['easy', 'medium', 'hard'].map((level) {
        return ChoiceChip(
          label: Text(level[0].toUpperCase() + level.substring(1)),
          selected: _difficulty == level,
          onSelected: (bool selected) {
            if (selected) setState(() => _difficulty = level);
          },
          showCheckmark: false,
          labelStyle: TextStyle(
            color: _difficulty == level ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _difficulty == level
                  ? Theme.of(context).primaryColor
                  : kBorderColor,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionTypeChips(Map<String, String> questionTypes) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: questionTypes.keys.map((type) {
        final isSelected = _selectedTypes.contains(type);
        return ChoiceChip(
          label: Text(questionTypes[type]!),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : null,
            fontWeight: FontWeight.w500,
          ),
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : kBorderColor,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildPromptField() {
    return TextFormField(
      controller: _promptController,
      decoration: InputDecoration(
        hintText: 'e.g., "Focus on the first two lectures"',
        fillColor: Colors.white,
        filled: true,
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
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      maxLines: 3,
      minLines: 2,
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
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
        child: ElevatedButton.icon(
          onPressed: _handleSubmit,
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: const Text('Generate Quiz'),
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
        ),
      ),
    );
  }
}