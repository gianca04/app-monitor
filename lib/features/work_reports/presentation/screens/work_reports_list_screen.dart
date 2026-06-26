import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../projects/data/models/project.dart' as proj;
import '../../../projects/presentation/providers/projects_provider.dart';
import '../providers/work_reports_provider.dart';
import '../widgets/work_report_list_item.dart';
import '../widgets/reports_empty_state.dart' as empty_state;
import '../widgets/reports_fab_menu.dart' as fab_menu;
import 'package:monitor/core/widgets/modern_bottom_modal.dart';
import 'package:monitor/core/theme_config.dart';

import 'package:monitor/core/widgets/industrial_feedback.dart';

class WorkReportsListScreen extends ConsumerStatefulWidget {
  final int? projectId;
  final Map<String, dynamic>? extra;
  const WorkReportsListScreen({super.key, this.projectId, this.extra});

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
      ref
          .read(workReportsProvider.notifier)
          .setFilters(projectId: widget.projectId);
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
      IndustrialFeedback.showSuccess(context, message: message);
      // setFilters already triggers a reload, so we skip it here if init
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

  String _formatDateRange(String? start, String? end) {
    if (start == null && end == null) return 'Sin fecha definida';

    String formatSingleDate(String? dateStr) {
      if (dateStr == null) return '-';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return dateStr.split('T')[0];
      }
    }

    return '${formatSingleDate(start)}  ~  ${formatSingleDate(end)}';
  }

  Widget _buildProjectHeader(BuildContext context, proj.Project project) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.kRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.kRadius - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IBM Carbon Top Accent Bar (stretched to edges)
            Container(
              height: 4.0,
              width: double.infinity,
              color: AppTheme.primaryAccent,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monospace Tag / Project Label (Carbon pattern)
                  Text(
                    'PROYECTO #${project.id ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAccent,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Project Name
                  Text(
                    project.name ?? 'Sin nombre',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Client and Sub-client badges
                  if (project.clientName != null ||
                      project.subClientName != null) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (project.clientName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryAccent.withOpacity(0.08),
                              border: Border.all(
                                color: AppTheme.secondaryAccent.withOpacity(
                                  0.3,
                                ),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.kRadius,
                              ),
                            ),
                            child: Text(
                              '${project.clientName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        if (project.subClientName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary.withOpacity(0.06),
                              border: Border.all(
                                color: AppTheme.textSecondary.withOpacity(0.2),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.kRadius,
                              ),
                            ),
                            child: Text(
                              '${project.subClientName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Date Range
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDateRange(project.startDate, project.endDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workReportsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final projectsState = ref.watch(projectsProvider);
    final project = widget.projectId != null
        ? projectsState.projects.firstWhere(
            (p) => p.id == widget.projectId,
            orElse: () => proj.Project(
              id: widget.projectId,
              name: 'Proyecto #${widget.projectId}',
            ),
          )
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.projectId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/work-reports');
                  }
                },
              )
            : null,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar reportes...',
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            filled: true,
            fillColor:
                theme.inputDecorationTheme.fillColor ?? AppTheme.inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                );
              },
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
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
                ? Column(
                    children: [
                      if (project != null)
                        _buildProjectHeader(context, project),
                      Expanded(
                        child: empty_state.ReportsEmptyState(
                          error: state.error,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(15.0),
                    itemCount:
                        (project != null ? 1 : 0) +
                        state.reports.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (project != null && index == 0) {
                        return _buildProjectHeader(context, project);
                      }
                      final reportIndex = project != null ? index - 1 : index;
                      if (reportIndex == state.reports.length) {
                        // Loading indicator at the end
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final report = state.reports[reportIndex];
                      return WorkReportListItem(report: report);
                    },
                  ),

          // El FAB ahora es un widget autónomo
          Positioned(
            bottom: 16,
            right: 16,
            child: fab_menu.ReportsFabMenu(projectId: widget.projectId),
          ),
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
    final theme = Theme.of(context);

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
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.colorScheme.primary),
            foregroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.kRadius),
            ),
          ),
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
