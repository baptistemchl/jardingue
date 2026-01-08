import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/database.dart';
import '../../../../core/providers/orchard_providers.dart';

/// Sheet affichant les détails d'un arbre fruitier du catalogue
/// avec possibilité de l'ajouter au verger
class FruitTreeDetailSheet extends ConsumerStatefulWidget {
  final FruitTree tree;

  const FruitTreeDetailSheet({super.key, required this.tree});

  @override
  ConsumerState<FruitTreeDetailSheet> createState() =>
      _FruitTreeDetailSheetState();
}

class _FruitTreeDetailSheetState extends ConsumerState<FruitTreeDetailSheet> {
  bool _showAddForm = false;
  final _nicknameController = TextEditingController();
  String? _selectedVariety;
  DateTime? _plantingDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _plantingDate = picked);
    }
  }

  Future<void> _addToOrchard() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(userFruitTreesNotifierProvider.notifier)
          .addTree(
            fruitTreeId: widget.tree.id,
            nickname: _nicknameController.text.trim().isEmpty
                ? null
                : _nicknameController.text.trim(),
            variety: _selectedVariety,
            plantingDate: _plantingDate,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.tree.emoji} ${widget.tree.commonName} ajouté à votre verger !',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    final varieties = tree.varietiesList;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Contenu scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          tree.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tree.commonName,
                            style: AppTypography.titleLarge,
                          ),
                          if (tree.latinName != null)
                            Text(
                              tree.latinName!,
                              style: AppTypography.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(
                      emoji: tree.categoryEnum.emoji,
                      label: tree.categoryEnum.label,
                    ),
                    _Tag(emoji: '🏷️', label: tree.subcategoryLabel),
                    if (tree.selfFertile)
                      const _Tag(emoji: '✅', label: 'Autofertile'),
                    if (tree.containerSuitable)
                      const _Tag(emoji: '🪴', label: 'En pot'),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                if (tree.description != null)
                  Text(
                    tree.description!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                const SizedBox(height: 20),

                // Formulaire d'ajout (si affiché)
                if (_showAddForm) ...[
                  _buildAddForm(varieties),
                ] else ...[
                  // Infos détaillées
                  _buildDetailedInfo(tree),
                ],
              ],
            ),
          ),

          // Bouton action
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: _buildActionButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_showAddForm) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _showAddForm = false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retour'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _addToOrchard,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      size: 18,
                    ),
              label: const Text('Confirmer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: () => setState(() => _showAddForm = true),
      icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
      label: const Text('Ajouter à mon verger'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAddForm(List<String> varieties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.info(PhosphorIconsStyle.fill),
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Personnalisez votre arbre (optionnel)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Surnom
        Text('Surnom', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: 'Ex: Le pommier du fond',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Variété
        if (varieties.isNotEmpty) ...[
          Text('Variété', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedVariety,
                hint: const Text('Sélectionner une variété'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Je ne sais pas / Autre'),
                  ),
                  ...varieties.map(
                    (v) => DropdownMenuItem(value: v, child: Text(v)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedVariety = v),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Date de plantation
        Text('Date de plantation', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _plantingDate != null
                      ? DateFormat(
                          'dd MMMM yyyy',
                          'fr_FR',
                        ).format(_plantingDate!)
                      : 'Non renseignée',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _plantingDate != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(FruitTree tree) {
    return Column(
      children: [
        // Caractéristiques
        _InfoCard(
          title: 'Caractéristiques',
          icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
          children: [
            if (tree.heightAdultM != null)
              _InfoRow(
                label: 'Hauteur adulte',
                value: '${tree.heightAdultM} m',
              ),
            if (tree.spreadAdultM != null)
              _InfoRow(label: 'Envergure', value: '${tree.spreadAdultM} m'),
            if (tree.growthRate != null)
              _InfoRow(label: 'Croissance', value: tree.growthRate!),
            if (tree.lifespanYears != null)
              _InfoRow(
                label: 'Durée de vie',
                value: '${tree.lifespanYears} ans',
              ),
            if (tree.coldResistanceCelsius != null)
              _InfoRow(
                label: 'Rusticité',
                value: '${tree.coldResistanceCelsius}°C',
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Conditions de culture
        _InfoCard(
          title: 'Culture',
          icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
          children: [
            if (tree.sunExposure != null)
              _InfoRow(label: 'Exposition', value: tree.sunExposure!),
            if (tree.soilType != null)
              _InfoRow(label: 'Sol', value: tree.soilType!),
            if (tree.waterNeeds != null)
              _InfoRow(label: 'Arrosage', value: tree.waterNeeds!),
            _InfoRow(
              label: 'Sécheresse',
              value: tree.droughtTolerance ? 'Tolère' : 'Sensible',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Production
        _InfoCard(
          title: 'Production',
          icon: PhosphorIcons.flower(PhosphorIconsStyle.fill),
          children: [
            if (tree.floweringPeriod != null)
              _InfoRow(label: 'Floraison', value: tree.floweringPeriod!),
            if (tree.harvestPeriod != null)
              _InfoRow(label: 'Récolte', value: tree.harvestPeriod!),
            if (tree.yearsToFirstFruit != null)
              _InfoRow(
                label: 'Premier fruit',
                value: '${tree.yearsToFirstFruit} ans',
              ),
            if (tree.yieldKgPerTree != null)
              _InfoRow(
                label: 'Rendement',
                value: '~${tree.yieldKgPerTree!.toInt()} kg/an',
              ),
            if (tree.pollinationDetails != null)
              _InfoRow(label: 'Pollinisation', value: tree.pollinationDetails!),
          ],
        ),

        const SizedBox(height: 12),

        // Plantation & Taille
        _InfoCard(
          title: 'Plantation & Entretien',
          icon: PhosphorIcons.shovel(PhosphorIconsStyle.fill),
          children: [
            if (tree.plantingPeriod != null)
              _InfoRow(label: 'Période', value: tree.plantingPeriod!),
            if (tree.plantingDistanceM != null)
              _InfoRow(label: 'Distance', value: '${tree.plantingDistanceM} m'),
            if (tree.pruningTrainingPeriod != null)
              _InfoRow(
                label: 'Taille formation',
                value: tree.pruningTrainingPeriod!,
              ),
            if (tree.pruningMaintenancePeriod != null)
              _InfoRow(
                label: 'Taille entretien',
                value: tree.pruningMaintenancePeriod!,
              ),
          ],
        ),

        // Variétés populaires
        if (tree.varietiesList.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Variétés populaires',
            icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
            iconColor: AppColors.secondary,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tree.varietiesList
                    .map((v) => _VarietyChip(name: v))
                    .toList(),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String emoji;
  final String label;

  const _Tag({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _VarietyChip extends StatelessWidget {
  final String name;

  const _VarietyChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: AppTypography.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
