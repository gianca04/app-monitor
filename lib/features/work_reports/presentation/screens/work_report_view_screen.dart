import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/work_reports_provider.dart';
import '../../../photos/presentation/widgets/image_viewer.dart';

class WorkReportViewScreen extends ConsumerWidget {
  final int id;

  const WorkReportViewScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workReportProvider(id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0, // REGLA: Sombras eliminadas
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/work-reports'),
        ),
        title: Text(
          'WORK REPORT DETAILS', // Estilo industrial
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            letterSpacing: 1.0,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colorScheme.outline, height: 1),
        ),
        actions: [
          // REGLA: Botón con borde y feedback contenido
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/work-reports/$id/edit'),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4), // REGLA: Radio 4
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'EDIT',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : state.error != null
              ? Center(child: Text('Error: ${state.error}', style: TextStyle(color: theme.colorScheme.error)))
              : state.report == null
                  ? Center(child: Text('Report not found', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. GENERAL INFO SECTION
                          _IndustrialCard(
                            theme: theme,
                            children: [
                              _SectionHeader(theme: theme, title: 'GENERAL INFORMATION', icon: Icons.info_outline),
                              const SizedBox(height: 12),
                              Text(
                                state.report!.name?.toUpperCase() ?? 'N/A',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _InfoRow(theme: theme, label: 'DATE', value: state.report!.reportDate)),
                                  Expanded(child: _InfoRow(theme: theme, label: 'START TIME', value: state.report!.startTime)),
                                  Expanded(child: _InfoRow(theme: theme, label: 'END TIME', value: state.report!.endTime)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white10, height: 1), // REGLA: Separadores
                              const SizedBox(height: 16),
                              Text('DESCRIPTION', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                              Html(
                                data: state.report!.description ?? '',
                                style: {
                                  "body": Style(color: colorScheme.onSurface, margin: Margins.zero, fontSize: FontSize(14)),
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 2. CONTEXT (PROJECT & EMPLOYEE)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _IndustrialCard(
                                  theme: theme,
                                  children: [
                                    _SectionHeader(theme: theme, title: 'EMPLOYEE', icon: Icons.person_outline),
                                    const SizedBox(height: 12),
                                    _InfoRow(theme: theme, label: 'NAME', value: state.report!.employee?.fullName),
                                    const SizedBox(height: 8),
                                    _InfoRow(theme: theme, label: 'POSITION', value: state.report!.employee?.position?.name),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _IndustrialCard(
                                  theme: theme,
                                  children: [
                                    _SectionHeader(theme: theme, title: 'PROJECT', icon: Icons.work_outline),
                                    const SizedBox(height: 12),
                                    _InfoRow(theme: theme, label: 'NAME', value: state.report!.project?.name),
                                    const SizedBox(height: 8),
                                    _InfoRow(theme: theme, label: 'STATUS', value: state.report!.project?.status),
                                    if (state.report!.project?.subClient != null) ...[
                                      const SizedBox(height: 8),
                                      _InfoRow(theme: theme, label: 'CLIENT', value: state.report!.project?.subClient?.name),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 3. RESOURCES SECTION
                          _IndustrialCard(
                            theme: theme,
                            children: [
                              _SectionHeader(theme: theme, title: 'RESOURCES & EXECUTION', icon: Icons.construction),
                              const SizedBox(height: 12),
                              _ResourceBlock(theme: theme, title: 'TOOLS', htmlContent: state.report!.resources?.tools),
                              const Divider(color: Colors.white10),
                              _ResourceBlock(theme: theme, title: 'PERSONNEL', htmlContent: state.report!.resources?.personnel),
                              const Divider(color: Colors.white10),
                              _ResourceBlock(
                                theme: theme,
                                title: 'MATERIALS',
                                htmlContent: (state.report!.resources?.materials?.isEmpty ?? true)
                                    ? 'None'
                                    : state.report!.resources!.materials,
                              ),
                              const Divider(color: Colors.white10),
                              _ResourceBlock(theme: theme, title: 'SUGGESTIONS', htmlContent: state.report!.suggestions),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 4. PHOTOS SECTION
                          if (state.report!.photos != null && state.report!.photos!.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'ATTACHED PHOTOS (${state.report!.summary?.photosCount ?? 0})',
                                style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1.0, fontSize: 12),
                              ),
                            ),
                            ...state.report!.photos!.map((photo) => _PhotoEntryCard(theme: theme, photo: photo)),
                            const SizedBox(height: 16),
                          ],

                          // 5. SIGNATURES & TIMESTAMPS
                          _IndustrialCard(
                            theme: theme,
                            children: [
                              _SectionHeader(theme: theme, title: 'VALIDATION', icon: Icons.verified_user_outlined),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if (state.report!.signatures?.supervisor != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('SUPERVISOR', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                                          const SizedBox(height: 4),
                                          Container(
                                            decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                                            child: ImageViewer(url: state.report!.signatures!.supervisor!),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (state.report!.signatures?.supervisor != null && state.report!.signatures?.manager != null)
                                    const SizedBox(width: 16),
                                  if (state.report!.signatures?.manager != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('MANAGER', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                                          const SizedBox(height: 4),
                                          Container(
                                            decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                                            child: ImageViewer(url: state.report!.signatures!.manager!),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('CREATED: ${state.report!.timestamps?.createdAt ?? '-'}',
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.5))),
                                  Text('UPDATED: ${state.report!.timestamps?.updatedAt ?? '-'}',
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.5))),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    ),
    );
  }
}

// --- WIDGETS AUXILIARES PRIVADOS PARA DISEÑO INDUSTRIAL ---

class _IndustrialCard extends StatelessWidget {
  final ThemeData theme;
  final List<Widget> children;
  const _IndustrialCard({required this.theme, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        // REGLA: Borde recto visible y radius 4
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  const _SectionHeader({required this.theme, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String? value;
  const _InfoRow({required this.theme, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? 'N/A',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ResourceBlock extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String? htmlContent;
  const _ResourceBlock({required this.theme, required this.title, this.htmlContent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
          Html(
            data: htmlContent ?? '',
            style: {
              "body": Style(color: theme.colorScheme.onSurface, margin: Margins.zero, fontSize: FontSize(13)),
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoEntryCard extends StatelessWidget {
  final ThemeData theme;
  final dynamic photo; // Tipar esto correctamente con tu modelo si es posible
  const _PhotoEntryCard({required this.theme, required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Text(
              'PHOTO ID: ${photo.id ?? 'N/A'}',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.beforeWork.photoPath != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BEFORE', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                           decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                           child: ImageViewer(url: photo.beforeWork.photoPath!),
                        ),
                        Html(
                          data: photo.beforeWork.description ?? '',
                          style: {"body": Style(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: FontSize(11))},
                        ),
                      ],
                    ),
                  ),
                if (photo.beforeWork.photoPath != null && photo.afterWork.photoPath != null)
                  const SizedBox(width: 12),
                if (photo.afterWork.photoPath != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AFTER', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                           decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                           child: ImageViewer(url: photo.afterWork.photoPath!),
                        ),
                        Html(
                          data: photo.afterWork.description ?? '',
                          style: {"body": Style(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: FontSize(11))},
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}