// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get language => '日本語';

  @override
  String get appName => 'ショクリスト';

  @override
  String get signIn => 'サインイン';

  @override
  String get register => 'サインアップ';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get myLists => 'マイリスト';

  @override
  String get sharedLists => '共有リスト';

  @override
  String get settings => 'セットアップ';

  @override
  String get friends => '友達';

  @override
  String get loyaltyCards => 'ポイントカード';

  @override
  String get newList => '新しいリストを作る';

  @override
  String get changeNicknameTitle => 'ニックネームを変更する';

  @override
  String get signOut => 'サインアウト';

  @override
  String get deleteAccount => 'アカウント削除';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get save => 'セーブ';

  @override
  String get cancel => 'キャンセル';

  @override
  String get cardName => 'カード名';

  @override
  String get cardCode => 'カードコード';

  @override
  String get remove => '取り除く';

  @override
  String get add => '追加する';

  @override
  String get chooseUser => 'セレクトユーザー';

  @override
  String get chooseUserEmptyMessage => '友達がいない、または友達が全員すでにアクセスしている';

  @override
  String get importance => '重要性';

  @override
  String get listName => 'リスト名';

  @override
  String get newListTitle => '新しいリストを追加する';

  @override
  String get editListTitle => '編集リスト';

  @override
  String get editItemTitle => '項目を編集';

  @override
  String get ok => 'OK';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get syncFailed => '同期に失敗しました';

  @override
  String unshareListTitle(String name) {
    return '$name の共有を解除しますか？';
  }

  @override
  String get decline => 'キャンセル';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get accept => '受入れる';

  @override
  String removeListTitle(String listName) {
    return '\'$listName\'リストを削除しますか';
  }

  @override
  String get noListsMsg => 'リストが無い';

  @override
  String get noSharedListsMsg => '共有リストが無い';

  @override
  String get giveAccess => 'Daj dostęp';

  @override
  String get share => '分け合う';

  @override
  String get shareListSubject => 'リストが公開されました!';

  @override
  String get giveAccessTitle => 'その友達に分け合うか';

  @override
  String get itemNameHint => '新しいアイテムの名前';

  @override
  String removeItemMsg(String itemName) {
    return '\'$itemName\'アイテムを削除しますか';
  }

  @override
  String get newCardTitle => '新しいポイントカードを追加する';

  @override
  String removeCardTitle(String cardName) {
    return '\'$cardName\'カードを取り除きますか';
  }

  @override
  String editCardTitle(String cardName) {
    return '\'$cardName\'カードをエディトします';
  }

  @override
  String get deleteAccountMsg => '本当にアカウントを削除しますか\n\nこの決定は不可逆的である';

  @override
  String get undefinedExc => '未定義のエラーが発生しました';

  @override
  String get noUserExc => 'このメールアドレスに該当するユーザーはいません';

  @override
  String get passwordExc => 'パスワードが正しくない';

  @override
  String get emailExc => '電子メールアドレスが正しくない';

  @override
  String get userDisabledExc => 'お客様のアカウントはブロックされています';

  @override
  String get emptyFieldExc => '少なくとも1つのフィールドが空である';

  @override
  String get weakPasswordExc => '入力されたパスワードが弱すぎる';

  @override
  String get emailInUseExc => 'このメールアドレスには、すでにアカウントが存在します';

  @override
  String get googleSignInExc => 'Googleからサインインしようとするとエラーが発生した';

  @override
  String get anonymousSignInExc => '匿名でログインしようとしたときにエラーが発生しました';

  @override
  String get friendRequests => '友達申請';

  @override
  String get searchFriends => '友達を探します';

  @override
  String get noFriendsMsg => 'あなたには友達がいない';

  @override
  String get removeFriendTitle => '友達リストから削除するか';

  @override
  String get noFriendRequestsMsg => '友達申請がありません';

  @override
  String get acceptFriendRequestTitle => '友達申請を承認しますか';

  @override
  String get cantFindUserMsg => 'そのユーザーが見つかりません、もう一度試してください';

  @override
  String get sendFriendRequestTitle => '友達申請を確認しますか';

  @override
  String get low => '微々たる';

  @override
  String get normal => '正常';

  @override
  String get important => '重要';

  @override
  String get urgent => 'アージャント';

  @override
  String get owner => 'オーナー';

  @override
  String get whoHasAccess => '誰はアクセスがありますか';

  @override
  String get removeAccessMsg => 'このユーザーのアクセス権を取り除く';

  @override
  String get you => 'あなた';

  @override
  String get noUsersYouHaveSharedListMsg => 'このショッピングリストは誰にも公開されていません';
}
