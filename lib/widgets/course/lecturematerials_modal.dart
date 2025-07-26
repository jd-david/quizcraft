import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quizcraft/models/lecture_materials.dart';

Future<void> showLectureMaterialsModal({
  required BuildContext context,
  required LectureMaterial material,
  required void Function(LectureMaterial material) onDelete,
}) async {
  Color statusColor = Colors.grey;
  switch (material.status) {
    case 'Uploaded':
      statusColor = Colors.green.shade600;
      break;
    case 'Processing':
      statusColor = Colors.orange.shade600;
      break;
    case 'Failed':
      statusColor = Colors.red.shade600;
      break;
    case 'Completed': 
      statusColor = Colors.blue.shade600;
      break;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the modal to take up more screen height.
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          // Adjust padding for the keyboard when it appears.
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: ListView(
          shrinkWrap: true,
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Material file name (Title of the modal).
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                material.fileName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.deepPurple.shade700,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 10),

            // File Description section.
            Text(
              'File Description',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.black),
            ),
            const Divider(height: 20, thickness: 1),
            Text(material.summary ?? 'No summary available.'), // Display summary or a fallback.
            const SizedBox(height: 10),

            // Material Details section.
            Text(
              'Material Details',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.black),
            ),
            const Divider(height: 20, thickness: 1),

            // Detail rows for File Type, File Size, Uploaded At, and Status.
            _buildDetailRow(
              context,
              Icons.folder_open,
              'File Type',
              material.fileType,
            ),
            _buildDetailRow(
              context,
              Icons.data_usage,
              'File Size',
              material.fileSize,
            ),
            _buildDetailRow(
              context,
              Icons.cloud_upload_outlined,
              'Uploaded At',
              DateFormat(
                'MMM dd, yyyy HH:mm',
              ).format(material.uploadedAt.toDate()),
            ),
            _buildDetailRow(
              context,
              Icons.info_outline,
              'Status',
              material.status,
              // Custom widget to display status as a badge.
              trailingWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30), // Using withAlpha for subtle background
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  material.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Delete button for the material.
            ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),
                ),
                backgroundColor: WidgetStatePropertyAll(Colors.red.shade800),
              ),
              onPressed: () => onDelete(material), // Invokes the onDelete callback.
              child: Text('Delete'),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildDetailRow(
  BuildContext context,
  IconData icon,
  String label,
  String value, {
  Widget? trailingWidget,
  bool canCopy = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.deepPurple.shade400),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // Using SelectableText for paths/IDs if canCopy is true.
              canCopy
                  ? SelectableText(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    )
                  : Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
            ],
          ),
        ),
        if (trailingWidget != null) ...[
          const SizedBox(width: 10),
          trailingWidget,
        ],
      ],
    ),
  );
}
