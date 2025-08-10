import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('ms')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Student Talent Profiling App'**
  String get appTitle;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Search tab label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Events tab label
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Favorites button label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Filter events button label
  ///
  /// In en, this message translates to:
  /// **'Filter Events'**
  String get filterEvents;

  /// Search events placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search events...'**
  String get searchEvents;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// Events discovery subtitle
  ///
  /// In en, this message translates to:
  /// **'Discover amazing events happening at UTHM'**
  String get discoverEvents;

  /// Favorite events screen title
  ///
  /// In en, this message translates to:
  /// **'Favorite Events'**
  String get favoriteEvents;

  /// Empty state title for favorite events
  ///
  /// In en, this message translates to:
  /// **'No Favorite Events Yet'**
  String get noFavoriteEvents;

  /// Empty state message for favorite events
  ///
  /// In en, this message translates to:
  /// **'Start exploring events and add them to your favorites!'**
  String get startExploringEvents;

  /// Button to explore events
  ///
  /// In en, this message translates to:
  /// **'Explore Events'**
  String get exploreEvents;

  /// Login prompt for favorites
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your favorite events'**
  String get pleaseLoginToViewFavorites;

  /// Go back button
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Success message when adding to favorites
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// Success message when removing from favorites
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// Error message when updating favorites
  ///
  /// In en, this message translates to:
  /// **'Error updating favorites: {error}'**
  String errorUpdatingFavorites(String error);

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Malay language option
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get malayLanguage;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Preferences section title
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Support section title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Account information setting
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// Security setting
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Help and support setting
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// About setting
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Privacy policy setting
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Empty state for notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// Mark all notifications as read button
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// Clear all notifications button
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// Interested count label
  ///
  /// In en, this message translates to:
  /// **'interested'**
  String get interested;

  /// Favorite events count message
  ///
  /// In en, this message translates to:
  /// **'You have {count} favorite events'**
  String youHaveFavoriteEvents(int count);

  /// Share event button
  ///
  /// In en, this message translates to:
  /// **'Share Event'**
  String get shareEvent;

  /// Event details screen title
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Event program tab label
  ///
  /// In en, this message translates to:
  /// **'Event/Program'**
  String get eventProgram;

  /// Discover tab label
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// Account section subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your account information'**
  String get manageYourAccount;

  /// Preferences section subtitle
  ///
  /// In en, this message translates to:
  /// **'Customize your app experience'**
  String get customizeYourExperience;

  /// Support section subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help and information'**
  String get getHelpAndInformation;

  /// Account information subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your personal details'**
  String get updatePersonalDetails;

  /// Security subtitle
  ///
  /// In en, this message translates to:
  /// **'Password and security settings'**
  String get passwordAndSecurity;

  /// Notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotificationPreferences;

  /// Help support subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help with the app'**
  String get getHelpWithApp;

  /// About subtitle
  ///
  /// In en, this message translates to:
  /// **'App version and information'**
  String get appVersionAndInformation;

  /// Privacy policy subtitle
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicy;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Home welcome message
  ///
  /// In en, this message translates to:
  /// **'Ready to showcase your talents today?'**
  String get readyToShowcase;

  /// Create post button
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// Share moment button
  ///
  /// In en, this message translates to:
  /// **'Share Moment'**
  String get shareMoment;

  /// Edit profile screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Basic information tab
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// Academic information tab
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get academic;

  /// Skills and interests tab
  ///
  /// In en, this message translates to:
  /// **'Skills & Interests'**
  String get skillsAndInterests;

  /// Experience tab
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// Basic information section title
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Full name validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// Headline field label
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get headline;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Bio field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Bio field hint text
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get tellUsAboutYourself;

  /// Academic information section title
  ///
  /// In en, this message translates to:
  /// **'Academic Information'**
  String get academicInformation;

  /// Student ID field label
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentId;

  /// Student ID validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your student ID'**
  String get pleaseEnterStudentId;

  /// Program field label
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get program;

  /// Department field label
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// Faculty field label
  ///
  /// In en, this message translates to:
  /// **'Faculty'**
  String get faculty;

  /// Current semester field label
  ///
  /// In en, this message translates to:
  /// **'Current Semester'**
  String get currentSemester;

  /// CGPA field label
  ///
  /// In en, this message translates to:
  /// **'CGPA'**
  String get cgpa;

  /// Skills section title
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// Skills selection description
  ///
  /// In en, this message translates to:
  /// **'Select your skills to showcase your expertise'**
  String get selectYourSkills;

  /// Selected skills label
  ///
  /// In en, this message translates to:
  /// **'Selected Skills'**
  String get selectedSkills;

  /// Add custom skill hint text
  ///
  /// In en, this message translates to:
  /// **'Add custom skill...'**
  String get addCustomSkill;

  /// Skill categories section title
  ///
  /// In en, this message translates to:
  /// **'Skill Categories'**
  String get skillCategories;

  /// Interests section title
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// Interests selection description
  ///
  /// In en, this message translates to:
  /// **'Select your interests to connect with like-minded people'**
  String get selectYourInterests;

  /// Selected interests label
  ///
  /// In en, this message translates to:
  /// **'Selected Interests'**
  String get selectedInterests;

  /// Add custom interest hint text
  ///
  /// In en, this message translates to:
  /// **'Add custom interest...'**
  String get addCustomInterest;

  /// Interest categories section title
  ///
  /// In en, this message translates to:
  /// **'Interest Categories'**
  String get interestCategories;

  /// Save profile button
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// Profile update success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// Profile update error message
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// Image selection success message
  ///
  /// In en, this message translates to:
  /// **'Image selected successfully'**
  String get imageSelectedSuccessfully;

  /// Image selection error message
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errorSelectingImage;

  /// Experience section description
  ///
  /// In en, this message translates to:
  /// **'Add your work experience and internships'**
  String get addYourWorkExperience;

  /// Empty experience state title
  ///
  /// In en, this message translates to:
  /// **'No Experience Added'**
  String get noExperienceAdded;

  /// Empty state instruction
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to start adding'**
  String get tapAddToStartAdding;

  /// Add experience button
  ///
  /// In en, this message translates to:
  /// **'Add Experience'**
  String get addExperience;

  /// Edit experience dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Experience'**
  String get editExperience;

  /// Delete experience dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Experience'**
  String get deleteExperience;

  /// Delete experience confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this experience?'**
  String get deleteExperienceConfirmation;

  /// Job title field label
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// Job title validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter job title'**
  String get pleaseEnterJobTitle;

  /// Company field label
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// Location field label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Currently working checkbox label
  ///
  /// In en, this message translates to:
  /// **'Currently working here'**
  String get currentlyWorking;

  /// Projects section description
  ///
  /// In en, this message translates to:
  /// **'Showcase your projects and achievements'**
  String get showcaseYourProjects;

  /// Projects section title
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// Empty projects state title
  ///
  /// In en, this message translates to:
  /// **'No Projects Added'**
  String get noProjectsAdded;

  /// Add project button
  ///
  /// In en, this message translates to:
  /// **'Add Project'**
  String get addProject;

  /// Edit project dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// Delete project dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// Delete project confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project?'**
  String get deleteProjectConfirmation;

  /// Project title field label
  ///
  /// In en, this message translates to:
  /// **'Project Title'**
  String get projectTitle;

  /// Project title validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter project title'**
  String get pleaseEnterProjectTitle;

  /// Technologies field label
  ///
  /// In en, this message translates to:
  /// **'Technologies'**
  String get technologies;

  /// Project URL field label
  ///
  /// In en, this message translates to:
  /// **'Project URL'**
  String get projectUrl;

  /// Ongoing project checkbox label
  ///
  /// In en, this message translates to:
  /// **'Ongoing project'**
  String get ongoingProject;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;
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
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
