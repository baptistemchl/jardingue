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
  String get appSubtitle => 'Mon potager connecte';

  @override
  String get loading => 'Chargement...';

  @override
  String errorWithMessage(String error) {
    return 'Erreur: $error';
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
  String get gridInfo => 'Grille: 1 carreau = 50cm';

  @override
  String get surface => 'Surface';

  @override
  String get createGarden => 'Créer le potager';

  @override
  String get gardenDefault => 'Potager';

  @override
  String get gardenNotFound => 'Potager introuvable';

  @override
  String get resetView => 'Reinitialiser la vue';

  @override
  String undoAction(String description) {
    return '↩️ Annule : $description';
  }

  @override
  String redoAction(String description) {
    return '↪️ Retabli : $description';
  }

  @override
  String get elementsList => 'Liste des elements';

  @override
  String pendingPlacementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes a placer',
      one: '1 plante a placer',
    );
    return '$_temp0';
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
  String get weatherLoading => 'Chargement de la météo...';

  @override
  String get weatherUnavailable => 'Météo indisponible';

  @override
  String get chooseCity => 'Choisir une ville';

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
      'Suivez les périodes de semis, plantation et récolte. Ne ratez plus jamais le bon moment grâceaux rappels et au calendrier interactif.';

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
}
