import '../shared/models/user_model.dart';

final mockUsers = [
  UserModel(
    id: 'usr-admin-001',
    fullName: 'Nguyễn Văn An',
    email: 'admin@snms.vn',
    role: UserRole.admin,
  ),
  UserModel(
    id: 'usr-researcher-001',
    fullName: 'TS. Nguyễn Minh Khoa',
    email: 'khoa.researcher@snms.vn',
    role: UserRole.researcher,
  ),
  UserModel(
    id: 'usr-farmmanager-001',
    fullName: 'Trần Văn Đức',
    email: 'duc.manager@snms.vn',
    role: UserRole.farmManager,
  ),
  UserModel(
    id: 'usr-technician-001',
    fullName: 'Lê Thị Hương',
    email: 'huong.tech@snms.vn',
    role: UserRole.technician,
    skills: [
      UserSkill(skillName: 'Tưới tiêu tự động', proficiencyLevel: 5),
      UserSkill(skillName: 'Vận hành cảm biến', proficiencyLevel: 4),
      UserSkill(skillName: 'Bón phân', proficiencyLevel: 4),
    ],
  ),
  UserModel(
    id: 'usr-technician-002',
    fullName: 'Phạm Hoàng Nam',
    email: 'nam.tech@snms.vn',
    role: UserRole.technician,
    skills: [
      UserSkill(skillName: 'Kiểm tra sâu bệnh', proficiencyLevel: 5),
      UserSkill(skillName: 'Vận hành cảm biến', proficiencyLevel: 3),
      UserSkill(skillName: 'Chụp ảnh cây', proficiencyLevel: 4),
    ],
  ),
  UserModel(
    id: 'usr-student-001',
    fullName: 'Võ Thị Lan',
    email: 'lan.student@snms.vn',
    role: UserRole.student,
    skills: [
      UserSkill(skillName: 'Quan sát tăng trưởng', proficiencyLevel: 3),
      UserSkill(skillName: 'Ghi chép dữ liệu', proficiencyLevel: 4),
    ],
  ),
  UserModel(
    id: 'usr-student-002',
    fullName: 'Đỗ Văn Bình',
    email: 'binh.student@snms.vn',
    role: UserRole.student,
    skills: [
      UserSkill(skillName: 'Quan sát tăng trưởng', proficiencyLevel: 4),
      UserSkill(skillName: 'Phân tích mẫu đất', proficiencyLevel: 3),
    ],
  ),
];

UserModel? getUserById(String id) {
  try {
    return mockUsers.firstWhere((u) => u.id == id);
  } catch (_) {
    return null;
  }
}
