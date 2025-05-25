import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageTestScreen extends ConsumerStatefulWidget {
  const StorageTestScreen({super.key});

  @override
  ConsumerState<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends ConsumerState<StorageTestScreen> {
  final _bucketName = 'uploads';
  String? _uploadedFileUrl;
  String? _error;
  bool _isUploading = false;
  List<FileObject> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await Supabase.instance.client.storage
          .from(_bucketName)
          .list();
      
      setState(() {
        _files = files;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load files: $e';
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
          _error = null;
        });

        final file = File(result.files.single.path!);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
        
        // Upload file
        await Supabase.instance.client.storage
            .from(_bucketName)
            .upload(
              fileName,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        // Get public URL
        final publicUrl = Supabase.instance.client.storage
            .from(_bucketName)
            .getPublicUrl(fileName);

        setState(() {
          _uploadedFileUrl = publicUrl;
          _isUploading = false;
        });

        // Refresh file list
        await _loadFiles();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to upload file: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      await Supabase.instance.client.storage
          .from(_bucketName)
          .remove([filePath]);
      
      // Refresh file list
      await _loadFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete file: $e')),
        );
      }
    }
  }

  Future<void> _downloadFile(String filePath) async {
    try {
      final bytes = await Supabase.instance.client.storage
          .from(_bucketName)
          .download(filePath);
      
      // Get the download directory
      final directory = Directory('/tmp/supabase_downloads');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Save the file
      final file = File('${directory.path}/$filePath');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Storage Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_uploadedFileUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Uploaded File:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(_uploadedFileUrl!),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Uploaded Files:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return ListTile(
                    title: Text(file.name),
                    subtitle: Text('Size: ${file.metadata?['size'] ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadFile(file.name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteFile(file.name),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 