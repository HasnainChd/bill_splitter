class Group {
  final String groupId;
  final String name;
  final List<String> members;
  final String currency;
  final DateTime createdAt;

  const Group({
    required this.groupId,
    required this.name,
    required this.members,
    required this.currency,
    required this.createdAt,
  });
}
