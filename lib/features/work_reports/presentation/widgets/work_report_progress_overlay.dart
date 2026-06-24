import 'package:flutter/material.dart';
import 'package:monitor/core/theme_config.dart';

enum WorkReportSubmissionStage {
  idle,
  converting,
  uploading,
  finalizing,
  success,
}

class WorkReportProgressOverlay extends StatelessWidget {
  final WorkReportSubmissionStage stage;
  final bool isVisible;

  const WorkReportProgressOverlay({
    super.key,
    required this.stage,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.kRadius * 2),
            border: Border.all(color: AppTheme.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PROCESANDO ENVÍO',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              _buildStep(
                label: 'Procesando contenido',
                isActive: stage == WorkReportSubmissionStage.converting,
                isCompleted:
                    stage.index > WorkReportSubmissionStage.converting.index,
              ),
              const SizedBox(height: 16),
              _buildStep(
                label: 'Subiendo archivos',
                isActive: stage == WorkReportSubmissionStage.uploading,
                isCompleted:
                    stage.index > WorkReportSubmissionStage.uploading.index,
              ),
              const SizedBox(height: 16),
              _buildStep(
                label: 'Finalizando',
                isActive: stage == WorkReportSubmissionStage.finalizing,
                isCompleted:
                    stage.index > WorkReportSubmissionStage.finalizing.index,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        _buildStepIcon(isActive: isActive, isCompleted: isCompleted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isActive || isCompleted
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary.withOpacity(0.5),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (isActive)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildStepIcon({required bool isActive, required bool isCompleted}) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppTheme.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.primaryAccent.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryAccent, width: 2),
        ),
        child: const Icon(Icons.circle, size: 8, color: AppTheme.primaryAccent),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.border.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderHighContrast.withOpacity(0.5), width: 1.5),
      ),
      child: const Icon(Icons.circle, size: 8, color: Colors.transparent),
    );
  }
}
