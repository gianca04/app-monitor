import 'package:flutter/material.dart';
import '../widgets/work_report_form.dart';

class WorkReportCreateScreen extends StatelessWidget {
  const WorkReportCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Work Report')),
      body: const WorkReportForm(),
    );
  }
}