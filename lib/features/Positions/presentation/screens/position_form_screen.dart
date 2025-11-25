import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/position_provider.dart';
import '../../data/models/position.dart';

class PositionFormScreen extends ConsumerStatefulWidget {
  final int? positionId;

  const PositionFormScreen({super.key, this.positionId});

  @override
  ConsumerState<PositionFormScreen> createState() => _PositionFormScreenState();
}

class _PositionFormScreenState extends ConsumerState<PositionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _id;

  @override
  void initState() {
    super.initState();
    if (widget.positionId != null) {
      // Load existing position
      _loadPosition(widget.positionId!);
    } else {
      // Generate new id
      _generateNewId();
    }
  }

  Future<void> _generateNewId() async {
    final usecase = ref.read(getNextPositionIdUseCaseProvider);
    _id = await usecase();
    setState(() {});
  }

  Future<void> _loadPosition(int id) async {
    // For edit, need to get the position
    // Since the provider has list, find it
    final positions = ref.read(positionsProvider);
    final position = positions.firstWhere((p) => p.id == id);
    _nameController.text = position.name;
    _id = position.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.positionId == null ? 'Add Position' : 'Edit Position'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_id != null && _formKey.currentState!.validate()) {
      final position = Position(
        id: _id!,
        name: _nameController.text,
      );
      ref.read(positionsProvider.notifier).addPosition(position);
      context.go('/positions');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}