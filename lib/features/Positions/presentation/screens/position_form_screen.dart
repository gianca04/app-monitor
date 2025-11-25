import 'package:flutter/material.dart';

class PositionFormScreen extends StatelessWidget {
  final int? positionId;

  const PositionFormScreen({super.key, this.positionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(positionId == null ? 'Add Position' : 'Edit Position'),
      ),
      body: const Center(
        child: Text('Position Form - To be implemented'),
      ),
    );
  }
}