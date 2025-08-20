/// A data model representing an authenticated user.
///
/// Users can either be registered accounts (with a valid id, username and
/// email) or a temporary guest account. When `isGuest` is true the other
/// fields may be empty. The `token` field holds the JSON Web Token returned
/// from the backend; the frontend will include this token in authenticated
/// requests.
class User {
  final String id;
  final String username;
  final String email;
  final bool isGuest;
  final String token;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.isGuest,
    required this.token,
  });

  /// Creates a guest user with no identifier. No token is attached because
  /// anonymous sessions aren't authenticated on the backend.
  factory User.guest() {
    return const User(
      id: '',
      username: 'Guest',
      email: '',
      isGuest: true,
      token: '',
    );
  }
}