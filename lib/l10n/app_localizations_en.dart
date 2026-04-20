// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get appName => 'Shoqlist';

  @override
  String get signIn => 'Sign-in';

  @override
  String get register => 'Register';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Password';

  @override
  String get myLists => 'My lists';

  @override
  String get sharedLists => 'Shared lists';

  @override
  String get settings => 'Settings';

  @override
  String get friends => 'Friends';

  @override
  String get loyaltyCards => 'Loyalty cards';

  @override
  String get newList => 'Create new list';

  @override
  String get changeNicknameTitle => 'Change nickname';

  @override
  String get signOut => 'Sign-out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get nickname => 'Nickname';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get cardName => 'Card name';

  @override
  String get cardCode => 'Card code';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get chooseUser => 'Choose user';

  @override
  String get chooseUserEmptyMessage =>
      'You have no friends or every one of your friends already has access';

  @override
  String get importance => 'Importance';

  @override
  String get listName => 'List name';

  @override
  String get newListTitle => 'Add new list';

  @override
  String get editListTitle => 'Edit list\'s data';

  @override
  String get editItemTitle => 'Edit item';

  @override
  String get ok => 'OK';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String unshareListTitle(String name) {
    return 'Unshare $name?';
  }

  @override
  String get decline => 'Decline';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get accept => 'Accept';

  @override
  String removeListTitle(String listName) {
    return 'Remove the \'$listName\' list?';
  }

  @override
  String get noListsMsg => 'You have no shopping lists';

  @override
  String get noSharedListsMsg => 'You have no shared lists';

  @override
  String get giveAccess => 'Give access';

  @override
  String get share => 'Share';

  @override
  String get shareListSubject => 'A list has been made available to you!';

  @override
  String get giveAccessTitle => 'Give access to that friend?';

  @override
  String get itemNameHint => 'New item name';

  @override
  String removeItemMsg(String itemName) {
    return 'Remove the \'$itemName\' item?';
  }

  @override
  String get newCardTitle => 'Add new loyalty card';

  @override
  String removeCardTitle(String cardName) {
    return 'Remove the \'$cardName\' card?';
  }

  @override
  String editCardTitle(String cardName) {
    return 'Edit the \'$cardName\' card';
  }

  @override
  String get deleteAccountMsg =>
      'Are you sure you want to delete your account?\n\nThis change will be irreversible';

  @override
  String get undefinedExc => 'An undefined Error happened';

  @override
  String get noUserExc => 'No user found for that email';

  @override
  String get passwordExc => 'Wrong password provided for that user';

  @override
  String get emailExc => 'Invalid email';

  @override
  String get userDisabledExc => 'Your account has been disabled';

  @override
  String get emptyFieldExc => 'At least one of the fields is empty';

  @override
  String get weakPasswordExc => 'The password provided is too weak';

  @override
  String get emailInUseExc => 'The account already exists for that email';

  @override
  String get googleSignInExc => 'Error with Google sign-in';

  @override
  String get anonymousSignInExc => 'Error with anonymously sign-in';

  @override
  String get friendRequests => 'Friend requests';

  @override
  String get searchFriends => 'Search friends';

  @override
  String get noFriendsMsg => 'You have no friends';

  @override
  String get removeFriendTitle => 'Remove from friends list?';

  @override
  String get noFriendRequestsMsg => 'You don\'t have any friend requests';

  @override
  String get acceptFriendRequestTitle => 'Accept friend request?';

  @override
  String get cantFindUserMsg => 'Can\'t find that user, try again';

  @override
  String get sendFriendRequestTitle => 'Send friend request?';

  @override
  String get low => 'Low';

  @override
  String get normal => 'Normal';

  @override
  String get important => 'Important';

  @override
  String get urgent => 'Urgent';

  @override
  String get owner => 'Owner';

  @override
  String get whoHasAccess => 'Who has access?';

  @override
  String get removeAccessMsg => 'Take away this user\'s access?';

  @override
  String get you => 'You';

  @override
  String get noUsersYouHaveSharedListMsg =>
      'You have not shared this shopping list with anyone';
}
