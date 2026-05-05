/// Model representing a user in the EcoFlora app.
///
/// Contains user profile information including name, email, and role.
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? role;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role,
  });

  /// Returns the full name combining first and last name.
  String get fullName => '$firstName $lastName';

  /// Returns true if the user has the researcher role.
  bool get isResearcher => role?.toLowerCase() == 'ricercatore';
}
