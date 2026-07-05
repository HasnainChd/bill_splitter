import 'package:hive/hive.dart';

part 'group.g.dart';

@HiveType(typeId: 0)
class Group {
  @HiveField(0)
  final String groupId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> members;

  @HiveField(3)
  final String currency;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final int? iconCodePoint;

  @HiveField(6)
  final String? iconFontFamily;

  @HiveField(7)
  final String? createdBy;

  @HiveField(8)
  final String? inviteCode;

  const Group({
    required this.groupId,
    required this.name,
    required this.members,
    required this.currency,
    required this.createdAt,
    this.iconCodePoint,
    this.iconFontFamily,
    this.createdBy,
    this.inviteCode,
  });
}
