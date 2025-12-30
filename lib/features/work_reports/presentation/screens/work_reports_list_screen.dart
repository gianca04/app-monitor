import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';
import '../providers/work_reports_provider.dart';
import '../widgets/work_report_list_item.dart';
import '../widgets/reports_empty_state.dart' as empty_state;
import '../widgets/reports_fab_menu.dart' as fab_menu;
import 'package:monitor/core/widgets/modern_bottom_modal.dart';
// import 'package:monitor/core/theme_config.dart';

import 'package:monitor/core/widgets/industrial_feedback.dart';

class WorkReportsListScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;
  const WorkReportsListScreen({super.key, this.extra});

  @override
  ConsumerState<WorkReportsListScreen> createState() =>
      _WorkReportsListScreenState();
}

class _WorkReportsListScreenState extends ConsumerState<WorkReportsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    // Check for extra data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleExtraData();
      ref.read(workReportsProvider.notifier).loadWorkReports();
    });
  }

  @override
  void didUpdateWidget(WorkReportsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.extra != oldWidget.extra) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleExtraData();
      });
    }
  }

  void _handleExtraData() {
    if (widget.extra != null && widget.extra!['success'] == true) {
      final message = widget.extra!['message'] ?? 'Operación exitosa';
      ScaffoldMessenger.of(context).showSnackBar(
        IndustrialFeedback.buildSuccess(
          message: message.toUpperCase(),
          onDismiss: () {},
        ),
      );
      // Force refresh if needed, although loadWorkReports is called in init
      ref.read(workReportsProvider.notifier).loadWorkReports();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSearch = ref.read(workReportsProvider).search ?? '';
    if (_searchController.text != currentSearch) {
      _searchController.text = currentSearch;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(workReportsProvider.notifier)
          .setFilters(search: _searchController.text);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(workReportsProvider.notifier).loadMoreWorkReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workReportsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar reportes...',
            hintStyle: TextStyle(color: const Color(0xFF8B949E)),
            filled: true,
            fillColor: const Color(0xFF0D1117),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(color: Color(0xFF30363D)),
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFFAB00)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          style: const TextStyle(color: Color(0xFFE1E4E8)),
        ),
        actions: [
          // Selector de elementos por página
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () =>
                      ref.read(workReportsProvider.notifier).loadWorkReports(),
            tooltip: 'RECARGAR',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showDateFilterDialog(context, ref),
            tooltip: 'FILTRAR',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (state.isLoading)
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),

          if (!state.isLoading)
            state.reports.isEmpty
                ? empty_state.ReportsEmptyState(error: state.error)
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(15.0),
                    itemCount:
                        state.reports.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == state.reports.length) {
                        // Loading indicator at the end
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final report = state.reports[index];
                      return WorkReportListItem(report: report);
                    },
                  ),

          // El FAB ahora es un widget autónomo
          Positioned(bottom: 16, right: 16, child: fab_menu.ReportsFabMenu()),
        ],
      ),
    );
  }

  void _showDateFilterDialog(BuildContext context, WidgetRef ref) {
    // Obtenemos fechas actuales del provider
    final currentState = ref.read(workReportsProvider);
    DateTime? selectedFrom = currentState.dateFrom != null
        ? DateTime.parse(currentState.dateFrom!)
        : null;
    DateTime? selectedTo = currentState.dateTo != null
        ? DateTime.parse(currentState.dateTo!)
        : null;
    int selectedPerPage = currentState.perPage ?? 10;

    ModernBottomModal.show(
      context,
      title: 'FILTROS Y CONFIGURACIÓN',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información de resultados
            if (currentState.total != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Total: ${currentState.total} reportes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

            // Selector de elementos por página
            DropdownButtonFormField<int>(
              initialValue: selectedPerPage,
              decoration: const InputDecoration(
                labelText: 'Elementos por página',
              ),
              items: [5, 10, 20, 50].map((value) {
                return DropdownMenuItem(value: value, child: Text('$value'));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedPerPage = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Filtros de fecha
            _DateInput(
              label: 'DESDE',
              date: selectedFrom,
              onPick: (d) => setState(() => selectedFrom = d),
            ),
            const SizedBox(height: 16),
            _DateInput(
              label: 'HASTA',
              date: selectedTo,
              onPick: (d) => setState(() => selectedTo = d),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: () {
            ref
                .read(workReportsProvider.notifier)
                .setFilters(
                  dateFrom: selectedFrom?.toIso8601String().split('T')[0],
                  dateTo: selectedTo?.toIso8601String().split('T')[0],
                  perPage: selectedPerPage,
                );
            Navigator.pop(context);
          },
          child: const Text('APLICAR'),
        ),
      ],
    );
  }
}

// Widget privado pequeño para evitar repetir código en el diálogo de fechas
class _DateInput extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime) onPick;

  const _DateInput({required this.label, this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
        text: date?.toIso8601String().split('T')[0],
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}
