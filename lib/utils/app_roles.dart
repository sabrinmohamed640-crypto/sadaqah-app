/// Canonical role strings stored in Firestore `users/{uid}.role`.
///
/// Admin accounts are **never** assigned by the client app. Promote a user in
/// Firebase Console → Firestore → `users/{uid}` → set `role` to [admin].
class AppRoles {
  AppRoles._();

  static const String muzakki = 'muzakki';
  static const String admin = 'admin';
  static const String mustahik = 'mustahik';

  static bool isAdminRole(String? role) {
    if (role == null || role.isEmpty) return false;
    return role.trim().toLowerCase() == admin;
  }
}
