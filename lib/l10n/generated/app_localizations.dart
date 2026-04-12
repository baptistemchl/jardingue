import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Jardingue'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon potager connecté'**
  String get appSubtitle;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @errorWithMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String errorWithMessage(String error);

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get start;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @change.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get change;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @tomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// No description provided for @orchardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon verger'**
  String get orchardTitle;

  /// No description provided for @orchardNoTrees.
  ///
  /// In fr, this message translates to:
  /// **'Aucun arbre'**
  String get orchardNoTrees;

  /// No description provided for @orchardTreeCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 arbre} other{{count} arbres}}'**
  String orchardTreeCount(int count);

  /// No description provided for @orchardEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre verger est vide'**
  String get orchardEmptyTitle;

  /// No description provided for @orchardEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos premiers arbres fruitiers\npour commencer à les suivre'**
  String get orchardEmptySubtitle;

  /// No description provided for @orchardAddTree.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un arbre'**
  String get orchardAddTree;

  /// No description provided for @orchardManageHint.
  ///
  /// In fr, this message translates to:
  /// **'Commencez à gérer vos arbres fruitiers'**
  String get orchardManageHint;

  /// No description provided for @orchardViewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get orchardViewAll;

  /// No description provided for @orchardOtherCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{+1 autre} other{+{count} autres}}'**
  String orchardOtherCount(int count);

  /// No description provided for @calendarTab.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendarTab;

  /// No description provided for @listTab.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get listTab;

  /// No description provided for @myTracking.
  ///
  /// In fr, this message translates to:
  /// **'Mon suivi'**
  String get myTracking;

  /// No description provided for @editGarden.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le potager'**
  String get editGarden;

  /// No description provided for @newGarden.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau potager'**
  String get newGarden;

  /// No description provided for @gardenNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nom pour votre potager'**
  String get gardenNameRequired;

  /// No description provided for @gardenName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du potager'**
  String get gardenName;

  /// No description provided for @gardenNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Potager principal'**
  String get gardenNameHint;

  /// No description provided for @dimensions.
  ///
  /// In fr, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @dimensionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Définissez la taille de votre potager en mètres'**
  String get dimensionsHint;

  /// No description provided for @width.
  ///
  /// In fr, this message translates to:
  /// **'Largeur'**
  String get width;

  /// No description provided for @length.
  ///
  /// In fr, this message translates to:
  /// **'Longueur'**
  String get length;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @gridInfo.
  ///
  /// In fr, this message translates to:
  /// **'Grille : 1 carreau = 50cm'**
  String get gridInfo;

  /// No description provided for @surface.
  ///
  /// In fr, this message translates to:
  /// **'Surface'**
  String get surface;

  /// No description provided for @createGarden.
  ///
  /// In fr, this message translates to:
  /// **'Créer le potager'**
  String get createGarden;

  /// No description provided for @gardenDefault.
  ///
  /// In fr, this message translates to:
  /// **'Potager'**
  String get gardenDefault;

  /// No description provided for @gardenNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Potager introuvable'**
  String get gardenNotFound;

  /// No description provided for @resetView.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la vue'**
  String get resetView;

  /// No description provided for @undoAction.
  ///
  /// In fr, this message translates to:
  /// **'↩️ Annulé : {description}'**
  String undoAction(String description);

  /// No description provided for @redoAction.
  ///
  /// In fr, this message translates to:
  /// **'↪️ Rétabli : {description}'**
  String redoAction(String description);

  /// No description provided for @elementsList.
  ///
  /// In fr, this message translates to:
  /// **'Liste des éléments'**
  String get elementsList;

  /// No description provided for @pendingPlacementCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 plante à placer} other{{count} plantes à placer}}'**
  String pendingPlacementCount(int count);

  /// No description provided for @undoTooltipDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Rien à annuler'**
  String get undoTooltipDisabled;

  /// No description provided for @redoTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir'**
  String get redoTooltip;

  /// No description provided for @redoTooltipDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Rien à rétablir'**
  String get redoTooltipDisabled;

  /// No description provided for @locked.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillé'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillé'**
  String get unlocked;

  /// No description provided for @editMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode édition'**
  String get editMode;

  /// No description provided for @tapToEdit.
  ///
  /// In fr, this message translates to:
  /// **'Appuyer pour éditer'**
  String get tapToEdit;

  /// No description provided for @moveElements.
  ///
  /// In fr, this message translates to:
  /// **'Déplacez les éléments'**
  String get moveElements;

  /// No description provided for @gardenElements.
  ///
  /// In fr, this message translates to:
  /// **'Éléments du potager'**
  String get gardenElements;

  /// No description provided for @noElement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément'**
  String get noElement;

  /// No description provided for @addPlantsOrZones.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des plantes ou des zones'**
  String get addPlantsOrZones;

  /// No description provided for @plantsSection.
  ///
  /// In fr, this message translates to:
  /// **'Plantes'**
  String get plantsSection;

  /// No description provided for @zonesSection.
  ///
  /// In fr, this message translates to:
  /// **'Zones'**
  String get zonesSection;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer \"{name}\" ?'**
  String deleteConfirmMessage(String name);

  /// No description provided for @editZone.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la zone'**
  String get editZone;

  /// No description provided for @editPlant.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la plante'**
  String get editPlant;

  /// No description provided for @confirmDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDeletion;

  /// No description provided for @deleteZoneConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer cette zone ?'**
  String get deleteZoneConfirm;

  /// No description provided for @deletePlantConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer cette plante ?'**
  String get deletePlantConfirm;

  /// No description provided for @addElement.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élément'**
  String get addElement;

  /// No description provided for @configureZone.
  ///
  /// In fr, this message translates to:
  /// **'Configurer la zone'**
  String get configureZone;

  /// No description provided for @configurePlant.
  ///
  /// In fr, this message translates to:
  /// **'Configurer la plante'**
  String get configurePlant;

  /// No description provided for @addPlantOption.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une plante'**
  String get addPlantOption;

  /// No description provided for @chooseAmongVarieties.
  ///
  /// In fr, this message translates to:
  /// **'Choisir parmi 200+ variétés'**
  String get chooseAmongVarieties;

  /// No description provided for @orAddZone.
  ///
  /// In fr, this message translates to:
  /// **'Ou ajouter une zone'**
  String get orAddZone;

  /// No description provided for @choosePlant.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une plante'**
  String get choosePlant;

  /// No description provided for @noPlantFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante trouvée'**
  String get noPlantFound;

  /// No description provided for @dates.
  ///
  /// In fr, this message translates to:
  /// **'Dates'**
  String get dates;

  /// No description provided for @plantingDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de plantation'**
  String get plantingDate;

  /// No description provided for @sowingDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de semis'**
  String get sowingDate;

  /// No description provided for @watering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage'**
  String get watering;

  /// No description provided for @addTheZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la zone'**
  String get addTheZone;

  /// No description provided for @addThePlant.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la plante'**
  String get addThePlant;

  /// No description provided for @notDefined.
  ///
  /// In fr, this message translates to:
  /// **'Non défini'**
  String get notDefined;

  /// No description provided for @needWatering.
  ///
  /// In fr, this message translates to:
  /// **'Besoin : {watering}'**
  String needWatering(String watering);

  /// No description provided for @nDays.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours'**
  String nDays(int count);

  /// No description provided for @myGardens.
  ///
  /// In fr, this message translates to:
  /// **'Mes potagers'**
  String get myGardens;

  /// No description provided for @noGardensCreated.
  ///
  /// In fr, this message translates to:
  /// **'Aucun potager créé'**
  String get noGardensCreated;

  /// No description provided for @gardenCountOne.
  ///
  /// In fr, this message translates to:
  /// **'1 potager'**
  String get gardenCountOne;

  /// No description provided for @gardenCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} potagers'**
  String gardenCount(int count);

  /// No description provided for @noGarden.
  ///
  /// In fr, this message translates to:
  /// **'Aucun potager'**
  String get noGarden;

  /// No description provided for @noGardenCreated.
  ///
  /// In fr, this message translates to:
  /// **'Aucun potager créé'**
  String get noGardenCreated;

  /// No description provided for @noGardenCreatedAlt.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jardin créé'**
  String get noGardenCreatedAlt;

  /// No description provided for @createFirstGardenHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre premier potager pour commencer'**
  String get createFirstGardenHint;

  /// No description provided for @createFirstGarden.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon premier potager'**
  String get createFirstGarden;

  /// No description provided for @createGardenAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer un potager'**
  String get createGardenAction;

  /// No description provided for @deleteGardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le potager ?'**
  String get deleteGardenTitle;

  /// No description provided for @deleteGardenConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer \"{name}\" ?'**
  String deleteGardenConfirmation(String name);

  /// No description provided for @wateringToday.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage du jour'**
  String get wateringToday;

  /// No description provided for @allUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'Tout est à jour'**
  String get allUpToDate;

  /// No description provided for @plantsToWaterCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 plante à arroser} other{{count} plantes à arroser}}'**
  String plantsToWaterCount(int count);

  /// No description provided for @otherPlantsCount.
  ///
  /// In fr, this message translates to:
  /// **'+{count} autres plantes'**
  String otherPlantsCount(int count);

  /// No description provided for @rainExpectedPostponed.
  ///
  /// In fr, this message translates to:
  /// **'Pluie prévue, reporté'**
  String get rainExpectedPostponed;

  /// No description provided for @neverWatered.
  ///
  /// In fr, this message translates to:
  /// **'Jamais arrosé'**
  String get neverWatered;

  /// No description provided for @wateredDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} jour{count, plural, =1{} other{s}}'**
  String wateredDaysAgo(int count);

  /// No description provided for @nameWatered.
  ///
  /// In fr, this message translates to:
  /// **'{name} arrosé !'**
  String nameWatered(String name);

  /// No description provided for @waterAction.
  ///
  /// In fr, this message translates to:
  /// **'Arroser'**
  String get waterAction;

  /// No description provided for @inGarden.
  ///
  /// In fr, this message translates to:
  /// **'Dans le potager'**
  String get inGarden;

  /// No description provided for @editDimensions.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les dimensions'**
  String get editDimensions;

  /// No description provided for @position.
  ///
  /// In fr, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @plantedOn.
  ///
  /// In fr, this message translates to:
  /// **'Planté le'**
  String get plantedOn;

  /// No description provided for @sownOn.
  ///
  /// In fr, this message translates to:
  /// **'Semé le'**
  String get sownOn;

  /// No description provided for @saveDimensions.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les dimensions'**
  String get saveDimensions;

  /// No description provided for @recommendedSpacing.
  ///
  /// In fr, this message translates to:
  /// **'Espacement recommandé'**
  String get recommendedSpacing;

  /// No description provided for @plantingDepth.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur de plantation'**
  String get plantingDepth;

  /// No description provided for @soilType.
  ///
  /// In fr, this message translates to:
  /// **'Type de sol'**
  String get soilType;

  /// No description provided for @culture.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get culture;

  /// No description provided for @quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActions;

  /// No description provided for @wateredToday.
  ///
  /// In fr, this message translates to:
  /// **'Arrosé aujourd\'hui'**
  String get wateredToday;

  /// No description provided for @wateredYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Arrosé hier'**
  String get wateredYesterday;

  /// No description provided for @lastWateringDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Dernier arrosage il y a {count} jours'**
  String lastWateringDaysAgo(int count);

  /// No description provided for @wateringRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage enregistré !'**
  String get wateringRegistered;

  /// No description provided for @harvestAction.
  ///
  /// In fr, this message translates to:
  /// **'Récolter'**
  String get harvestAction;

  /// No description provided for @harvestRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Récolte enregistrée !'**
  String get harvestRegistered;

  /// No description provided for @addEvent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un événement'**
  String get addEvent;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @calendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendar;

  /// No description provided for @sowing.
  ///
  /// In fr, this message translates to:
  /// **'Semis'**
  String get sowing;

  /// No description provided for @harvest.
  ///
  /// In fr, this message translates to:
  /// **'Récolte'**
  String get harvest;

  /// No description provided for @goodAssociations.
  ///
  /// In fr, this message translates to:
  /// **'Bonnes associations'**
  String get goodAssociations;

  /// No description provided for @avoidNearby.
  ///
  /// In fr, this message translates to:
  /// **'À éviter à proximité'**
  String get avoidNearby;

  /// No description provided for @removeFromGarden.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du potager'**
  String get removeFromGarden;

  /// No description provided for @removePlantConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette plante ?'**
  String get removePlantConfirm;

  /// No description provided for @removePlantMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous retirer \"{name}\" du potager ?'**
  String removePlantMessage(String name);

  /// No description provided for @remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// No description provided for @wateringFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence d\'arrosage'**
  String get wateringFrequency;

  /// No description provided for @everyNDays.
  ///
  /// In fr, this message translates to:
  /// **'Tous les {count} jours'**
  String everyNDays(int count);

  /// No description provided for @weatherTitle.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get weatherTitle;

  /// No description provided for @approximatePosition.
  ///
  /// In fr, this message translates to:
  /// **'Position approximative'**
  String get approximatePosition;

  /// No description provided for @preciseLocationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La localisation précise n\'a pas pu être obtenue.'**
  String get preciseLocationUnavailable;

  /// No description provided for @searchCityHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une ville...'**
  String get searchCityHint;

  /// No description provided for @noCityFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ville trouvée'**
  String get noCityFound;

  /// No description provided for @searchError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de recherche'**
  String get searchError;

  /// No description provided for @whatToRecord.
  ///
  /// In fr, this message translates to:
  /// **'Que voulez-vous enregistrer ?'**
  String get whatToRecord;

  /// No description provided for @whichPlant.
  ///
  /// In fr, this message translates to:
  /// **'Quelle plante ?'**
  String get whichPlant;

  /// No description provided for @addToGarden.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à un potager ?'**
  String get addToGarden;

  /// No description provided for @orAddToGarden.
  ///
  /// In fr, this message translates to:
  /// **'Ou ajouter à un potager'**
  String get orAddToGarden;

  /// No description provided for @subcategoryPepins.
  ///
  /// In fr, this message translates to:
  /// **'Pépins'**
  String get subcategoryPepins;

  /// No description provided for @subcategoryMediterraneen.
  ///
  /// In fr, this message translates to:
  /// **'Méditerranéen'**
  String get subcategoryMediterraneen;

  /// No description provided for @subcategoryFruitsACoque.
  ///
  /// In fr, this message translates to:
  /// **'Fruits à coque'**
  String get subcategoryFruitsACoque;

  /// No description provided for @subcategoryBruyeres.
  ///
  /// In fr, this message translates to:
  /// **'Bruyères'**
  String get subcategoryBruyeres;

  /// No description provided for @plants.
  ///
  /// In fr, this message translates to:
  /// **'Plantes'**
  String get plants;

  /// No description provided for @varietiesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} variétés'**
  String varietiesCount(int count);

  /// No description provided for @discoverVarieties.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez et gérez vos variétés'**
  String get discoverVarieties;

  /// No description provided for @searchPlant.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une plante...'**
  String get searchPlant;

  /// No description provided for @categoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get categoryLabel;

  /// No description provided for @exposureLabel.
  ///
  /// In fr, this message translates to:
  /// **'Exposition'**
  String get exposureLabel;

  /// No description provided for @resultsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 résultat} other{{count} résultats}}'**
  String resultsCount(int count);

  /// No description provided for @clearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get clearFilters;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @noPlants.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante'**
  String get noPlants;

  /// No description provided for @tryModifyingCriteria.
  ///
  /// In fr, this message translates to:
  /// **'Essayez de modifier vos critères'**
  String get tryModifyingCriteria;

  /// No description provided for @databaseEmpty.
  ///
  /// In fr, this message translates to:
  /// **'La base de données est vide'**
  String get databaseEmpty;

  /// No description provided for @loadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadingError;

  /// No description provided for @regularWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage régulier'**
  String get regularWatering;

  /// No description provided for @periodsSection.
  ///
  /// In fr, this message translates to:
  /// **'📅 Périodes'**
  String get periodsSection;

  /// No description provided for @sowingOpenGround.
  ///
  /// In fr, this message translates to:
  /// **'Semis pleine terre'**
  String get sowingOpenGround;

  /// No description provided for @sowingUnderCover.
  ///
  /// In fr, this message translates to:
  /// **'Semis sous abri'**
  String get sowingUnderCover;

  /// No description provided for @transplanting.
  ///
  /// In fr, this message translates to:
  /// **'Repiquage'**
  String get transplanting;

  /// No description provided for @harvestLabel.
  ///
  /// In fr, this message translates to:
  /// **'Récolte'**
  String get harvestLabel;

  /// No description provided for @plantingSection.
  ///
  /// In fr, this message translates to:
  /// **'🌱 Plantation'**
  String get plantingSection;

  /// No description provided for @careSection.
  ///
  /// In fr, this message translates to:
  /// **'🧑‍🌾 Entretien'**
  String get careSection;

  /// No description provided for @attentionSection.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Points d\'attention'**
  String get attentionSection;

  /// No description provided for @goodCompanions.
  ///
  /// In fr, this message translates to:
  /// **'✅ Bonnes associations'**
  String get goodCompanions;

  /// No description provided for @badCompanions.
  ///
  /// In fr, this message translates to:
  /// **'❌ À éviter'**
  String get badCompanions;

  /// No description provided for @weatherLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la météo...'**
  String get weatherLoading;

  /// No description provided for @weatherUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Météo indisponible'**
  String get weatherUnavailable;

  /// No description provided for @chooseCity.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une ville'**
  String get chooseCity;

  /// No description provided for @aboutVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon potager connecté'**
  String get aboutSubtitle;

  /// No description provided for @aboutMadeWithLove.
  ///
  /// In fr, this message translates to:
  /// **'Conçu avec amour en Bretagne'**
  String get aboutMadeWithLove;

  /// No description provided for @aboutContact.
  ///
  /// In fr, this message translates to:
  /// **'contact@agence-ixp.fr'**
  String get aboutContact;

  /// No description provided for @aboutCopyright.
  ///
  /// In fr, this message translates to:
  /// **'© {year} Jardingue. Tous droits réservés.'**
  String aboutCopyright(String year);

  /// No description provided for @aboutThanks.
  ///
  /// In fr, this message translates to:
  /// **'Remerciements'**
  String get aboutThanks;

  /// No description provided for @aboutThanksMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un immense merci à Ana & Charles\npour la motivation, les idées folles,\net les sessions de tests intensives !'**
  String get aboutThanksMessage;

  /// No description provided for @aboutTapToCelebrate.
  ///
  /// In fr, this message translates to:
  /// **'Tapez pour célébrer !'**
  String get aboutTapToCelebrate;

  /// No description provided for @aboutFamilyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma famille'**
  String get aboutFamilyTitle;

  /// No description provided for @aboutFamilyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un merci tout particulier à ma femme et mes enfants,\nqui me donnent chaque jour la détermination\net l\'énergie de construire ce projet.'**
  String get aboutFamilyMessage;

  /// No description provided for @aboutSourcesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sources des données'**
  String get aboutSourcesTitle;

  /// No description provided for @aboutSourcesBody.
  ///
  /// In fr, this message translates to:
  /// **'Les fiches plantes et arbres fruitiers s\'appuient sur des sources horticoles reconnues : INRAE, Vilmorin, Royal Horticultural Society (RHS), Rustica, et les zones de rusticité USDA.'**
  String get aboutSourcesBody;

  /// No description provided for @onboardingGardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre potager'**
  String get onboardingGardenTitle;

  /// No description provided for @onboardingGardenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Concevez votre jardin'**
  String get onboardingGardenSubtitle;

  /// No description provided for @onboardingGardenDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créez et organisez vos parcelles sur mesure. Placez vos plantes, visualisez votre potager et gérez plusieurs jardins facilement.'**
  String get onboardingGardenDesc;

  /// No description provided for @onboardingPlantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue de plantes'**
  String get onboardingPlantsTitle;

  /// No description provided for @onboardingPlantsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Explorez les variétés'**
  String get onboardingPlantsSubtitle;

  /// No description provided for @onboardingPlantsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Parcourez des dizaines de plantes avec leurs besoins en soleil, arrosage et associations. Trouvez les meilleurs compagnons pour votre potager.'**
  String get onboardingPlantsDesc;

  /// No description provided for @onboardingCalendarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get onboardingCalendarTitle;

  /// No description provided for @onboardingCalendarSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Planifiez vos saisons'**
  String get onboardingCalendarSubtitle;

  /// No description provided for @onboardingCalendarDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suivez les périodes de semis, plantation et récolte. Ne ratez plus jamais le bon moment grâce aux rappels et au calendrier interactif.'**
  String get onboardingCalendarDesc;

  /// No description provided for @onboardingWeatherTitle.
  ///
  /// In fr, this message translates to:
  /// **'Météo intelligente'**
  String get onboardingWeatherTitle;

  /// No description provided for @onboardingWeatherSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Jardinez au bon moment'**
  String get onboardingWeatherSubtitle;

  /// No description provided for @onboardingWeatherDesc.
  ///
  /// In fr, this message translates to:
  /// **'Consultez la météo locale, les phases de lune et recevez des conseils adaptés pour savoir quand arroser et quand planter.'**
  String get onboardingWeatherDesc;

  /// No description provided for @onboardingDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos données'**
  String get onboardingDataTitle;

  /// No description provided for @onboardingDataSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Stockage local sur votre téléphone'**
  String get onboardingDataSubtitle;

  /// No description provided for @onboardingDataDesc.
  ///
  /// In fr, this message translates to:
  /// **'Vos jardins et événements sont enregistrés sur votre téléphone. Supprimer l\'application ou vider le cache supprimera vos données.\n\nLa sauvegarde en ligne arrive bientôt !'**
  String get onboardingDataDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
