import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/{{name.snakeCase()}}_provider.dart';

/// Écran principal de {{name.pascalCase()}}
class {{name.pascalCase()}}Screen extends ConsumerWidget {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final {{name.camelCase()}}State = ref.watch({{name.camelCase()}}NotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('{{name.titleCase()}}'),
      ),
      body: {{name.camelCase()}}State.when(
        data: (items) => _buildContent(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aucun élément',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Commencez par en ajouter un',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(item.id),
            onTap: () {
              // TODO: Navigation vers le détail
            },
          ),
        );
      },
    );
  }
}
