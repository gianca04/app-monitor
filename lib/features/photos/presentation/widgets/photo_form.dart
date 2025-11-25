import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _workReportIdController,
              decoration: const InputDecoration(labelText: 'Work Report ID'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Work Report ID is required' : null,
            ),
            TextFormField(
              controller: _afterWorkDescriptionController,
              decoration: const InputDecoration(labelText: 'After Work Description'),
              validator: (value) => value?.isEmpty ?? true ? 'After Work Description is required' : null,
            ),
            TextFormField(
              controller: _beforeWorkDescriptionController,
              decoration: const InputDecoration(labelText: 'Before Work Description'),
              validator: (value) => value?.isEmpty ?? true ? 'Before Work Description is required' : null,
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.photo == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final photo = Photo(
        id: widget.photo?.id,
        workReportId: int.parse(_workReportIdController.text),
        afterWork: AfterWork(
          photoUrl: widget.photo?.afterWork.photoUrl,
          description: _afterWorkDescriptionController.text,
        ),
        beforeWork: BeforeWork(
          photoUrl: widget.photo?.beforeWork.photoUrl,
          description: _beforeWorkDescriptionController.text,
        ),
        timestamps: widget.photo?.timestamps ?? Timestamps(createdAt: '', updatedAt: ''),
      );

      if (widget.photo == null) {
        ref.read(photosProvider.notifier).createPhoto(photo);
      } else {
        ref.read(photosProvider.notifier).updatePhoto(widget.photo!.id!, photo);
      }

      Navigator.of(context).pop();
    }
  }
}