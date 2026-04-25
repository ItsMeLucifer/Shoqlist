import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pl.dart';

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
    Locale('en'),
    Locale('ja'),
    Locale('pl'),
  ];

  /// The current language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// The name od application
  ///
  /// In en, this message translates to:
  /// **'Shoqlist'**
  String get appName;

  /// 'Sign-in' phrase
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get signIn;

  /// 'Register' word
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// 'Email' word
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// 'Password' word
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// 'My lists' phrase
  ///
  /// In en, this message translates to:
  /// **'My lists'**
  String get myLists;

  /// 'Shared lists' phrase
  ///
  /// In en, this message translates to:
  /// **'Shared lists'**
  String get sharedLists;

  /// 'Settings' word
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// 'Friends' word
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// 'Loyalty cards' phrase
  ///
  /// In en, this message translates to:
  /// **'Loyalty cards'**
  String get loyaltyCards;

  /// 'Create new list' phrase
  ///
  /// In en, this message translates to:
  /// **'Create new list'**
  String get newList;

  /// 'Change nickname' phrase
  ///
  /// In en, this message translates to:
  /// **'Change nickname'**
  String get changeNicknameTitle;

  /// 'Sign-out' phrase
  ///
  /// In en, this message translates to:
  /// **'Sign-out'**
  String get signOut;

  /// 'Delete account' phrase
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// 'Nickname' word
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// 'Save' word
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// 'Cancel' word
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// 'Card name' phrase
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardName;

  /// 'Card code' phrase
  ///
  /// In en, this message translates to:
  /// **'Card code'**
  String get cardCode;

  /// 'Remove' word
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// 'Add' word
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// 'Choose user' phrase
  ///
  /// In en, this message translates to:
  /// **'Choose user'**
  String get chooseUser;

  /// The message that displays when there are no friends to display
  ///
  /// In en, this message translates to:
  /// **'You have no friends or every one of your friends already has access'**
  String get chooseUserEmptyMessage;

  /// 'Importance' word
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get importance;

  /// 'List name' phrase
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// Title of dialog, when creating a new shopping list
  ///
  /// In en, this message translates to:
  /// **'Add new list'**
  String get newListTitle;

  /// Title of dialog, when editing an existing shopping list
  ///
  /// In en, this message translates to:
  /// **'Edit list\'s data'**
  String get editListTitle;

  /// Title of dialog, when editing a shopping list item
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItemTitle;

  /// 'OK' word
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Toast message after copying list text to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// SnackBar shown when a write to Firestore fails and local state had to be reverted
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync — try again'**
  String get syncFailed;

  /// Confirmation when user unshares themselves from a shared list
  ///
  /// In en, this message translates to:
  /// **'Unshare {name}?'**
  String unshareListTitle(String name);

  /// 'Decline' word
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// 'Yes' word
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// 'No' word
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// 'Accept' word
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// The title of the message that displays when you try to delete a shopping list
  ///
  /// In en, this message translates to:
  /// **'Remove the \'{listName}\' list?'**
  String removeListTitle(String listName);

  /// A message displated when user has no shopping lists
  ///
  /// In en, this message translates to:
  /// **'You have no shopping lists'**
  String get noListsMsg;

  /// A message displated when user has no shared lists
  ///
  /// In en, this message translates to:
  /// **'You have no shared lists'**
  String get noSharedListsMsg;

  /// 'Give access' phrase'
  ///
  /// In en, this message translates to:
  /// **'Give access'**
  String get giveAccess;

  /// 'Share' word'
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Message title when sharing a shopping list
  ///
  /// In en, this message translates to:
  /// **'A list has been made available to you!'**
  String get shareListSubject;

  /// The message that pops up when you give access to a friend
  ///
  /// In en, this message translates to:
  /// **'Give access to that friend?'**
  String get giveAccessTitle;

  /// HintText displayed during adding new item to the list
  ///
  /// In en, this message translates to:
  /// **'New item name'**
  String get itemNameHint;

  /// The message that pops up when you want to remove an item
  ///
  /// In en, this message translates to:
  /// **'Remove the \'{itemName}\' item?'**
  String removeItemMsg(String itemName);

  /// The message that pops up when you want to add new loyalty card
  ///
  /// In en, this message translates to:
  /// **'Add new loyalty card'**
  String get newCardTitle;

  /// The message that pops up when you want to add new loyalty card
  ///
  /// In en, this message translates to:
  /// **'Remove the \'{cardName}\' card?'**
  String removeCardTitle(String cardName);

  /// The message that pops up when you want to edit existing loyalty card
  ///
  /// In en, this message translates to:
  /// **'Edit the \'{cardName}\' card'**
  String editCardTitle(String cardName);

  /// The message that pops up when you want to delete account
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?\n\nThis change will be irreversible'**
  String get deleteAccountMsg;

  /// Exception throwed when undefined error happened
  ///
  /// In en, this message translates to:
  /// **'An undefined Error happened'**
  String get undefinedExc;

  /// Exception throwed when no user found for that email
  ///
  /// In en, this message translates to:
  /// **'No user found for that email'**
  String get noUserExc;

  /// Exception throwed when wrong password has been provided
  ///
  /// In en, this message translates to:
  /// **'Wrong password provided for that user'**
  String get passwordExc;

  /// Exception throwed when wrong email has been provided
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailExc;

  /// Exception throwed when account has been disabled
  ///
  /// In en, this message translates to:
  /// **'Your account has been disabled'**
  String get userDisabledExc;

  /// Exception throwed when at least one of the fields in register/login form is empty
  ///
  /// In en, this message translates to:
  /// **'At least one of the fields is empty'**
  String get emptyFieldExc;

  /// Exception throwed when provided password is too weak
  ///
  /// In en, this message translates to:
  /// **'The password provided is too weak'**
  String get weakPasswordExc;

  /// Exception throwed when email is already in use
  ///
  /// In en, this message translates to:
  /// **'The account already exists for that email'**
  String get emailInUseExc;

  /// Exception throwed when there was an error with Google sign-in
  ///
  /// In en, this message translates to:
  /// **'Error with Google sign-in'**
  String get googleSignInExc;

  /// Exception throwed when there was an error with anonymous sign-in
  ///
  /// In en, this message translates to:
  /// **'Error with anonymously sign-in'**
  String get anonymousSignInExc;

  /// 'Friend requests' phrase
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequests;

  /// 'Search friends' phrase
  ///
  /// In en, this message translates to:
  /// **'Search friends'**
  String get searchFriends;

  /// Message displayed when you have no friends
  ///
  /// In en, this message translates to:
  /// **'You have no friends'**
  String get noFriendsMsg;

  /// Message displayed when you want to remove an user from friends list
  ///
  /// In en, this message translates to:
  /// **'Remove from friends list?'**
  String get removeFriendTitle;

  /// Message displayed when you have no friend requests
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any friend requests'**
  String get noFriendRequestsMsg;

  /// Message displayed when you want to accept friend request
  ///
  /// In en, this message translates to:
  /// **'Accept friend request?'**
  String get acceptFriendRequestTitle;

  /// Message displayed when there is no user with provided email
  ///
  /// In en, this message translates to:
  /// **'Can\'t find that user, try again'**
  String get cantFindUserMsg;

  /// Message displayed when searched user is already on the friends list
  ///
  /// In en, this message translates to:
  /// **'This user is already in your friends list'**
  String get userAlreadyFriendMsg;

  /// Message displayed when there is already a pending friend request with this user (sent or received)
  ///
  /// In en, this message translates to:
  /// **'Friend request with this user is already pending'**
  String get friendRequestAlreadyPendingMsg;

  /// Message displayed when you want to send a friend request
  ///
  /// In en, this message translates to:
  /// **'Send friend request?'**
  String get sendFriendRequestTitle;

  /// The lowest importance word
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// The normal importance word
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// The important importance word
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// The urgent importance word
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// The 'Owner' word
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// Message displayed when user want to check who has the access to current shopping list
  ///
  /// In en, this message translates to:
  /// **'Who has access?'**
  String get whoHasAccess;

  /// Message displayed when user want to take away someone's access to his list
  ///
  /// In en, this message translates to:
  /// **'Take away this user\'s access?'**
  String get removeAccessMsg;

  /// The 'you' word
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// The message displayed when there is no users you have shared the shopping list
  ///
  /// In en, this message translates to:
  /// **'You have not shared this shopping list with anyone'**
  String get noUsersYouHaveSharedListMsg;
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
      <String>['en', 'ja', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
