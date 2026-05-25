import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '_shared_sheet_fields.dart';

/// Bottom sheet pour créer ou éditer une entrée de carnet de notes.
class AddJournalEntrySheet extends ConsumerStatefulWidget {
  /// Entrée existante en cas d'édition.
  final JournalEntry? existing;

  const AddJournalEntrySheet({super.key, this.existing});

  static Future<void> show(
    BuildContext context, {
    JournalEntry? existing,
  }) {
    return AppBottomSheet.show(
      context: context,
      heightFraction: 0.9,
      child: AddJournalEntrySheet(existing: existing),
    );
  }

  @override
  ConsumerState<AddJournalEntrySheet> createState() =>
      _AddJournalEntrySheetState();
}

class _AddJournalEntrySheetState
    extends ConsumerState<AddJournalEntrySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _entryDate;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _contentController =
        TextEditingController(text: existing?.content ?? '');
    _entryDate = existing?.entryDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canSave => _contentController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final existing = widget.existing;
      if (existing != null) {
        await db.updateJournalEntry(
          existing.id,
          content: content,
          title: title.isEmpty ? null : title,
          entryDate: _entryDate,
        );
      } else {
        await db.insertJournalEntry(JournalEntriesCompanion.insert(
          entryDate: _entryDate,
          content: content,
          title: title.isEmpty ? const Value.absent() : Value(title),
        ));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.notebook(PhosphorIconsStyle.fill),
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isEditing
                      ? loc.addJournalEditTitle
                      : loc.addJournalSheetTitle,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              CarnetSheetLabel(text: loc.addJournalDateLabel),
              const SizedBox(height: 6),
              CarnetDateField(
                value: _entryDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                onChanged: (d) => setState(() => _entryDate = d),
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addJournalTitleLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: carnetSheetInputDecoration().copyWith(
                  hintText: loc.addJournalTitleHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              CarnetSheetLabel(text: loc.addJournalContentLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: 12,
                decoration: carnetSheetInputDecoration().copyWith(
                  hintText: loc.addJournalContentHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _canSave && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing
                        ? loc.addJournalUpdateButton
                        : loc.addJournalSaveButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
