class UserModel {
  final int id;
  final String name;
  final String schoolId;
  final String className;
  final String section;

  UserModel({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      schoolId: json['school_college_id'].toString(),
      className: json['userdetails']['is_class_name'] ?? '',
      section: json['userdetails']['is_section_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schoolId': schoolId,
      'className': className,
      'section': section,
    };
  }
}
