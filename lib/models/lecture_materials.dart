import 'package:cloud_firestore/cloud_firestore.dart';

class LectureMaterial {  final String materialId;
  final String fileName;
  final String storagePath;
  final String fileType;
  final String fileSize;
  final Timestamp uploadedAt;
  final String status;
  // The URL or path to the processed text content derived from the original file.
  final String processedTextContentUrl;
  // An optional summary of the material's content.
  final String? summary;

  LectureMaterial({
    required this.materialId,
    required this.fileName,
    required this.storagePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.status,
    required this.processedTextContentUrl,
    this.summary,
  });


  factory LectureMaterial.fromFirestore(String id, Map<String, dynamic> data) {
    return LectureMaterial(
      materialId: id,
      fileName: data['fileName'] as String,
      storagePath: data['storagePath'] as String,
      fileType: data['fileType'] as String,
      fileSize: data['fileSize'] as String,
      uploadedAt: data['uploadedAt'] as Timestamp,
      status: data['status'] as String,
      processedTextContentUrl: data['processedTextContentUrl'] as String,
      summary: data['summary'] as String?,
    );
  }

  
  Map<String, dynamic> toFirestore() {
    return {
      'materialId':
          materialId, 
      'fileName': fileName,
      'storagePath': storagePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
      'status': status,
      'processedTextContentUrl': processedTextContentUrl,
      if (summary != null) 'summary': summary,
    };
  }

  static LectureMaterial get deletedDummy => LectureMaterial(
    materialId: 'deleted',
    fileName: 'Deleted File',
    storagePath: '',
    fileType: 'unknown',
    fileSize: '0 B',
    uploadedAt: Timestamp.now(),
    status: 'Deleted',
    processedTextContentUrl: '',
    summary: 'This file has been deleted.',
  );
}
