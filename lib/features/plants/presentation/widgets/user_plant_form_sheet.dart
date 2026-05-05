import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/database.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../garden/domain/models/rotation_family.dart';
import '../../domain/models/user_plant_input.dart';
import 'user_plant_companion_picker.dart';
import 'user_plant_emoji_picker.dart';

/// Sheet de création / édition d'une plante personnalisée.
///
/// - Mode création : `initialPlant` null → tous les champs vides + bouton
///   "Créer".
/// - Mode édition : `initialPlant` fournie → champs pré-remplis +
///   bouton "Enregistrer" + bouton "Supprimer".
///
/// Renvoie :
/// - l'ID de la plante créée ou éditée si l'utilisateur a sauvegardé
/// - `null` si l'utilisateur a annulé / fermé sans sauver, ou si la
///   plante a été supprimée (mode édition uniquement).
///
/// Le retour permet aux callers (ex. le sheet d'ajout au potager) de
/// chaîner directement sur la plante fraîchement créée sans forcer
/// l'utilisateur à la rechercher à la main.
Future<int?> showUserPlantFormSheet({
  required BuildContext context,
  Plant? initialPlant,
}) {
  return AppBottomSheet.show<int?>(
    context: context,
    heightFraction: 0.95,
    child: UserPlantFormSheet(initialPlant: initialPlant),
  );
}

class UserPlantFormSheet extends ConsumerStatefulWidget {
  final Plant? initialPlant;

  const UserPlantFormSheet({super.key, this.initialPlant});

  @override
  ConsumerState<UserPlantFormSheet> createState() =>
      _UserPlantFormSheetState();
}

