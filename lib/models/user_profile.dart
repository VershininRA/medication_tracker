import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 5) // Убедись, что ID уникален (0-Med, 1-Rem, 2-Side, 3-CycleSet, 4-UserProfile)
class UserProfile extends HiveObject {
  @HiveField(0) final String name;
  @HiveField(1) final bool notificationsEnabled;
  @HiveField(2) final DateTime? createdAt;

  UserProfile({
    required this.name,
    this.notificationsEnabled = true,
    this.createdAt,
  });

  UserProfile copyWith({String? name, bool? notificationsEnabled}) {
    return UserProfile(
      name: name ?? this.name,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}