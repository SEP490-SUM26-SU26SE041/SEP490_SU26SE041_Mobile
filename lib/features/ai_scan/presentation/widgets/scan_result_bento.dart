import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/mock_ai_scan.dart';
import 'material_symbol.dart';

/// Bento grid kết quả chẩn đoán:
///   ┌────────────────────────────────────────────┐
///   │  Header: label + tên bệnh + severity chip   │
///   │  Confidence progress bar                    │
///   ├──────────────┬──────────────┬─────────────┤
///   │  Mức độ      │  Phát hiện   │             │
///   └──────────────┴──────────────┴─────────────┘
class ScanResultBento extends StatelessWidget {
  const ScanResultBento({super.key, required this.result});
  final DiseaseResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final severityColor = result.severity.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card chính
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outline.withAlpha(80), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KẾT QUẢ CHẨN ĐOÁN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: cs.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.diseaseName,
                          style: tt.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SeverityChip(label: result.severity.viLabel, color: severityColor),
                ],
              ),

              const SizedBox(height: 12),

              // Confidence progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: result.confidencePercent / 100,
                  minHeight: 4,
                  backgroundColor: cs.outline.withAlpha(60),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF93D962)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Độ tin cậy AI',
                    style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                  ),
                  Text(
                    '${result.confidencePercent}%',
                    style: tt.titleMedium?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Bento: 2 stat cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: MaterialSymbol.get('thermostat'),
                label: 'Mức độ',
                value: result.severity.viLabel,
                iconColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: MaterialSymbol.get('history'),
                label: 'Phát hiện',
                value: result.detectedAt,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withAlpha(80), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}