class _UserPlantFormSheetState
    extends ConsumerState<UserPlantFormSheet> {
  // ---- Champs requis ----
  final _commonNameCtrl = TextEditingController();
  PlantCategory _category = PlantCategory.fruitVegetable;
  final _spacingPlantsCtrl = TextEditingController();
  final _spacingRowsCtrl = TextEditingController();
  String? _emoji;
  // L'utilisateur a-t-il choisi manuellement un emoji (sinon on
  // suit les changements de nom).
  bool _emojiPickedManually = false;

  // ---- Calendriers (mois 1..12 sélectionnés) ----
  final Set<int> _sowingMonths = {};
  final Set<int> _plantingMonths = {};
  final Set<int> _harvestMonths = {};

  // ---- Conditions de culture ----
  final _latinNameCtrl = TextEditingController();
  final _plantingDepthCtrl = TextEditingController();
  final _minTempCtrl = TextEditingController();
  String? _sunExposure; // valeur enum-like (cf. _sunOptions)
  final _soilTypeCtrl = TextEditingController();
  final _soilMoistureCtrl = TextEditingController();
  final _wateringCtrl = TextEditingController();
  RotationFamily? _rotationFamily;
  // True si l'utilisateur a choisi manuellement la famille
  // (sinon on auto-déduit depuis le nom latin).
  bool _rotationPickedManually = false;

  // ---- Conseils ----
  final _sowingRecoCtrl = TextEditingController();
  final _plantingAdviceCtrl = TextEditingController();
  final _careAdviceCtrl = TextEditingController();
  final _redFlagsCtrl = TextEditingController();
  final _practicalTipsCtrl = TextEditingController();

  // ---- Avancé ----
  final _toxicityCtrl = TextEditingController();

  // ---- Compagnons / antagonistes ----
  List<int> _companionIds = [];
  List<int> _antagonistIds = [];

  // ---- État UI ----
  String? _errorMessage;
  bool _saving = false;

  bool get _isEdit => widget.initialPlant != null;

  List<(String, String)> _sunOptions(AppLocalizations l) => [
        ('ensoleillé', l.userPlantSunFull),
        ('mi-ombre', l.userPlantSunPartial),
        ('ombragé', l.userPlantSunShade),
      ];

  static const _englishMonths = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _commonNameCtrl.addListener(_onCommonNameChanged);
    _latinNameCtrl.addListener(_onLatinNameChanged);
    if (_isEdit) _hydrateFrom(widget.initialPlant!);
  }

  @override
  void dispose() {
    _commonNameCtrl.dispose();
    _latinNameCtrl.dispose();
    _spacingPlantsCtrl.dispose();
    _spacingRowsCtrl.dispose();
    _plantingDepthCtrl.dispose();
    _minTempCtrl.dispose();
    _soilTypeCtrl.dispose();
    _soilMoistureCtrl.dispose();
    _wateringCtrl.dispose();
    _sowingRecoCtrl.dispose();
    _plantingAdviceCtrl.dispose();
    _careAdviceCtrl.dispose();
    _redFlagsCtrl.dispose();
    _practicalTipsCtrl.dispose();
    _toxicityCtrl.dispose();
    super.dispose();
  }

  void _hydrateFrom(Plant p) {
    _commonNameCtrl.text = p.commonName;
    _latinNameCtrl.text = p.latinName ?? '';
    _category = PlantCategory.fromCode(p.categoryCode);
    _spacingPlantsCtrl.text =
        p.spacingBetweenPlants?.toString() ?? '';
    _spacingRowsCtrl.text =
        p.spacingBetweenRows?.toString() ?? '';
    _plantingDepthCtrl.text =
        p.plantingDepthCm?.toString() ?? '';
    _minTempCtrl.text = p.plantingMinTempC?.toString() ?? '';
    _emoji = PlantEmojiMapper.fromName(
      p.commonName,
      categoryCode: p.categoryCode,
    );
    // En édition on suppose que l'emoji actuel reflète un choix
    // — désactive l'auto-update pour éviter d'écraser sans
    // demander.
    _emojiPickedManually = true;

    _sunExposure = p.sunExposure;
    _soilTypeCtrl.text = p.soilType ?? '';
    _soilMoistureCtrl.text = p.soilMoisturePreference ?? '';
    _wateringCtrl.text = p.watering ?? '';
    _rotationFamily =
        RotationFamily.fromCode(p.rotationFamily);
    _rotationPickedManually = _rotationFamily != null;

    _sowingRecoCtrl.text = p.sowingRecommendation ?? '';
    _plantingAdviceCtrl.text = p.plantingAdvice ?? '';
    _careAdviceCtrl.text = p.careAdvice ?? '';
    _redFlagsCtrl.text = p.redFlags ?? '';
    _practicalTipsCtrl.text = p.practicalTips ?? '';
    _toxicityCtrl.text = p.toxicity ?? '';

    _sowingMonths.addAll(_decodeMonths(p.sowingMonths));
    _plantingMonths.addAll(_decodeMonths(p.plantingMonths));
    _harvestMonths.addAll(_decodeMonths(p.harvestMonths));

    // Compagnons et antagonistes : chargés en async via les
    // providers, hors initState (cf. didChangeDependencies).
    Future.microtask(() async {
      final repo = ref.read(plantRepositoryProvider);
      final c = await repo.getCompanions(p.id);
      final a = await repo.getAntagonists(p.id);
      if (!mounted) return;
      setState(() {
        _companionIds = c.map((p) => p.id).toList();
        _antagonistIds = a.map((p) => p.id).toList();
      });
    });
  }

  Set<int> _decodeMonths(List<String> englishMonths) {
    final out = <int>{};
    for (final m in englishMonths) {
      final idx = _englishMonths.indexOf(m);
      if (idx >= 0) out.add(idx + 1);
    }
    return out;
  }

  void _onCommonNameChanged() {
    if (_emojiPickedManually) return;
    final auto = PlantEmojiMapper.fromName(
      _commonNameCtrl.text,
      categoryCode: _category.code,
    );
    if (auto != _emoji) {
      setState(() => _emoji = auto);
    }
  }

  void _onLatinNameChanged() {
    if (_rotationPickedManually) return;
    final family =
        RotationFamily.fromLatinName(_latinNameCtrl.text);
    if (family != _rotationFamily) {
      setState(() => _rotationFamily = family);
    }
  }

  String? _encodeCalendar(Set<int> months) {
    if (months.isEmpty) return null;
    final monthly = <String, String?>{
      for (var i = 0; i < 12; i++)
        _englishMonths[i]:
            months.contains(i + 1) ? 'Oui' : null,
    };
    return jsonEncode({'monthly_period': monthly});
  }

  String? _validate(AppLocalizations l) {
    if (_commonNameCtrl.text.trim().isEmpty) {
      return l.userPlantValidationName;
    }
    if (_category == PlantCategory.all) {
      return l.userPlantValidationCategory;
    }
    final sp = int.tryParse(_spacingPlantsCtrl.text.trim());
    if (sp == null || sp <= 0) {
      return l.userPlantValidationSpacingPlants;
    }
    final sr = int.tryParse(_spacingRowsCtrl.text.trim());
    if (sr == null || sr <= 0) {
      return l.userPlantValidationSpacingRows;
    }
    final hasAnyMonth = _sowingMonths.isNotEmpty ||
        _plantingMonths.isNotEmpty ||
        _harvestMonths.isNotEmpty;
    if (!hasAnyMonth) {
      return l.userPlantValidationCalendars;
    }
    return null;
  }

  UserPlantInput _buildInput() {
    return UserPlantInput(
      commonName: _commonNameCtrl.text.trim(),
      latinName: _latinNameCtrl.text.trim().isEmpty
          ? null
          : _latinNameCtrl.text.trim(),
      categoryCode: _category.code!,
      categoryLabel: _category.label,
      spacingBetweenPlants:
          int.tryParse(_spacingPlantsCtrl.text.trim()),
      spacingBetweenRows:
          int.tryParse(_spacingRowsCtrl.text.trim()),
      plantingDepthCm:
          int.tryParse(_plantingDepthCtrl.text.trim()),
      sunExposure: _sunExposure,
      soilType: _soilTypeCtrl.text.trim().isEmpty
          ? null
          : _soilTypeCtrl.text.trim(),
      soilMoisturePreference:
          _soilMoistureCtrl.text.trim().isEmpty
              ? null
              : _soilMoistureCtrl.text.trim(),
      watering: _wateringCtrl.text.trim().isEmpty
          ? null
          : _wateringCtrl.text.trim(),
      plantingMinTempC: int.tryParse(_minTempCtrl.text.trim()),
      sowingCalendarJson: _encodeCalendar(_sowingMonths),
      plantingCalendarJson:
          _encodeCalendar(_plantingMonths),
      harvestCalendarJson:
          _encodeCalendar(_harvestMonths),
      sowingRecommendation:
          _sowingRecoCtrl.text.trim().isEmpty
              ? null
              : _sowingRecoCtrl.text.trim(),
      plantingAdvice: _plantingAdviceCtrl.text.trim().isEmpty
          ? null
          : _plantingAdviceCtrl.text.trim(),
      careAdvice: _careAdviceCtrl.text.trim().isEmpty
          ? null
          : _careAdviceCtrl.text.trim(),
      redFlags: _redFlagsCtrl.text.trim().isEmpty
          ? null
          : _redFlagsCtrl.text.trim(),
      practicalTips: _practicalTipsCtrl.text.trim().isEmpty
          ? null
          : _practicalTipsCtrl.text.trim(),
      toxicity: _toxicityCtrl.text.trim().isEmpty
          ? null
          : _toxicityCtrl.text.trim(),
      rotationFamily: _rotationFamily?.code,
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final err = _validate(l);
    if (err != null) {
      setState(() => _errorMessage = err);
      return;
    }
    setState(() {
      _errorMessage = null;
      _saving = true;
    });

    final repo = ref.read(plantRepositoryProvider);
    final input = _buildInput();
    try {
      final int savedId;
      if (_isEdit) {
        await repo.updateUserPlant(
          widget.initialPlant!.id,
          input,
          companions: _companionIds,
          antagonists: _antagonistIds,
        );
        savedId = widget.initialPlant!.id;
      } else {
        savedId = await repo.insertUserPlant(
          input,
          companions: _companionIds,
          antagonists: _antagonistIds,
        );
      }
      if (!mounted) return;
      // Invalide les providers qui montrent les listes pour
      // refléter le nouvel ajout/édition.
      ref.invalidate(filteredPlantsProvider);
      ref.invalidate(allPlantsSortedProvider);
      ref.invalidate(userPlantsListProvider);
      // Le caller (ex. sheet d'ajout au potager) peut récupérer
      // l'ID pour chaîner directement sur la plante fraîchement
      // créée sans forcer l'utilisateur à re-rechercher.
      Navigator.of(context).pop<int>(savedId);
    } catch (e) {
      setState(() {
        _errorMessage = l.userPlantSaveError(e.toString());
        _saving = false;
      });
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final p = widget.initialPlant!;
    final repo = ref.read(plantRepositoryProvider);

    // 1. Pré-calcule l'impact pour adapter le message du dialog.
    //    Si la plante n'est pas posée → simple confirmation. Si elle
    //    l'est → on prévient explicitement de la cascade (gardenPlants
    //    + events + tâches de planif effacés).
    final usage = await repo.getUserPlantUsage(p.id);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.userPlantDeleteConfirmTitle),
        content: Text(_buildDeleteMessage(l, p.commonName, usage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.userPlantDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.userPlantDeleteConfirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await repo.deleteUserPlant(p.id);
      if (!mounted) return;
      // Invalide tous les providers susceptibles d'afficher la plante
      // ou ses traces (potager, suivi, planning).
      ref.invalidate(filteredPlantsProvider);
      ref.invalidate(allPlantsSortedProvider);
      ref.invalidate(userPlantsListProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = l.userPlantDeleteError(e.toString());
        _saving = false;
      });
    }
  }

  /// Construit le corps du dialog de confirmation. Sans usage : simple
  /// info. Avec usage : avertissement explicite de la cascade.
  String _buildDeleteMessage(
    AppLocalizations l,
    String plantName,
    UserPlantUsageInfo usage,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(l.userPlantDeleteConfirmBody(plantName));
    if (!usage.isInUse) {
      return buffer.toString().trim();
    }
    buffer.writeln();
    buffer.writeln(l.userPlantInUseHeader(plantName));
    if (usage.gardenNames.isNotEmpty) {
      buffer.writeln(
        l.userPlantInUseGardens(usage.gardenNames.join(', ')),
      );
    }
    if (usage.eventCount > 0) {
      buffer.writeln(l.userPlantInUseEvents(usage.eventCount));
    }
    buffer.writeln();
    buffer.writeln(l.userPlantInUseFooter);
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isEdit
                      ? l.userPlantFormEditTitle
                      : l.userPlantFormCreateTitle,
                  style: AppTypography.titleLarge,
                ),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.x()),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(
                    PhosphorIconsStyle.fill,
                  ),
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: [
              _buildEssentielSection(),
              _buildCalendarsSection(),
              _buildConditionsSection(),
              _buildAdviceSection(),
              _buildCompanionsSection(),
              _buildAdvancedSection(),
              const SizedBox(height: AppSpacing.lg),
              if (_isEdit)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  child: TextButton.icon(
                    onPressed: _saving ? null : _delete,
                    icon: Icon(
                      PhosphorIcons.trash(),
                      color: AppColors.error,
                    ),
                    label: Text(
                      l.userPlantDelete,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isEdit
                          ? l.userPlantSaveEdit
                          : l.userPlantSaveCreate,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // SECTIONS
  // ============================================

  Widget _section({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide.none,
        ),
        title: Text(title, style: AppTypography.titleSmall),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: children,
      ),
    );
  }

  Widget _buildEssentielSection() {
    final l = AppLocalizations.of(context)!;
    return _section(
      title: l.userPlantFormSectionEssentials,
      subtitle: l.userPlantFormSectionEssentialsSubtitle,
      initiallyExpanded: true,
      children: [
        _LabeledField(
          label: l.userPlantFieldCommonName,
          child: TextField(
            controller: _commonNameCtrl,
            decoration: _inputDecoration(
              hint: l.userPlantFieldCommonNameHint,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldCategory,
          child: DropdownButtonFormField<PlantCategory>(
            initialValue: _category,
            decoration: _inputDecoration(),
            items: PlantCategory.values
                .where((c) => c != PlantCategory.all)
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayLabel),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _category = v);
                if (!_emojiPickedManually) {
                  _onCommonNameChanged();
                }
              }
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: l.userPlantFieldSpacingPlants,
                child: TextField(
                  controller: _spacingPlantsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: l.userPlantFieldSpacingPlantsHint,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _LabeledField(
                label: l.userPlantFieldSpacingRows,
                child: TextField(
                  controller: _spacingRowsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: l.userPlantFieldSpacingRowsHint,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldEmoji,
          child: InkWell(
            onTap: _saving
                ? null
                : () async {
                    final picked =
                        await showUserPlantEmojiPicker(
                      context: context,
                      currentEmoji: _emoji,
                    );
                    if (picked != null) {
                      setState(() {
                        _emoji = picked;
                        _emojiPickedManually = true;
                      });
                    }
                  },
            borderRadius: AppSpacing.borderRadiusMd,
            child: Container(
              height: AppSpacing.inputHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    _emoji ?? '🌱',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _emojiPickedManually
                        ? l.userPlantFieldEmojiManual
                        : l.userPlantFieldEmojiAuto,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarsSection() {
    final l = AppLocalizations.of(context)!;
    return _section(
      title: l.userPlantFormSectionCalendars,
      subtitle: l.userPlantFormSectionCalendarsSubtitle,
      initiallyExpanded: true,
      children: [
        _MonthGrid(
          label: l.userPlantCalendarSowing,
          selected: _sowingMonths,
          onToggle: (m) => setState(() {
            _sowingMonths.contains(m)
                ? _sowingMonths.remove(m)
                : _sowingMonths.add(m);
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        _MonthGrid(
          label: l.userPlantCalendarPlanting,
          selected: _plantingMonths,
          onToggle: (m) => setState(() {
            _plantingMonths.contains(m)
                ? _plantingMonths.remove(m)
                : _plantingMonths.add(m);
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        _MonthGrid(
          label: l.userPlantCalendarHarvest,
          selected: _harvestMonths,
          onToggle: (m) => setState(() {
            _harvestMonths.contains(m)
                ? _harvestMonths.remove(m)
                : _harvestMonths.add(m);
          }),
        ),
      ],
    );
  }

  Widget _buildConditionsSection() {
    final l = AppLocalizations.of(context)!;
    return _section(
      title: l.userPlantFormSectionConditions,
      children: [
        _LabeledField(
          label: l.userPlantFieldSun,
          child: DropdownButtonFormField<String>(
            initialValue: _sunExposure,
            decoration:
                _inputDecoration(hint: l.userPlantFieldSunHint),
            items: _sunOptions(l)
                .map(
                  (o) => DropdownMenuItem(
                    value: o.$1,
                    child: Text(o.$2),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _sunExposure = v),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: l.userPlantFieldDepth,
                child: TextField(
                  controller: _plantingDepthCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: l.userPlantFieldDepthHint,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _LabeledField(
                label: l.userPlantFieldMinTemp,
                child: TextField(
                  controller: _minTempCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: l.userPlantFieldMinTempHint,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldSoilType,
          child: TextField(
            controller: _soilTypeCtrl,
            decoration: _inputDecoration(
              hint: l.userPlantFieldSoilTypeHint,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldSoilMoisture,
          child: TextField(
            controller: _soilMoistureCtrl,
            decoration: _inputDecoration(
              hint: l.userPlantFieldSoilMoistureHint,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldWatering,
          child: TextField(
            controller: _wateringCtrl,
            decoration: _inputDecoration(
              hint: l.userPlantFieldWateringHint,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldRotation,
          child: DropdownButtonFormField<RotationFamily>(
            initialValue: _rotationFamily,
            decoration: _inputDecoration(
              hint: l.userPlantFieldRotationHint,
            ),
            items: RotationFamily.values
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _rotationFamily = v;
              _rotationPickedManually = v != null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceSection() {
    final l = AppLocalizations.of(context)!;
    return _section(
      title: l.userPlantFormSectionAdvice,
      children: [
        _LabeledField(
          label: l.userPlantFieldSowingReco,
          child: TextField(
            controller: _sowingRecoCtrl,
            maxLines: 3,
            decoration: _inputDecoration(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldPlantingAdvice,
          child: TextField(
            controller: _plantingAdviceCtrl,
            maxLines: 3,
            decoration: _inputDecoration(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldCare,
          child: TextField(
            controller: _careAdviceCtrl,
            maxLines: 3,
            decoration: _inputDecoration(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldRedFlags,
          child: TextField(
            controller: _redFlagsCtrl,
            maxLines: 2,
            decoration: _inputDecoration(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldPracticalTips,
          child: TextField(
            controller: _practicalTipsCtrl,
            maxLines: 3,
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanionsSection() {
    final l = AppLocalizations.of(context)!;
    final allPlantsAsync = ref.watch(allPlantsSortedProvider);
    return _section(
      title: l.userPlantFormSectionCompanions,
      subtitle: l.userPlantCompanionsSubtitle(
        _companionIds.length,
        _antagonistIds.length,
      ),
      children: [
        _CompanionList(
          label: l.userPlantCompanionsLabel,
          ids: _companionIds,
          allPlants: allPlantsAsync,
          onEdit: () async {
            final updated =
                await showUserPlantCompanionPicker(
              context: context,
              title: l.userPlantCompanionsTitle,
              initialSelected: _companionIds,
              excludePlantId: widget.initialPlant?.id,
            );
            if (updated != null) {
              setState(() => _companionIds = updated);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _CompanionList(
          label: l.userPlantAntagonistsLabel,
          ids: _antagonistIds,
          allPlants: allPlantsAsync,
          onEdit: () async {
            final updated =
                await showUserPlantCompanionPicker(
              context: context,
              title: l.userPlantAntagonistsTitle,
              initialSelected: _antagonistIds,
              excludePlantId: widget.initialPlant?.id,
            );
            if (updated != null) {
              setState(() => _antagonistIds = updated);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    final l = AppLocalizations.of(context)!;
    return _section(
      title: l.userPlantFormSectionAdvanced,
      children: [
        _LabeledField(
          label: l.userPlantFieldLatinName,
          child: TextField(
            controller: _latinNameCtrl,
            decoration: _inputDecoration(
              hint: l.userPlantFieldLatinNameHint,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l.userPlantFieldToxicity,
          child: TextField(
            controller: _toxicityCtrl,
            maxLines: 3,
            decoration: _inputDecoration(
              hint: l.userPlantFieldToxicityHint,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide:
            BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }
}

// ============================================
// SOUS-WIDGETS
// ============================================

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final String label;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _MonthGrid({
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  static const _frenchMonthsShort = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(12, (i) {
            final m = i + 1;
            final isOn = selected.contains(m);
            return GestureDetector(
              onTap: () => onToggle(m),
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isOn
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: AppSpacing.borderRadiusFull,
                  border: Border.all(
                    color: isOn
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _frenchMonthsShort[i],
                  style: AppTypography.caption.copyWith(
                    color: isOn
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CompanionList extends StatelessWidget {
  final String label;
  final List<int> ids;
  final AsyncValue<List<Plant>> allPlants;
  final VoidCallback onEdit;

  const _CompanionList({
    required this.label,
    required this.ids,
    required this.allPlants,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: Icon(PhosphorIcons.plus(), size: 16),
              label: Text(
                ids.isEmpty
                    ? l.userPlantCompanionsAdd
                    : l.userPlantCompanionsEdit,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        if (ids.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              l.userPlantCompanionsEmpty,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          )
        else
          allPlants.when(
            loading: () => const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (plants) {
              final byId = {for (final p in plants) p.id: p};
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ids
                    .map(
                      (id) => byId[id] == null
                          ? null
                          : Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                    AppSpacing.borderRadiusFull,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    PlantEmojiMapper.fromName(
                                      byId[id]!.commonName,
                                      categoryCode:
                                          byId[id]!.categoryCode,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    byId[id]!.commonName,
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                    )
                    .whereType<Widget>()
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}
