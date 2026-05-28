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

  /// No description provided for @orchardQuantityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Combien d\'arbres ?'**
  String get orchardQuantityLabel;

  /// No description provided for @orchardQuantityHint.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Une fiche sera créée} other{{count} fiches seront créées}}'**
  String orchardQuantityHint(int count);

  /// No description provided for @orchardNicknamePrefixLabel.
  ///
  /// In fr, this message translates to:
  /// **'Surnom (préfixe pour le groupe)'**
  String get orchardNicknamePrefixLabel;

  /// No description provided for @orchardNicknamePrefixHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Pommier du fond'**
  String get orchardNicknamePrefixHint;

  /// No description provided for @orchardNicknameSingleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Le pommier du fond'**
  String get orchardNicknameSingleHint;

  /// No description provided for @orchardBatchAddedSnack.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{name} ajouté au verger} other{{count} {name} ajoutés au verger}}'**
  String orchardBatchAddedSnack(int count, String name);

  /// No description provided for @orchardGroupCardCount.
  ///
  /// In fr, this message translates to:
  /// **'×{count}'**
  String orchardGroupCardCount(int count);

  /// No description provided for @orchardGroupVarietyAndType.
  ///
  /// In fr, this message translates to:
  /// **'{variety} · {type}'**
  String orchardGroupVarietyAndType(String variety, String type);

  /// No description provided for @orchardGroupHealthAllGood.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 arbre en bon état} other{{count} arbres en bon état}}'**
  String orchardGroupHealthAllGood(int count);

  /// No description provided for @orchardGroupHealthMixed.
  ///
  /// In fr, this message translates to:
  /// **'{healthy} en forme · {warning} à surveiller'**
  String orchardGroupHealthMixed(int healthy, int warning);

  /// No description provided for @orchardGroupHealthAlert.
  ///
  /// In fr, this message translates to:
  /// **'{healthy} en forme · {alert} en alerte'**
  String orchardGroupHealthAlert(int healthy, int alert);

  /// No description provided for @orchardGroupSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'{species} · {count} arbres'**
  String orchardGroupSheetTitle(String species, int count);

  /// No description provided for @orchardGroupStatsHarvestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernière récolte'**
  String get orchardGroupStatsHarvestTitle;

  /// No description provided for @orchardGroupStatsHarvestNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore'**
  String get orchardGroupStatsHarvestNone;

  /// No description provided for @orchardGroupStatsHarvestValue.
  ///
  /// In fr, this message translates to:
  /// **'{kg} kg cumulés'**
  String orchardGroupStatsHarvestValue(String kg);

  /// No description provided for @orchardGroupStatsPruningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernière taille'**
  String get orchardGroupStatsPruningTitle;

  /// No description provided for @orchardGroupStatsPruningValue.
  ///
  /// In fr, this message translates to:
  /// **'{date}'**
  String orchardGroupStatsPruningValue(String date);

  /// No description provided for @orchardGroupStatsPruningNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore taillé'**
  String get orchardGroupStatsPruningNone;

  /// No description provided for @orchardGroupActionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Action sur tout le groupe'**
  String get orchardGroupActionsTitle;

  /// No description provided for @orchardGroupActionPruneAll.
  ///
  /// In fr, this message translates to:
  /// **'Tailler tous'**
  String get orchardGroupActionPruneAll;

  /// No description provided for @orchardGroupActionHarvest.
  ///
  /// In fr, this message translates to:
  /// **'Récolter'**
  String get orchardGroupActionHarvest;

  /// No description provided for @orchardGroupActionTreat.
  ///
  /// In fr, this message translates to:
  /// **'Traiter'**
  String get orchardGroupActionTreat;

  /// No description provided for @orchardGroupActionHealth.
  ///
  /// In fr, this message translates to:
  /// **'État de santé'**
  String get orchardGroupActionHealth;

  /// No description provided for @orchardGroupTreesTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Mon arbre} other{Mes {count} arbres}}'**
  String orchardGroupTreesTitle(int count);

  /// No description provided for @orchardSelectionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 arbre sélectionné} other{{count} arbres sélectionnés}}'**
  String orchardSelectionCount(int count);

  /// No description provided for @orchardSelectionCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la sélection'**
  String get orchardSelectionCancel;

  /// No description provided for @orchardSelectionEnter.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner plusieurs'**
  String get orchardSelectionEnter;

  /// No description provided for @orchardBatchPruneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tailler {count, plural, =1{cet arbre} other{ces {count} arbres}} ?'**
  String orchardBatchPruneTitle(int count);

  /// No description provided for @orchardBatchPruneMessage.
  ///
  /// In fr, this message translates to:
  /// **'La date de taille d\'aujourd\'hui sera appliquée.'**
  String get orchardBatchPruneMessage;

  /// No description provided for @orchardBatchPruneDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Taille enregistrée} other{Taille enregistrée pour {count} arbres}}'**
  String orchardBatchPruneDone(int count);

  /// No description provided for @orchardBatchHarvestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récolte du groupe'**
  String get orchardBatchHarvestTitle;

  /// No description provided for @orchardBatchHarvestMessage.
  ///
  /// In fr, this message translates to:
  /// **'Rendement total à répartir sur {count, plural, =1{cet arbre} other{les {count} arbres}}.'**
  String orchardBatchHarvestMessage(int count);

  /// No description provided for @orchardBatchHarvestTotalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quantité totale (kg)'**
  String get orchardBatchHarvestTotalLabel;

  /// No description provided for @orchardBatchHarvestPerTreeHint.
  ///
  /// In fr, this message translates to:
  /// **'{kg} kg par arbre'**
  String orchardBatchHarvestPerTreeHint(String kg);

  /// No description provided for @orchardBatchHarvestDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Récolte enregistrée} other{Récolte enregistrée pour {count} arbres}}'**
  String orchardBatchHarvestDone(int count);

  /// No description provided for @orchardBatchTreatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer un traitement'**
  String get orchardBatchTreatTitle;

  /// No description provided for @orchardBatchTreatMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'observation sera ajoutée aux notes de {count, plural, =1{cet arbre} other{{count} arbres}}.'**
  String orchardBatchTreatMessage(int count);

  /// No description provided for @orchardBatchTreatHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Bouillie bordelaise, purin d\'ortie...'**
  String get orchardBatchTreatHint;

  /// No description provided for @orchardBatchTreatDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Traitement noté} other{Traitement noté sur {count} arbres}}'**
  String orchardBatchTreatDone(int count);

  /// No description provided for @orchardBatchHealthTitle.
  ///
  /// In fr, this message translates to:
  /// **'État de santé du groupe'**
  String get orchardBatchHealthTitle;

  /// No description provided for @orchardBatchHealthDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{État mis à jour} other{État mis à jour pour {count} arbres}}'**
  String orchardBatchHealthDone(int count);

  /// No description provided for @pageHelpTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get pageHelpTooltip;

  /// No description provided for @pageHelpDismiss.
  ///
  /// In fr, this message translates to:
  /// **'C\'est compris !'**
  String get pageHelpDismiss;

  /// No description provided for @pageHelpWhy.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi ?'**
  String get pageHelpWhy;

  /// No description provided for @pageHelpHow.
  ///
  /// In fr, this message translates to:
  /// **'Comment ?'**
  String get pageHelpHow;

  /// No description provided for @pageHelpWhen.
  ///
  /// In fr, this message translates to:
  /// **'Quand ?'**
  String get pageHelpWhen;

  /// No description provided for @pageHelpWhere.
  ///
  /// In fr, this message translates to:
  /// **'Où ?'**
  String get pageHelpWhere;

  /// No description provided for @pageHelpOrchardWhy.
  ///
  /// In fr, this message translates to:
  /// **'Garder un œil sur tous vos arbres fruitiers et leur état au fil des saisons, des tailles aux récoltes.'**
  String get pageHelpOrchardWhy;

  /// No description provided for @pageHelpOrchardHow.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez chaque arbre (ou un lot d\'arbres identiques) avec son surnom, sa variété et son emplacement. Chaque action s\'enregistre en deux tapes.'**
  String get pageHelpOrchardHow;

  /// No description provided for @pageHelpOrchardWhen.
  ///
  /// In fr, this message translates to:
  /// **'À chaque taille, traitement, récolte ou changement d\'état de santé — pour reconstituer l\'historique d\'un seul coup d\'œil.'**
  String get pageHelpOrchardWhen;

  /// No description provided for @pageHelpOrchardWhere.
  ///
  /// In fr, this message translates to:
  /// **'Tap sur une carte pour voir les détails d\'un arbre ou d\'un groupe. Long-press sur un groupe pour appliquer une action à plusieurs arbres d\'un coup.'**
  String get pageHelpOrchardWhere;

  /// No description provided for @pageHelpPlanningWhy.
  ///
  /// In fr, this message translates to:
  /// **'Savoir ce qui se passe ce mois-ci dans le potager et anticiper les semis, plantations et récoltes à venir.'**
  String get pageHelpPlanningWhy;

  /// No description provided for @pageHelpPlanningHow.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez vos plants pour voir leurs périodes, basculez entre Tout / Mes plants / Potagère, et utilisez le filtre par mois.'**
  String get pageHelpPlanningHow;

  /// No description provided for @pageHelpPlanningWhen.
  ///
  /// In fr, this message translates to:
  /// **'À consulter en début de mois ou avant chaque sortie au jardin pour ne rater aucune fenêtre de semis ou de récolte.'**
  String get pageHelpPlanningWhen;

  /// No description provided for @pageHelpPlanningWhere.
  ///
  /// In fr, this message translates to:
  /// **'Tap sur un plant pour voir ses détails. Tap sur une tâche potagère pour l\'enregistrer dans votre suivi.'**
  String get pageHelpPlanningWhere;

  /// No description provided for @pageHelpCarnetWhy.
  ///
  /// In fr, this message translates to:
  /// **'Centraliser votre journal de jardin : semis, récoltes, observations, statistiques de la saison.'**
  String get pageHelpCarnetWhy;

  /// No description provided for @pageHelpCarnetHow.
  ///
  /// In fr, this message translates to:
  /// **'Naviguez entre les onglets (Semis, Récoltes, Journal, Stats) via les marque-pages sur le bord. Ajoutez une entrée avec le « + » de chaque onglet.'**
  String get pageHelpCarnetHow;

  /// No description provided for @pageHelpCarnetWhen.
  ///
  /// In fr, this message translates to:
  /// **'Au quotidien — quelques secondes suffisent pour noter une récolte du jour ou un semis qui a levé.'**
  String get pageHelpCarnetWhen;

  /// No description provided for @pageHelpCarnetWhere.
  ///
  /// In fr, this message translates to:
  /// **'Glissez depuis le bord gauche de l\'écran, ou tapez sur le bouton menu en haut à droite de l\'accueil pour ouvrir/fermer le carnet.'**
  String get pageHelpCarnetWhere;

  /// No description provided for @pageHelpGardenWhy.
  ///
  /// In fr, this message translates to:
  /// **'Visualiser tous vos potagers, vos rappels de soin et la météo qui les concerne, en un seul écran d\'accueil.'**
  String get pageHelpGardenWhy;

  /// No description provided for @pageHelpGardenHow.
  ///
  /// In fr, this message translates to:
  /// **'Tap sur un potager pour entrer dans son éditeur (placer ou déplacer les plantes). Bouton « + » en bas pour créer un nouveau potager.'**
  String get pageHelpGardenHow;

  /// No description provided for @pageHelpGardenWhen.
  ///
  /// In fr, this message translates to:
  /// **'À chaque ouverture de l\'app — c\'est votre tableau de bord. Les rappels affichent ce qu\'il faut faire aujourd\'hui.'**
  String get pageHelpGardenWhen;

  /// No description provided for @pageHelpGardenWhere.
  ///
  /// In fr, this message translates to:
  /// **'Les cartes Météo, Potagers et Verger sont empilées du haut vers le bas. Le bouton Carnet est en haut à droite, l\'accès Premium juste à côté.'**
  String get pageHelpGardenWhere;

  /// No description provided for @pageHelpPlanningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planification'**
  String get pageHelpPlanningTitle;

  /// No description provided for @pageHelpGardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon jardin'**
  String get pageHelpGardenTitle;

  /// No description provided for @pageHelpCarnetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carnet de bord'**
  String get pageHelpCarnetTitle;

  /// No description provided for @pageHelpCalendarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get pageHelpCalendarTitle;

  /// No description provided for @pageHelpPlantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue de plantes'**
  String get pageHelpPlantsTitle;

  /// No description provided for @pageHelpEditorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan du potager'**
  String get pageHelpEditorTitle;

  /// No description provided for @pageHelpPlantsWhy.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir le catalogue complet pour trouver les bonnes variétés à planter, et créer vos propres plantes si la vôtre manque.'**
  String get pageHelpPlantsWhy;

  /// No description provided for @pageHelpPlantsHow.
  ///
  /// In fr, this message translates to:
  /// **'Recherchez par nom ou filtrez par catégorie (légumes, fruits, aromatiques…). Tap sur une plante pour voir sa fiche détaillée et l\'ajouter à un potager.'**
  String get pageHelpPlantsHow;

  /// No description provided for @pageHelpPlantsWhen.
  ///
  /// In fr, this message translates to:
  /// **'Au moment de planifier vos semis, d\'ajouter une plante à un potager, ou de noter les caractéristiques d\'une variété rare.'**
  String get pageHelpPlantsWhen;

  /// No description provided for @pageHelpPlantsWhere.
  ///
  /// In fr, this message translates to:
  /// **'Tap sur « + Créer une plante personnalisée » juste sous la barre de recherche pour ajouter une variété qui n\'existe pas dans le catalogue.'**
  String get pageHelpPlantsWhere;

  /// No description provided for @pageHelpEditorWhy.
  ///
  /// In fr, this message translates to:
  /// **'Dessiner et organiser votre potager à l\'échelle réelle, prévenir les antagonismes et faciliter la rotation des cultures.'**
  String get pageHelpEditorWhy;

  /// No description provided for @pageHelpEditorHow.
  ///
  /// In fr, this message translates to:
  /// **'Tap sur le cadenas en bas pour déverrouiller, puis ajoutez plantes et zones depuis le bouton +. Glissez pour déplacer, pincez pour zoomer.'**
  String get pageHelpEditorHow;

  /// No description provided for @pageHelpEditorWhen.
  ///
  /// In fr, this message translates to:
  /// **'Au moment de la planification annuelle, ou après chaque ajout/déplacement de plante pour garder le plan à jour.'**
  String get pageHelpEditorWhen;

  /// No description provided for @pageHelpEditorWhere.
  ///
  /// In fr, this message translates to:
  /// **'Les boutons en haut servent à annuler, lister les éléments, gérer les calques (compagnons, amendements) et exporter le plan en PDF.'**
  String get pageHelpEditorWhere;

  /// No description provided for @pageHelpCalendarWhy.
  ///
  /// In fr, this message translates to:
  /// **'Voir d\'un coup d\'œil les périodes de semis, plantation, floraison et récolte de tous vos plants.'**
  String get pageHelpCalendarWhy;

  /// No description provided for @pageHelpCalendarHow.
  ///
  /// In fr, this message translates to:
  /// **'Basculez entre la vue Calendrier (points colorés sur les jours) et la vue Liste (groupée par type d\'activité). Sélectionnez un plant pour filtrer.'**
  String get pageHelpCalendarHow;

  /// No description provided for @pageHelpCalendarWhen.
  ///
  /// In fr, this message translates to:
  /// **'Au moment de planifier vos cultures, ou pour vérifier si vous êtes dans la bonne période pour une action donnée.'**
  String get pageHelpCalendarWhen;

  /// No description provided for @pageHelpCalendarWhere.
  ///
  /// In fr, this message translates to:
  /// **'Tap sur un jour pour ajouter un événement (semis, arrosage…). Tap sur Mon suivi pour retrouver l\'historique de toutes vos actions enregistrées.'**
  String get pageHelpCalendarWhere;

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

  /// No description provided for @moveMode.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get moveMode;

  /// No description provided for @resizeMode.
  ///
  /// In fr, this message translates to:
  /// **'Redimensionner'**
  String get resizeMode;

  /// No description provided for @resizeElements.
  ///
  /// In fr, this message translates to:
  /// **'Redimensionnez les éléments'**
  String get resizeElements;

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

  /// No description provided for @fertilizingToday.
  ///
  /// In fr, this message translates to:
  /// **'Fertilisation du jour'**
  String get fertilizingToday;

  /// No description provided for @plantsToFertilizeCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 plante à fertiliser} other{{count} plantes à fertiliser}}'**
  String plantsToFertilizeCount(int count);

  /// No description provided for @neverFertilized.
  ///
  /// In fr, this message translates to:
  /// **'Jamais fertilisé'**
  String get neverFertilized;

  /// No description provided for @fertilizedDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Fertilisé il y a {count} jour{count, plural, =1{} other{s}}'**
  String fertilizedDaysAgo(int count);

  /// No description provided for @nameFertilized.
  ///
  /// In fr, this message translates to:
  /// **'{name} fertilisé !'**
  String nameFertilized(String name);

  /// No description provided for @fertilizeAction.
  ///
  /// In fr, this message translates to:
  /// **'Fertiliser'**
  String get fertilizeAction;

  /// No description provided for @pheromoneTrapsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pièges à phéromones'**
  String get pheromoneTrapsTitle;

  /// No description provided for @pheromoneTrapsToReplace.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 piège à renouveler} other{{count} pièges à renouveler}}'**
  String pheromoneTrapsToReplace(int count);

  /// No description provided for @pheromoneTrapsOverdueCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 en retard} other{{count} en retard}}'**
  String pheromoneTrapsOverdueCount(int count);

  /// No description provided for @pheromoneTrapsDueSoon.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement à prévoir'**
  String get pheromoneTrapsDueSoon;

  /// No description provided for @otherTrapsCount.
  ///
  /// In fr, this message translates to:
  /// **'+{count} autres pièges'**
  String otherTrapsCount(int count);

  /// No description provided for @renewAction.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler'**
  String get renewAction;

  /// No description provided for @trapRenewedFor.
  ///
  /// In fr, this message translates to:
  /// **'Piège de {name} renouvelé !'**
  String trapRenewedFor(String name);

  /// No description provided for @installedDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Posé il y a {count} jour{count, plural, =1{} other{s}}'**
  String installedDaysAgo(int count);

  /// No description provided for @renewalInDays.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement dans {count} jour{count, plural, =1{} other{s}}'**
  String renewalInDays(int count);

  /// No description provided for @trapsScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes pièges'**
  String get trapsScreenTitle;

  /// No description provided for @myTrapsAction.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes pièges'**
  String get myTrapsAction;

  /// No description provided for @addTrapAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un piège'**
  String get addTrapAction;

  /// No description provided for @addTrapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un piège à phéromones'**
  String get addTrapTitle;

  /// No description provided for @trapType.
  ///
  /// In fr, this message translates to:
  /// **'Type de piège'**
  String get trapType;

  /// No description provided for @installationDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de pose'**
  String get installationDate;

  /// No description provided for @lifetimeDays.
  ///
  /// In fr, this message translates to:
  /// **'Durée de vie (jours)'**
  String get lifetimeDays;

  /// No description provided for @lifetimeAboutDays.
  ///
  /// In fr, this message translates to:
  /// **'Environ {count} jours'**
  String lifetimeAboutDays(int count);

  /// No description provided for @showAllTrapTypes.
  ///
  /// In fr, this message translates to:
  /// **'Afficher tous les types'**
  String get showAllTrapTypes;

  /// No description provided for @selectTypeFirst.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez d\'abord un type'**
  String get selectTypeFirst;

  /// No description provided for @notesHint.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get notesHint;

  /// No description provided for @pickTreeForTrap.
  ///
  /// In fr, this message translates to:
  /// **'Pour quel arbre ?'**
  String get pickTreeForTrap;

  /// No description provided for @trapsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun piège'**
  String get trapsEmptyTitle;

  /// No description provided for @trapsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Posez votre premier piège à phéromones\npour suivre les renouvellements.'**
  String get trapsEmptySubtitle;

  /// No description provided for @deleteTrapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le piège ?'**
  String get deleteTrapTitle;

  /// No description provided for @deleteTrapConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer ce piège ({type}) ?'**
  String deleteTrapConfirm(String type);

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

  /// No description provided for @fertilizerAction.
  ///
  /// In fr, this message translates to:
  /// **'Engrais'**
  String get fertilizerAction;

  /// No description provided for @fertilizerRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Engrais enregistré !'**
  String get fertilizerRegistered;

  /// No description provided for @mulchingAction.
  ///
  /// In fr, this message translates to:
  /// **'Paillage'**
  String get mulchingAction;

  /// No description provided for @mulchingRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Paillage enregistré !'**
  String get mulchingRegistered;

  /// No description provided for @slugControlAction.
  ///
  /// In fr, this message translates to:
  /// **'Anti-limaces'**
  String get slugControlAction;

  /// No description provided for @slugControlRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Anti-limaces enregistré !'**
  String get slugControlRegistered;

  /// No description provided for @treatmentAction.
  ///
  /// In fr, this message translates to:
  /// **'Traitement'**
  String get treatmentAction;

  /// No description provided for @treatmentRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Traitement enregistré !'**
  String get treatmentRegistered;

  /// No description provided for @maintenanceSection.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get maintenanceSection;

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

  /// No description provided for @searchOffline.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet. Vérifiez votre réseau et réessayez.'**
  String get searchOffline;

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

  /// No description provided for @createPlantAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer une plante personnalisée'**
  String get createPlantAction;

  /// No description provided for @createPlantHint.
  ///
  /// In fr, this message translates to:
  /// **'Pas dans la liste ? Ajoute-la'**
  String get createPlantHint;

  /// No description provided for @userPlantBadge.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisée'**
  String get userPlantBadge;

  /// No description provided for @userPlantFormCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une plante'**
  String get userPlantFormCreateTitle;

  /// No description provided for @userPlantFormEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la plante'**
  String get userPlantFormEditTitle;

  /// No description provided for @userPlantFormSectionEssentials.
  ///
  /// In fr, this message translates to:
  /// **'Essentiel'**
  String get userPlantFormSectionEssentials;

  /// No description provided for @userPlantFormSectionEssentialsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Champs obligatoires'**
  String get userPlantFormSectionEssentialsSubtitle;

  /// No description provided for @userPlantFormSectionCalendars.
  ///
  /// In fr, this message translates to:
  /// **'Calendriers'**
  String get userPlantFormSectionCalendars;

  /// No description provided for @userPlantFormSectionCalendarsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un mois requis (semis, plantation ou récolte)'**
  String get userPlantFormSectionCalendarsSubtitle;

  /// No description provided for @userPlantFormSectionConditions.
  ///
  /// In fr, this message translates to:
  /// **'Conditions de culture'**
  String get userPlantFormSectionConditions;

  /// No description provided for @userPlantFormSectionAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Conseils & repères'**
  String get userPlantFormSectionAdvice;

  /// No description provided for @userPlantFormSectionCompanions.
  ///
  /// In fr, this message translates to:
  /// **'Compagnons & antagonistes'**
  String get userPlantFormSectionCompanions;

  /// No description provided for @userPlantFormSectionAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get userPlantFormSectionAdvanced;

  /// No description provided for @userPlantFieldCommonName.
  ///
  /// In fr, this message translates to:
  /// **'Nom commun *'**
  String get userPlantFieldCommonName;

  /// No description provided for @userPlantFieldCommonNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: Pastèque'**
  String get userPlantFieldCommonNameHint;

  /// No description provided for @userPlantFieldCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie *'**
  String get userPlantFieldCategory;

  /// No description provided for @userPlantFieldSpacingPlants.
  ///
  /// In fr, this message translates to:
  /// **'Espacement plants (cm) *'**
  String get userPlantFieldSpacingPlants;

  /// No description provided for @userPlantFieldSpacingPlantsHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: 100'**
  String get userPlantFieldSpacingPlantsHint;

  /// No description provided for @userPlantFieldSpacingRows.
  ///
  /// In fr, this message translates to:
  /// **'Espacement rangs (cm) *'**
  String get userPlantFieldSpacingRows;

  /// No description provided for @userPlantFieldSpacingRowsHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: 150'**
  String get userPlantFieldSpacingRowsHint;

  /// No description provided for @userPlantFieldEmoji.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get userPlantFieldEmoji;

  /// No description provided for @userPlantFieldEmojiAuto.
  ///
  /// In fr, this message translates to:
  /// **'Auto (modifier)'**
  String get userPlantFieldEmojiAuto;

  /// No description provided for @userPlantFieldEmojiManual.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'icône'**
  String get userPlantFieldEmojiManual;

  /// No description provided for @userPlantFieldSun.
  ///
  /// In fr, this message translates to:
  /// **'Exposition'**
  String get userPlantFieldSun;

  /// No description provided for @userPlantFieldSunHint.
  ///
  /// In fr, this message translates to:
  /// **'— Choisir —'**
  String get userPlantFieldSunHint;

  /// No description provided for @userPlantFieldDepth.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur (cm)'**
  String get userPlantFieldDepth;

  /// No description provided for @userPlantFieldDepthHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: 2'**
  String get userPlantFieldDepthHint;

  /// No description provided for @userPlantFieldMinTemp.
  ///
  /// In fr, this message translates to:
  /// **'Temp. mini (°C)'**
  String get userPlantFieldMinTemp;

  /// No description provided for @userPlantFieldMinTempHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: 12'**
  String get userPlantFieldMinTempHint;

  /// No description provided for @userPlantFieldSoilType.
  ///
  /// In fr, this message translates to:
  /// **'Type de sol'**
  String get userPlantFieldSoilType;

  /// No description provided for @userPlantFieldSoilTypeHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: léger, sableux, drainé'**
  String get userPlantFieldSoilTypeHint;

  /// No description provided for @userPlantFieldSoilMoisture.
  ///
  /// In fr, this message translates to:
  /// **'Humidité préférée'**
  String get userPlantFieldSoilMoisture;

  /// No description provided for @userPlantFieldSoilMoistureHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: modérée à régulière'**
  String get userPlantFieldSoilMoistureHint;

  /// No description provided for @userPlantFieldWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage'**
  String get userPlantFieldWatering;

  /// No description provided for @userPlantFieldWateringHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: régulier au pied'**
  String get userPlantFieldWateringHint;

  /// No description provided for @userPlantFieldRotation.
  ///
  /// In fr, this message translates to:
  /// **'Famille botanique (rotation)'**
  String get userPlantFieldRotation;

  /// No description provided for @userPlantFieldRotationHint.
  ///
  /// In fr, this message translates to:
  /// **'Auto depuis le nom latin'**
  String get userPlantFieldRotationHint;

  /// No description provided for @userPlantFieldSowingReco.
  ///
  /// In fr, this message translates to:
  /// **'Conseil de semis'**
  String get userPlantFieldSowingReco;

  /// No description provided for @userPlantFieldPlantingAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Conseil de plantation'**
  String get userPlantFieldPlantingAdvice;

  /// No description provided for @userPlantFieldCare.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get userPlantFieldCare;

  /// No description provided for @userPlantFieldRedFlags.
  ///
  /// In fr, this message translates to:
  /// **'Points d\'attention'**
  String get userPlantFieldRedFlags;

  /// No description provided for @userPlantFieldPracticalTips.
  ///
  /// In fr, this message translates to:
  /// **'Astuces pratiques'**
  String get userPlantFieldPracticalTips;

  /// No description provided for @userPlantFieldLatinName.
  ///
  /// In fr, this message translates to:
  /// **'Nom latin'**
  String get userPlantFieldLatinName;

  /// No description provided for @userPlantFieldLatinNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: Citrullus lanatus'**
  String get userPlantFieldLatinNameHint;

  /// No description provided for @userPlantFieldToxicity.
  ///
  /// In fr, this message translates to:
  /// **'Toxicité'**
  String get userPlantFieldToxicity;

  /// No description provided for @userPlantFieldToxicityHint.
  ///
  /// In fr, this message translates to:
  /// **'Laisser vide si non toxique'**
  String get userPlantFieldToxicityHint;

  /// No description provided for @userPlantCalendarSowing.
  ///
  /// In fr, this message translates to:
  /// **'Semis'**
  String get userPlantCalendarSowing;

  /// No description provided for @userPlantCalendarPlanting.
  ///
  /// In fr, this message translates to:
  /// **'Plantation'**
  String get userPlantCalendarPlanting;

  /// No description provided for @userPlantCalendarHarvest.
  ///
  /// In fr, this message translates to:
  /// **'Récolte'**
  String get userPlantCalendarHarvest;

  /// No description provided for @userPlantCompanionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plantes compagnes'**
  String get userPlantCompanionsLabel;

  /// No description provided for @userPlantAntagonistsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plantes antagonistes'**
  String get userPlantAntagonistsLabel;

  /// No description provided for @userPlantCompanionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{c} compagne(s), {a} antagoniste(s)'**
  String userPlantCompanionsSubtitle(int c, int a);

  /// No description provided for @userPlantCompanionsAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get userPlantCompanionsAdd;

  /// No description provided for @userPlantCompanionsEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get userPlantCompanionsEdit;

  /// No description provided for @userPlantCompanionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sélection'**
  String get userPlantCompanionsEmpty;

  /// No description provided for @userPlantCompanionsValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider ({n})'**
  String userPlantCompanionsValidate(int n);

  /// No description provided for @userPlantCompanionsSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher…'**
  String get userPlantCompanionsSearch;

  /// No description provided for @userPlantSaveCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get userPlantSaveCreate;

  /// No description provided for @userPlantSaveEdit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get userPlantSaveEdit;

  /// No description provided for @userPlantDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette plante'**
  String get userPlantDelete;

  /// No description provided for @userPlantDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette plante ?'**
  String get userPlantDeleteConfirmTitle;

  /// No description provided for @userPlantDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'La plante \"{name}\" sera définitivement retirée de ton catalogue.'**
  String userPlantDeleteConfirmBody(String name);

  /// No description provided for @userPlantDeleteCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get userPlantDeleteCancel;

  /// No description provided for @userPlantDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get userPlantDeleteConfirm;

  /// No description provided for @userPlantInUseHeader.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ \"{name}\" figure encore dans tes plans.'**
  String userPlantInUseHeader(String name);

  /// No description provided for @userPlantInUseGardens.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera retirée de : {gardens}.'**
  String userPlantInUseGardens(String gardens);

  /// No description provided for @userPlantInUseEvents.
  ///
  /// In fr, this message translates to:
  /// **'{count} événement(s) de suivi seront effacés.'**
  String userPlantInUseEvents(int count);

  /// No description provided for @userPlantInUseFooter.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get userPlantInUseFooter;

  /// No description provided for @userPlantValidationName.
  ///
  /// In fr, this message translates to:
  /// **'Le nom commun est obligatoire.'**
  String get userPlantValidationName;

  /// No description provided for @userPlantValidationCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une catégorie.'**
  String get userPlantValidationCategory;

  /// No description provided for @userPlantValidationSpacingPlants.
  ///
  /// In fr, this message translates to:
  /// **'Indique l\'espacement entre plants (cm > 0).'**
  String get userPlantValidationSpacingPlants;

  /// No description provided for @userPlantValidationSpacingRows.
  ///
  /// In fr, this message translates to:
  /// **'Indique l\'espacement entre rangs (cm > 0).'**
  String get userPlantValidationSpacingRows;

  /// No description provided for @userPlantValidationCalendars.
  ///
  /// In fr, this message translates to:
  /// **'Coche au moins un mois sur l\'un des calendriers (semis, plantation ou récolte).'**
  String get userPlantValidationCalendars;

  /// No description provided for @userPlantSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement : {message}'**
  String userPlantSaveError(String message);

  /// No description provided for @userPlantDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression : {message}'**
  String userPlantDeleteError(String message);

  /// No description provided for @userPlantSunFull.
  ///
  /// In fr, this message translates to:
  /// **'☀️ Ensoleillé'**
  String get userPlantSunFull;

  /// No description provided for @userPlantSunPartial.
  ///
  /// In fr, this message translates to:
  /// **'⛅ Mi-ombre'**
  String get userPlantSunPartial;

  /// No description provided for @userPlantSunShade.
  ///
  /// In fr, this message translates to:
  /// **'🌥️ Ombragé'**
  String get userPlantSunShade;

  /// No description provided for @userPlantEmojiPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une icône'**
  String get userPlantEmojiPickerTitle;

  /// No description provided for @userPlantCompanionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compagnes'**
  String get userPlantCompanionsTitle;

  /// No description provided for @userPlantAntagonistsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Antagonistes'**
  String get userPlantAntagonistsTitle;

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
  /// **'agenceixp.app@gmail.com'**
  String get aboutContact;

  /// No description provided for @aboutInstagram.
  ///
  /// In fr, this message translates to:
  /// **'@agenceixp'**
  String get aboutInstagram;

  /// No description provided for @aboutInstagramUrl.
  ///
  /// In fr, this message translates to:
  /// **'https://www.instagram.com/agenceixp/'**
  String get aboutInstagramUrl;

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

  /// No description provided for @elementTooBigForGarden.
  ///
  /// In fr, this message translates to:
  /// **'Élément trop grand pour le jardin (max {maxWidthCm}cm × {maxHeightCm}cm)'**
  String elementTooBigForGarden(int maxWidthCm, int maxHeightCm);

  /// No description provided for @gardenResizeOverflow.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Impossible de redimensionner : 1 élément dépasse du nouveau jardin.} other{Impossible de redimensionner : {count} éléments dépassent du nouveau jardin.}}'**
  String gardenResizeOverflow(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsGuidanceSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils de jardinage'**
  String get settingsGuidanceSectionTitle;

  /// No description provided for @settingsGuidanceSectionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aide-toi des données de compagnonnage et d\'incompatibilité du catalogue. Désactivé par défaut.'**
  String get settingsGuidanceSectionSubtitle;

  /// No description provided for @settingsCompanionSuggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggérer les compagnons au dépôt'**
  String get settingsCompanionSuggestionsTitle;

  /// No description provided for @settingsCompanionSuggestionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Après chaque plante posée, propose ses plantes compagnes (à ajouter au panier).'**
  String get settingsCompanionSuggestionsSubtitle;

  /// No description provided for @settingsAntagonistWarningsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avertir des incompatibilités'**
  String get settingsAntagonistWarningsTitle;

  /// No description provided for @settingsAntagonistWarningsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Affiche un avertissement avant de placer une plante à côté d\'un antagoniste connu.'**
  String get settingsAntagonistWarningsSubtitle;

  /// No description provided for @companionSuggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compagnons de la {plantName}'**
  String companionSuggestionsTitle(String plantName);

  /// No description provided for @companionSuggestionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ces plantes au panier pour les placer après.'**
  String get companionSuggestionsSubtitle;

  /// No description provided for @companionSuggestionsLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get companionSuggestionsLater;

  /// No description provided for @companionSuggestionsAddToBasket.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get companionSuggestionsAddToBasket;

  /// No description provided for @antagonistDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Incompatibilité détectée'**
  String get antagonistDialogTitle;

  /// No description provided for @antagonistDialogConfirmQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Placer quand même ?'**
  String get antagonistDialogConfirmQuestion;

  /// No description provided for @antagonistDialogPlace.
  ///
  /// In fr, this message translates to:
  /// **'Placer'**
  String get antagonistDialogPlace;

  /// No description provided for @antagonistConflictWithReason.
  ///
  /// In fr, this message translates to:
  /// **'{sourceName} et {neighborName} partagent {reason}.'**
  String antagonistConflictWithReason(
    String sourceName,
    String neighborName,
    String reason,
  );

  /// No description provided for @antagonistConflictGeneric.
  ///
  /// In fr, this message translates to:
  /// **'{sourceName} et {neighborName} ne s\'aiment pas.'**
  String antagonistConflictGeneric(String sourceName, String neighborName);

  /// No description provided for @guidanceOptOutCompanionLink.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus afficher ces suggestions'**
  String get guidanceOptOutCompanionLink;

  /// No description provided for @guidanceOptOutAntagonistLink.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus afficher ces avertissements'**
  String get guidanceOptOutAntagonistLink;

  /// No description provided for @guidanceOptOutCompanionSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions désactivées. Vous pouvez les réactiver depuis l\'engrenage ⚙️ en haut à droite de l\'accueil.'**
  String get guidanceOptOutCompanionSnackbar;

  /// No description provided for @guidanceOptOutAntagonistSnackbar.
  ///
  /// In fr, this message translates to:
  /// **'Avertissements désactivés. Vous pouvez les réactiver depuis l\'engrenage ⚙️ en haut à droite de l\'accueil.'**
  String get guidanceOptOutAntagonistSnackbar;

  /// No description provided for @guidanceOptOutUndo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get guidanceOptOutUndo;

  /// No description provided for @gardenCellSizeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Précision de la grille'**
  String get gardenCellSizeTitle;

  /// No description provided for @gardenCellSizeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Plus la cellule est petite, plus le placement est précis. Plus elle est grande, plus la grille est lisible.'**
  String get gardenCellSizeSubtitle;

  /// No description provided for @gardenCellSizeValue.
  ///
  /// In fr, this message translates to:
  /// **'{value} cm'**
  String gardenCellSizeValue(int value);

  /// No description provided for @gardenCellSizeHintFine.
  ///
  /// In fr, this message translates to:
  /// **'Précis'**
  String get gardenCellSizeHintFine;

  /// No description provided for @gardenCellSizeHintCoarse.
  ///
  /// In fr, this message translates to:
  /// **'Lisible'**
  String get gardenCellSizeHintCoarse;

  /// No description provided for @colorPickerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une couleur pour distinguer ce pied.'**
  String get colorPickerSubtitle;

  /// No description provided for @colorPickerReset.
  ///
  /// In fr, this message translates to:
  /// **'Couleur par défaut (catégorie)'**
  String get colorPickerReset;

  /// No description provided for @colorPickerCustom.
  ///
  /// In fr, this message translates to:
  /// **'Couleur personnalisée'**
  String get colorPickerCustom;

  /// No description provided for @colorPickerCustomDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une couleur'**
  String get colorPickerCustomDialogTitle;

  /// No description provided for @colorPickerCustomDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get colorPickerCustomDialogConfirm;

  /// No description provided for @colorPickerApplyToAll.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer à tou(te)s les {count} {plantName} de ce potager'**
  String colorPickerApplyToAll(int count, String plantName);

  /// No description provided for @templatesSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer avec un modèle'**
  String get templatesSectionTitle;

  /// No description provided for @templatesSectionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un préréglage et toutes les plantes sont placées d\'un coup. Vous pourrez tout modifier ensuite.'**
  String get templatesSectionSubtitle;

  /// No description provided for @templateCardDimensions.
  ///
  /// In fr, this message translates to:
  /// **'{width} × {height} m  ·  {count} plantes'**
  String templateCardDimensions(String width, String height, int count);

  /// No description provided for @templateCustomTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get templateCustomTitle;

  /// No description provided for @templateCustomSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Potager vierge'**
  String get templateCustomSubtitle;

  /// No description provided for @carnetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carnet de bord'**
  String get carnetTitle;

  /// No description provided for @carnetOpenA11y.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le carnet de bord'**
  String get carnetOpenA11y;

  /// No description provided for @carnetTabHarvests.
  ///
  /// In fr, this message translates to:
  /// **'Récoltes'**
  String get carnetTabHarvests;

  /// No description provided for @carnetTabSeedlings.
  ///
  /// In fr, this message translates to:
  /// **'Semis'**
  String get carnetTabSeedlings;

  /// No description provided for @carnetTabJournal.
  ///
  /// In fr, this message translates to:
  /// **'Carnet'**
  String get carnetTabJournal;

  /// No description provided for @carnetTabStats.
  ///
  /// In fr, this message translates to:
  /// **'Stats'**
  String get carnetTabStats;

  /// No description provided for @carnetHarvestsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune récolte enregistrée'**
  String get carnetHarvestsEmptyTitle;

  /// No description provided for @carnetHarvestsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette section accueillera bientôt vos cueillettes, quantités et historique de la saison.'**
  String get carnetHarvestsEmptySubtitle;

  /// No description provided for @carnetSeedlingsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun semis en cours'**
  String get carnetSeedlingsEmptyTitle;

  /// No description provided for @carnetSeedlingsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez bientôt suivre vos semis, dates de germination et repiquages.'**
  String get carnetSeedlingsEmptySubtitle;

  /// No description provided for @carnetJournalEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carnet vierge'**
  String get carnetJournalEmptyTitle;

  /// No description provided for @carnetJournalEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos observations, idées et anecdotes au fil des saisons.'**
  String get carnetJournalEmptySubtitle;

  /// No description provided for @carnetStatsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de statistiques'**
  String get carnetStatsEmptyTitle;

  /// No description provided for @carnetStatsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les bilans de saison s\'afficheront ici dès que vous aurez enregistré des récoltes.'**
  String get carnetStatsEmptySubtitle;

  /// No description provided for @carnetTabSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get carnetTabSettings;

  /// No description provided for @carnetSettingsMoreSection.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get carnetSettingsMoreSection;

  /// No description provided for @carnetSettingsPremiumTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde Premium'**
  String get carnetSettingsPremiumTitle;

  /// No description provided for @carnetSettingsPremiumSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cloud, restauration multi-appareils'**
  String get carnetSettingsPremiumSubtitle;

  /// No description provided for @carnetSettingsAboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos de Jardingue'**
  String get carnetSettingsAboutTitle;

  /// No description provided for @carnetSettingsAboutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Crédits, contact, mentions légales'**
  String get carnetSettingsAboutSubtitle;

  /// No description provided for @carnetSettingsThanksMessage.
  ///
  /// In fr, this message translates to:
  /// **'Merci d\'utiliser Jardingue.\nFait avec ♥ pour les jardiniers.'**
  String get carnetSettingsThanksMessage;

  /// No description provided for @carnetTabAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get carnetTabAbout;

  /// No description provided for @carnetHarvestsTitleYear.
  ///
  /// In fr, this message translates to:
  /// **'Récoltes {year}'**
  String carnetHarvestsTitleYear(int year);

  /// No description provided for @carnetHarvestsSummaryLine.
  ///
  /// In fr, this message translates to:
  /// **'{plantCount} plantes • {totalHarvests} récoltes'**
  String carnetHarvestsSummaryLine(int plantCount, int totalHarvests);

  /// No description provided for @carnetHarvestsCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{count} récolte{count, plural, one{} other{s}} • {lastDate}'**
  String carnetHarvestsCardSubtitle(int count, String lastDate);

  /// No description provided for @carnetHarvestsAddButton.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle récolte'**
  String get carnetHarvestsAddButton;

  /// No description provided for @addHarvestSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une récolte'**
  String get addHarvestSheetTitle;

  /// No description provided for @addHarvestPlantLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plante'**
  String get addHarvestPlantLabel;

  /// No description provided for @addHarvestPlantSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Chercher : tomate, carotte…'**
  String get addHarvestPlantSearchHint;

  /// No description provided for @addHarvestPlantNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante trouvée.'**
  String get addHarvestPlantNoResult;

  /// No description provided for @addHarvestDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get addHarvestDateLabel;

  /// No description provided for @addHarvestQuantityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get addHarvestQuantityLabel;

  /// No description provided for @addHarvestUnitLabel.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get addHarvestUnitLabel;

  /// No description provided for @addHarvestUnitGrams.
  ///
  /// In fr, this message translates to:
  /// **'g'**
  String get addHarvestUnitGrams;

  /// No description provided for @addHarvestUnitKilos.
  ///
  /// In fr, this message translates to:
  /// **'kg'**
  String get addHarvestUnitKilos;

  /// No description provided for @addHarvestUnitPieces.
  ///
  /// In fr, this message translates to:
  /// **'pièces'**
  String get addHarvestUnitPieces;

  /// No description provided for @addHarvestUnitBunches.
  ///
  /// In fr, this message translates to:
  /// **'bottes'**
  String get addHarvestUnitBunches;

  /// No description provided for @addHarvestNoteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note (optionnel)'**
  String get addHarvestNoteLabel;

  /// No description provided for @addHarvestSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la récolte'**
  String get addHarvestSaveButton;

  /// No description provided for @dateRelativeToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get dateRelativeToday;

  /// No description provided for @dateRelativeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get dateRelativeYesterday;

  /// No description provided for @dateRelativeDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {days} j'**
  String dateRelativeDaysAgo(int days);

  /// No description provided for @carnetSeedlingsAddButton.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau semis'**
  String get carnetSeedlingsAddButton;

  /// No description provided for @carnetSeedlingsStatusGerminating.
  ///
  /// In fr, this message translates to:
  /// **'En germination'**
  String get carnetSeedlingsStatusGerminating;

  /// No description provided for @carnetSeedlingsStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêts à repiquer'**
  String get carnetSeedlingsStatusReady;

  /// No description provided for @carnetSeedlingsStatusTransplanted.
  ///
  /// In fr, this message translates to:
  /// **'Repiqués'**
  String get carnetSeedlingsStatusTransplanted;

  /// No description provided for @carnetSeedlingsStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoués'**
  String get carnetSeedlingsStatusFailed;

  /// No description provided for @carnetSeedlingsArchiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Archive'**
  String get carnetSeedlingsArchiveTitle;

  /// No description provided for @carnetSeedlingsUnknownPlant.
  ///
  /// In fr, this message translates to:
  /// **'Plante supprimée'**
  String get carnetSeedlingsUnknownPlant;

  /// No description provided for @carnetSeedlingsSowedOn.
  ///
  /// In fr, this message translates to:
  /// **'Semé le {date}'**
  String carnetSeedlingsSowedOn(String date);

  /// No description provided for @carnetSeedlingsCountInline.
  ///
  /// In fr, this message translates to:
  /// **'{count} godet{count, plural, one{} other{s}}'**
  String carnetSeedlingsCountInline(int count);

  /// No description provided for @addSeedlingSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un semis'**
  String get addSeedlingSheetTitle;

  /// No description provided for @addSeedlingPlantLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plante semée'**
  String get addSeedlingPlantLabel;

  /// No description provided for @addSeedlingSowedAtLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date du semis'**
  String get addSeedlingSowedAtLabel;

  /// No description provided for @addSeedlingCountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de godets / graines (optionnel)'**
  String get addSeedlingCountLabel;

  /// No description provided for @addSeedlingCountHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : 12'**
  String get addSeedlingCountHint;

  /// No description provided for @addSeedlingNoteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note (optionnel)'**
  String get addSeedlingNoteLabel;

  /// No description provided for @addSeedlingSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le semis'**
  String get addSeedlingSaveButton;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @carnetJournalAddButton.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle note'**
  String get carnetJournalAddButton;

  /// No description provided for @carnetJournalEditedLabel.
  ///
  /// In fr, this message translates to:
  /// **'modifié'**
  String get carnetJournalEditedLabel;

  /// No description provided for @carnetJournalDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette note ?'**
  String get carnetJournalDeleteTitle;

  /// No description provided for @carnetJournalDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get carnetJournalDeleteMessage;

  /// No description provided for @addJournalSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle note'**
  String get addJournalSheetTitle;

  /// No description provided for @addJournalEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la note'**
  String get addJournalEditTitle;

  /// No description provided for @addJournalDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get addJournalDateLabel;

  /// No description provided for @addJournalTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre (optionnel)'**
  String get addJournalTitleLabel;

  /// No description provided for @addJournalTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Plantation des tomates'**
  String get addJournalTitleHint;

  /// No description provided for @addJournalContentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get addJournalContentLabel;

  /// No description provided for @addJournalContentHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez librement votre observation, idée, succès ou ennui du jour…'**
  String get addJournalContentHint;

  /// No description provided for @addJournalSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get addJournalSaveButton;

  /// No description provided for @addJournalUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get addJournalUpdateButton;

  /// No description provided for @carnetStatsHeroSeasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'SAISON {year}'**
  String carnetStatsHeroSeasonLabel(int year);

  /// No description provided for @carnetStatsHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{count} récolte{count, plural, one{} other{s}} enregistrée{count, plural, one{} other{s}}'**
  String carnetStatsHeroSubtitle(int count);

  /// No description provided for @carnetStatsHeroPieces.
  ///
  /// In fr, this message translates to:
  /// **'{count} pièces'**
  String carnetStatsHeroPieces(int count);

  /// No description provided for @carnetStatsHeroBunches.
  ///
  /// In fr, this message translates to:
  /// **'{count} bottes'**
  String carnetStatsHeroBunches(int count);

  /// No description provided for @carnetStatsPlantOfTheYearLabel.
  ///
  /// In fr, this message translates to:
  /// **'STAR DE L\'ANNÉE'**
  String get carnetStatsPlantOfTheYearLabel;

  /// No description provided for @carnetStatsPlantOfTheYearCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} récoltes cette saison'**
  String carnetStatsPlantOfTheYearCount(int count);

  /// No description provided for @carnetStatsMonthlyTitle.
  ///
  /// In fr, this message translates to:
  /// **'RÉCOLTES PAR MOIS'**
  String get carnetStatsMonthlyTitle;

  /// No description provided for @carnetStatsTopPlantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'TOP DES PLANTES'**
  String get carnetStatsTopPlantsTitle;

  /// No description provided for @carnetStatsSeedlingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Semis de l\'année'**
  String get carnetStatsSeedlingsTitle;

  /// No description provided for @carnetStatsSeedlingsRingLabel.
  ///
  /// In fr, this message translates to:
  /// **'taux de réussite'**
  String get carnetStatsSeedlingsRingLabel;

  /// No description provided for @carnetStatsSeedlingsTransplanted.
  ///
  /// In fr, this message translates to:
  /// **'Repiqués'**
  String get carnetStatsSeedlingsTransplanted;

  /// No description provided for @carnetStatsSeedlingsFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoués'**
  String get carnetStatsSeedlingsFailed;

  /// No description provided for @carnetStatsSeedlingsInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get carnetStatsSeedlingsInProgress;

  /// No description provided for @carnetStatsCounterNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get carnetStatsCounterNotes;

  /// No description provided for @carnetStatsCounterSeedlings.
  ///
  /// In fr, this message translates to:
  /// **'Semis'**
  String get carnetStatsCounterSeedlings;

  /// No description provided for @premiumRestoreSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Achat Premium restauré.'**
  String get premiumRestoreSuccess;

  /// No description provided for @premiumRestoreNothingFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun achat trouvé sur ce compte Play Store.'**
  String get premiumRestoreNothingFound;

  /// No description provided for @premiumRestoreError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de restaurer.'**
  String get premiumRestoreError;

  /// No description provided for @addHarvestEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la récolte'**
  String get addHarvestEditTitle;

  /// No description provided for @addHarvestUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get addHarvestUpdateButton;

  /// No description provided for @harvestHistorySheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail des récoltes en {unit}'**
  String harvestHistorySheetSubtitle(String unit);

  /// No description provided for @harvestHistoryDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette récolte ?'**
  String get harvestHistoryDeleteTitle;

  /// No description provided for @harvestHistoryDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get harvestHistoryDeleteMessage;

  /// No description provided for @harvestFilterMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get harvestFilterMonth;

  /// No description provided for @harvestFilterPlant.
  ///
  /// In fr, this message translates to:
  /// **'Plante'**
  String get harvestFilterPlant;

  /// No description provided for @harvestFilterUnit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get harvestFilterUnit;

  /// No description provided for @harvestFilterAllMonths.
  ///
  /// In fr, this message translates to:
  /// **'Tous les mois'**
  String get harvestFilterAllMonths;

  /// No description provided for @harvestFilterAllPlants.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les plantes'**
  String get harvestFilterAllPlants;

  /// No description provided for @harvestFilterAllUnits.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les unités'**
  String get harvestFilterAllUnits;

  /// No description provided for @harvestFilterNoMatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune récolte ne correspond'**
  String get harvestFilterNoMatchTitle;

  /// No description provided for @harvestFilterNoMatchSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Essayez de retirer un filtre pour élargir la sélection.'**
  String get harvestFilterNoMatchSubtitle;

  /// No description provided for @harvestFilterReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les filtres'**
  String get harvestFilterReset;

  /// No description provided for @carnetStatsActivitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'ACTIVITÉS DU JARDIN'**
  String get carnetStatsActivitiesTitle;

  /// No description provided for @carnetStatsActivityWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosages'**
  String get carnetStatsActivityWatering;

  /// No description provided for @carnetStatsActivityWateringPlants.
  ///
  /// In fr, this message translates to:
  /// **'Arrosages (plants)'**
  String get carnetStatsActivityWateringPlants;

  /// No description provided for @carnetStatsActivityWateringSeedlings.
  ///
  /// In fr, this message translates to:
  /// **'Arrosages (semis)'**
  String get carnetStatsActivityWateringSeedlings;

  /// No description provided for @seedlingWateredSnack.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage du semi enregistré 💧'**
  String get seedlingWateredSnack;

  /// No description provided for @carnetHeaderHarvests.
  ///
  /// In fr, this message translates to:
  /// **'Mes récoltes'**
  String get carnetHeaderHarvests;

  /// No description provided for @carnetHeaderSeedlings.
  ///
  /// In fr, this message translates to:
  /// **'Mes semis'**
  String get carnetHeaderSeedlings;

  /// No description provided for @carnetHeaderJournal.
  ///
  /// In fr, this message translates to:
  /// **'Carnet de notes'**
  String get carnetHeaderJournal;

  /// No description provided for @carnetHeaderStats.
  ///
  /// In fr, this message translates to:
  /// **'Bilan de la saison'**
  String get carnetHeaderStats;

  /// No description provided for @carnetHeaderSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get carnetHeaderSettings;

  /// No description provided for @carnetHeaderAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos de Jardingue'**
  String get carnetHeaderAbout;

  /// No description provided for @carnetSeedlingsInStock.
  ///
  /// In fr, this message translates to:
  /// **'{remaining} / {total} en stock'**
  String carnetSeedlingsInStock(int remaining, int total);

  /// No description provided for @seedlingTransplantDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Repiquage'**
  String get seedlingTransplantDialogTitle;

  /// No description provided for @seedlingTransplantDialogStockHint.
  ///
  /// In fr, this message translates to:
  /// **'Tu as {stock} plant(s) prêt(s) à repiquer.'**
  String seedlingTransplantDialogStockHint(int stock);

  /// No description provided for @seedlingTransplantDialogCountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Combien planter maintenant ?'**
  String get seedlingTransplantDialogCountLabel;

  /// No description provided for @seedlingTransplantDialogGardenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dans quel potager ?'**
  String get seedlingTransplantDialogGardenLabel;

  /// No description provided for @seedlingTransplantDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Planter'**
  String get seedlingTransplantDialogConfirm;

  /// No description provided for @seedlingTransplantPartialSnack.
  ///
  /// In fr, this message translates to:
  /// **'{planted} repiqué(s) — reste {remaining} en stock.'**
  String seedlingTransplantPartialSnack(int planted, int remaining);

  /// No description provided for @seedlingTransplantNoGardenSnack.
  ///
  /// In fr, this message translates to:
  /// **'Aucun potager pour le repiquage — crée d\'abord un potager.'**
  String get seedlingTransplantNoGardenSnack;

  /// No description provided for @seedlingTransplantNoGardenOption.
  ///
  /// In fr, this message translates to:
  /// **'Aucun potager (plantation libre)'**
  String get seedlingTransplantNoGardenOption;

  /// No description provided for @seedlingFailureDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer des échecs'**
  String get seedlingFailureDialogTitle;

  /// No description provided for @seedlingFailureDialogPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Sur {available} en stock, combien ont échoué ?'**
  String seedlingFailureDialogPrompt(int available);

  /// No description provided for @seedlingFailureDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Soustraire'**
  String get seedlingFailureDialogConfirm;

  /// No description provided for @seedlingAdvanceDialogTitleV2.
  ///
  /// In fr, this message translates to:
  /// **'Bilan de l\'étape'**
  String get seedlingAdvanceDialogTitleV2;

  /// No description provided for @seedlingAdvanceDialogPromptV2.
  ///
  /// In fr, this message translates to:
  /// **'Sur {base} godets, combien ont réussi ? combien ont échoué ?'**
  String seedlingAdvanceDialogPromptV2(int base);

  /// No description provided for @seedlingAdvanceFieldSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Réussis'**
  String get seedlingAdvanceFieldSuccess;

  /// No description provided for @seedlingAdvanceFieldFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoués'**
  String get seedlingAdvanceFieldFailed;

  /// No description provided for @seedlingAdvanceRemainingHint.
  ///
  /// In fr, this message translates to:
  /// **'{count} restent en attente (ni réussis, ni échoués).'**
  String seedlingAdvanceRemainingHint(int count);

  /// No description provided for @seedlingTransplantFieldFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoués depuis'**
  String get seedlingTransplantFieldFailed;

  /// No description provided for @carnetSeedlingsFailedInline.
  ///
  /// In fr, this message translates to:
  /// **'{count} échec{count, plural, one{} other{s}}'**
  String carnetSeedlingsFailedInline(int count);

  /// No description provided for @carnetStatsActivityFertilizing.
  ///
  /// In fr, this message translates to:
  /// **'Fertilisations'**
  String get carnetStatsActivityFertilizing;

  /// No description provided for @carnetStatsActivitySowing.
  ///
  /// In fr, this message translates to:
  /// **'Semis enregistrés'**
  String get carnetStatsActivitySowing;

  /// No description provided for @carnetStatsActivityPlanting.
  ///
  /// In fr, this message translates to:
  /// **'Plantations'**
  String get carnetStatsActivityPlanting;

  /// No description provided for @carnetStatsActivityMulching.
  ///
  /// In fr, this message translates to:
  /// **'Paillages'**
  String get carnetStatsActivityMulching;

  /// No description provided for @carnetStatsActivityOtherCare.
  ///
  /// In fr, this message translates to:
  /// **'Autres soins'**
  String get carnetStatsActivityOtherCare;

  /// No description provided for @carnetStatsTopSortWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids'**
  String get carnetStatsTopSortWeight;

  /// No description provided for @carnetStatsTopSortCount.
  ///
  /// In fr, this message translates to:
  /// **'Récoltes'**
  String get carnetStatsTopSortCount;

  /// No description provided for @carnetStatsTopSortPieces.
  ///
  /// In fr, this message translates to:
  /// **'Pièces'**
  String get carnetStatsTopSortPieces;

  /// No description provided for @carnetStatsTopSortBunches.
  ///
  /// In fr, this message translates to:
  /// **'Bottes'**
  String get carnetStatsTopSortBunches;

  /// No description provided for @carnetSeedlingsSuccessRatio.
  ///
  /// In fr, this message translates to:
  /// **'{success} / {total} godets'**
  String carnetSeedlingsSuccessRatio(int success, int total);

  /// No description provided for @seedlingAdvanceDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passer à : {status}'**
  String seedlingAdvanceDialogTitle(String status);

  /// No description provided for @seedlingAdvanceDialogPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Sur {base} godets, combien sont passés à cette étape ?'**
  String seedlingAdvanceDialogPrompt(int base);

  /// No description provided for @seedlingAdvanceDialogConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get seedlingAdvanceDialogConfirm;

  /// No description provided for @carnetPlantDeletedBadge.
  ///
  /// In fr, this message translates to:
  /// **'supprimée'**
  String get carnetPlantDeletedBadge;

  /// No description provided for @addSeedlingGardenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Potager (optionnel)'**
  String get addSeedlingGardenLabel;

  /// No description provided for @addSeedlingGardenNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get addSeedlingGardenNone;

  /// No description provided for @seedlingTransplantedPlacedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Repiqué dans le potager — pense à repositionner si besoin.'**
  String get seedlingTransplantedPlacedSnack;
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
