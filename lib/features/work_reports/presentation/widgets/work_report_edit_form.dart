import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../data/models/work_report.dart';
import '../providers/work_reports_provider.dart';
import '../../../photos/presentation/providers/photos_provider.dart';
import '../../../photos/presentation/widgets/image_viewer.dart';

class WorkReportForm extends ConsumerStatefulWidget {
  final WorkReport? report;

  const WorkReportForm({super.key, this.report});

  @override
  ConsumerState<WorkReportForm> createState() => _WorkReportFormState();
}

class _WorkReportFormState extends ConsumerState<WorkReportForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _reportDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _toolsController;
  late TextEditingController _personnelController;
  late TextEditingController _materialsController;
  late TextEditingController _suggestionsController;
  late TextEditingController _employeeIdController;
  late TextEditingController _projectIdController;

  MultipartFile? _supervisorSignature;
  MultipartFile? _managerSignature;
  Uint8List? _supervisorSignatureBytes;
  Uint8List? _managerSignatureBytes;

  List<Map<String, dynamic>> _photos = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.report?.name ?? '');
    _descriptionController = TextEditingController(text: widget.report?.description ?? '');
    _reportDateController = TextEditingController(text: widget.report?.reportDate ?? '');
    _startTimeController = TextEditingController(text: widget.report?.startTime ?? '');
    _endTimeController = TextEditingController(text: widget.report?.endTime ?? '');
    _toolsController = TextEditingController(text: widget.report?.resources?.tools ?? '');
    _personnelController = TextEditingController(text: widget.report?.resources?.personnel ?? '');
    _materialsController = TextEditingController(text: widget.report?.resources?.materials ?? '');
    _suggestionsController = TextEditingController(text: widget.report?.suggestions ?? '');
    _employeeIdController = TextEditingController(text: widget.report?.employee?.id.toString() ?? '');
    _projectIdController = TextEditingController(text: widget.report?.project?.id.toString() ?? '');

    if (widget.report != null) {
      for (var photo in widget.report!.photos ?? []) {
        _photos.add({
          'id': photo.id,
          'descripcion': photo.afterWork.description,
          'before_work_descripcion': photo.beforeWork.description,
          'photo': null,
          'before_work_photo': null,
          'photo_bytes': null,
          'before_work_photo_bytes': null,
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _reportDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _toolsController.dispose();
    _personnelController.dispose();
    _materialsController.dispose();
    _suggestionsController.dispose();
    _employeeIdController.dispose();
    _projectIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isSupervisor) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(bytes, filename: pickedFile.name);

      setState(() {
        if (isSupervisor) {
          _supervisorSignature = multipartFile;
          _supervisorSignatureBytes = bytes;
        } else {
          _managerSignature = multipartFile;
          _managerSignatureBytes = bytes;
        }
      });
    }
  }

  void _addPhoto() {
    setState(() {
      _photos.add({
        'descripcion': '',
        'before_work_descripcion': '',
        'photo': null,
        'before_work_photo': null,
        'photo_bytes': null,
        'before_work_photo_bytes': null,
      });
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _pickPhotoImage(int index, bool isAfterWork) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(bytes, filename: pickedFile.name);

      setState(() {
        if (isAfterWork) {
          _photos[index]['photo'] = multipartFile;
          _photos[index]['photo_bytes'] = bytes;
        } else {
          _photos[index]['before_work_photo'] = multipartFile;
          _photos[index]['before_work_photo_bytes'] = bytes;
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
                controller: _projectIdController,
                decoration: const InputDecoration(labelText: 'Project ID'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(labelText: 'Employee ID'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _reportDateController,
                decoration: const InputDecoration(labelText: 'Report Date (YYYY-MM-DD)'),
                validator: (value) => value?.isEmpty ?? true ? 'Report Date is required' : null,
              ),
              TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
              ),
              TextFormField(
                controller: _endTimeController,
                decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _toolsController,
                decoration: const InputDecoration(labelText: 'Tools'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _personnelController,
                decoration: const InputDecoration(labelText: 'Personnel'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _materialsController,
                decoration: const InputDecoration(labelText: 'Materials'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _suggestionsController,
                decoration: const InputDecoration(labelText: 'Suggestions'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text('Photos'),
              ..._photos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Photo ${index + 1}'),
                    if (photo['id'] != null) ...[
                      const Text('Current After Work Photo:'),
                      ImageViewer(url: widget.report!.photos?.firstWhere((p) => p.id == photo['id']).afterWork.photoPath ?? ''),
                      const Text('Current Before Work Photo:'),
                      ImageViewer(url: widget.report!.photos?.firstWhere((p) => p.id == photo['id']).beforeWork.photoPath ?? ''),
                    ],
                    TextFormField(
                      initialValue: photo['descripcion'],
                      decoration: const InputDecoration(labelText: 'After Work Description'),
                      onChanged: (value) => photo['descripcion'] = value,
                    ),
                    ElevatedButton(
                      onPressed: () => _pickPhotoImage(index, true),
                      child: const Text('Pick After Work Photo'),
                    ),
                    if (photo['photo_bytes'] != null)
                      Image.memory(photo['photo_bytes'], height: 100, fit: BoxFit.contain),
                    TextFormField(
                      initialValue: photo['before_work_descripcion'],
                      decoration: const InputDecoration(labelText: 'Before Work Description'),
                      onChanged: (value) => photo['before_work_descripcion'] = value,
                    ),
                    ElevatedButton(
                      onPressed: () => _pickPhotoImage(index, false),
                      child: const Text('Pick Before Work Photo'),
                    ),
                    if (photo['before_work_photo_bytes'] != null)
                      Image.memory(photo['before_work_photo_bytes'], height: 100, fit: BoxFit.contain),
                    ElevatedButton(
                      onPressed: () => _removePhoto(index),
                      child: const Text('Remove Photo'),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              ElevatedButton(
                onPressed: _addPhoto,
                child: const Text('Add Photo'),
              ),
              const SizedBox(height: 16),
              const Text('Supervisor Signature'),
              ElevatedButton(
                onPressed: () => _pickImage(true),
                child: const Text('Pick Supervisor Signature'),
              ),
              if (_supervisorSignatureBytes != null)
                Image.memory(_supervisorSignatureBytes!, height: 100, fit: BoxFit.contain),
              const SizedBox(height: 16),
              const Text('Manager Signature'),
              ElevatedButton(
                onPressed: () => _pickImage(false),
                child: const Text('Pick Manager Signature'),
              ),
              if (_managerSignatureBytes != null)
                Image.memory(_managerSignatureBytes!, height: 100, fit: BoxFit.contain),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.report == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      List<Map<String, dynamic>> validPhotos = _photos.where((photo) => photo['id'] != null || photo['photo'] != null || photo['before_work_photo'] != null).toList();
      if (widget.report == null) {
        try {
          final newReport = await ref.read(workReportsProvider.notifier).createWorkReport(
            int.parse(_projectIdController.text),
            int.parse(_employeeIdController.text),
            _nameController.text,
            _reportDateController.text,
            _startTimeController.text.isEmpty ? null : _startTimeController.text,
            _endTimeController.text.isEmpty ? null : _endTimeController.text,
            _descriptionController.text.isEmpty ? null : _descriptionController.text,
            _toolsController.text.isEmpty ? null : _toolsController.text,
            _personnelController.text.isEmpty ? null : _personnelController.text,
            _materialsController.text.isEmpty ? null : _materialsController.text,
            _suggestionsController.text.isEmpty ? null : _suggestionsController.text,
            validPhotos,
          );

          // Navigate to the detail screen of the newly created report
          if (mounted) {
            context.go('/work-reports/${newReport.id}');
          }
        } catch (e) {
          // Handle error, maybe show a snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating work report: $e')),
            );
          }
        }
      } else {
        try {
          print('Updating work report with: projectId: ${_projectIdController.text.isEmpty ? null : int.parse(_projectIdController.text)}, employeeId: ${_employeeIdController.text.isEmpty ? null : int.parse(_employeeIdController.text)}, name: ${_nameController.text}');
          await ref.read(workReportsProvider.notifier).updateWorkReport(
            widget.report!.id!,
            _projectIdController.text.isEmpty ? null : int.parse(_projectIdController.text),
            _employeeIdController.text.isEmpty ? null : int.parse(_employeeIdController.text),
            _nameController.text,
            _reportDateController.text,
            _startTimeController.text.isEmpty ? null : _startTimeController.text,
            _endTimeController.text.isEmpty ? null : _endTimeController.text,
            _descriptionController.text.isEmpty ? null : _descriptionController.text,
            _toolsController.text.isEmpty ? null : _toolsController.text,
            _personnelController.text.isEmpty ? null : _personnelController.text,
            _materialsController.text.isEmpty ? null : _materialsController.text,
            _suggestionsController.text.isEmpty ? null : _suggestionsController.text,
            _supervisorSignature,
            _managerSignature,
            validPhotos,
          );

          // Update photos separately
          for (int i = 0; i < _photos.length; i++) {
            final photo = _photos[i];
            if (photo['id'] != null) {
              MultipartFile? photoFile = photo['photo_bytes'] != null ? MultipartFile.fromBytes(photo['photo_bytes'], filename: 'photo.jpg') : null;
              MultipartFile? beforePhotoFile = photo['before_work_photo_bytes'] != null ? MultipartFile.fromBytes(photo['before_work_photo_bytes'], filename: 'before.jpg') : null;
              await ref.read(photosProvider.notifier).updatePhoto(
                photo['id'],
                photoFile,
                photo['descripcion'],
                beforePhotoFile,
                photo['before_work_descripcion'],
              );
            }
          }

          // Navigate back to the detail screen
          if (mounted) {
            context.go('/work-reports/${widget.report!.id}');
          }
        } catch (e) {
          // Handle error, maybe show a snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating work report: $e')),
            );
          }
        }
      }
    }
  }
}