import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/backup_providers.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metaAsync = ref.watch(cloudMetadataProvider);
    final backupState = ref.watch(backupNotifierProvider);
    final isWorking = backupState is BackupInProgress &&
        backupState.operation == BackupOperation.backup;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.cloudArrowUp(
                  PhosphorIconsStyle.fill,
                ),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Sauvegarder',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dernière sauvegarde
          metaAsync.when(
            data: (meta) {
              if (meta == null) {
                return Text(
                  'Aucune sauvegarde cloud',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              }
              final fmt = DateFormat(
                'dd MMM yyyy à HH:mm',
                'fr_FR',
              );
              return Text(
                'Dernière : ${fmt.format(meta.createdAt)}'
                '\n${meta.totalItems} éléments',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              );
            },
            loading: () => Text(
              'Vérification...',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            error: (_, __) => Text(
              'Impossible de vérifier le cloud',
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isWorking
                  ? null
                  : () => ref
                      .read(
                        backupNotifierProvider.notifier,
                      )
                      .backup(),
              icon: isWorking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      PhosphorIcons.cloudArrowUp(
                        PhosphorIconsStyle.bold,
                      ),
                      size: 18,
                    ),
              label: Text(
                isWorking
                    ? 'Sauvegarde en cours...'
                    : 'Sauvegarder maintenant',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
