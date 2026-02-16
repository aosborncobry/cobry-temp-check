class CobryUser {
  final String uid;
  final String email;
  final String role; // 'client' or 'staff'

  CobryUser({required this.uid, required this.email, required this.role});
}