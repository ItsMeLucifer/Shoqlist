// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get language => 'Polski';

  @override
  String get appName => 'Shoqlist';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get register => 'Zarejestruj się';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Hasło';

  @override
  String get myLists => 'Moje listy';

  @override
  String get sharedLists => 'Udostępnione';

  @override
  String get settings => 'Ustawienia';

  @override
  String get friends => 'Znajomi';

  @override
  String get loyaltyCards => 'Karty lojalnościowe';

  @override
  String get newList => 'Stwórz nową listę';

  @override
  String get changeNicknameTitle => 'Zmień pseudonim';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get nickname => 'Pseudonim';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get cardName => 'Nazwa karty';

  @override
  String get cardCode => 'Kod karty';

  @override
  String get remove => 'Usuń';

  @override
  String get add => 'Dodaj';

  @override
  String get chooseUser => 'Wybierz użytkownika';

  @override
  String get chooseUserEmptyMessage =>
      'Nie masz przyjaciół, lub każdy z przyjaciół posiada już dostęp';

  @override
  String get importance => 'Ważność';

  @override
  String get listName => 'Nazwa listy';

  @override
  String get newListTitle => 'Dodaj nową listę';

  @override
  String get editListTitle => 'Edytuj listę';

  @override
  String get editItemTitle => 'Edytuj element';

  @override
  String get ok => 'OK';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get syncFailed => 'Nie udało się zsynchronizować';

  @override
  String unshareListTitle(String name) {
    return 'Odpiąć się od $name?';
  }

  @override
  String get decline => 'Odrzuć';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  @override
  String get accept => 'Akceptuj';

  @override
  String removeListTitle(String listName) {
    return 'Usunąć listę \'$listName\'?';
  }

  @override
  String get noListsMsg => 'Nie masz żadnych list';

  @override
  String get noSharedListsMsg => 'Nie udostępniono ci żadnych list';

  @override
  String get giveAccess => 'Daj dostęp';

  @override
  String get share => 'Udostępnij';

  @override
  String get shareListSubject => 'Udostępniono ci listę!';

  @override
  String get giveAccessTitle => 'Dać dostęp temu przyjacielowi?';

  @override
  String get itemNameHint => 'Nazwa nowego elementu';

  @override
  String removeItemMsg(String itemName) {
    return 'Czy usunąć element \'$itemName\'?';
  }

  @override
  String get newCardTitle => 'Dodaj nową kartę lojalnościową';

  @override
  String removeCardTitle(String cardName) {
    return 'Usunąć kartę \'$cardName\'?';
  }

  @override
  String editCardTitle(String cardName) {
    return 'Edycja karty \'$cardName\'';
  }

  @override
  String get deleteAccountMsg =>
      'Jesteś pewien/na, że chcesz usunąć konto?\n\nTa decyzja jest nieodwracalna';

  @override
  String get undefinedExc => 'Wystąpił niezdefiniowany błąd';

  @override
  String get noUserExc => 'Nie znaleziono użytkownika dla tego adresu e-mail';

  @override
  String get passwordExc => 'Nieprawidłowe hasło';

  @override
  String get emailExc => 'Nieprawidłowy adres e-mail';

  @override
  String get userDisabledExc => 'Twoje konto zostało zablokowane';

  @override
  String get emptyFieldExc => 'Przynajmniej jedno z pól jest puste';

  @override
  String get weakPasswordExc => 'Podane hasło jest za słabe';

  @override
  String get emailInUseExc => 'Dla tego adresu e-mail konto już istnieje';

  @override
  String get googleSignInExc =>
      'Wystąpił błąd przy próbie zalogowania przez platformę Google';

  @override
  String get anonymousSignInExc =>
      'Wystąpił błąd przy próbie anonimowego zalogowania';

  @override
  String get friendRequests => 'Zaproszenia do znajomych';

  @override
  String get searchFriends => 'Szukaj znajomych';

  @override
  String get noFriendsMsg => 'Nie masz żadnych znajomych';

  @override
  String get removeFriendTitle => 'Usunąć z listy znajomych?';

  @override
  String get noFriendRequestsMsg => 'Nie masz żadnych zaproszeń do znajomych';

  @override
  String get acceptFriendRequestTitle =>
      'Zaakceptować zaproszenie do znajomych?';

  @override
  String get cantFindUserMsg =>
      'Nie znaleziono użytkownika z podanym adresem e-mail, spróbuj ponownie';

  @override
  String get sendFriendRequestTitle => 'Wysłać zaproszenie do znajomych?';

  @override
  String get low => 'Mało ważne';

  @override
  String get normal => 'Normalne';

  @override
  String get important => 'Ważne';

  @override
  String get urgent => 'Pilne';

  @override
  String get owner => 'Właściciel';

  @override
  String get whoHasAccess => 'Kto ma dostęp?';

  @override
  String get removeAccessMsg => 'Zabrać dostęp temu użytkownikowi?';

  @override
  String get you => 'Ty';

  @override
  String get noUsersYouHaveSharedListMsg =>
      'Ta lista zakupów nie została nikomu udostępniona';
}
