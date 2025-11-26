import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/photos_provider.dart';
import '../../data/models/photo.dart';

class PhotoForm extends ConsumerStatefulWidget {
  final Photo? photo;

  const PhotoForm({super.key, this.photo});

  @override
  ConsumerState<PhotoForm> createState() => _PhotoFormState();
}

class _PhotoFormState extends ConsumerState<PhotoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _workReportIdController;
  late TextEditingController _afterWorkDescriptionController;
  late TextEditingController _beforeWorkDescriptionController;

  MultipartFile? _afterWorkPhoto;
  MultipartFile? _beforeWorkPhoto;

  @override
  void initState() {
    super.initState();
    _workReportIdController = TextEditingController(text: widget.photo?.workReportId.toString() ?? '');
    _afterWorkDescriptionController = TextEditingController(text: widget.photo?.afterWork.description ?? '');
    _beforeWorkDescriptionController = TextEditingController(text: widget.photo?.beforeWork.description ?? '');
  }

  @override
  void dispose() {
    _workReportIdController.dispose();
    _afterWorkDescriptionController.dispose();
    _beforeWorkDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAfterWork) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(bytes, filename: pickedFile.name);

      setState(() {
        if (isAfterWork) {
          _afterWorkPhoto = multipartFile;
        } else {
          _beforeWorkPhoto = multipartFile;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _workReportIdController,
                decoration: const InputDecoration(labelText: 'Work Report ID'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Work Report ID is required' : null,
              ),
              const SizedBox(height: 16),
              const Text('After Work Photo'),
              ElevatedButton(
                onPressed: () => _pickImage(true),
                child: const Text('Pick After Work Photo'),
              ),
              TextFormField(
                controller: _afterWorkDescriptionController,
                decoration: const InputDecoration(labelText: 'After Work Description'),
                validator: (value) => value?.isEmpty ?? true ? 'After Work Description is required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Before Work Photo (Optional)'),
              ElevatedButton(
                onPressed: () => _pickImage(false),
                child: const Text('Pick Before Work Photo'),
              ),
              TextFormField(
                controller: _beforeWorkDescriptionController,
                decoration: const InputDecoration(labelText: 'Before Work Description'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.photo == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_afterWorkPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('After Work Photo is required')),
        );
        return;
      }

      if (widget.photo == null) {
        ref.read(photosProvider.notifier).createPhoto(
          int.parse(_workReportIdController.text),
          _afterWorkPhoto!,
          _afterWorkDescriptionController.text,
          _beforeWorkPhoto,
          _beforeWorkDescriptionController.text.isEmpty ? null : _beforeWorkDescriptionController.text,
        );
      } else {
        // For update, we might need to handle differently
        // ref.read(photosProvider.notifier).updatePhoto(widget.photo!.id!, photo);
      }

      Navigator.of(context).pop();
    }
  }
}