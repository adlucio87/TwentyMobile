import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TwentyMobile'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// No description provided for @navCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get navCompanies;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @demoBanner.
  ///
  /// In en, this message translates to:
  /// **'🎭 Demo mode · Data is reset every night'**
  String get demoBanner;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning 👋'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon 👋'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening 👋'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Still awake? 👋'**
  String get greetingNight;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @newAction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newAction;

  /// No description provided for @scanBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Scan business card'**
  String get scanBusinessCard;

  /// No description provided for @newContact.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get newContact;

  /// No description provided for @newQuickTask.
  ///
  /// In en, this message translates to:
  /// **'New quick task'**
  String get newQuickTask;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue Tasks'**
  String get overdueTasks;

  /// No description provided for @todayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todayTasks;

  /// No description provided for @tomorrowTasks.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s Tasks'**
  String get tomorrowTasks;

  /// No description provided for @recentContacts.
  ///
  /// In en, this message translates to:
  /// **'Recent Contacts'**
  String get recentContacts;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today! Great job 🎉'**
  String get noTasksToday;

  /// No description provided for @noRecentContacts.
  ///
  /// In en, this message translates to:
  /// **'No recent contacts'**
  String get noRecentContacts;

  /// No description provided for @onlyMobileScan.
  ///
  /// In en, this message translates to:
  /// **'📱 Only available on iPhone and Android'**
  String get onlyMobileScan;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get searchContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get editContact;

  /// No description provided for @deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get deleteContact;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get voiceNote;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @shareContact.
  ///
  /// In en, this message translates to:
  /// **'Share Contact'**
  String get shareContact;

  /// No description provided for @exportVCard.
  ///
  /// In en, this message translates to:
  /// **'Export vCard'**
  String get exportVCard;

  /// No description provided for @importFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Import from phone'**
  String get importFromPhone;

  /// No description provided for @noContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsFound;

  /// No description provided for @deleteContactConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this contact?'**
  String get deleteContactConfirmation;

  /// No description provided for @companies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companies;

  /// No description provided for @searchCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search companies...'**
  String get searchCompanies;

  /// No description provided for @noCompaniesFound.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get noCompaniesFound;

  /// No description provided for @domain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domain;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @linkedContacts.
  ///
  /// In en, this message translates to:
  /// **'Linked Contacts'**
  String get linkedContacts;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasks;

  /// No description provided for @todo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get todo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @linkedContact.
  ///
  /// In en, this message translates to:
  /// **'Linked Contact'**
  String get linkedContact;

  /// No description provided for @noTasksFound.
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get noTasksFound;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitle;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @taskReopened.
  ///
  /// In en, this message translates to:
  /// **'Task reopened'**
  String get taskReopened;

  /// No description provided for @workflows.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get workflows;

  /// No description provided for @manualWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Manual Workflows'**
  String get manualWorkflows;

  /// No description provided for @slideToExecute.
  ///
  /// In en, this message translates to:
  /// **'Slide to execute'**
  String get slideToExecute;

  /// No description provided for @executing.
  ///
  /// In en, this message translates to:
  /// **'Executing...'**
  String get executing;

  /// No description provided for @workflowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Workflow executed successfully'**
  String get workflowSuccess;

  /// No description provided for @workflowFailed.
  ///
  /// In en, this message translates to:
  /// **'Workflow execution failed'**
  String get workflowFailed;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @scanCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Business Card'**
  String get scanCardTitle;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @saveToCrm.
  ///
  /// In en, this message translates to:
  /// **'Save to CRM'**
  String get saveToCrm;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @scannedDetails.
  ///
  /// In en, this message translates to:
  /// **'Scanned Details'**
  String get scannedDetails;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @personalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal Account'**
  String get personalAccount;

  /// No description provided for @apiKeyAdmin.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyAdmin;

  /// No description provided for @customFields.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get customFields;

  /// No description provided for @editFields.
  ///
  /// In en, this message translates to:
  /// **'Edit fields'**
  String get editFields;

  /// No description provided for @iAm.
  ///
  /// In en, this message translates to:
  /// **'I am'**
  String get iAm;

  /// No description provided for @iAmNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — tap to choose'**
  String get iAmNotSet;

  /// No description provided for @iAmHint.
  ///
  /// In en, this message translates to:
  /// **'An API key has no user behind it. Choose who you are so the greeting and “my tasks” are yours.'**
  String get iAmHint;

  /// No description provided for @changeLoginMethod.
  ///
  /// In en, this message translates to:
  /// **'Change login method'**
  String get changeLoginMethod;

  /// No description provided for @applicationTheme.
  ///
  /// In en, this message translates to:
  /// **'Application Theme'**
  String get applicationTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @taskReminderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Task reminder notifications'**
  String get taskReminderNotifications;

  /// No description provided for @reminderAdvance.
  ///
  /// In en, this message translates to:
  /// **'Reminder advance'**
  String get reminderAdvance;

  /// No description provided for @iosContacts.
  ///
  /// In en, this message translates to:
  /// **'iOS Contacts'**
  String get iosContacts;

  /// No description provided for @iosContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Twenty contacts to iOS address book and Caller ID'**
  String get iosContactsSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String minutesBefore(int minutes);

  /// No description provided for @hourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get hourBefore;

  /// No description provided for @dayBefore.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get dayBefore;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @customObjects.
  ///
  /// In en, this message translates to:
  /// **'Custom Objects'**
  String get customObjects;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @allInOrder.
  ///
  /// In en, this message translates to:
  /// **'Everything is in order!'**
  String get allInOrder;

  /// No description provided for @noTasksDueToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks due today'**
  String get noTasksDueToday;

  /// No description provided for @andMoreTasks.
  ///
  /// In en, this message translates to:
  /// **'and {count} more...'**
  String andMoreTasks(int count);

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingError;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @phoneMobile.
  ///
  /// In en, this message translates to:
  /// **'Phone (Mobile)'**
  String get phoneMobile;

  /// No description provided for @importFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Import from contacts'**
  String get importFromContacts;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save Contact'**
  String get saveContact;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @contactAdded.
  ///
  /// In en, this message translates to:
  /// **'Contact added'**
  String get contactAdded;

  /// No description provided for @contactUpdated.
  ///
  /// In en, this message translates to:
  /// **'Contact updated'**
  String get contactUpdated;

  /// No description provided for @contactDeleted.
  ///
  /// In en, this message translates to:
  /// **'Contact deleted'**
  String get contactDeleted;

  /// No description provided for @errorCreatingContact.
  ///
  /// In en, this message translates to:
  /// **'Error creating contact'**
  String get errorCreatingContact;

  /// No description provided for @errorDuringDeletion.
  ///
  /// In en, this message translates to:
  /// **'Error during deletion'**
  String get errorDuringDeletion;

  /// No description provided for @deleteContactConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?\nThis action cannot be undone.'**
  String deleteContactConfirmMessage(String name);

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get saveNote;

  /// No description provided for @noNotesPresent.
  ///
  /// In en, this message translates to:
  /// **'No notes present'**
  String get noNotesPresent;

  /// No description provided for @saveToDeviceContacts.
  ///
  /// In en, this message translates to:
  /// **'Save to Contacts'**
  String get saveToDeviceContacts;

  /// No description provided for @unableOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Unable to open email client'**
  String get unableOpenEmail;

  /// No description provided for @unableStartCall.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the call'**
  String get unableStartCall;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @taskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get taskCreated;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdated;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @reminderNotification.
  ///
  /// In en, this message translates to:
  /// **'Reminder notification'**
  String get reminderNotification;

  /// No description provided for @linkedTo.
  ///
  /// In en, this message translates to:
  /// **'Linked to'**
  String get linkedTo;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use (EULA)'**
  String get termsOfUse;

  /// No description provided for @showTwentyInIosContacts.
  ///
  /// In en, this message translates to:
  /// **'Show Twenty people in iOS Contacts'**
  String get showTwentyInIosContacts;

  /// No description provided for @receiveNotificationBeforeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Receive notification before due date'**
  String get receiveNotificationBeforeDueDate;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @rerecord.
  ///
  /// In en, this message translates to:
  /// **'Rerecord'**
  String get rerecord;

  /// No description provided for @saveAsNote.
  ///
  /// In en, this message translates to:
  /// **'Save as note'**
  String get saveAsNote;

  /// No description provided for @speechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechNotAvailable;

  /// No description provided for @createNewCompany.
  ///
  /// In en, this message translates to:
  /// **'Create New Company'**
  String get createNewCompany;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @removeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get removeDueDate;

  /// No description provided for @analyzingBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Analyzing business card...'**
  String get analyzingBusinessCard;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @verifyData.
  ///
  /// In en, this message translates to:
  /// **'Verify data'**
  String get verifyData;

  /// No description provided for @noLinkedContacts.
  ///
  /// In en, this message translates to:
  /// **'No linked contacts'**
  String get noLinkedContacts;

  /// No description provided for @confidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'✅ Excellent capture — verify data'**
  String get confidenceHigh;

  /// No description provided for @confidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Partial capture — check fields'**
  String get confidenceMedium;

  /// No description provided for @confidenceLow.
  ///
  /// In en, this message translates to:
  /// **'❌ Difficult to read — fill manually'**
  String get confidenceLow;

  /// No description provided for @enterNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter at least name or email'**
  String get enterNameOrEmail;

  /// No description provided for @newCompany.
  ///
  /// In en, this message translates to:
  /// **'New Company'**
  String get newCompany;

  /// No description provided for @editCompany.
  ///
  /// In en, this message translates to:
  /// **'Edit Company'**
  String get editCompany;

  /// No description provided for @deleteCompany.
  ///
  /// In en, this message translates to:
  /// **'Delete Company'**
  String get deleteCompany;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @domainOrWebsite.
  ///
  /// In en, this message translates to:
  /// **'Domain or Website'**
  String get domainOrWebsite;

  /// No description provided for @saveCompany.
  ///
  /// In en, this message translates to:
  /// **'Save Company'**
  String get saveCompany;

  /// No description provided for @companyCreated.
  ///
  /// In en, this message translates to:
  /// **'Company created successfully'**
  String get companyCreated;

  /// No description provided for @companyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Company updated successfully'**
  String get companyUpdated;

  /// No description provided for @companyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Company deleted'**
  String get companyDeleted;

  /// No description provided for @deleteCompanyConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?\nThis action cannot be undone.'**
  String deleteCompanyConfirmMessage(String name);

  /// No description provided for @companyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get companyDetails;

  /// No description provided for @industry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industry;

  /// No description provided for @noCompaniesInDatabase.
  ///
  /// In en, this message translates to:
  /// **'There are no companies in the database.'**
  String get noCompaniesInDatabase;

  /// No description provided for @noteText.
  ///
  /// In en, this message translates to:
  /// **'Note text'**
  String get noteText;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved successfully'**
  String get noteSaved;

  /// No description provided for @selectCompany.
  ///
  /// In en, this message translates to:
  /// **'Select Company'**
  String get selectCompany;

  /// No description provided for @selectContact.
  ///
  /// In en, this message translates to:
  /// **'Select Contact'**
  String get selectContact;

  /// No description provided for @frameBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Frame the business card'**
  String get frameBusinessCard;

  /// No description provided for @keepCardHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Keep the card horizontal and well-lit'**
  String get keepCardHorizontal;

  /// No description provided for @cropBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Crop business card'**
  String get cropBusinessCard;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Filter completed'**
  String get filterCompleted;

  /// No description provided for @addCompany.
  ///
  /// In en, this message translates to:
  /// **'Add Company'**
  String get addCompany;

  /// No description provided for @deleteTaskConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?\nThis action cannot be undone.'**
  String deleteTaskConfirmMessage(String name);

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get noCompletedTasks;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get allClear;

  /// No description provided for @noCheckedTasksYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t checked any tasks yet.'**
  String get noCheckedTasksYet;

  /// No description provided for @noPendingTasksAtTheMoment.
  ///
  /// In en, this message translates to:
  /// **'You have no pending tasks at the moment.'**
  String get noPendingTasksAtTheMoment;

  /// No description provided for @noResultsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No results match your search.'**
  String get noResultsMatchSearch;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your portable CRM always with you. Manage contacts and companies on the go with a premium experience.'**
  String get welcomeSubtitle;

  /// No description provided for @connectCrm.
  ///
  /// In en, this message translates to:
  /// **'Connect your CRM'**
  String get connectCrm;

  /// No description provided for @configureCrm.
  ///
  /// In en, this message translates to:
  /// **'Configure CRM'**
  String get configureCrm;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get tryDemo;

  /// No description provided for @demoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Example data · No configuration required\nData is reset every night'**
  String get demoSubtitle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @instanceUrlQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is your Twenty CRM instance URL?'**
  String get instanceUrlQuestion;

  /// No description provided for @instanceUrl.
  ///
  /// In en, this message translates to:
  /// **'Instance URL'**
  String get instanceUrl;

  /// No description provided for @instanceUrlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. http://localhost:3000'**
  String get instanceUrlHint;

  /// No description provided for @enterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get enterValidUrl;

  /// No description provided for @urlMustStartWithHttp.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get urlMustStartWithHttp;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @demoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Demo temporarily unavailable. Please try again later.'**
  String get demoUnavailable;

  /// No description provided for @authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// No description provided for @howDoYouWantToConnect.
  ///
  /// In en, this message translates to:
  /// **'How do you want to connect?'**
  String get howDoYouWantToConnect;

  /// No description provided for @chooseAccessMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to access your Twenty CRM instance'**
  String get chooseAccessMethod;

  /// No description provided for @loginWithAccount.
  ///
  /// In en, this message translates to:
  /// **'Login with your account'**
  String get loginWithAccount;

  /// No description provided for @loginWithAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your email and password. You will only see data assigned to you.'**
  String get loginWithAccountDesc;

  /// No description provided for @loginWithApiKey.
  ///
  /// In en, this message translates to:
  /// **'Login with API Key'**
  String get loginWithApiKey;

  /// No description provided for @loginWithApiKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Full workspace access. For administrators and owners.'**
  String get loginWithApiKeyDesc;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminBadge;

  /// No description provided for @apiTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'API Token'**
  String get apiTokenTitle;

  /// No description provided for @enterApiToken.
  ///
  /// In en, this message translates to:
  /// **'Enter your Twenty CRM API Token.'**
  String get enterApiToken;

  /// No description provided for @whereFindToken.
  ///
  /// In en, this message translates to:
  /// **'Where can I find the token? Twenty → Settings → API & Webhooks'**
  String get whereFindToken;

  /// No description provided for @tokenHint.
  ///
  /// In en, this message translates to:
  /// **'Enter token...'**
  String get tokenHint;

  /// No description provided for @tokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a token'**
  String get tokenRequired;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @loginWithEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Login with Email'**
  String get loginWithEmailTitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @securityCheck.
  ///
  /// In en, this message translates to:
  /// **'Security check...'**
  String get securityCheck;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @incorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get incorrectCredentials;

  /// No description provided for @noAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get noAccountFound;

  /// No description provided for @unableToReachServer.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server. Check the URL.'**
  String get unableToReachServer;

  /// No description provided for @passwordLoginDisabled.
  ///
  /// In en, this message translates to:
  /// **'Password login is not enabled on this Twenty instance.'**
  String get passwordLoginDisabled;

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorTitle;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your verification code'**
  String get enterVerificationCode;

  /// No description provided for @openAuthenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app and enter the 6-digit code'**
  String get openAuthenticatorApp;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @cantFindCode.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find the code? Check your authenticator app (e.g. Google Authenticator, Authy).'**
  String get cantFindCode;

  /// No description provided for @codePasted.
  ///
  /// In en, this message translates to:
  /// **'Code pasted from clipboard'**
  String get codePasted;

  /// No description provided for @stayUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stay updated'**
  String get stayUpdated;

  /// No description provided for @receiveRemindersTasks.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders for your upcoming tasks'**
  String get receiveRemindersTasks;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;
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
      <String>['de', 'en', 'fr', 'hi', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
