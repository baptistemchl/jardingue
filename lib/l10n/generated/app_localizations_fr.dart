// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Jardingue';

  @override
  String get appSubtitle => 'Mon potager connecté';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String errorWithMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get add => 'Ajouter';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get retry => 'Réessayer';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get start => 'Commencer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get validate => 'Valider';

  @override
  String get change => 'Changer';

  @override
  String get other => 'Autre';

  @override
  String get notes => 'Notes';

  @override
  String get tomorrow => 'Demain';

  @override
  String get orchardTitle => 'Mon verger';

  @override
  String get orchardNoTrees => 'Aucun arbre';

  @override
  String orchardTreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbres',
      one: '1 arbre',
    );
    return '$_temp0';
  }

  @override
  String get orchardEmptyTitle => 'Votre verger est vide';

  @override
  String get orchardEmptySubtitle =>
      'Ajoutez vos premiers arbres fruitiers\npour commencer à les suivre';

  @override
  String get orchardAddTree => 'Ajouter un arbre';

  @override
  String get orchardManageHint => 'Commencez à gérer vos arbres fruitiers';

  @override
  String get orchardViewAll => 'Voir tout';

  @override
  String orchardOtherCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count autres',
      one: '+1 autre',
    );
    return '$_temp0';
  }

  @override
  String get calendarTab => 'Calendrier';

  @override
  String get listTab => 'Liste';

  @override
  String get myTracking => 'Mon suivi';

  @override
  String get editGarden => 'Modifier le potager';

  @override
  String get newGarden => 'Nouveau potager';

  @override
  String get gardenNameRequired => 'Veuillez entrer un nom pour votre potager';

  @override
  String get gardenName => 'Nom du potager';

  @override
  String get gardenNameHint => 'Ex: Potager principal';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get dimensionsHint =>
      'Définissez la taille de votre potager en mètres';

  @override
  String get width => 'Largeur';

  @override
  String get length => 'Longueur';

  @override
  String get preview => 'Aperçu';

  @override
  String get gridInfo => 'Grille : 1 carreau = 50cm';

  @override
  String get surface => 'Surface';

  @override
  String get createGarden => 'Créer le potager';

  @override
  String get gardenDefault => 'Potager';

  @override
  String get gardenNotFound => 'Potager introuvable';

  @override
  String get resetView => 'Réinitialiser la vue';

  @override
  String undoAction(String description) {
    return '↩️ Annulé : $description';
  }

  @override
  String redoAction(String description) {
    return '↪️ Rétabli : $description';
  }

  @override
  String get elementsList => 'Liste des éléments';

  @override
  String pendingPlacementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes à placer',
      one: '1 plante à placer',
    );
    return '$_temp0';
  }

  @override
  String get undoTooltipDisabled => 'Rien à annuler';

  @override
  String get redoTooltip => 'Rétablir';

  @override
  String get redoTooltipDisabled => 'Rien à rétablir';

  @override
  String get locked => 'Verrouillé';

  @override
  String get unlocked => 'Déverrouillé';

  @override
  String get editMode => 'Mode édition';

  @override
  String get tapToEdit => 'Appuyer pour éditer';

  @override
  String get moveElements => 'Déplacez les éléments';

  @override
  String get moveMode => 'Déplacer';

  @override
  String get resizeMode => 'Redimensionner';

  @override
  String get resizeElements => 'Redimensionnez les éléments';

  @override
  String get gardenElements => 'Éléments du potager';

  @override
  String get noElement => 'Aucun élément';

  @override
  String get addPlantsOrZones => 'Ajoutez des plantes ou des zones';

  @override
  String get plantsSection => 'Plantes';

  @override
  String get zonesSection => 'Zones';

  @override
  String get deleteConfirmTitle => 'Supprimer ?';

  @override
  String deleteConfirmMessage(String name) {
    return 'Voulez-vous supprimer \"$name\" ?';
  }

  @override
  String get editZone => 'Modifier la zone';

  @override
  String get editPlant => 'Modifier la plante';

  @override
  String get confirmDeletion => 'Confirmer la suppression';

  @override
  String get deleteZoneConfirm => 'Voulez-vous vraiment supprimer cette zone ?';

  @override
  String get deletePlantConfirm =>
      'Voulez-vous vraiment supprimer cette plante ?';

  @override
  String get addElement => 'Ajouter un élément';

  @override
  String get configureZone => 'Configurer la zone';

  @override
  String get configurePlant => 'Configurer la plante';

  @override
  String get addPlantOption => 'Ajouter une plante';

  @override
  String get chooseAmongVarieties => 'Choisir parmi 200+ variétés';

  @override
  String get orAddZone => 'Ou ajouter une zone';

  @override
  String get choosePlant => 'Choisir une plante';

  @override
  String get noPlantFound => 'Aucune plante trouvée';

  @override
  String get dates => 'Dates';

  @override
  String get plantingDate => 'Date de plantation';

  @override
  String get sowingDate => 'Date de semis';

  @override
  String get watering => 'Arrosage';

  @override
  String get addTheZone => 'Ajouter la zone';

  @override
  String get addThePlant => 'Ajouter la plante';

  @override
  String get notDefined => 'Non défini';

  @override
  String needWatering(String watering) {
    return 'Besoin : $watering';
  }

  @override
  String nDays(int count) {
    return '$count jours';
  }

  @override
  String get myGardens => 'Mes potagers';

  @override
  String get noGardensCreated => 'Aucun potager créé';

  @override
  String get gardenCountOne => '1 potager';

  @override
  String gardenCount(int count) {
    return '$count potagers';
  }

  @override
  String get noGarden => 'Aucun potager';

  @override
  String get noGardenCreated => 'Aucun potager créé';

  @override
  String get noGardenCreatedAlt => 'Aucun jardin créé';

  @override
  String get createFirstGardenHint =>
      'Créez votre premier potager pour commencer';

  @override
  String get createFirstGarden => 'Créer mon premier potager';

  @override
  String get createGardenAction => 'Créer un potager';

  @override
  String get deleteGardenTitle => 'Supprimer le potager ?';

  @override
  String deleteGardenConfirmation(String name) {
    return 'Voulez-vous supprimer \"$name\" ?';
  }

  @override
  String get wateringToday => 'Arrosage du jour';

  @override
  String get allUpToDate => 'Tout est à jour';

  @override
  String plantsToWaterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes à arroser',
      one: '1 plante à arroser',
    );
    return '$_temp0';
  }

  @override
  String otherPlantsCount(int count) {
    return '+$count autres plantes';
  }

  @override
  String get rainExpectedPostponed => 'Pluie prévue, reporté';

  @override
  String get neverWatered => 'Jamais arrosé';

  @override
  String wateredDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Il y a $count jour$_temp0';
  }

  @override
  String nameWatered(String name) {
    return '$name arrosé !';
  }

  @override
  String get waterAction => 'Arroser';

  @override
  String get fertilizingToday => 'Fertilisation du jour';

  @override
  String plantsToFertilizeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes à fertiliser',
      one: '1 plante à fertiliser',
    );
    return '$_temp0';
  }

  @override
  String get neverFertilized => 'Jamais fertilisé';

  @override
  String fertilizedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Fertilisé il y a $count jour$_temp0';
  }

  @override
  String nameFertilized(String name) {
    return '$name fertilisé !';
  }

  @override
  String get fertilizeAction => 'Fertiliser';

  @override
  String get pheromoneTrapsTitle => 'Pièges à phéromones';

  @override
  String pheromoneTrapsToReplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièges à renouveler',
      one: '1 piège à renouveler',
    );
    return '$_temp0';
  }

  @override
  String pheromoneTrapsOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en retard',
      one: '1 en retard',
    );
    return '$_temp0';
  }

  @override
  String get pheromoneTrapsDueSoon => 'Renouvellement à prévoir';

  @override
  String otherTrapsCount(int count) {
    return '+$count autres pièges';
  }

  @override
  String get renewAction => 'Renouveler';

  @override
  String trapRenewedFor(String name) {
    return 'Piège de $name renouvelé !';
  }

  @override
  String installedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Posé il y a $count jour$_temp0';
  }

  @override
  String renewalInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Renouvellement dans $count jour$_temp0';
  }

  @override
  String get trapsScreenTitle => 'Mes pièges';

  @override
  String get myTrapsAction => 'Gérer mes pièges';

  @override
  String get addTrapAction => 'Ajouter un piège';

  @override
  String get addTrapTitle => 'Ajouter un piège à phéromones';

  @override
  String get trapType => 'Type de piège';

  @override
  String get installationDate => 'Date de pose';

  @override
  String get lifetimeDays => 'Durée de vie (jours)';

  @override
  String lifetimeAboutDays(int count) {
    return 'Environ $count jours';
  }

  @override
  String get showAllTrapTypes => 'Afficher tous les types';

  @override
  String get selectTypeFirst => 'Sélectionnez d\'abord un type';

  @override
  String get notesHint => 'Optionnel';

  @override
  String get pickTreeForTrap => 'Pour quel arbre ?';

  @override
  String get trapsEmptyTitle => 'Aucun piège';

  @override
  String get trapsEmptySubtitle =>
      'Posez votre premier piège à phéromones\npour suivre les renouvellements.';

  @override
  String get deleteTrapTitle => 'Supprimer le piège ?';

  @override
  String deleteTrapConfirm(String type) {
    return 'Voulez-vous vraiment supprimer ce piège ($type) ?';
  }

  @override
  String get inGarden => 'Dans le potager';

  @override
  String get editDimensions => 'Modifier les dimensions';

  @override
  String get position => 'Position';

  @override
  String get plantedOn => 'Planté le';

  @override
  String get sownOn => 'Semé le';

  @override
  String get saveDimensions => 'Enregistrer les dimensions';

  @override
  String get recommendedSpacing => 'Espacement recommandé';

  @override
  String get plantingDepth => 'Profondeur de plantation';

  @override
  String get soilType => 'Type de sol';

  @override
  String get culture => 'Culture';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get wateredToday => 'Arrosé aujourd\'hui';

  @override
  String get wateredYesterday => 'Arrosé hier';

  @override
  String lastWateringDaysAgo(int count) {
    return 'Dernier arrosage il y a $count jours';
  }

  @override
  String get wateringRegistered => 'Arrosage enregistré !';

  @override
  String get harvestAction => 'Récolter';

  @override
  String get harvestRegistered => 'Récolte enregistrée !';

  @override
  String get fertilizerAction => 'Engrais';

  @override
  String get fertilizerRegistered => 'Engrais enregistré !';

  @override
  String get mulchingAction => 'Paillage';

  @override
  String get mulchingRegistered => 'Paillage enregistré !';

  @override
  String get slugControlAction => 'Anti-limaces';

  @override
  String get slugControlRegistered => 'Anti-limaces enregistré !';

  @override
  String get treatmentAction => 'Traitement';

  @override
  String get treatmentRegistered => 'Traitement enregistré !';

  @override
  String get maintenanceSection => 'Entretien';

  @override
  String get addEvent => 'Ajouter un événement';

  @override
  String get type => 'Type';

  @override
  String get history => 'Historique';

  @override
  String get calendar => 'Calendrier';

  @override
  String get sowing => 'Semis';

  @override
  String get harvest => 'Récolte';

  @override
  String get goodAssociations => 'Bonnes associations';

  @override
  String get avoidNearby => 'À éviter à proximité';

  @override
  String get removeFromGarden => 'Retirer du potager';

  @override
  String get removePlantConfirm => 'Retirer cette plante ?';

  @override
  String removePlantMessage(String name) {
    return 'Voulez-vous retirer \"$name\" du potager ?';
  }

  @override
  String get remove => 'Retirer';

  @override
  String get wateringFrequency => 'Fréquence d\'arrosage';

  @override
  String everyNDays(int count) {
    return 'Tous les $count jours';
  }

  @override
  String get weatherTitle => 'Météo';

  @override
  String get approximatePosition => 'Position approximative';

  @override
  String get preciseLocationUnavailable =>
      'La localisation précise n\'a pas pu être obtenue.';

  @override
  String get searchCityHint => 'Rechercher une ville...';

  @override
  String get noCityFound => 'Aucune ville trouvée';

  @override
  String get searchError => 'Erreur de recherche';

  @override
  String get searchOffline =>
      'Pas de connexion internet. Vérifiez votre réseau et réessayez.';

  @override
  String get whatToRecord => 'Que voulez-vous enregistrer ?';

  @override
  String get whichPlant => 'Quelle plante ?';

  @override
  String get addToGarden => 'Ajouter à un potager ?';

  @override
  String get orAddToGarden => 'Ou ajouter à un potager';

  @override
  String get subcategoryPepins => 'Pépins';

  @override
  String get subcategoryMediterraneen => 'Méditerranéen';

  @override
  String get subcategoryFruitsACoque => 'Fruits à coque';

  @override
  String get subcategoryBruyeres => 'Bruyères';

  @override
  String get plants => 'Plantes';

  @override
  String varietiesCount(int count) {
    return '$count variétés';
  }

  @override
  String get discoverVarieties => 'Découvrez et gérez vos variétés';

  @override
  String get searchPlant => 'Rechercher une plante...';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get exposureLabel => 'Exposition';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noPlants => 'Aucune plante';

  @override
  String get tryModifyingCriteria => 'Essayez de modifier vos critères';

  @override
  String get databaseEmpty => 'La base de données est vide';

  @override
  String get loadingError => 'Erreur de chargement';

  @override
  String get regularWatering => 'Arrosage régulier';

  @override
  String get periodsSection => '📅 Périodes';

  @override
  String get sowingOpenGround => 'Semis pleine terre';

  @override
  String get sowingUnderCover => 'Semis sous abri';

  @override
  String get transplanting => 'Repiquage';

  @override
  String get harvestLabel => 'Récolte';

  @override
  String get plantingSection => '🌱 Plantation';

  @override
  String get careSection => '🧑‍🌾 Entretien';

  @override
  String get attentionSection => '⚠️ Points d\'attention';

  @override
  String get goodCompanions => '✅ Bonnes associations';

  @override
  String get badCompanions => '❌ À éviter';

  @override
  String get createPlantAction => 'Créer une plante personnalisée';

  @override
  String get createPlantHint => 'Pas dans la liste ? Ajoute-la';

  @override
  String get userPlantBadge => 'Personnalisée';

  @override
  String get userPlantFormCreateTitle => 'Créer une plante';

  @override
  String get userPlantFormEditTitle => 'Modifier la plante';

  @override
  String get userPlantFormSectionEssentials => 'Essentiel';

  @override
  String get userPlantFormSectionEssentialsSubtitle => 'Champs obligatoires';

  @override
  String get userPlantFormSectionCalendars => 'Calendriers';

  @override
  String get userPlantFormSectionCalendarsSubtitle =>
      'Au moins un mois requis (semis, plantation ou récolte)';

  @override
  String get userPlantFormSectionConditions => 'Conditions de culture';

  @override
  String get userPlantFormSectionAdvice => 'Conseils & repères';

  @override
  String get userPlantFormSectionCompanions => 'Compagnons & antagonistes';

  @override
  String get userPlantFormSectionAdvanced => 'Avancé';

  @override
  String get userPlantFieldCommonName => 'Nom commun *';

  @override
  String get userPlantFieldCommonNameHint => 'ex: Pastèque';

  @override
  String get userPlantFieldCategory => 'Catégorie *';

  @override
  String get userPlantFieldSpacingPlants => 'Espacement plants (cm) *';

  @override
  String get userPlantFieldSpacingPlantsHint => 'ex: 100';

  @override
  String get userPlantFieldSpacingRows => 'Espacement rangs (cm) *';

  @override
  String get userPlantFieldSpacingRowsHint => 'ex: 150';

  @override
  String get userPlantFieldEmoji => 'Icône';

  @override
  String get userPlantFieldEmojiAuto => 'Auto (modifier)';

  @override
  String get userPlantFieldEmojiManual => 'Modifier l\'icône';

  @override
  String get userPlantFieldSun => 'Exposition';

  @override
  String get userPlantFieldSunHint => '— Choisir —';

  @override
  String get userPlantFieldDepth => 'Profondeur (cm)';

  @override
  String get userPlantFieldDepthHint => 'ex: 2';

  @override
  String get userPlantFieldMinTemp => 'Temp. mini (°C)';

  @override
  String get userPlantFieldMinTempHint => 'ex: 12';

  @override
  String get userPlantFieldSoilType => 'Type de sol';

  @override
  String get userPlantFieldSoilTypeHint => 'ex: léger, sableux, drainé';

  @override
  String get userPlantFieldSoilMoisture => 'Humidité préférée';

  @override
  String get userPlantFieldSoilMoistureHint => 'ex: modérée à régulière';

  @override
  String get userPlantFieldWatering => 'Arrosage';

  @override
  String get userPlantFieldWateringHint => 'ex: régulier au pied';

  @override
  String get userPlantFieldRotation => 'Famille botanique (rotation)';

  @override
  String get userPlantFieldRotationHint => 'Auto depuis le nom latin';

  @override
  String get userPlantFieldSowingReco => 'Conseil de semis';

  @override
  String get userPlantFieldPlantingAdvice => 'Conseil de plantation';

  @override
  String get userPlantFieldCare => 'Entretien';

  @override
  String get userPlantFieldRedFlags => 'Points d\'attention';

  @override
  String get userPlantFieldPracticalTips => 'Astuces pratiques';

  @override
  String get userPlantFieldLatinName => 'Nom latin';

  @override
  String get userPlantFieldLatinNameHint => 'ex: Citrullus lanatus';

  @override
  String get userPlantFieldToxicity => 'Toxicité';

  @override
  String get userPlantFieldToxicityHint => 'Laisser vide si non toxique';

  @override
  String get userPlantCalendarSowing => 'Semis';

  @override
  String get userPlantCalendarPlanting => 'Plantation';

  @override
  String get userPlantCalendarHarvest => 'Récolte';

  @override
  String get userPlantCompanionsLabel => 'Plantes compagnes';

  @override
  String get userPlantAntagonistsLabel => 'Plantes antagonistes';

  @override
  String userPlantCompanionsSubtitle(int c, int a) {
    return '$c compagne(s), $a antagoniste(s)';
  }

  @override
  String get userPlantCompanionsAdd => 'Ajouter';

  @override
  String get userPlantCompanionsEdit => 'Modifier';

  @override
  String get userPlantCompanionsEmpty => 'Aucune sélection';

  @override
  String userPlantCompanionsValidate(int n) {
    return 'Valider ($n)';
  }

  @override
  String get userPlantCompanionsSearch => 'Rechercher…';

  @override
  String get userPlantSaveCreate => 'Créer';

  @override
  String get userPlantSaveEdit => 'Enregistrer';

  @override
  String get userPlantDelete => 'Supprimer cette plante';

  @override
  String get userPlantDeleteConfirmTitle => 'Supprimer cette plante ?';

  @override
  String userPlantDeleteConfirmBody(String name) {
    return 'La plante \"$name\" sera définitivement retirée de ton catalogue.';
  }

  @override
  String get userPlantDeleteCancel => 'Annuler';

  @override
  String get userPlantDeleteConfirm => 'Supprimer';

  @override
  String userPlantInUseHeader(String name) {
    return '⚠️ \"$name\" figure encore dans tes plans.';
  }

  @override
  String userPlantInUseGardens(String gardens) {
    return 'Elle sera retirée de : $gardens.';
  }

  @override
  String userPlantInUseEvents(int count) {
    return '$count événement(s) de suivi seront effacés.';
  }

  @override
  String get userPlantInUseFooter => 'Cette action est irréversible.';

  @override
  String get userPlantValidationName => 'Le nom commun est obligatoire.';

  @override
  String get userPlantValidationCategory => 'Choisis une catégorie.';

  @override
  String get userPlantValidationSpacingPlants =>
      'Indique l\'espacement entre plants (cm > 0).';

  @override
  String get userPlantValidationSpacingRows =>
      'Indique l\'espacement entre rangs (cm > 0).';

  @override
  String get userPlantValidationCalendars =>
      'Coche au moins un mois sur l\'un des calendriers (semis, plantation ou récolte).';

  @override
  String userPlantSaveError(String message) {
    return 'Erreur lors de l\'enregistrement : $message';
  }

  @override
  String userPlantDeleteError(String message) {
    return 'Erreur lors de la suppression : $message';
  }

  @override
  String get userPlantSunFull => '☀️ Ensoleillé';

  @override
  String get userPlantSunPartial => '⛅ Mi-ombre';

  @override
  String get userPlantSunShade => '🌥️ Ombragé';

  @override
  String get userPlantEmojiPickerTitle => 'Choisir une icône';

  @override
  String get userPlantCompanionsTitle => 'Compagnes';

  @override
  String get userPlantAntagonistsTitle => 'Antagonistes';

  @override
  String get weatherLoading => 'Chargement de la météo...';

  @override
  String get weatherUnavailable => 'Météo indisponible';

  @override
  String get chooseCity => 'Choisir une ville';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutSubtitle => 'Mon potager connecté';

  @override
  String get aboutMadeWithLove => 'Conçu avec amour en Bretagne';

  @override
  String get aboutContact => 'agenceixp.app@gmail.com';

  @override
  String get aboutInstagram => '@agenceixp';

  @override
  String get aboutInstagramUrl => 'https://www.instagram.com/agenceixp/';

  @override
  String aboutCopyright(String year) {
    return '© $year Jardingue. Tous droits réservés.';
  }

  @override
  String get aboutThanks => 'Remerciements';

  @override
  String get aboutThanksMessage =>
      'Un immense merci à Ana & Charles\npour la motivation, les idées folles,\net les sessions de tests intensives !';

  @override
  String get aboutTapToCelebrate => 'Tapez pour célébrer !';

  @override
  String get aboutFamilyTitle => 'Ma famille';

  @override
  String get aboutFamilyMessage =>
      'Un merci tout particulier à ma femme et mes enfants,\nqui me donnent chaque jour la détermination\net l\'énergie de construire ce projet.';

  @override
  String get aboutSourcesTitle => 'Sources des données';

  @override
  String get aboutSourcesBody =>
      'Les fiches plantes et arbres fruitiers s\'appuient sur des sources horticoles reconnues : INRAE, Vilmorin, Royal Horticultural Society (RHS), Rustica, et les zones de rusticité USDA.';

  @override
  String get onboardingGardenTitle => 'Votre potager';

  @override
  String get onboardingGardenSubtitle => 'Concevez votre jardin';

  @override
  String get onboardingGardenDesc =>
      'Créez et organisez vos parcelles sur mesure. Placez vos plantes, visualisez votre potager et gérez plusieurs jardins facilement.';

  @override
  String get onboardingPlantsTitle => 'Catalogue de plantes';

  @override
  String get onboardingPlantsSubtitle => 'Explorez les variétés';

  @override
  String get onboardingPlantsDesc =>
      'Parcourez des dizaines de plantes avec leurs besoins en soleil, arrosage et associations. Trouvez les meilleurs compagnons pour votre potager.';

  @override
  String get onboardingCalendarTitle => 'Calendrier';

  @override
  String get onboardingCalendarSubtitle => 'Planifiez vos saisons';

  @override
  String get onboardingCalendarDesc =>
      'Suivez les périodes de semis, plantation et récolte. Ne ratez plus jamais le bon moment grâce aux rappels et au calendrier interactif.';

  @override
  String get onboardingWeatherTitle => 'Météo intelligente';

  @override
  String get onboardingWeatherSubtitle => 'Jardinez au bon moment';

  @override
  String get onboardingWeatherDesc =>
      'Consultez la météo locale, les phases de lune et recevez des conseils adaptés pour savoir quand arroser et quand planter.';

  @override
  String get onboardingDataTitle => 'Vos données';

  @override
  String get onboardingDataSubtitle => 'Stockage local sur votre téléphone';

  @override
  String get onboardingDataDesc =>
      'Vos jardins et événements sont enregistrés sur votre téléphone. Supprimer l\'application ou vider le cache supprimera vos données.\n\nLa sauvegarde en ligne arrive bientôt !';

  @override
  String elementTooBigForGarden(int maxWidthCm, int maxHeightCm) {
    return 'Élément trop grand pour le jardin (max ${maxWidthCm}cm × ${maxHeightCm}cm)';
  }

  @override
  String gardenResizeOverflow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Impossible de redimensionner : $count éléments dépassent du nouveau jardin.',
      one:
          'Impossible de redimensionner : 1 élément dépasse du nouveau jardin.',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsGuidanceSectionTitle => 'Conseils de jardinage';

  @override
  String get settingsGuidanceSectionSubtitle =>
      'Aide-toi des données de compagnonnage et d\'incompatibilité du catalogue. Désactivé par défaut.';

  @override
  String get settingsCompanionSuggestionsTitle =>
      'Suggérer les compagnons au dépôt';

  @override
  String get settingsCompanionSuggestionsSubtitle =>
      'Après chaque plante posée, propose ses plantes compagnes (à ajouter au panier).';

  @override
  String get settingsAntagonistWarningsTitle => 'Avertir des incompatibilités';

  @override
  String get settingsAntagonistWarningsSubtitle =>
      'Affiche un avertissement avant de placer une plante à côté d\'un antagoniste connu.';

  @override
  String companionSuggestionsTitle(String plantName) {
    return 'Compagnons de la $plantName';
  }

  @override
  String get companionSuggestionsSubtitle =>
      'Ajoute ces plantes au panier pour les placer après.';

  @override
  String get companionSuggestionsLater => 'Plus tard';

  @override
  String get companionSuggestionsAddToBasket => 'Ajouter au panier';

  @override
  String get antagonistDialogTitle => 'Incompatibilité détectée';

  @override
  String get antagonistDialogConfirmQuestion => 'Placer quand même ?';

  @override
  String get antagonistDialogPlace => 'Placer';

  @override
  String antagonistConflictWithReason(
    String sourceName,
    String neighborName,
    String reason,
  ) {
    return '$sourceName et $neighborName partagent $reason.';
  }

  @override
  String antagonistConflictGeneric(String sourceName, String neighborName) {
    return '$sourceName et $neighborName ne s\'aiment pas.';
  }

  @override
  String get guidanceOptOutCompanionLink => 'Ne plus afficher ces suggestions';

  @override
  String get guidanceOptOutAntagonistLink =>
      'Ne plus afficher ces avertissements';

  @override
  String get guidanceOptOutCompanionSnackbar =>
      'Suggestions désactivées. Vous pouvez les réactiver depuis l\'engrenage ⚙️ en haut à droite de l\'accueil.';

  @override
  String get guidanceOptOutAntagonistSnackbar =>
      'Avertissements désactivés. Vous pouvez les réactiver depuis l\'engrenage ⚙️ en haut à droite de l\'accueil.';

  @override
  String get guidanceOptOutUndo => 'Annuler';

  @override
  String get gardenCellSizeTitle => 'Précision de la grille';

  @override
  String get gardenCellSizeSubtitle =>
      'Plus la cellule est petite, plus le placement est précis. Plus elle est grande, plus la grille est lisible.';

  @override
  String gardenCellSizeValue(int value) {
    return '$value cm';
  }

  @override
  String get gardenCellSizeHintFine => 'Précis';

  @override
  String get gardenCellSizeHintCoarse => 'Lisible';

  @override
  String get colorPickerSubtitle =>
      'Choisissez une couleur pour distinguer ce pied.';

  @override
  String get colorPickerReset => 'Couleur par défaut (catégorie)';

  @override
  String get colorPickerCustom => 'Couleur personnalisée';

  @override
  String get colorPickerCustomDialogTitle => 'Choisir une couleur';

  @override
  String get colorPickerCustomDialogConfirm => 'Appliquer';

  @override
  String colorPickerApplyToAll(int count, String plantName) {
    return 'Appliquer à tou(te)s les $count $plantName de ce potager';
  }

  @override
  String get templatesSectionTitle => 'Démarrer avec un modèle';

  @override
  String get templatesSectionSubtitle =>
      'Choisissez un préréglage et toutes les plantes sont placées d\'un coup. Vous pourrez tout modifier ensuite.';

  @override
  String templateCardDimensions(String width, String height, int count) {
    return '$width × $height m  ·  $count plantes';
  }

  @override
  String get templateCustomTitle => 'Personnalisé';

  @override
  String get templateCustomSubtitle => 'Potager vierge';
}
