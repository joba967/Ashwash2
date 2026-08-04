class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final int totalPoints;
  final int sessionsAttended;
  final int tasksCompleted;
  final String? avatar;
  final String? bio;
  final String? preferredCategory;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'PATIENT',
    this.phone,
    this.totalPoints = 450,
    this.sessionsAttended = 5,
    this.tasksCompleted = 1,
    this.avatar,
    this.bio,
    this.preferredCategory = 'First Time Mother',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'PATIENT',
      phone: json['phone'],
      totalPoints: json['total_points'] ?? 450,
      sessionsAttended: json['sessions_attended'] ?? 5,
      tasksCompleted: json['tasks_completed'] ?? 1,
      avatar: json['avatar'],
      bio: json['bio'],
      preferredCategory: json['category'] ?? json['preferred_category'] ?? 'First Time Mother',
    );
  }
}
