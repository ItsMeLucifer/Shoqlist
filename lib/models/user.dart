import 'package:hive/hive.dart';
part 'user.g.dart';

@HiveType(typeId: 3)
class User {
  @HiveField(0)
  String nickname;
  @HiveField(1)
  String email;
  @HiveField(2)
  final String userId;

  User(this.nickname, this.email, this.userId);
}
