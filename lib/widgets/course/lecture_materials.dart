// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizcraft/widgets/course/cards.dart'; // Or use the one defined above
import 'package:quizcraft/widgets/course/lecturematerials_modal.dart';
import 'package:quizcraft/models/lecture_materials.dart';
import 'package:quizcraft/services/provider_model.dart';

class LectureMaerialscreen extends StatefulWidget {
  const LectureMaerialscreen({
    super.key,
    required this.courseid,
    this.materials, 
  });

  final String courseid;
  final List<LectureMaterial>? materials;

  @override
  State<LectureMaerialscreen> createState() => _LectureMaerialscreenState();
}

class _LectureMaerialscreenState extends State<LectureMaerialscreen> {
  bool _isUploading = false;

  Future<void> _handleUpload() async {
    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    try {
      await Provider.of<AppProvider>(
        context,
        listen: false,
      ).handlePickMaterials(context, widget.courseid);
      // Provider should call notifyListeners() upon completion to refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture Materials'),
        elevation: 1, // Subtle shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return FutureBuilder<List<LectureMaterial>>(
            future: appProvider.getMaterials(widget.courseid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Materials',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final materials = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 80.0,
                  ), // Padding for FAB
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return GestureDetector(
                      onLongPress: () {
                        if (_isUploading) return; // Prevent modal during upload
                        showLectureMaterialsModal(
                          context: context,
                          material: material,
                          onDelete: (matToDelete) async {
                      
                            try {
                              await Provider.of<AppProvider>(
                                context,
                                listen: false,
                              ).deleteSlide(widget.courseid, matToDelete);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${matToDelete.fileName} deleted.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              Navigator.pop(context); // Close the modal
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                      child: LectureMaterialCard(material: material),
                    );
                  },
                );
              } else {
                // Empty state
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Materials Yet',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Looks like this course doesn't have any lecture materials uploaded. Tap the button below to add some!",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading
            ? null
            : _handleUpload, 
        icon: _isUploading
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.upload_file_outlined), // Changed icon
        label: Text(_isUploading ? 'UPLOADING...' : 'Upload File'),
        backgroundColor: _isUploading ? Colors.grey.shade400 : null,
        foregroundColor: Colors.white,
      ),
    );
  }
}
