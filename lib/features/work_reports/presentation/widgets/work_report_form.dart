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
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _statusController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report?.title ?? '');
    _descriptionController = TextEditingController(text: widget.report?.description ?? '');
    _statusController = TextEditingController(text: widget.report?.status ?? 'pending');
    _selectedDate = widget.report?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _statusController.dispose();
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
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            TextFormField(
              controller: _statusController,
              decoration: const InputDecoration(labelText: 'Status'),
              validator: (value) => value?.isEmpty ?? true ? 'Status is required' : null,
            ),
            Row(
              children: [
                Text('Date: ${_selectedDate.toString().split(' ')[0]}'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ],
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final report = WorkReport(
        id: widget.report?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        status: _statusController.text,
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