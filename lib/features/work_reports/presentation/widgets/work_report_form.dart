import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/work_reports_provider.dart';
import '../../data/models/work_report.dart';

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
  late TextEditingController _suggestionsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.report?.name ?? '');
    _descriptionController = TextEditingController(text: widget.report?.description ?? '');
    _reportDateController = TextEditingController(text: widget.report?.reportDate ?? '');
    _startTimeController = TextEditingController(text: widget.report?.startTime ?? '');
    _endTimeController = TextEditingController(text: widget.report?.endTime ?? '');
    _suggestionsController = TextEditingController(text: widget.report?.suggestions ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _reportDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _suggestionsController.dispose();
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            TextFormField(
              controller: _reportDateController,
              decoration: const InputDecoration(labelText: 'Report Date (YYYY-MM-DD)'),
              validator: (value) => value?.isEmpty ?? true ? 'Report Date is required' : null,
            ),
            TextFormField(
              controller: _startTimeController,
              decoration: const InputDecoration(labelText: 'Start Time'),
            ),
            TextFormField(
              controller: _endTimeController,
              decoration: const InputDecoration(labelText: 'End Time'),
            ),
            TextFormField(
              controller: _suggestionsController,
              decoration: const InputDecoration(labelText: 'Suggestions'),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.report == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final report = WorkReport(
        id: widget.report?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        reportDate: _reportDateController.text,
        startTime: _startTimeController.text.isEmpty ? null : _startTimeController.text,
        endTime: _endTimeController.text.isEmpty ? null : _endTimeController.text,
        resources: Resources(tools: '', personnel: '', materials: ''), // Default empty
        suggestions: _suggestionsController.text,
        signatures: Signatures(supervisor: null, manager: null), // Default null
        timestamps: Timestamps(createdAt: '', updatedAt: ''), // Will be set by server
      );

      if (widget.report == null) {
        ref.read(workReportsProvider.notifier).createWorkReport(report);
      } else {
        ref.read(workReportsProvider.notifier).updateWorkReport(widget.report!.id!, report);
      }

      Navigator.of(context).pop();
    }
  }
}