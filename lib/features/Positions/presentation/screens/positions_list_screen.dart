import 'package:flutter/material.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filters_widget.dart';
import '../widgets/positions_list_widget.dart';

class PositionsListScreen extends StatelessWidget {
  const PositionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add position
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          SearchBarWidget(),
          FiltersWidget(),
          Expanded(child: PositionsListWidget()),
        ],
      ),
    );
  }
}