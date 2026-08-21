
class User {
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.avatarUrl,
    this.rating,
    this.email,
    this.dob,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? email;
  final String? avatarUrl;
  final DateTime? dob;
  final double? rating;
}
