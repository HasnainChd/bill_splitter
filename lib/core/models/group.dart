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

  const Group({
    required this.groupId,
    required this.name,
    required this.members,
    required this.currency,
    required this.createdAt,
  });
}
