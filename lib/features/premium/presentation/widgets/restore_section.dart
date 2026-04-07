import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/backup_providers.dart';

class RestoreSection extends ConsumerWidget {
  const RestoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupNotifierProvider);
    final isWorking = backupState is BackupInProgress &&
        backupState.operation == BackupOperation.restore;

    // Ecouter les changements de state pour snackbars
    ref.listen<BackupState>(
      backupNotifierProvider,
      (prev, next) => _onStateChange(context, ref, next),
    );

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
                PhosphorIcons.cloudArrowDown(
                  PhosphorIconsStyle.fill,
                ),
                size: 20,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              Text(
                'Restaurer',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Remplace toutes vos données locales '
            'par la sauvegarde cloud.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isWorking
                  ? null
                  : () => _confirmRestore(context, ref),
              icon: isWorking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      PhosphorIcons.cloudArrowDown(
                        PhosphorIconsStyle.bold,
                      ),
                      size: 18,
                    ),
              label: Text(
                isWorking
                    ? 'Restauration en cours...'
                    : 'Restaurer depuis le cloud',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: BorderSide(color: AppColors.info),
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

  void _confirmRestore(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer les données ?'),
        content: const Text(
          'Vos données locales seront remplacées '
          'par la sauvegarde cloud. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(backupNotifierProvider.notifier)
                  .restore();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.info,
            ),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }

  void _onStateChange(
    BuildContext context,
    WidgetRef ref,
    BackupState state,
  ) {
    final message = switch (state) {
      BackupSuccess(operation: BackupOperation.backup) =>
        'Sauvegarde réussie !',
      BackupSuccess(
        operation: BackupOperation.restore,
      ) =>
        'Restauration réussie !',
      BackupError(:final message) => message,
      _ => null,
    };
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      ref.read(backupNotifierProvider.notifier).reset();
    }
  }
}
