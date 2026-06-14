enum UserRole { admin, researcher, farmManager, technician, student }

class UserSkill {
  const UserSkill({required this.skillName, required this.proficiencyLevel});
  final String skillName;
  final int proficiencyLevel;
}

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.skills = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final List<UserSkill> skills;

  String get roleLabel => switch (role) {
    UserRole.admin        => 'Admin',
    UserRole.researcher   => 'Researcher',
    UserRole.farmManager => 'Farm Manager',
    UserRole.technician  => 'Technician',
    UserRole.student     => 'Student',
  };

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts.last[0]}${parts[parts.length - 2][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
